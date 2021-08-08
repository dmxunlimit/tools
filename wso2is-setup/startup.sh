#!/bin/bash

# Detect the platform (similar to $OSTYPE)
OS="$(uname)"
case $OS in
'Linux')
    git config --global credential.helper cache
    ;;
*NT*)
    git config --system core.longpaths true
    git config --global credential.helper wincred
    ;;
esac

##### Automated script update #####

script_dir=$(dirname "$0")
scriptBaseName="$(basename $0)"
scriptFile="$script_dir/$scriptBaseName"
scriptFilelst=$scriptFile"_latest"
echo "Checking for latest version of the script $scriptBaseName !"

curl -sf https://raw.githubusercontent.com/dmxunlimit/tools/master/git-tools/$scriptBaseName -o $scriptFilelst

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
    *NT*)
        crr_md5=$(md5sum $scriptFile)
        remt_md5=$(md5sum $scriptFilelst)
        crr_md5=$(echo $crr_md5 | cut -d " " -f1)
        remt_md5=$(echo $remt_md5 | cut -d " " -f1)
        ;;
    *)
        crr_md5=$(md5sum $scriptFile)
        remt_md5=$(md5sum $scriptFilelst)
        crr_md5=$(echo $crr_md5 | cut -d " " -f1)
        remt_md5=$(echo $remt_md5 | cut -d " " -f1)
        ;;
    esac

    if [ "$crr_md5" != "$remt_md5" ]; then
        printf "\nUpdate found for the script, hence updating."
        mv $scriptFilelst $scriptFile
        chmod 755 $scriptFile
        printf "\nPlease run it again !!\n"
        exit
    else
        rm -rf $scriptFilelst
    fi
fi

####

cd $script_dir

wrk_dir=$(pwd)

is_versions_arr=(wso2is-5.0.0 wso2is-5.1.0 wso2is-5.2.0 wso2is-5.3.0 wso2is-5.4.0 wso2is-5.4.1 wso2is-5.5.0 wso2is-5.6.0 wso2is-5.7.0 wso2is-5.8.0 wso2is-5.9.0 wso2is-5.10.0 wso2is-5.11.0)
db_types_arr=(H2 MySQL Oracle PostgreSQL MSSQL)
toml_ver_index=10
update2_index=1

isVersion="wso2is-5.2.0"
isVersionIndex=$(expr ${#is_versions_arr[@]} - 1)
dbType="h2"
startupPrams=""

dockerStart() {

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
            while true; do
                sleep 2
                dbStartupState=$(curl -vs localhost:$db_port 2>&1 | grep Connected)
                if [[ "$dbStartupState" == *"Connected"* ]]; then
                    break
                fi
            done
        else
            echo "Creating new container"
            echo "Waiting for container to complete startup ..."
            docker $docker_run
            dockerps=$(docker ps -a | grep -i "$docker_ps" | rev | cut -d " " -f1 | rev)
            while true; do
                sleep 2
                dbStartupState=$(curl -vs localhost:$db_port 2>&1 | grep Connected)
                if [[ "$dbStartupState" == *"Connected"* ]]; then
                    break
                fi
            done
        fi
    fi
}

mysqlFunc() {

    docker_ps="cs-mysql-57"
    db_port=3306
    docker_run="run -d --name $docker_ps -p $db_port:$db_port -e MYSQL_ROOT_PASSWORD=root mysql:5.7.34"

    dockerStart

    db_schema=$(echo $isVersion | sed -e 's/-/_/g' | sed -e 's/\.//g')
    read -p 'Do you wish to change database name ['$db_schema']: ' input
    db_schema=${input:-$db_schema}
    echo "Using database name :"$db_schema

    db_url="jdbc:mysql:\/\/localhost:3306\/"$db_schema"?autoReconnect=true\&amp;useSSL=false"
    db_username="root"
    db_password="root"
    db_driver="com.mysql.jdbc.Driver"
    db_validation_query="SELECT 1"
    db_option_param=''

    if [ $isVersionIndex -lt $toml_ver_index ]; then
        cp -r "$script_dir/artefacts/xml-based/repository/" "$script_dir/"$isVersion"/repository/"
    else
        configFile="$script_dir/"$isVersion"/repository/conf/deployment.toml"
        cp "$script_dir/artefacts/toml-based/repository/conf/deployment.toml" $configFile
    fi

    sed -i.bkp 's/'db_url'/'$db_url'/g' $configFile
    sed -i.bkp 's/'db_username'/'$db_username'/g' $configFile
    sed -i.bkp 's/'db_password'/'$db_password'/g' $configFile
    sed -i.bkp 's/'db_driver'/'$db_driver'/g' $configFile
    sed -i.bkp "s/db_validation_query/$db_validation_query/g" $configFile
    sed -i.bkp "s/db_option_param/$db_option_param/g" $configFile

    docker exec -it $dockerps /bin/sh -c "echo '[client]\nuser=$db_username\npassword=$db_password'>/home/cred.cnf"

    if [[ "$db_option_param" == *"ALLOW_INVALID_DATES"* ]]; then
        echo "Allowing Invalid Dates"
        docker exec -it $dockerps /bin/sh -c "mysql --defaults-extra-file=/home/cred.cnf -e "\""SET GLOBAL SQL_MODE='ALLOW_INVALID_DATES';"\"""
    fi

    db_status=$(docker exec -it $dockerps /bin/sh -c "mysql --defaults-extra-file=/home/cred.cnf -e 'create database $db_schema;'")
    sleep 2

    if [[ "$db_status" != *"exists"* ]]; then
        for i in $(find $script_dir/$isVersion/dbscripts -name "mysql.sql"); do
            echo "Processing File  "$i
            docker cp $i $dockerps:/home/mysql.sql
            docker exec -it $dockerps /bin/sh -c "mysql --defaults-extra-file=/home/cred.cnf $db_schema < /home/mysql.sql"
        done
    else
        read -p 'Database already exists, do you wish to create new database ? [no]: ' db_clean
        db_clean=$(echo "$db_clean" | awk '{print tolower($0)}')
        if [ "$db_clean" == "yes" ] || [ "$db_clean" == "y" ]; then
            docker exec -it $dockerps /bin/sh -c "mysql --defaults-extra-file=/home/cred.cnf -e 'drop database $db_schema;'"
            sleep 2
            docker exec -it $dockerps /bin/sh -c "mysql --defaults-extra-file=/home/cred.cnf -e 'create database $db_schema;'"
            sleep 2
            for i in $(find $script_dir/$isVersion/dbscripts -name "mysql.sql"); do
                echo "Processing File "$i
                docker cp $i $dockerps:/home/mysql.sql
                docker exec -it $dockerps /bin/sh -c "mysql --defaults-extra-file=/home/cred.cnf $db_schema < /home/mysql.sql"
            done
        fi

    fi

}

oracleFunc() {

    docker_ps="cs-oracle-12c"
    db_port=1521
    docker_run="run -d --name $docker_ps --privileged -v $script_dir/artefacts/oradata:/u01/app/oracle -p $db_port:$db_port absolutapps/oracle-12c-ee"

    dockerStart

    db_schema=$(echo $isVersion | sed -e 's/-/_/g' | sed -e 's/\.//g')
    read -p 'Do you wish to change database name ['$db_schema']: ' input
    db_schema=${input:-$db_schema}
    echo "Using database name :"$db_schema

    db_url="jdbc:oracle:thin:@localhost:1521\/xe"
    db_username="$db_schema"
    db_password="$db_schema"
    db_driver="oracle.jdbc.driver.OracleDriver"
    db_validation_query="SELECT 1 FROM DUAL"
    db_option_param=""

    if [ $isVersionIndex -lt $toml_ver_index ]; then
        configFile="$script_dir/"$isVersion"/repository/conf/datasources/master-datasources.xml"
        cp -r "$script_dir/artefacts/xml-based/repository/" "$script_dir/"$isVersion"/repository/"
    else
        configFile="$script_dir/"$isVersion"/repository/conf/deployment.toml"
        cp "$script_dir/artefacts/toml-based/repository/conf/deployment.toml" $configFile
    fi

    sed -i.bkp 's/'db_url'/'$db_url'/g' $configFile
    sed -i.bkp 's/'db_username'/'$db_username'/g' $configFile
    sed -i.bkp 's/'db_password'/'$db_password'/g' $configFile
    sed -i.bkp 's/'db_driver'/'$db_driver'/g' $configFile
    sed -i.bkp "s/db_validation_query/$db_validation_query/g" $configFile
    sed -i.bkp "s/db_option_param/$db_option_param/g" $configFile

    docker exec -it -u oracle $dockerps /bin/sh -c "echo 'CREATE USER $db_schema IDENTIFIED BY $db_schema;
    GRANT CONNECT TO $db_schema;
    GRANT CONNECT, RESOURCE, DBA TO $db_schema;
    GRANT CREATE SESSION  TO $db_schema;'>/home/oracle/user.sql"

    oracle_schema=$(echo "$db_schema" | awk '{print toupper($0)}')

    db_status=$(docker exec -it --user oracle $dockerps /bin/sh -c "sqlplus -s / as sysdba <<< 'SELECT 1 FROM all_users where username='\''$oracle_schema'\'';'" | grep -i "no rows selected")

    if [[ "$db_status" == *"no rows selected"* ]]; then
        echo $(docker exec -it --user oracle $dockerps /bin/sh -c "echo @/home/oracle/user.sql | sqlplus -s / as sysdba")
        sleep 2
        for i in $(find $script_dir/$isVersion/dbscripts -name "oracle.sql"); do
            echo "Processing File  "$i
            docker cp $i $dockerps:/home/oracle/oracle.sql
            tmp=$(docker exec -it $dockerps /bin/sh -c "echo @/home/oracle/oracle.sql | sqlplus -s $db_schema/$db_schema")
        done
    else
        read -p 'Database already exists, do you wish to create new database ? [no]: ' db_clean
        db_clean=$(echo "$db_clean" | awk '{print tolower($0)}')
        if [ "$db_clean" == "yes" ] || [ "$db_clean" == "y" ]; then
            echo "Dropping exsiting schema :"$oracle_schema
            echo $(docker exec -it --user oracle $dockerps /bin/sh -c "sqlplus -s / as sysdba <<< 'drop user $oracle_schema cascade;'")
            sleep 2
            echo $(docker exec -it --user oracle $dockerps /bin/sh -c "echo @/home/oracle/user.sql | sqlplus -s / as sysdba")
            sleep 2
            for i in $(find $script_dir/$isVersion/dbscripts -name "oracle.sql"); do
                echo "Processing File  "$i
                docker cp $i $dockerps:/home/oracle/oracle.sql
                tmp=$(docker exec -it $dockerps /bin/sh -c "echo @/home/oracle/oracle.sql | sqlplus -s $db_schema/$db_schema")
            done
        fi

    fi

}

postgresqlFunc() {

    docker_ps="cs-postgre-10"
    db_port=5432
    docker_run="run -d --name $docker_ps -p $db_port:$db_port -e POSTGRES_PASSWORD=postgres postgres:10 -c shared_buffers=1024MB -c max_connections=400"

    dockerStart

    db_schema=$(echo $isVersion | sed -e 's/-/_/g' | sed -e 's/\.//g')
    read -p 'Do you wish to change database name ['$db_schema']: ' input
    db_schema=${input:-$db_schema}
    echo "Using database name :"$db_schema

    db_url="jdbc:postgresql:\/\/localhost:5432\/"$db_schema
    db_username="postgres"
    db_password="postgres"
    db_driver="org.postgresql.Driver"
    db_option_param=""
    db_validation_query="SELECT 1;COMMIT"

    if [ $isVersionIndex -lt $toml_ver_index ]; then
        configFile="$script_dir/"$isVersion"/repository/conf/datasources/master-datasources.xml"
        cp -r "$script_dir/artefacts/xml-based/repository/" "$script_dir/"$isVersion"/repository/"
    else
        configFile="$script_dir/"$isVersion"/repository/conf/deployment.toml"
        cp "$script_dir/artefacts/toml-based/repository/conf/deployment.toml" $configFile
    fi

    sed -i.bkp 's/'db_url'/'$db_url'/g' $configFile
    sed -i.bkp 's/'db_username'/'$db_username'/g' $configFile
    sed -i.bkp 's/'db_password'/'$db_password'/g' $configFile
    sed -i.bkp 's/'db_driver'/'$db_driver'/g' $configFile
    sed -i.bkp "s/db_validation_query/$db_validation_query/g" $configFile
    sed -i.bkp "s/db_option_param/$db_option_param/g" $configFile

    db_status=$(docker exec -it $dockerps psql -U postgres -c "CREATE DATABASE $db_schema;")

    if [[ "$db_status" != *"already exists"* ]]; then
        sleep 2
        for i in $(find $script_dir/$isVersion/dbscripts -name "postgresql.sql"); do
            echo "Processing File  "$i
            docker cp $i $dockerps:/var/lib/postgresql/postgres.sql
            tmp=$(docker exec -it $dockerps psql -U postgres -d $db_schema -f /var/lib/postgresql/postgres.sql)
        done
    else
        read -p 'Database already exists, do you wish to create new database ? [no]: ' db_clean
        db_clean=$(echo "$db_clean" | awk '{print tolower($0)}')
        if [ "$db_clean" == "yes" ] || [ "$db_clean" == "y" ]; then
            echo "Dropping exsiting schema :"$db_schema
            echo $(docker exec -it $dockerps psql -U postgres -c "DROP DATABASE $db_schema;")
            sleep 2
            echo $(docker exec -it $dockerps psql -U postgres -c "CREATE DATABASE $db_schema;")
            sleep 2
            for i in $(find $script_dir/$isVersion/dbscripts -name "postgresql.sql"); do
                echo "Processing File  "$i
                docker cp $i $dockerps:/var/lib/postgresql/postgres.sql
                tmp=$(docker exec -it $dockerps psql -U postgres -d $db_schema -f /var/lib/postgresql/postgres.sql)
            done
        fi

    fi

}

mssqlFunc() {

    docker_ps="cs-mssql-2017"
    db_port=1433
    docker_run="run -d --name $docker_ps -p $db_port:$db_port  -e ACCEPT_EULA=Y -e SA_PASSWORD=SADMIN123# mcr.microsoft.com/mssql/server:2017-latest"

    dockerStart

    db_schema=$(echo $isVersion | sed -e 's/-/_/g' | sed -e 's/\.//g')
    read -p 'Do you wish to change database name ['$db_schema']: ' input
    db_schema=${input:-$db_schema}
    echo "Using database name :"$db_schema

    db_url="jdbc:sqlserver:\/\/localhost:1433;databaseName="$db_schema";SendStringParametersAsUnicode=false"
    db_username="sa"
    db_password="SADMIN123#"
    db_driver="com.microsoft.sqlserver.jdbc.SQLServerDriver"
    db_option_param=""
    db_validation_query="SELECT 1"

    if [ $isVersionIndex -lt $toml_ver_index ]; then
        configFile="$script_dir/"$isVersion"/repository/conf/datasources/master-datasources.xml"
        cp -r "$script_dir/artefacts/xml-based/repository/" "$script_dir/"$isVersion"/repository/"
    else
        configFile="$script_dir/"$isVersion"/repository/conf/deployment.toml"
        cp "$script_dir/artefacts/toml-based/repository/conf/deployment.toml" $configFile
    fi

    sed -i.bkp 's/'db_url'/'$db_url'/g' $configFile
    sed -i.bkp 's/'db_username'/'$db_username'/g' $configFile
    sed -i.bkp 's/'db_password'/'$db_password'/g' $configFile
    sed -i.bkp 's/'db_driver'/'$db_driver'/g' $configFile
    sed -i.bkp "s/db_validation_query/$db_validation_query/g" $configFile
    sed -i.bkp "s/db_option_param/$db_option_param/g" $configFile

    db_status=$(docker exec -it $dockerps /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $db_password -Q "CREATE DATABASE $db_schema")

    if [[ "$db_status" != *"already exists"* ]]; then
        sleep 2
        for i in $(find $script_dir/$isVersion/dbscripts -name "mssql.sql"); do
            echo "Processing File  "$i
            docker cp $i $dockerps:/opt/mssql.sql
            tmp=$(docker exec -it $dockerps /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $db_password -d $db_schema -i /opt/mssql.sql)
        done
    else
        read -p 'Database already exists, do you wish to create new database ? [no]: ' db_clean
        db_clean=$(echo "$db_clean" | awk '{print tolower($0)}')
        if [ "$db_clean" == "yes" ] || [ "$db_clean" == "y" ]; then
            echo "Dropping exsiting schema :"$db_schema
            echo $(docker exec -it $dockerps /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $db_password -Q "DROP DATABASE $db_schema")
            sleep 2
            echo $(docker exec -it $dockerps /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $db_password -Q "CREATE DATABASE $db_schema")
            sleep 2
            for i in $(find $script_dir/$isVersion/dbscripts -name "mssql.sql"); do
                echo "Processing File  "$i
                docker cp $i $dockerps:/opt/mssql.sql
                tmp=$(docker exec -it $dockerps /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $db_password -d $db_schema -i /opt/mssql.sql)
            done
        fi

    fi

}

h2Func() {

    db_schema=$(echo $isVersion | sed -e 's/-/_/g' | sed -e 's/\.//g')
    read -p 'Do you wish to change database name ['$db_schema']: ' input
    db_schema=${input:-$db_schema}
    echo "Using database name :"$db_schema

    db_url="jdbc:h2:.\/repository\/database\/"$db_schema";DB_CLOSE_ON_EXIT=FALSE"
    db_username="wso2carbon"
    db_password="wso2carbon"
    db_driver="org.h2.Driver"
    db_validation_query="SELECT 1"
    db_option_param=""

    if [ $isVersionIndex -lt $toml_ver_index ]; then
        configFile="$script_dir/"$isVersion"/repository/conf/datasources/master-datasources.xml"
        cp -r "$script_dir/artefacts/xml-based/repository/" "$script_dir/"$isVersion"/repository/"
    else
        configFile="$script_dir/"$isVersion"/repository/conf/deployment.toml"
        cp "$script_dir/artefacts/toml-based/repository/conf/deployment.toml" $configFile
        if [ $isVersionIndex -lt 12 ]; then
            sed -i.bkp 's/'database_unique_id'/'database'/g' $configFile
        fi
    fi

    sed -i.bkp 's/'db_url'/'$db_url'/g' $configFile
    sed -i.bkp 's/'db_username'/'$db_username'/g' $configFile
    sed -i.bkp 's/'db_password'/'$db_password'/g' $configFile
    sed -i.bkp 's/'db_driver'/'$db_driver'/g' $configFile
    sed -i.bkp "s/db_validation_query/$db_validation_query/g" $configFile
    sed -i.bkp "s/db_option_param/$db_option_param/g" $configFile

    db_status=$(ls $script_dir/$isVersion/repository/database | grep $db_schema | wc -l)

    if [[ "$db_status" == *"0"* ]]; then
        # sleep 2
        # java -cp $script_dir/artefacts/db-client/h2*.jar org.h2.tools.RunScript -url "jdbc:h2:$script_dir/"$isVersion"/repository/database/"$db_schema -user wso2carbon -password wso2carbon -script $script_dir/$isVersion/dbscripts/h2.sql
        startupPrams="-Dsetup"
        # for i in $(find $script_dir/$isVersion/dbscripts -name "h2.sql"); do
        #     echo "Processing File  "$i
        #     java -cp $script_dir/artefacts/db-client/h2*.jar org.h2.tools.RunScript -url "jdbc:h2:$script_dir/"$isVersion"/repository/database/"$db_schema -user wso2carbon -password wso2carbon -script $i
        #     sleep 1
        # done
    else
        read -p 'Database already exists, do you wish to create new database ? [no]: ' db_clean
        db_clean=$(echo "$db_clean" | awk '{print tolower($0)}')
        if [ "$db_clean" == "yes" ] || [ "$db_clean" == "y" ]; then
            echo "Dropping exsiting schema :"$db_schema
            rm -rf $script_dir/"$isVersion"/repository/database/$db_schema.*
            sleep 2
            # java -cp $script_dir/artefacts/db-client/h2*.jar org.h2.tools.RunScript -url "jdbc:h2:$script_dir/"$isVersion"/repository/database/"$db_schema -user wso2carbon -password wso2carbon -script $script_dir/$isVersion/dbscripts/h2.sql
            startupPrams="-Dsetup"
            # for i in $(find $script_dir/$isVersion/dbscripts -name "h2.sql"); do
            #     echo "Processing File  "$i
            #     java -cp $script_dir/artefacts/db-client/h2*.jar org.h2.tools.RunScript -url "jdbc:h2:$script_dir/"$isVersion"/repository/database/"$db_schema -user wso2carbon -password wso2carbon -script $i
            #     sleep 1
            # done
        fi

    fi

}

# GET IS version
printf "\nAvailable WSO2IS Versions\n"
for index in "${!is_versions_arr[@]}"; do
    echo "[$index]  ${is_versions_arr[$index]}"
done
read -p 'Enter the index of the WSO2IS Version in above list ['$isVersionIndex']: ' input
isVersionIndex=${input:-$isVersionIndex}
echo "Selected IS version : "${is_versions_arr[$isVersionIndex]}
isVersion=${is_versions_arr[$isVersionIndex]}

if [ ! -d "$script_dir/$isVersion" ]; then
    echo "$isVersion not exists in the location of $script_dir/$isVersion"
    exit
fi

cp -r "$script_dir/artefacts/drivers/repository/" "$script_dir/"$isVersion"/repository/"
cd "$script_dir/$isVersion"

if [ "$isVersionIndex" -gt "$update2_index" ]; then
    read -p 'Do you wish to update the product [no]: ' updateProd
    updateProd=$(echo "$updateProd" | awk '{print tolower($0)}')
    if [ "$updateProd" == "yes" ] || [ "$updateProd" == "y" ]; then
        echo "Updating Product with update 2.0"
        read -p 'Enter the update level : ' updateLevel

        # if [ ! -z $updateLevel ]; then

        # fi
    fi
fi

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
    mysqlFunc
    ;;
'Oracle')
    oracleFunc
    ;;
'PostgreSQL')
    postgresqlFunc
    ;;
'MSSQL')
    mssqlFunc
    ;;
*)
    h2Func
    ;;

esac

printf "\n#### Starting up "$isVersion" with database "$dbType" ####\n\n"

sh $script_dir/$isVersion/bin/wso2server.sh $startupPrams
