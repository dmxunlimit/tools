#!/bin/bash
# run this from your workspace, which contains all your Git repos

FILE=./properties.conf

if [ ! -f "$FILE" ]; then
  curl -s https://raw.githubusercontent.com/dmxunlimit/tools/master/git-tooles/properties.conf -o properties.conf
fi

source ./properties.conf
wrk_dir=$(pwd)

FILE=./templates

if [ -f "$FILE" ]; then
  rm -rf $FILE
fi


if [ -z $1 ]; then
    read -p 'Default checkout is MASTER or Enter the Identity Server version to checkout [5.2.0]: ' branch_version
else
    branch_version=$1
fi

if [ -z $2 ]; then
    read -p 'Force checkout [no]: ' force
    if [ "$force" == "yes" ]; then
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
    branch_version=$2

    if [ "$branch_version" != "master" ] && [ ! -z $branch_version ]; then
        version='wso2is-'$branch_version
        dirname=$(echo $dirname | sed 's/\-/\_/g')
        version=$(echo $version | sed 's/\./\_/g')
        version=$(echo $version | sed 's/\-/\_/g')
        key=$dirname"_"$version
        value=$(echo "${!key}")

        if [ ! -z "$value" ]; then
            echo $key"='$value'" >>$wrk_dir/templates
            branch=$value
        else
            echo $key"='master'" >>$wrk_dir/templates
            branch='master'
        fi

    else

        branch='master'
    fi

    echo "Checking out branch "$branch" for" $dirname

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
printf "\nComplete!\n"
