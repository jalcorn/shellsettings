# modified from agnoster theme

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

DEFAULT_BG='DEFAULT'
CURRENT_BG='NONE'
SEGMENT_SEPARATOR='▒'
BLEND_SEPARATOR=' '

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
	if [[ $CURRENT_BG != 'NONE' ]]; then
		if [[ $CURRENT_BG != $DEFAULT_BG && $1 != $CURRENT_BG ]]; then
		  echo -n "%{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%}"
		else
		  echo -n "$BLEND_SEPARATOR%{$bg%}%{$fg%}"
		fi
  else
    echo -n "%{$bg%}%{$fg%}"
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG && $CURRENT_BG != $DEFAULT_BG ]]; then
    echo -n "%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR$CURRENT_BG"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%F{magenta}%}: %{%f%}"
  DEFAULT_BG=''
  CURRENT_BG=''
  SEGMENT_SEPARATOR=''
  BLEND_SEPARATOR=''
}

prompt_status() {
  local symbols=''

  # Output if last command was successful
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}×"

  # Output if background jobs are running
  local job_count=$(jobs -l | wc -l | tr -d '[:space:]')
  [[ $job_count -gt 0 ]] && symbols+="%{%F{cyan}%}λ"
  [[ $job_count -gt 1 ]] && symbols+="%{%F{cyan}%}$job_count"

  # Output if running as root
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}√"

  [[ -n "$symbols" ]] && prompt_segment $DEFAULT_BG default "$symbols"
}

prompt_time() {
  prompt_segment $DEFAULT_BG magenta "%*"
}

# Context: user@hostname (who am I and where am I)
prompt_context() {
  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment $DEFAULT_BG default "%(!.%{%F{yellow}%}.)$USER"
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment $DEFAULT_BG blue '%~'
}

simple_git() {
  (( $+commands[git] )) || return
  local PL_BRANCH_CHAR='├'
  local PL_DETATCHED_CHAR='┌'
  local head_path=$(git symbolic-ref HEAD 2> /dev/null)
  local ref
  if [[ $head_path ]]; then
    ref="$PL_BRANCH_CHAR$(basename $head_path 2>/dev/null)$diverge"
  else
    ref="$PL_DETATCHED_CHAR$(git rev-parse --short HEAD 2> /dev/null)"
  fi
  prompt_segment $DEFAULT_BG magenta "$ref"
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
      diverge+="˄"
      if [[ $ahead -gt 1 ]]; then
        diverge+="$ahead"
      fi
    fi
    if [[ $behind -gt 0 ]]; then
      diverge+="˅"
      if [[ $behind -gt 1 ]]; then
        diverge+="$behind"
      fi
    fi

    local PL_BRANCH_CHAR='├'
    local PL_DETATCHED_CHAR='┌'
    local head_path=$(git symbolic-ref HEAD 2> /dev/null)
    local ref
    if [[ $head_path ]]; then
      ref="$PL_BRANCH_CHAR$(basename $head_path 2>/dev/null)$diverge"
    else
      ref="$PL_DETATCHED_CHAR$(git rev-parse --short HEAD 2> /dev/null)"
    fi

    local untracked_string=''
    local all_clean=1
    local text_color=red
    local PL_MODE_CHAR='¦'
    local repo_path=$(git rev-parse --git-dir 2>/dev/null)
    local mode
    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
      mode=$PL_MODE_CHAR"Bisect"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
      mode=$PL_MODE_CHAR"Merge"
    elif [[ -e "${repo_path}/rebase" ]]; then
      mode=$PL_MODE_CHAR"Rebase"
    elif [[ -e "${repo_path}/rebase-apply" ]]; then
      mode=$PL_MODE_CHAR"Rebase Apply"
    elif [[ -e "${repo_path}/rebase-merge" ]]; then
      mode=$PL_MODE_CHAR"Rebase Merge"
    else
      local dirty=$(parse_git_dirty)
      if [[ -n $dirty ]]; then
        text_color=yellow
        if [[ -n $(git ls-files --other --exclude-standard :/ 2> /dev/null) ]]; then
          untracked_string="¿"
        fi
      else
        text_color=green
        all_clean=0
      fi
    fi


    prompt_segment $DEFAULT_BG $text_color

    setopt promptsubst
    autoload -Uz vcs_info

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' get-revision true
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' stagedstr '•'
    zstyle ':vcs_info:*' unstagedstr '±'
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

PROMPT='%{%f%b%k%}$(simple_prompt)'
RPROMPT='%{%f%F{red}%}${DISPLAY_RPROMPT_COMMAND_TIME} %{%f%F{magenta}%}$(date +%H:%M:%S)%{%f%F{default}%}'

###########
# TODO: cleanup below

setopt prompt_subst # enable command substition in prompt

ASYNC_PROC=0

strlen () {
   local input_str=$1
   local invisible='%([BSUbfksu]|([FK]|){*})'
   local LEN=${#${(S%%)input_str//$~invisible/}}
   echo -n $LEN
 }

 export DISPLAY_RPROMPT_COMMAND_TIME=''

 # Necessary for $EPOCHSECONDS, the UNIX time.
 zmodload zsh/datetime

prompt_cmd() {
    echo -n '%{%f%b%k%}$(build_prompt)'
}

TRAPUSR1() {
    # read from temp file
    PROMPT="$(cat /tmp/zsh_prompt_$$)"

    # reset proc number
    ASYNC_PROC=0

    # redisplay
    zle && zle reset-prompt
}

josh_last=()
precmd () {
   function async() {
       # save to temp file
       printf "%s" "$(prompt_cmd)" > "/tmp/zsh_prompt_$$"

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

  if [[ -z $josh_last ]]; then
 return
  fi

  local difference=$(( $EPOCHSECONDS - $josh_last ))
  local base_rprompt='%{%f%F{magenta}%}$(date +%H:%M:%S)%{%f%F{default}%}'
  if [[ $difference -gt 10 ]]; then
 DISPLAY_RPROMPT_COMMAND_TIME="∆${difference}s"
  else
 DISPLAY_RPROMPT_COMMAND_TIME=''
  fi

  josh_last=()
}

preexec () {
  ####
  josh_last=$EPOCHSECONDS
  ####

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
