#!/bin/bash
# run this from your workspace, which contains all your Git repos

FILE=./repo-versions

if [ ! -f "$FILE" ]; then
  curl -s https://raw.githubusercontent.com/dmxunlimit/tools/master/git-tools/repo-versions -o repo-versions
fi

source ./repo-versions
wrk_dir=$(pwd)

# FILE=./templates

# if [ -f "$FILE" ]; then
#   rm -rf $FILE
# fi


if [ -z $1 ]; then
    read -p 'Default checkout is MASTER or Enter the Identity Server version to checkout [5.2.0]: ' branch_version
else
    branch_version=$1
fi

if [ -z $2 ]; then
    read -p 'Force checkout [no]: ' force
    if [ "$force" == "yes" ] || [ "$force" == "y" ]; then
        printf "\nWRAN : Force checkout , local changes will destroy !!\n"
        force="-f"
    else
        force=""
    fi
else
    force=$2
fi

getBranch() {
    dirname=$1
    dirname="${dirname:2}"
    branch=''
    branch_version=$2

    if [ "$branch_version" != "master" ] && [ ! -z $branch_version ]; then
        version='wso2is-'$branch_version
        dirname=$(echo $dirname | sed 's/\-/\_/g')
        version=$(echo $version | sed 's/\./\_/g')
        version=$(echo $version | sed 's/\-/\_/g')
        key=$dirname"_"$version
        value=$(echo "${!key}")
        
        if [ ! -z "$value" ]; then
            branch=$value
            support_brach=$(git branch -r | grep $branch | grep 'support' | grep -Ev 'release|security|full|revert' | head -1)
            # echo "#### support_brach : $support_brach"
            if [ -z "$support_brach" ]; then
            branch=$(git branch -r | grep $branch | grep -Ev 'HEAD|release|security|full|revert' | head -1)
            else
            branch=$support_brach
            fi

            branch=$(echo $branch | sed -e 's/origin\///g')
        fi

        if [ -z "$branch" ]; then
            branch='master'
        fi
        # echo $key"='$branch'" >>$wrk_dir/templates
    else

        branch='master'
    fi


    echo "# Checking out branch "$branch" for" $dirname

}

echo "$branch"

CUR_DIR=$(pwd)
printf "Updating remotes for all repositories...\n"
for i in $(find . -mindepth 1 -maxdepth 1 -type d); do
    if [ $i != "./.idea" ]; then
        printf "\nIn Folder: $i"
        cd "$i"
        printf "\n"
        THIS_REMOTES="$(git remote -v)"
        arr=($THIS_REMOTES)
        OLD_REMOTE="${arr[1]}"
        NEW_REMOTE="${OLD_REMOTE/git.old.net/git.new.org}"
        printf "New remote: $NEW_REMOTE"
        printf "\n"
        git remote set-url origin "$NEW_REMOTE"
        getBranch $i $branch_version
        git checkout $branch $force
        git pull
        cd $CUR_DIR
    fi
done
printf "\nCompleted!\n"
