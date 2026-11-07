_thm_bash_prompt() {
    _thm_refresh
    THM_PS_BASH=""
    if [ -n "$VPN_IP" ]; then
        THM_PS_BASH=$'\001\e[33m\002'"[${VPN_IP}"
        [ -n "${TARGET:-}" ] && THM_PS_BASH+=$' → \001\e[31m\002'"${TARGET}"$'\001\e[33m\002'
        THM_PS_BASH+=$']\001\e[0m\002 '
    elif [ -n "${TARGET:-}" ]; then
        THM_PS_BASH=$'\001\e[31m\002'"[${TARGET}]"$'\001\e[0m\002 '
    fi
}

case ";${PROMPT_COMMAND:-};" in
    *";_thm_bash_prompt;"*) ;;
    *) PROMPT_COMMAND="_thm_bash_prompt${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
esac

case "$PS1" in
    *THM_PS_BASH*) ;;
    *) PS1='${THM_PS_BASH}'"$PS1" ;;
esac

complete -W "vpn ip target room status extras help" thm
