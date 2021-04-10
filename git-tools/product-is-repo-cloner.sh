repopath='/Users/supunpe/Documents/wso2/git/wso2-support/product-is/pom.xml'
CUR_DIR=$(pwd)
echo >repo-versions
echo >repos-not-found

FILE=./product-is-versions

if [ ! -f "$FILE" ]; then
  curl -s https://raw.githubusercontent.com/dmxunlimit/tools/master/git-tools/product-is-versions -o product-is-versions
fi


while read line || [ -n "$line" ]; do
    echo
    prodVersion=$(echo $line | sed -e 's/\support-/\wso2is_/g' | sed 's/\./\_/g')
    echo "### "$prodVersion" ###"
    echo "## $prodVersion" >>repo-versions

    git clone "https://github.com/wso2-support/product-is"
    cd product-is
    git checkout $line
    git pull
    cd $CUR_DIR
    echo

    getRepoVersions() {

        line=$(echo $1 | sed -e 's/<\/.*/'\''/g' | sed -e 's/<//g')
        key=$(echo $line | cut -d ">" -f1 | sed 's/\./\_/g' | sed 's/\-/\_/g' | sed 's/\version//g' | sed 's/.$//')
        gitrepo=$(echo $key | sed 's/\_/\-/g')
        value=$(echo $line | cut -d ">" -f2)
    }

    grep ".version>" product-is/pom.xml | grep -v "<version>" >temp-versions
    jag_version=$(grep "jaggery.extensions.version>" temp-versions)

    getRepoVersions $jag_version
    jag_version=$value

    while read line || [ -n "$line" ]; do

        if [[ "$line" != "<!--"* ]]; then
            getRepoVersions $line

            if [[ "$value" == *"jaggery.extensions.version"* ]]; then
                value=$jag_version
            fi
            final_key=$key"_"$prodVersion"='$value"
            echo $final_key >>repo-versions

            if [ ! -d "$gitrepo" ]; then

                git clone "https://github.com/wso2-support/$gitrepo.git"

                if [[ $? != 0 ]]; then
                    echo
                    echo "Unable to locate the repository in wso2-support , hence checking with wso2-extensions"
                    git clone "https://github.com/wso2-extensions/$gitrepo.git"
                    if [[ $? != 0 ]]; then
                        echo "$gitrepo" >>repos-not-found
                    fi
                    echo
                else
                    echo
                fi
            fi

        fi

    done <./temp-versions
    echo "" >>repo-versions
done <./product-is-versions

rm -rf temp-versions
