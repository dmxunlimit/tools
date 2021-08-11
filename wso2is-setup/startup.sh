#!/bin/bash

###################

# Configurable Attributes
# Maintain the order of the versions
db_types_arr=(H2 MySQL Oracle PostgreSQL MSSQL)
tomlSupportArr=(wso2is-5.9.0 wso2is-5.10.0 wso2is-5.11.0)
# U2SupportFrom="wso2is-5.2.0"

# To support arguments passing to the script. ex : ./startup "--debug 5005"
startupPrams=$1

###################

# Detect the platform (similar to $OSTYPE)
OS="$(uname)"
case $OS in
'Linux')
    git config --global credential.helper cache
    dockerPemSet=$(docker ps 2>&1 | grep "permission denied")
    if [[ "$dockerPemSet" == *"permission denied"* ]]; then
        sudo chmod 666 /var/run/docker.sock
    fi

    ;;
*NT*)
    git config --system core.longpaths true
    git config --global credential.helper wincred
    ;;
esac

## Colors
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'

##### Automated script update #####

script_dir="$(
  cd "$(dirname "$0")"
  pwd
)"
scriptBaseName="$(basename $0)"
scriptFile="$script_dir/$scriptBaseName"
scriptFilelst="."$scriptBaseName"_latest"
scriptFilelst=$script_dir"/"$scriptFilelst
echo "Checking for latest version of the script $scriptBaseName !"

curl -sf https://raw.githubusercontent.com/dmxunlimit/tools/master/wso2is-setup/$scriptBaseName -o $scriptFilelst

if [ -f "$scriptFilelst" ] && [ -s "$scriptFilelst" ]; then

  case $OS in
  'Linux')
    alias ls='ls --color=auto'
    crr_md5=$(md5sum $scriptFile)
    remt_md5=$(md5sum $scriptFilelst)
    crr_md5=$(echo $crr_md5 | cut -d " " -f1)
    remt_md5=$(echo $remt_md5 | cut -d " " -f1)
    ;;
  'Darwin')
    crr_md5=$(md5 $scriptFile)
    remt_md5=$(md5 $scriptFilelst)
    crr_md5=$(echo $crr_md5 | cut -d "=" -f2)
    remt_md5=$(echo $remt_md5 | cut -d "=" -f2)
    ;;
  *)
    crr_md5=$(md5sum $scriptFile)
    remt_md5=$(md5sum $scriptFilelst)
    crr_md5=$(echo $crr_md5 | cut -d " " -f1)
    remt_md5=$(echo $remt_md5 | cut -d " " -f1)
    ;;
  esac

  if [ "$crr_md5" != "$remt_md5" ]; then
  printf "\n${blu}NEW UPDATE FOUND !\n${end}"
    read -p 'Do you wish to update the script [no]: ' updateScript
    updateScript=$(echo "$updateScript" | awk '{print tolower($0)}')
    if [ "$updateScript" == "yes" ] || [ "$updateScript" == "y" ]; then
      printf "\nUpdating The Script File "
      mv $scriptFilelst $scriptFile
      chmod 755 $scriptFile
      printf "\n\n${red}Please Run The Script Again !!${end}\n\n"
      exit
    fi

  else
    rm -rf $scriptFilelst
  fi
fi

if [ ! -f $script_dir/.artefacts.tar ]; then
    printf "\nDownloading required artefacts ...\n"
    curl -sfL https://github.com/dmxunlimit/tools/raw/master/wso2is-setup/.artefacts.tar -o $script_dir/.artefacts.tar
fi

if [ ! -d $script_dir/artefacts ]; then
    mkdir $script_dir/artefacts
    tar -xf $script_dir/.artefacts.tar -C $script_dir
fi

################

IsDockerReady() {

    dcLog=""
    sleep 2
    sek=0
    echo ""

    while true; do
        sleep 2

        dbStartupState=$(docker logs $dockerReadyTailCount $dockerps 2>&1 | grep "$dockerReadyLog")
        echo -n "$dockerps : "
        if [[ "$dbStartupState" == *"$dockerReadyLog"* ]]; then
            if [ "$dcLog" != "$dbStartupState" ]; then
                echo $dbStartupState
            fi
            break
        else
            tmp=$(docker logs -n1 $dockerps)
            if [ ! -z "$tmp" ] && [ "$dcLog" != "$tmp" ]; then
                dcLog=$tmp
                echo $dcLog
            else
                printf " waiting $sek \r"
                sek=$(($sek + 1))
            fi
        fi

    done
}

DockerStart() {

    dockerps=$(docker ps -a | grep -i "$docker_ps" | rev | cut -d " " -f1 | rev)
    dockerDemon=$(echo $dockerps | grep -i "Error response from daemon")

    if [ ! -z $dockerDemon ]; then
        echo "Docker deamon not running !"
        exit
    fi

    runningContainer=$(docker ps | grep -i "$db_port" | grep -iv "$docker_ps" | rev | cut -d " " -f1 | rev)

    if [ ! -z $runningContainer ]; then
        echo "Already Running Container found, Hence stopping the same."
        docker stop $runningContainer
    fi

    runningContainer=$(docker ps | grep -i "$docker_ps" | rev | cut -d " " -f1 | rev)

    if [ ! -z $runningContainer ]; then

        echo "Already Running Container found"

    else
        if [ ! -z $dockerps ]; then
            printf "\nContainer found, Hence starting "
            docker start $dockerps
            printf "Waiting for container to complete startup, This might take a while !!\n"
            IsDockerReady
        else
            printf "\nWaiting for container to complete startup, This might take a while !!\n"
            docker $docker_run
            dockerps=$(docker ps -a | grep -i "$docker_ps" | rev | cut -d " " -f1 | rev)
            IsDockerReady
        fi
    fi
}

ApplyConfig() {

    isTOMLsupported=false

    for index in "${!tomlSupportArr[@]}"; do

        if [ "${tomlSupportArr[$index]}" == "$isVersion" ]; then
            isTOMLsupported=true
        fi

    done

    if [ "${is_versions_arr[$index]}" == "$tomlSupportFrom" ]; then
        toml_ver_index=$index
        uniqueDbIdVersion=$(expr ${toml_ver_index} + 1)
    fi

    if [ "$isTOMLsupported" = false ]; then
        configFile="$script_dir/"$isVersion"/repository/conf/datasources/master-datasources.xml"
        cp -r "$script_dir/artefacts/xml-based/repository/" "$script_dir/"$isVersion"/repository/"
    else
        configFile="$script_dir/"$isVersion"/repository/conf/deployment.toml"
        cp "$script_dir/artefacts/toml-based/repository/conf/deployment.toml" $configFile
        if [ "$isVersion" == "wso2is-5.9.0" ]; then
            sed -i.bkp 's/'database_unique_id'/'database'/g' $configFile
        fi
    fi

    sed -i.bkp 's/'db_url'/'$db_url'/g' $configFile
    sed -i.bkp 's/'db_username'/'$db_username'/g' $configFile
    sed -i.bkp 's/'db_password'/'$db_password'/g' $configFile
    sed -i.bkp 's/'db_driver'/'$db_driver'/g' $configFile
    sed -i.bkp "s/db_validation_query/$db_validation_query/g" $configFile
    sed -i.bkp "s/db_option_param/$db_option_param/g" $configFile

}

CreateDB() {

    db_status=$(eval "$createdbCMD")

    if [[ "$db_status" != *"$dbExistMsg"* ]]; then
        sleep 2
        for i in $(find $script_dir/$isVersion/dbscripts -name "$dbTypeSqlFile"); do
            echo "Processing File  "$i
            docker cp $i $dockerps:$dockerScriptPath
            echo $(eval "$createSchemaFrmFileCMD") >>startup.log
        done
    else
        echo ""
        read -p 'Database already exists, do you wish to create new database ? [no]: ' db_clean
        db_clean=$(echo "$db_clean" | awk '{print tolower($0)}')
        if [ "$db_clean" == "yes" ] || [ "$db_clean" == "y" ]; then
            echo "Dropping exsiting schema :"$db_schema
            echo $(eval "$dropDBCMD") >>$script_dir/startup.log
            sleep 2
            echo $(eval "$createdbCMD") >>$script_dir/startup.log
            sleep 2
            for i in $(find $script_dir/$isVersion/dbscripts -name "$dbTypeSqlFile"); do
                echo "Processing File  "$i
                docker cp $i $dockerps:$dockerScriptPath
                echo $(eval "$createSchemaFrmFileCMD") >>$script_dir/startup.log
            done
        fi

    fi
}

MySqlFunc() {

    docker_ps="cs-mysql-57"
    db_port=3306
    dockerReadyTailCount="-n4"
    dockerReadyLog="ready for connections"
    docker_run="run -d --name $docker_ps -p $db_port:$db_port -e MYSQL_ROOT_PASSWORD=root mysql:5.7.34"

    DockerStart

    db_schema=$(echo $isVersion | sed -e 's/-/_/g' | sed -e 's/\.//g')
    echo ""
    read -p 'Do you wish to change database name ['$db_schema']: ' input
    db_schema=${input:-$db_schema}
    echo "Using database name :"$db_schema

    db_url="jdbc:mysql:\/\/localhost:3306\/"$db_schema"?autoReconnect=true\&amp;useSSL=false"
    db_username="root"
    db_password="root"
    db_driver="com.mysql.jdbc.Driver"
    db_validation_query="SELECT 1"
    db_option_param='ALLOW_INVALID_DATES'

    ApplyConfig

    docker exec -it $dockerps /bin/sh -c "echo '[client]\nuser=$db_username\npassword=$db_password'>/home/cred.cnf"

    if [[ "$db_option_param" == *"ALLOW_INVALID_DATES"* ]]; then
        echo "Allowing Invalid Dates"
        docker exec -it $dockerps /bin/sh -c "mysql --defaults-extra-file=/home/cred.cnf -e "\""SET GLOBAL SQL_MODE='ALLOW_INVALID_DATES';"\"""
    fi

    createdbCMD="docker exec -it $dockerps /bin/sh -c \"mysql --defaults-extra-file=/home/cred.cnf -e 'create database $db_schema;'\""
    dbExistMsg="exists"
    dbTypeSqlFile="mysql.sql"
    dockerScriptPath="/home/$dbTypeSqlFile"
    createSchemaFrmFileCMD="docker exec -it $dockerps /bin/sh -c \"mysql --defaults-extra-file=/home/cred.cnf $db_schema < $dockerScriptPath\""
    dropDBCMD="docker exec -it $dockerps /bin/sh -c \"mysql --defaults-extra-file=/home/cred.cnf -e 'drop database $db_schema;'\""

    CreateDB
}

OracleFunc() {

    docker_ps="cs-oracle-12c"
    db_port=1521
    dockerReadyTailCount="-n4"
    dockerReadyLog="we are ready to go"
    docker_run="run -d --name $docker_ps --privileged -v $script_dir/artefacts/oradata:/u01/app/oracle -p $db_port:$db_port absolutapps/oracle-12c-ee"

    DockerStart

    db_schema=$(echo $isVersion | sed -e 's/-/_/g' | sed -e 's/\.//g')
    echo ""
    read -p 'Do you wish to change database name ['$db_schema']: ' input
    db_schema=${input:-$db_schema}
    echo "Using database name :"$db_schema

    db_url="jdbc:oracle:thin:@localhost:1521\/ORCL"
    db_username="$db_schema"
    db_password="$db_schema"
    db_driver="oracle.jdbc.driver.OracleDriver"
    db_validation_query="SELECT 1 FROM DUAL"
    db_option_param=""

    ApplyConfig

    docker exec -it -u oracle $dockerps /bin/sh -c "echo 'CREATE USER $db_schema IDENTIFIED BY $db_schema;
    GRANT CONNECT TO $db_schema;
    GRANT CONNECT, RESOURCE, DBA TO $db_schema;
    GRANT CREATE SESSION  TO $db_schema;'>/home/oracle/user.sql"

    oracle_schema=$(echo "$db_schema" | awk '{print toupper($0)}')

    createdbCMD="docker exec -it --user oracle cs-oracle-12c /bin/sh -c \"echo @/home/oracle/user.sql | sqlplus -s / as sysdba\" | grep \"conflicts\""
    dbExistMsg="conflicts"
    dbTypeSqlFile="oracle.sql"
    dockerScriptPath="/home/oracle/$dbTypeSqlFile"
    createSchemaFrmFileCMD="docker exec -it -u oracle $dockerps /bin/sh -c \"echo @/home/oracle/oracle.sql | sqlplus -s $db_schema/$db_schema\""
    dropDBCMD="docker exec -it --user oracle $dockerps /bin/sh -c \"sqlplus -s / as sysdba <<< 'drop user $oracle_schema cascade;'\""

    CreateDB

}

PostgreSqlFunc() {

    docker_ps="cs-postgre-10"
    db_port=5432
    dockerReadyTailCount="-n4"
    dockerReadyLog="ready to accept connections"
    docker_run="run -d --name $docker_ps -p $db_port:$db_port -e POSTGRES_PASSWORD=postgres postgres:10 -c shared_buffers=1024MB -c max_connections=400"

    DockerStart

    db_schema=$(echo $isVersion | sed -e 's/-/_/g' | sed -e 's/\.//g')
    echo ""
    read -p 'Do you wish to change database name ['$db_schema']: ' input
    db_schema=${input:-$db_schema}
    echo "Using database name :"$db_schema

    db_url="jdbc:postgresql:\/\/localhost:5432\/"$db_schema
    db_username="postgres"
    db_password="postgres"
    db_driver="org.postgresql.Driver"
    db_option_param=""
    db_validation_query="SELECT 1;COMMIT"

    ApplyConfig

    createdbCMD="docker exec -it $dockerps psql -U postgres -c \"CREATE DATABASE $db_schema;\""
    dbExistMsg="already exists"
    dbTypeSqlFile="postgresql.sql"
    dockerScriptPath="/var/lib/postgresql/$dbTypeSqlFile"
    createSchemaFrmFileCMD="docker exec -it $dockerps psql -U postgres -d $db_schema -f $dockerScriptPath"
    dropDBCMD="docker exec -it $dockerps psql -U postgres -c \"DROP DATABASE $db_schema;\""

    CreateDB
}

MSSqlFunc() {

    docker_ps="cs-mssql-2017"
    db_port=1433
    dockerReadyTailCount="-n25"
    dockerReadyLog="SQL Server is now ready"
    docker_run="run -d --name $docker_ps -p $db_port:$db_port  -e ACCEPT_EULA=Y -e SA_PASSWORD=SADMIN123# mcr.microsoft.com/mssql/server:2017-latest"

    DockerStart

    db_schema=$(echo $isVersion | sed -e 's/-/_/g' | sed -e 's/\.//g')
    echo ""
    read -p 'Do you wish to change database name ['$db_schema']: ' input
    db_schema=${input:-$db_schema}
    echo "Using database name :"$db_schema

    db_url="jdbc:sqlserver:\/\/localhost:1433;databaseName="$db_schema";SendStringParametersAsUnicode=false"
    db_username="sa"
    db_password="SADMIN123#"
    db_driver="com.microsoft.sqlserver.jdbc.SQLServerDriver"
    db_option_param=""
    db_validation_query="SELECT 1"

    ApplyConfig

    createdbCMD="docker exec -it $dockerps /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $db_password -Q \"CREATE DATABASE $db_schema\""
    dbExistMsg="already exists"
    dbTypeSqlFile="mssql.sql"
    dockerScriptPath="/opt/$dbTypeSqlFile"
    createSchemaFrmFileCMD="docker exec -it $dockerps /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $db_password -d $db_schema -i /opt/mssql.sql"
    dropDBCMD="docker exec -it $dockerps /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $db_password -Q \"DROP DATABASE $db_schema\""

    CreateDB
}

H2Func() {

    db_schema=$(echo $isVersion | sed -e 's/-/_/g' | sed -e 's/\.//g')
    echo ""
    read -p 'Do you wish to change database name ['$db_schema']: ' input
    db_schema=${input:-$db_schema}
    echo "Using database name :"$db_schema

    db_url="jdbc:h2:.\/repository\/database\/"$db_schema";DB_CLOSE_ON_EXIT=FALSE"
    db_username="wso2carbon"
    db_password="wso2carbon"
    db_driver="org.h2.Driver"
    db_validation_query="SELECT 1"
    db_option_param=""

    ApplyConfig

    db_status=$(ls $script_dir/$isVersion/repository/database | grep $db_schema | wc -l)

    if [[ "$db_status" == *"0"* ]]; then
        # sleep 2
        # java -cp $script_dir/artefacts/db-client/h2*.jar org.h2.tools.RunScript -url "jdbc:h2:$script_dir/"$isVersion"/repository/database/"$db_schema -user wso2carbon -password wso2carbon -script $script_dir/$isVersion/dbscripts/h2.sql
        startupPrams="-Dsetup $startupPrams"
        # for i in $(find $script_dir/$isVersion/dbscripts -name "h2.sql"); do
        #     echo "Processing File  "$i
        #     java -cp $script_dir/artefacts/db-client/h2*.jar org.h2.tools.RunScript -url "jdbc:h2:$script_dir/"$isVersion"/repository/database/"$db_schema -user wso2carbon -password wso2carbon -script $i
        #     sleep 1
        # done
    else
        echo ""
        read -p 'Database already exists, do you wish to create new database ? [no]: ' db_clean
        db_clean=$(echo "$db_clean" | awk '{print tolower($0)}')
        if [ "$db_clean" == "yes" ] || [ "$db_clean" == "y" ]; then
            echo "Dropping exsiting schema :"$db_schema
            rm -rf $script_dir/"$isVersion"/repository/database/$db_schema.*
            sleep 2
            # java -cp $script_dir/artefacts/db-client/h2*.jar org.h2.tools.RunScript -url "jdbc:h2:$script_dir/"$isVersion"/repository/database/"$db_schema -user wso2carbon -password wso2carbon -script $script_dir/$isVersion/dbscripts/h2.sql
            startupPrams="-Dsetup $startupPrams"
            # for i in $(find $script_dir/$isVersion/dbscripts -name "h2.sql"); do
            #     echo "Processing File  "$i
            #     java -cp $script_dir/artefacts/db-client/h2*.jar org.h2.tools.RunScript -url "jdbc:h2:$script_dir/"$isVersion"/repository/database/"$db_schema -user wso2carbon -password wso2carbon -script $i
            #     sleep 1
            # done
        fi

    fi

}

updateProduct() {

    u2lvelarg=""

    echo "Updating Product with update 2.0\n"
    read -p 'Enter the update level [latest]: ' updateLevel
    if [ ! -z $updateLevel ]; then
        echo "Removing the exising product to update specific U2 level "$updateLevel
        rm -rf $script_dir/$isVersion
        unzip $script_dir/$isVersion".zip" -d $script_dir
        u2lvelarg=" -l "$updateLevel
    fi

    case $OS in
    'Linux')
        cd $script_dir/$isVersion/bin/
        ./wso2update_linux $u2lvelarg
        ;;
    'Darwin')
        cd $script_dir/$isVersion/bin/
        ./wso2update_darwin $u2lvelarg
        ;;
    *NT*)
        $script_dir/$isVersion/bin/wso2update_windows.exe $u2lvelarg
        ;;
    *)
        echo "Unknown OS Type "$OS
        ;;

    esac

    cd $script_dir
}

for i in $(find $script_dir -mindepth 1 -maxdepth 1 -type d -name "wso2*" -print0 | xargs -0 basename -a | sort -V); do
    is_versions_arr+=("$i")
done

if [ ${#is_versions_arr[@]} -eq 0 ]; then
    printf "\nNO WSO2 Server directories available in the path "$script_dir"\n\n"
    exit
fi

update2_index=2
isVersionIndex=$(expr ${#is_versions_arr[@]} - 1)

# GET IS version
printf "\nAvailable WSO2 Versions\n"
for index in "${!is_versions_arr[@]}"; do
    echo "[$index]  ${is_versions_arr[$index]}"

    # if [ "${is_versions_arr[$index]}" == "$U2SupportFrom" ]; then
    #     update2_index=$index
    # fi

done

read -p 'Enter the index of the WSO2 Server version in above list ['$isVersionIndex']: ' input
isVersionIndex=${input:-$isVersionIndex}
echo "Selected IS version : "${is_versions_arr[$isVersionIndex]}
isVersion=${is_versions_arr[$isVersionIndex]}

if [ ! -d "$script_dir/$isVersion" ]; then
    echo "$isVersion not exists in the location of $script_dir/$isVersion"
    exit
fi

cp -rf "$script_dir/artefacts/drivers/repository/components" "$script_dir/"$isVersion"/repository/"
# cd "$script_dir/$isVersion"

# if [ "$isVersionIndex" -ge "$update2_index" ]; then
#     echo ""
#     read -p 'Do you wish to update the product [no]: ' updateProd
#     updateProd=$(echo "$updateProd" | awk '{print tolower($0)}')
#     if [ "$updateProd" == "yes" ] || [ "$updateProd" == "y" ]; then
#         updateProduct
#     fi
# fi

# GET Database type
printf "\nAvailable Databases\n"
for index in "${!db_types_arr[@]}"; do
    echo "[$index]  ${db_types_arr[$index]}"
done
read -p 'Enter the Database type [0]: ' db_type
echo "Selected Database type : "${db_types_arr[$db_type]}
dbType=${db_types_arr[$db_type]}

case ${db_types_arr[$db_type]} in
'MySQL')
    MySqlFunc
    ;;
'Oracle')
    OracleFunc
    ;;
'PostgreSQL')
    PostgreSqlFunc
    ;;
'MSSQL')
    MSSqlFunc
    ;;
*)
    H2Func
    ;;

esac

printf "\n#### Starting up "$isVersion" with database "$dbType" ####\n\n"

sh $script_dir/$isVersion/bin/wso2server.sh $startupPrams
