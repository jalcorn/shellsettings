
# Note this will not work with symlinks
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo $SCRIPT_PATH

# Copy ZSH config
local diff_count=$(diff $SCRIPT_PATH/zshrc ~/.zshrc | wc -l)
if [[ $diff_count -gt 0 ]]; then
  echo "updating .zshrc file"
  local cur_date="$(date +'%Y-%m-%d-%H:%M:%S')"
  cp ~/.zshrc ~/.zshrc.bak-$cur_date
  cp $SCRIPT_PATH/zshrc ~/.zshrc
else
  echo ".zshrc file already up to date"
fi

if [ -n "$ZSH_VERSION" ]; then
  # assume Zsh
  echo "running in ZSH"
elif [ -n "$BASH_VERSION" ]; then
  # assume Bash
  echo "BASH is not finished"
fi
