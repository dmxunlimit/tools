#!/bin/bash

##### Automated script update #####

script_dir=$(dirname "$0")
scriptBaseName="$(basename $0)"
scriptFile="$script_dir/$scriptBaseName"
scriptFilelst=$scriptFile"_latest"
echo "Checking for latest version of the script $scriptBaseName !"

curl -s https://raw.githubusercontent.com/dmxunlimit/tools/master/git-tools/$scriptBaseName -o $scriptFilelst

if [ -f "$scriptFilelst" ] && [ -s "$scriptFilelst" ]; then
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

wrk_dir=$(pwd)
mkdir -p $wrk_dir'/artefacts'

repoFile=$wrk_dir'/artefacts/git-repos'
tmpFile=$wrk_dir'/artefacts/tmp'

if test -f "$repoFile"; then
    rm -rf $repoFile
fi

org="wso2"
repoFilter="identity"

read -p 'Enter the ORG name to clone [wso2]: ' org
if [ -z $org ]; then
    org="wso2"
fi

read -p 'Enter the repo filter [identity]: ' repoFilter
if [ "$repoFilter" == "*" ]; then
    echo "WARN : Cloning all the repos of the ORG : $org"
elif [ -z $repoFilter ]; then
    repoFilter="identity"
fi

read -sp 'Enter the GIT Token: ' token
printf "\n"
read -p 'Force clone by removing existing repos [no]: ' force
if [ "$force" == "yes" ]; then
    printf "\nWRAN : Force cloning , exisitng repos will be removed. !!\n"
    force=true
else
    force=false
fi

if [ ! -z "$token" ]; then
    # With Authentication
    base_url="https://api.github.com/orgs/$org/repos?access_token=$token&per_page=100"
else
    # Without Authentication
    printf "\nWARN : GIT API without authentication will have limited access."
    base_url="https://api.github.com/orgs/$org/repos?per_page=100"
fi

finalize() {
    rm -rf $tmpFile
    printf "\nCompleted!\n"
}

for i in {1..1000}; do
    request=$base_url'&page='$i
    printf "\n$request\n"
    curl -s -H "Accept: application/vnd.github.v3+json" $request | grep 'clone_url' | grep -o 'https://github.com[^"]*' >$tmpFile

    if [ -s $tmpFile ]; then
        while read line || [ -n "$line" ]; do
            if [[ "$line" == *"github"* ]]; then

                path=$(echo "$line" | grep -o $org'.*' | cut -d "/" -f2 | cut -d "." -f1)

                if [ -d "$path" ] && [ "$force" = true ]; then
                    printf "\nRemoveing the exisitng repo : $path \n"
                    rm -rf $path
                fi

                if [ "$repoFilter" == "*" ]; then
                    printf "\n"
                    echo $line >>$repoFile
                    git clone $line
                elif [[ "$line" == *"$repoFilter"* ]]; then
                    printf "\n"
                    echo $line >>$repoFile
                    git clone $line
                fi
            else
                finalize
                exit 0
            fi
        done <$tmpFile
    else
        finalize
        exit 0
    fi
    sleep 5
done

rm -rf $tmpFile
