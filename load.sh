#! /bin/bash

# Note this will not work with symlinks
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Script location: $SCRIPT_PATH"

function copy_config_file {
  echo
  if [[ ! -n $1 ]]; then
    echo "ERROR: method needs an argument"
  else
    local file_name=$1
    local source_file=$SCRIPT_PATH/$file_name
    local destination_file=~/.$file_name
    if [[ ! -f $source_file ]]; then
      echo "Cannot find $source_file"
    elif [[ ! -f $destination_file || -n $2 ]]; then
      echo "Creating $destination_file file"
      cp $source_file $destination_file

      if [[ -n $2 ]]; then
        echo $2 >> $destination_file
      fi
    elif [[ $(diff $source_file $destination_file | wc -l | tr -d '[:space:]') -gt 0 ]]; then
      read -p "Replace $destination_file with default? " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "  Updating $destination_file file"
        local cur_date="$(date +'%Y-%m-%d-%H:%M:%S')"
        cp ~/.$file_name $destination_file.bak-$cur_date
        cp $source_file $destination_file
      else
        echo "  Leaving $destination_file file unchanged"
      fi
    else
      echo "$destination_file file already up to date"
    fi
  fi
}

copy_config_file "vimrc"
copy_config_file "customrc" 
copy_config_file "zshrc"
copy_config_file "pre_customrc" "export SCRIPTS_PATH=$SCRIPT_PATH"

# TODO: add default bashrc
