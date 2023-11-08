#! bash oh-my-bash.module

# Define this here so it can be used by all of the Powerline themes
THEME_CHECK_SUDO=${THEME_CHECK_SUDO:=false}

function set_color {
	if [[ "${1}" != "-" ]]; then
		fg="38;5;${1}"
	fi
	if [[ "${2}" != "-" ]]; then
		bg="48;5;${2}"
		[[ -n "${fg}" ]] && bg=";${bg}"
	fi
	echo -e "\[\033[${fg}${bg}m\]"
}

function __powerline_user_info_prompt {
	local user_info=""
	local color=${USER_INFO_THEME_PROMPT_COLOR}

	if [[ "${THEME_CHECK_SUDO}" = true ]]; then
		# check whether sudo is active for no-password executions
		if sudo -n cat <<<c3bcc5c 2>&1 | grep -q c3bcc5c; then
			color=${USER_INFO_THEME_PROMPT_COLOR_SUDO}
		fi
	fi
	case "${POWERLEVEL10K_PROMPT_USER_INFO_MODE}" in
	"sudo")
		if [[ "${color}" == "${USER_INFO_THEME_PROMPT_COLOR_SUDO}" ]]; then
			user_info="!"
		fi
		;;
	*)
		if [[ -n "${SSH_CLIENT}" ]]; then
			user_info="${USER_INFO_SSH_CHAR}${USER}@${HOSTNAME}"
		else
			user_info="${USER}"
		fi
		;;
	esac
	[[ -n "${user_info}" ]] && echo "${user_info}|${color}"
}

function __powerline_ruby_prompt {
	local ruby_version=""

	if _omb_util_command_exists 'rvm'; then
		ruby_version="$(rvm_version_prompt)"
	elif _omb_util_command_exists 'rbenv'; then
		ruby_version=$(rbenv_version_prompt)
	fi

	[[ -n "${ruby_version}" ]] && echo "${RUBY_CHAR}${ruby_version}|${RUBY_THEME_PROMPT_COLOR}"
}

function __powerline_python_venv_prompt {
	local python_venv=""

	if [[ -n "${CONDA_DEFAULT_ENV}" ]]; then
		python_venv="${CONDA_DEFAULT_ENV}"
		PYTHON_VENV_CHAR=${CONDA_PYTHON_VENV_CHAR}
	elif [[ -n "${VIRTUAL_ENV}" ]]; then
		python_venv=$(basename "${VIRTUAL_ENV}")
	fi

	[[ -n "${python_venv}" ]] && echo "${PYTHON_VENV_CHAR}${python_venv}|${PYTHON_VENV_THEME_PROMPT_COLOR}"
}

function __powerline_scm_prompt {
	local color=""
	local scm_prompt=""

	scm_prompt_vars

	if [[ "${SCM_NONE_CHAR}" != "${SCM_CHAR}" ]]; then
		if [[ "${SCM_DIRTY}" -eq 3 ]]; then
			color=${SCM_THEME_PROMPT_STAGED_COLOR}
		elif [[ "${SCM_DIRTY}" -eq 2 ]]; then
			color=${SCM_THEME_PROMPT_UNSTAGED_COLOR}
		elif [[ "${SCM_DIRTY}" -eq 1 ]]; then
			color=${SCM_THEME_PROMPT_DIRTY_COLOR}
		else
			color=${SCM_THEME_PROMPT_CLEAN_COLOR}
		fi
		if [[ "${SCM_GIT_CHAR}" == "${SCM_CHAR}" ]]; then
			scm_prompt+="${SCM_CHAR}${SCM_BRANCH}${SCM_STATE}"
		fi
		echo "${scm_prompt}${scm}|${color}"
	fi
}

function __powerline_cwd_prompt {
	echo "$(pwd | sed "s|^${HOME}|~|")|${CWD_THEME_PROMPT_COLOR}"
}

function __powerline_clock_prompt {
	echo "$(date +"${THEME_CLOCK_FORMAT}")|${CLOCK_THEME_PROMPT_COLOR}"
}

function __powerline_battery_prompt {
	local color=""
	local battery_status="$(battery_percentage 2>/dev/null)"

	if [[ -z "${battery_status}" ]] || [[ "${battery_status}" = "-1" ]] || [[ "${battery_status}" = "no" ]]; then
		true
	else
		if [[ "$((10#${battery_status}))" -le 5 ]]; then
			color="${BATTERY_STATUS_THEME_PROMPT_CRITICAL_COLOR}"
		elif [[ "$((10#${battery_status}))" -le 25 ]]; then
			color="${BATTERY_STATUS_THEME_PROMPT_LOW_COLOR}"
		else
			color="${BATTERY_STATUS_THEME_PROMPT_GOOD_COLOR}"
		fi
		ac_adapter_connected && battery_status="${BATTERY_AC_CHAR}${battery_status}"
		echo "${battery_status}%|${color}"
	fi
}

function __powerline_in_vim_prompt {
	if [ -n "$VIMRUNTIME" ]; then
		echo "${IN_VIM_THEME_PROMPT_TEXT}|${IN_VIM_THEME_PROMPT_COLOR}"
	fi
}

function __powerline_left_segment {
	local OLD_IFS="${IFS}"
	IFS="|"
	local params=($1)
	IFS="${OLD_IFS}"
	local separator_char="${POWERLEVEL10K_LEFT_SEPARATOR}"
	local separator=""

	if [[ "${SEGMENTS_AT_LEFT}" -gt 0 ]]; then
		separator="$(set_color ${LAST_SEGMENT_COLOR} ${params[1]})${separator_char}${_omb_prompt_normal}"
	fi
	LEFT_PROMPT+="${separator}$(set_color - ${params[1]}) ${params[0]} ${_omb_prompt_normal}"
	LAST_SEGMENT_COLOR=${params[1]}
	((SEGMENTS_AT_LEFT += 1))
}

function __powerline_last_status_prompt {
	[[ "$1" -ne 0 ]] && echo "$(set_color "${LAST_STATUS_THEME_PROMPT_COLOR}" -) ${1} ${_omb_prompt_normal}"
}

function __powerline_right_segment {
	local OLD_IFS="${IFS}"
	IFS="|"
	local params=($1)
	IFS="${OLD_IFS}"
	local separator_char="${POWERLEVEL10K_RIGHT_SEPARATOR}"
	local padding=2
	local separator_color=""

	if [[ "${SEGMENTS_AT_RIGHT}" -eq 0 ]]; then
		separator_color="$(set_color ${params[1]} -)"
	else
		separator_color="$(set_color ${params[1]} ${LAST_SEGMENT_COLOR})"
		((padding += 1))
	fi
	RIGHT_PROMPT+="${separator_color}${separator_char}${_omb_prompt_normal}$(set_color 232 ${params[1]}) ${params[0]} ${_omb_prompt_normal}$(set_color - ${COLOR})${_omb_prompt_normal}"
	RIGHT_PROMPT_LENGTH=$((${#params[0]} + RIGHT_PROMPT_LENGTH + padding))
	LAST_SEGMENT_COLOR="${params[1]}"
	((SEGMENTS_AT_RIGHT += 1))
}

function __powerline_prompt_command {
	local last_status="$?" ## always the first
	local separator_char="${POWERLEVEL10K_LEFT_SEPARATOR}"
	local move_cursor_rightmost='\033[500C'

	LEFT_PROMPT="╭─"
	RIGHT_PROMPT=""
	RIGHT_PROMPT_LENGTH=0
	SEGMENTS_AT_LEFT=0
	SEGMENTS_AT_RIGHT=0
	LAST_SEGMENT_COLOR=""

	## left prompt ##
	for segment in $POWERLEVEL10K_LEFT_PROMPT; do
		local info="$(__powerline_${segment}_prompt)"
		[[ -n "${info}" ]] && __powerline_left_segment "${info}"
	done
	[[ -n "${LEFT_PROMPT}" ]] && LEFT_PROMPT+="$(set_color ${LAST_SEGMENT_COLOR} -)${separator_char}${_omb_prompt_normal}"

	## right prompt ##
	if [[ -n "${POWERLEVEL10K_RIGHT_PROMPT}" ]]; then
		LEFT_PROMPT+="${move_cursor_rightmost}"
		for segment in $POWERLEVEL10K_RIGHT_PROMPT; do
			local info="$(__powerline_${segment}_prompt)"
			[[ -n "${info}" ]] && __powerline_right_segment "${info}"
		done
		LEFT_PROMPT+="\033[${RIGHT_PROMPT_LENGTH}D"
	fi

	PS1="${LEFT_PROMPT}${RIGHT_PROMPT}\n$(__powerline_last_status_prompt ${last_status})${PROMPT_CHAR} "

	## cleanup ##
	unset LAST_SEGMENT_COLOR \
		LEFT_PROMPT RIGHT_PROMPT RIGHT_PROMPT_LENGTH \
		SEGMENTS_AT_LEFT SEGMENTS_AT_RIGHT
}