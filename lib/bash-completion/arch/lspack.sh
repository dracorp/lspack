# bash completion for lspack.pl
_lspack(){
    local cur prev packages opts
    _get_comp_words_by_ref cur
    COMPREPLY=()
    packages=$(pacman -Qq)
    opts=$(_parse_help $1 -h)
    COMPREPLY=( $( compgen -W "$packages" -- "$cur" ) )
    COMPREPLY+=( $( compgen -W "$opts" -- "$cur" ) )
} &&
complete -F _lspack lspack.pl lspack
