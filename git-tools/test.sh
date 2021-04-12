#!/bin/bash
# run this from your workspace, which contains all your Git repos
# usage : ./git-checkout <product_version> <force>
# usage : ./git-checkout 5.2.0 y

####

script_dir=$(dirname "$0")
scriptFilebaseNme="$(basename $0)"
scriptFile="$script_dir/$scriptFilebaseNme"
scriptFilelst=$scriptFile"_latest"
echo "Checking for latest version of the script $scriptFile !"

if [ -f "$scriptFilelst" ]; then
    rm -rf $scriptFilelst
fi

wget -q https://raw.githubusercontent.com/dmxunlimit/tools/master/git-tools/$scriptFilebaseNme -O $scriptFilelst

if [ -f "$scriptFilelst" ]; then
    # Detect the platform (similar to $OSTYPE)
    OS="$(uname)"
    case $OS in
    'Linux')
        OS='Linux'
        alias ls='ls --color=auto'
        crr_md5=$(md5sum $scriptFile)
        remt_md5=$(md5sum $scriptFilelst)
        crr_md5=$(echo $crr_md5 | cut -d " " -f1)
        remt_md5=$(echo $remt_md5 | cut -d " " -f1)
        ;;
    'Darwin')
        OS='Mac'
        crr_md5=$(md5 $scriptFile)
        remt_md5=$(md5 $scriptFilelst)
        crr_md5=$(echo $crr_md5 | cut -d "=" -f2)
        remt_md5=$(echo $remt_md5 | cut -d "=" -f2)
        ;;
    *)
        crr_md5=$(md5sum $scriptFile)
        remt_md5=$(md5sum $scriptFilelst)
        ;;
    esac

    crr_md5=$(echo $crr_md5 | cut -d "=" -f2)
    remt_md5=$(echo $remt_md5 | cut -d "=" -f2)
    echo $crr_md5
    echo $remt_md5
    if [ "$crr_md5" != "$remt_md5" ]; then
        echo "Update found for the script, hence updating."
        mv $scriptFilelst $scriptFile
        chmod 755 $scriptFile
        printf "Script updated ! \n\nPlease run it again."
        exit
    else
        rm -rf $scriptFilelst
    fi
fi
####
exit
CUR_DIR=$(pwd)

git config --global credential.helper cache

wrk_dir=$(pwd)
mkdir -p $wrk_dir'/artefacts'

PRODCT_VER_FILE=$wrk_dir'/artefacts/product-is-versions'
INVALID_REPOS_FILE=$wrk_dir'/artefacts/invalid-repos'
MAPPED_REPOS_FILE=$wrk_dir'/artefacts/repo-mapping'
REPO_VERSIONS_FILE=$wrk_dir'/artefacts/repo-versions'
echo >$REPO_VERSIONS_FILE

if [ ! -f "$MAPPED_REPOS_FILE" ]; then
    curl -s https://raw.githubusercontent.com/dmxunlimit/tools/master/git-tools/artefacts/repo-mapping -o $MAPPED_REPOS_FILE
fi

if [ ! -f "$PRODCT_VER_FILE" ]; then
    curl -s https://raw.githubusercontent.com/dmxunlimit/tools/master/git-tools/artefacts/product-is-versions -o $PRODCT_VER_FILE
fi

if [ ! -f "$INVALID_REPOS_FILE" ]; then
    curl -s https://raw.githubusercontent.com/dmxunlimit/tools/master/git-tools/artefacts/invalid-repos -o $INVALID_REPOS_FILE
fi

DIR_PROD_IS=$wrk_dir'/product-is'
if [ ! -d "$DIR_PROD_IS" ]; then
    git clone "https://github.com/wso2-support/product-is"
fi

cloneRepo() {

    if [ ! -d "$gitrepo" ]; then
        mappedRepo=$(grep "^$gitrepo=" $MAPPED_REPOS_FILE)
        invalidRepo=$(grep "^$gitrepo$" $INVALID_REPOS_FILE)

        if [ ! -z "$mappedRepo" ]; then
            gitorg=$(echo $mappedRepo | cut -d "=" -f2 | cut -d "#" -f2)
            gitrepo=$(echo $mappedRepo | cut -d "=" -f2 | cut -d "#" -f1)
            if [ ! -d "$gitrepo" ]; then
                echo "Mapped Repo :"$gitrepo
                git clone "https://github.com/$gitorg/$gitrepo.git"
                echo
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

}

getRepoVersions() {

    line=$(echo $1 | sed -e 's/<\/.*/'\''/g' | sed -e 's/<//g')
    key=$(echo $line | cut -d ">" -f1 | sed 's/\./\-/g' | sed -e 's/version//g' | sed 's/.$//')
    gitrepo=$key
    value=$(echo $line | cut -d ">" -f2)
}

while read line || [ -n "$line" ]; do
    echo
    prodVersion=$(echo $line | sed -e 's/support-/\wso2is-/g' | sed 's/\./\-/g')
    display_name=$(echo $line | sed -e 's/support-/\WSO2IS-/g')
    mainVersion=$(echo $line | sed -e 's/support-//g')
    echo "### "$display_name" ###"
    echo "## $display_name" >>$REPO_VERSIONS_FILE
    echo "product-is-$prodVersion='$mainVersion'" >>$REPO_VERSIONS_FILE

    cd product-is
    git checkout $line -f
    git pull
    cd $CUR_DIR
    echo

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
            echo $final_key >>$REPO_VERSIONS_FILE

            cloneRepo
        fi

    done <./temp-versions
    echo "" >>$REPO_VERSIONS_FILE
done <$PRODCT_VER_FILE

grep "^custom" $MAPPED_REPOS_FILE | while read line; do
    echo "Clonning custom repos !"
    gitrepo=$(echo $line | cut -d "=" -f1)
    echo "$gitrepo"
    cloneRepo
done

rm -rf ./temp-versions

printf "\nCompleted!\n"
