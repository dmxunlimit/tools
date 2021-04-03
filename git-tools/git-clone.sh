#!/bin/bash

repoFile=./git-repos
tmpFile=./tmp
if test -f "$repoFile"; then
    rm -rf $repoFile
fi

org="wso2-extensions"
repoFilter="identity"

read -p 'Enter the ORG name to clone [wso2-extensions]: ' org
if [ -z $org ]; then
    org="wso2-extensions"
fi

read -p 'Enter the repo filter [identity]: ' repoFilter
if [ "$repoFilter" == "*" ]; then
    echo "WARN : Cloning all the repos of echo the ORG : $org"
elif [ -z $repoFilter ]; then
    repoFilter="identity"
fi

read -sp 'Enter the GIT Token: ' token

if [ ! -z "$token" ]; then
    # With Authentication
    base_url="https://api.github.com/orgs/$org/repos?access_token=$token&per_page=100"
else
    # Without Authentication
    printf "\nWARN : GIT API without authentication will have limited access."
    base_url="https://api.github.com/orgs/$org/repos?per_page=100"
fi

for i in {1..100}; do
    request=$base_url'&page='$i
    printf "\n"$request
    curl -s -H "Accept: application/vnd.github.v3+json" $request | jq -r '.[].clone_url' >$tmpFile

    if [ -s $tmpFile ]; then
        while read line || [ -n "$line" ]; do
            if [[ "$line" == *"github"* ]]; then

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
                exit 0
            fi
        done <$tmpFile
    else
        exit 0
    fi
    sleep 2
done

rm -rf ./tmp
