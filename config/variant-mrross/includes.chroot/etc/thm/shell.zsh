setopt promptsubst
typeset -g THM_PS=""

_thm_zsh_precmd() {
    _thm_refresh
    local c='%F{%(#.yellow.red)}'
    THM_PS=""
    if [[ -n "$VPN_IP" ]]; then
        THM_PS="[%F{yellow}${VPN_IP}"
        [[ -n "${TARGET:-}" ]] && THM_PS+="%F{white}→%F{green}${TARGET}"
        THM_PS+="${c}]─"
    elif [[ -n "${TARGET:-}" ]]; then
        THM_PS="[%F{green}${TARGET}${c}]─"
    fi
}

_mrross_configure_prompt() {
    local a='%F{%(#.yellow.red)}'
    local dyn='${THM_PS}${debian_chroot:+($debian_chroot)─}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))─}'
    PROMPT="${a}┌──${dyn}[%B%F{%(#.red.white)}%n%b${a}@%B%F{white}%m%b${a}]─[%B%F{reset}%(6~.%-1~/…/%4~.%5~)%b${a}]"$'\n'"${a}└─%B%(#.%F{red}#.%F{red}\$)%b%F{reset} "
}

_thm_patch_prompt() {
    local seg='${THM_PS}'
    [[ "$PROMPT" == *"$seg"* ]] && return 0
    if [[ "$PROMPT" == *'┌──'* ]]; then
        PROMPT="${PROMPT/┌──/┌──$seg}"
    else
        PROMPT="${seg}${PROMPT}"
    fi
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _thm_zsh_precmd

if (( ${+functions[configure_prompt]} )); then
    if (( ! ${+functions[_thm_kali_configure_prompt]} )); then
        functions[_thm_kali_configure_prompt]="${functions[configure_prompt]}"
        configure_prompt() {
            if [[ "${PROMPT_ALTERNATIVE:-twoline}" == twoline ]]; then
                _mrross_configure_prompt
            else
                _thm_kali_configure_prompt "$@"
                _thm_patch_prompt
            fi
        }
    fi
    configure_prompt
else
    _mrross_configure_prompt
fi

_thm_complete() {
    local -a subcmds
    subcmds=(
        'vpn:połącz/rozłącz VPN TryHackMe'
        'ip:twoje IP w VPN'
        'target:ustaw IP maszyny'
        'room:nowy folder pokoju z notatkami'
        'status:stan VPN, celu i pokoju'
        'extras:doinstaluj większe pakiety'
        'help:pomoc'
    )
    if (( CURRENT == 2 )); then
        _describe 'polecenie' subcmds
    elif [[ "${words[2]}" == vpn ]] && (( CURRENT == 3 )); then
        _alternative 'akcja:akcja:(stop status log)' 'pliki:plik ovpn:_files -g "*.ovpn"'
    elif [[ "${words[2]}" == target ]] && (( CURRENT == 3 )); then
        _alternative 'akcja:akcja:(clear)'
    fi
}
(( ${+functions[compdef]} )) && compdef _thm_complete thm
