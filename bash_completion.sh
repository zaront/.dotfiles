
# add support for bash completion
# must be sourced in the current shell to work (e.g. from .bashrc)

_dotfiles_subcommand_completion() {
    COMPREPLY=()
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local exec_name="${COMP_WORDS}"
    local wrapper_path

    # Resolve absolute location of the tool from system PATH or local path
    if [[ "$exec_name" == /* ]] || [[ "$exec_name" == .* ]]; then
        wrapper_path="$exec_name"
    else
        wrapper_path=$(type -p "$exec_name")
    fi
    [ -z "$wrapper_path" ] && return 0

    # Construct base path to the companion commands directory
    local base_dir=$(dirname "$wrapper_path")
    local wrapper_name=$(basename "$wrapper_path")
    local current_cmds_dir="${base_dir}/${wrapper_name}_cmds"
    local i
    local in_subcommand_space=true

    # Walk through typed arguments to navigate nested subcommand folders
    for ((i=1; i < COMP_CWORD; i++)); do
        local word="${COMP_WORDS[i]}"
        if [ "$in_subcommand_space" = true ]; then
            if [ -d "${current_cmds_dir}/${word}_cmds" ]; then
                current_cmds_dir="${current_cmds_dir}/${word}_cmds"
            elif [ -d "${current_cmds_dir}/${word}" ]; then
                current_cmds_dir="${current_cmds_dir}/${word}"
            else
                in_subcommand_space=false # Arrived at final script or standard arguments
            fi
        fi
    done

    # Generate options: suggest nested files/dirs or drop back to file completion
    if [ "$in_subcommand_space" = true ] && [ -d "$current_cmds_dir" ]; then
        local subcommands=""
        for item in "$current_cmds_dir"/*; do
            if [ -f "$item" ] && [[ "$item" == *.sh ]]; then
                local name="${item##*/}"
                subcommands="$subcommands ${name%.sh}"
            elif [ -d "$item" ]; then
                local name="${item##*/}"
                name="${name%_cmds}"
                subcommands="$subcommands $name"
            fi
        done
        COMPREPLY=( $(compgen -W "${subcommands}" -- "$cur") )
    else
        COMPREPLY=( $(compgen -f -- "$cur") )
    fi
    return 0
}

# Automatically scan dotfiles directory and register matching executable wrappers
_df_bin_dir="$DOTFILES/bin"
if [ -d "$_df_bin_dir" ]; then
    for _target_exec in "$_df_bin_dir"/*; do
        if [ -f "$_target_exec" ] && [ -x "$_target_exec" ]; then
            _cmd_name=$(basename "$_target_exec")
            if [ -d "${_target_exec}_cmds" ]; then
                complete -F _dotfiles_subcommand_completion "$_cmd_name"
            fi
        fi
    done
fi
unset _df_bin_dir _target_exec _cmd_name



