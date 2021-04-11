#!/bin/bash
# run this from your workspace, which contains all your Git repos
# usage : ./git-checkout <product_version> <force>
# usage : ./git-checkout 5.2.0 y

repopath='/Users/supunpe/Documents/wso2/git/wso2-support/product-is/pom.xml'
CUR_DIR=$(pwd)
echo >repo-versions
git config --global credential.helper cache

wrk_dir=$(pwd)

PRODCT_VER_FILE=$wrk_dir'/product-is-versions'
INVALID_REPOS_FILE=$wrk_dir'/invalid-repos'

MAPPED_REPOS_FILE=$wrk_dir'/repo-mapping'

if [ ! -f "$MAPPED_REPOS_FILE" ]; then
curl -s https://raw.githubusercontent.com/dmxunlimit/tools/master/git-tools/repo-mapping -o repo-mapping
fi

if [ ! -f "$PRODCT_VER_FILE" ]; then
    curl -s https://raw.githubusercontent.com/dmxunlimit/tools/master/git-tools/product-is-versions -o product-is-versions
fi

if [ ! -f "$INVALID_REPOS_FILE" ]; then
    curl -s https://raw.githubusercontent.com/dmxunlimit/tools/master/git-tools/invalid-repos -o invalid-repos
fi

DIR_PROD_IS=$wrk_dir'/product-is'
if [ ! -d "$DIR_PROD_IS" ]; then
    git clone "https://github.com/wso2-support/product-is"
fi

while read line || [ -n "$line" ]; do
    echo
    prodVersion=$(echo $line | sed -e 's/support-/\wso2is-/g' | sed 's/\./\-/g')
    display_name=$(echo $line | sed -e 's/support-/\WSO2IS-/g')
    echo "### "$display_name" ###"
    echo "## $display_name" >>repo-versions

    cd product-is
    git checkout $line
    git pull
    cd $CUR_DIR
    echo

    getRepoVersions() {

        line=$(echo $1 | sed -e 's/<\/.*/'\''/g' | sed -e 's/<//g')
        key=$(echo $line | cut -d ">" -f1 | sed 's/\./\-/g' | sed -e 's/version//g' | sed 's/.$//')
        gitrepo=$key
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
            final_key=$key"-"$prodVersion"='$value"
            echo $final_key >>repo-versions

            if [ ! -d "$gitrepo" ]; then
                mappedRepo=$(grep "^$gitrepo=" $MAPPED_REPOS_FILE)
                invalidRepo=$(grep "^$gitrepo$" $INVALID_REPOS_FILE)

                if [ ! -z "$mappedRepo" ]; then
                    gitorg=$(echo $mappedRepo | cut -d "=" -f2 | cut -d "#" -f2)
                    gitrepo=$(echo $mappedRepo | cut -d "=" -f2 | cut -d "#" -f1)
                    if [ ! -d "$gitrepo" ]; then
                        echo "Mapped Repo :"$gitrepo
                        git clone "https://github.com/$gitorg/$gitrepo.git"
                    fi

                elif [ -z "$invalidRepo" ]; then

                    git clone "https://github.com/wso2-support/$gitrepo.git"

                    if [[ $? != 0 ]]; then
                        echo
                        echo "Unable to locate the repository in wso2-support , hence checking with wso2-extensions"
                        git clone "https://github.com/wso2-extensions/$gitrepo.git"
                        if [[ $? != 0 ]]; then
                            echo "$gitrepo" >>$INVALID_REPOS_FILE
                        fi
                        echo
                    else
                        echo
                    fi
                fi
            fi

        fi

    done <./temp-versions
    echo "" >>repo-versions
done <$PRODCT_VER_FILE

rm -rf ./temp-versions

printf "\nCompleted!\n"
