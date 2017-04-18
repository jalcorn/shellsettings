# modified from agnoster theme

# some constants
JA_DEFAULT_BG='DEFAULT'
JA_CURRENT_BG='NONE'
JA_SEGMENT_SEPARATOR='▒'
JA_BLEND_SEPARATOR=' '

JA_GIT_BRANCH='├'
JA_GIT_DETATCHED='┌'
JA_GIT_MODE='¦'
JA_GIT_STAGED='•'
JA_GIT_UNSTAGED='±'
JA_GIT_UNTRACKED='¿'
JA_GIT_AHEAD='˄'
JA_GIT_BEHIND='˅'

JA_CMD_FAILED='×'
JA_BG_JOB='λ'
JA_ROOT='√'

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
	if [[ $JA_CURRENT_BG != 'NONE' ]]; then
		if [[ $JA_CURRENT_BG != $JA_DEFAULT_BG && $1 != $JA_CURRENT_BG ]]; then
		  echo -n "%{$bg%F{$JA_CURRENT_BG}%}$JA_SEGMENT_SEPARATOR%{$fg%}"
		else
		  echo -n "$JA_BLEND_SEPARATOR%{$bg%}%{$fg%}"
		fi
  else
    echo -n "%{$bg%}%{$fg%}"
  fi
  JA_CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $JA_CURRENT_BG && $JA_CURRENT_BG != $JA_DEFAULT_BG ]]; then
    echo -n "%{%k%F{$JA_CURRENT_BG}%}$JA_SEGMENT_SEPARATOR$JA_CURRENT_BG"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%F{magenta}%}: %{%f%}"
  JA_DEFAULT_BG=''
  JA_CURRENT_BG=''
  JA_SEGMENT_SEPARATOR=''
  JA_BLEND_SEPARATOR=''
}

prompt_status() {
  local symbols=''

  # Output if last command was successful
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}$JA_CMD_FAILED"

  # Output if background jobs are running
  local job_count=$(jobs -l | wc -l | tr -d '[:space:]')
  [[ $job_count -gt 0 ]] && symbols+="%{%F{cyan}%}$JA_BG_JOB"
  [[ $job_count -gt 1 ]] && symbols+="%{%F{cyan}%}$job_count"

  # Output if running as root
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}$JA_ROOT"

  [[ -n "$symbols" ]] && prompt_segment $JA_DEFAULT_BG default "$symbols"
}

prompt_time() {
  prompt_segment $JA_DEFAULT_BG magenta "%*"
}

# Context: user@hostname (who am I and where am I)
prompt_context() {
  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment $JA_DEFAULT_BG default "%(!.%{%F{yellow}%}.)$USER"
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment $JA_DEFAULT_BG blue '%~'
}

simple_git() {
  (( $+commands[git] )) || return

  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    local head_path=$(git symbolic-ref HEAD 2> /dev/null)
    local ref
    if [[ $head_path ]]; then
      ref="$JA_GIT_BRANCH$(basename $head_path 2>/dev/null)$diverge"
    else
      ref="$JA_GIT_DETATCHED$(git rev-parse --short HEAD 2> /dev/null)"
    fi
    prompt_segment $JA_DEFAULT_BG magenta "$ref"
  fi
}
# Git: branch/detached head, dirty status
prompt_git() {
  (( $+commands[git] )) || return

  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
   # local parsed_status=$git_status | grep "^##" | head -n 1 | sed -E "s/^##\s*([a-ZA-Z0-9\-\_]*)(\.\.\..*\[)?(ahead )?([0-9]*)(,?\s*behind )?([0-9]*)\]?/\1 \4 \6/g"

    local ahead="$(git log @{u}.. --pretty=oneline 2> /dev/null | wc -l | tr -d '[:space:]')"
    local behind="$(git log ..@{u} --pretty=oneline 2> /dev/null | wc -l | tr -d '[:space:]')"
    local diverge=''
    if [[ $ahead -gt 0 || $behind -gt 0 ]]; then
      diverge+=" "
    fi
    if [[ $ahead -gt 0 ]]; then
      diverge+="$JA_GIT_AHEAD"
      if [[ $ahead -gt 1 ]]; then
        diverge+="$ahead"
      fi
    fi
    if [[ $behind -gt 0 ]]; then
      diverge+="$JA_GIT_BEHIND"
      if [[ $behind -gt 1 ]]; then
        diverge+="$behind"
      fi
    fi

    local head_path=$(git symbolic-ref HEAD 2> /dev/null)
    local ref
    if [[ $head_path ]]; then
      ref="$JA_GIT_BRANCH$(basename $head_path 2>/dev/null)$diverge"
    else
      ref="$JA_GIT_DETATCHED$(git rev-parse --short HEAD 2> /dev/null)"
    fi

    local untracked_string=''
    local all_clean=1
    local text_color=red
    local repo_path=$(git rev-parse --git-dir 2>/dev/null)
    local mode
    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
      mode=$JA_GIT_MODE"Bisect"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
      mode=$JA_GIT_MODE"Merge"
    elif [[ -e "${repo_path}/rebase" ]]; then
      mode=$JA_GIT_MODE"Rebase"
    elif [[ -e "${repo_path}/rebase-apply" ]]; then
      mode=$JA_GIT_MODE"Rebase Apply"
    elif [[ -e "${repo_path}/rebase-merge" ]]; then
      mode=$JA_GIT_MODE"Rebase Merge"
    else
      local dirty=$(parse_git_dirty)
      if [[ -n $dirty ]]; then
        text_color=yellow
        if [[ -n $(git ls-files --other --exclude-standard :/ 2> /dev/null) ]]; then
          untracked_string="$JA_GIT_UNTRACKED"
        fi
      else
        text_color=green
        all_clean=0
      fi
    fi


    prompt_segment $JA_DEFAULT_BG $text_color

    setopt promptsubst
    autoload -Uz vcs_info

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' get-revision true
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' stagedstr $JA_GIT_STAGED
    zstyle ':vcs_info:*' unstagedstr $JA_GIT_UNSTAGED
    zstyle ':vcs_info:*' formats '%u%c'
    zstyle ':vcs_info:*' actionformats '%u%c'
    vcs_info

    if [[ "$all_clean" -eq 0 ]]; then
      echo -n "$ref${mode}${vcs_info_msg_0_%%}"
    else
      echo -n "$ref${mode} $untracked_string${vcs_info_msg_0_%%}"
    fi
  fi
}

## Main prompt
build_prompt() {
  RETVAL=$?
  prompt_status
  #prompt_time
  prompt_context
  prompt_dir
  prompt_git
  prompt_end
}

simple_prompt() {
  RETVAL=$?
  prompt_status
  #prompt_time
  prompt_context
  prompt_dir
  simple_git
  prompt_end
}

setopt prompt_subst # enable command substition in prompt

ASYNC_PROC=0
DISPLAY_RPROMPT_COMMAND_TIME=()

# Necessary for $EPOCHSECONDS, the UNIX time.
zmodload zsh/datetime

# Capture the USR1 kill signal
TRAPUSR1() {
  # read from temp file
  PROMPT="$(cat /tmp/zsh_prompt_$$)"

  # reset proc number
  ASYNC_PROC=0

  # redisplay
  zle && zle reset-prompt
}

COMMAND_START_TIME=()
precmd () {
  function prompt_cmd() {
    echo -n '%{%f%b%k%}$(build_prompt)'
  }

  function async() {
    # save to temp file
    # FIXME: somehow adding a sleep for a short time fixes this on MAC
    sleep 0.05 | printf "%s" "$(prompt_cmd)" > "/tmp/zsh_prompt_$$"

    # signal parent
    kill -s USR1 $$
  }

  # default prompt values
  PROMPT='%{%f%b%k%}$(simple_prompt)'
  RPROMPT='%{%f%F{red}%}${DISPLAY_RPROMPT_COMMAND_TIME} %{%f%F{magenta}%}$(date +%H:%M:%S)%{%f%F{default}%}'

  # kill child if necessary
  if [[ "${ASYNC_PROC}" != 0 ]]; then
    kill -s HUP $ASYNC_PROC >/dev/null 2>&1 || :
  fi

  # start background computation
  async &!
  ASYNC_PROC=$!

  # Display execution time as delta for long running commands
  if [[ ! -z $COMMAND_START_TIME ]]; then
    local difference=$(( $EPOCHSECONDS - $COMMAND_START_TIME ))
    local base_rprompt='%{%f%F{magenta}%}$(date +%H:%M:%S)%{%f%F{default}%}'
    if [[ $difference -gt 10 ]]; then
      DISPLAY_RPROMPT_COMMAND_TIME="∆${difference}s"
    else
      DISPLAY_RPROMPT_COMMAND_TIME=''
    fi
  else
    DISPLAY_RPROMPT_COMMAND_TIME=''
  fi

  # clear the command start time
  COMMAND_START_TIME=()
}

preexec () {
  # returns the displayed length of a string
  function strlen () {
    local input_str=$1
    local invisible='%([BSUbfksu]|([FK]|){*})'
    local LEN=${#${(S%%)input_str//$~invisible/}}
    echo -n $LEN
  }

  # save the current time as the command start time
  COMMAND_START_TIME=$EPOCHSECONDS

  # overwrite RPROMPT location (or place below) the starting time of executing a command
  local cur_time=$(date +"%H:%M:%S•")
  local len_right=$(strlen $cur_time)
  local len_r_prompt=$(strlen $RPROMPT)
  local right_start=$(($COLUMNS - $len_right - 1))

  local len_cmd=$(strlen $@)
  local cleaned_prompt='$(sed -E "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" <<< ${(S%%)PROMPT//$~invisible/})'
  local len_prompt=$(strlen $cleaned_prompt)
  local len_left=$(($len_cmd + $len_prompt))

  local right_cur_time="\033[${right_start}C ${cur_time}"

  if [ $len_left -gt $right_start ]; then
    echo -e "${fg[cyan]}${right_cur_time}${fg[default]}"
  else
    # move up one line
    echo -e "\033[1A${fg[cyan]}${right_cur_time}${fg[default]}"
  fi
}
