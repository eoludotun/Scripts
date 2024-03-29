#!/bin/sh

# gittask.sh: taskbased git branching utility

# This script requires that git has been installed and properly configured,
# that the remote "master" and "development" branches exist (locally too) 
# and that a network connection to the "origin" repository is established.

set -o errexit

usage()
{
    echo
    echo "Usage:"
    echo "  gittask.sh new feature name_of_feature"
    echo "    - Creates a new branch off from 'development' named"
    echo "      'feature/name_of_feature'."
    echo "  gittask.sh new release name_of_release"
    echo "    - Creates a new branch off from 'development' named"
    echo "      'release/name_of_release'."
    echo "  gittask.sh new hotfix name_of_hotfix"
    echo "    - Creates a new branch off from 'master' named"
    echo "      'hotfix/name_of_hotfix'."
    echo "  gittask.sh done"
    echo "    - Merges current branch into master and/or development"
    echo "      depending on if it's a feature, release or hotfix."
}

delete_branch()
{
    # Infinite loop, only way out (except for Ctrl+C) is to answer yes or no.
    while true; do
        echo "Delete $current branch? "
        read yn
        case $yn in
            [Yy]* ) 
                git branch -d ${current}
                break
                ;;
            [Nn]* )
                echo "Leaving $current branch as it is."
                break
                ;;
            * )
                echo "Error: Please answer (y)es or (n)o."
                ;;
        esac
    done
}

define_tag()
{
    # Don't proceed until both variables have been set.
    while [ -z ${version_number} ] && [ -z ${version_note} ]; do
        echo "Enter version number (major.minor.fix): "
        read version_number
        echo "Enter version number note: "
        read version_note
    done
}

# Confirm that user is in a git repository, abort otherwise.
git status >/dev/null 2>&1 || { echo "Error: You're not in a git repository."; exit 1; }

# If "new", confirm that the required arguments were provided.
if [ "$1" == "new" ] && [ -n "$2" ] && [ -n "$3" ]; then
    
    # Validate $3, only allow a-z (lower case), 0-9 and _ (underscore) in branch names.
    [ "${3//[0-9a-z_]/}" = "" ] || { echo "Error: Branch names may only consist of a-z, 0-9 and underscore."; exit 1; }
    case $2 in
        feature )
            git checkout development
            git checkout -b "feature/$3"
            exit 0
            ;;
        release )
            git checkout development
            git checkout -b "release/$3"
            exit 0
            ;;
        hotfix )
            git checkout master
            git checkout -b "hotfix/$3"
            exit 0
            ;;
        * )
            echo "Error: You didn't specify feature, release or hotfix."
            exit 1
            ;;
    esac

# If "done", proceed to determine current branch and by that what to do next.
elif [ "$1" == "done" ]; then
    current=`git branch | awk '/\*/{print $2}'`
    case ${current} in
        feature* )
            echo "Merging into development branch..."
            git checkout development
            git merge ${current}
            git push origin development
            delete_branch
            exit 0
            ;;
        release* )
            echo "Merging into development branch..."
            git checkout development
            git merge ${current}
            git push origin development

            # Infinite loop, only way out (except for Ctrl+C) is to answer yes or no.
            while true; do
                echo "Merge into master (make a release)? "
                read yn
                case $yn in
                    [Yy]* )
                        echo "Merging into master branch..."
                        git checkout master
                        git merge ${current}
                        define_tag
                        git tag -s ${version_number} -m ${version_note}
                        git push --tags origin master
                        delete_branch
                        break
                        ;;
                    [Nn]* )
                        echo "Leaving branch master as it is."
                        break
                        ;;
                    * )
                        echo "Error: Please answer (y)es or (n)o."
                        ;;
                esac
            done
            exit 0
            ;;
        hotfix* )
            git checkout master
            git merge ${current}
            define_tag
            git tag -s ${version_number} -m ${version_note}
            git push --tags origin master
            git checkout development
            git merge ${current}
            git push origin development
            delete_branch
            exit 0
            ;;
        * )
            echo "Error: You're not on a feature, release or hotfix branch."
            exit 1
            ;;
    esac
else
    echo "Error: You didn't provide the needed arguments."
    usage
    exit 1
fi
shell
git
sh
Share
Improve this question
Follow
