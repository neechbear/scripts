#!/bin/bash

shell="-bash"
expPS1=$(echo xyzzyplughtwisty | bash -i 2>&1 | grep xyzzyplughtwisty | head -1 | sed 's/xyzzyplughtwisty//g')

builtin_msg () {
    if [ -n "$3" ] && [ -n "$2" ] && [ -n "$1" ] ; then
        echo "$shell: $1: ($2): $3" >&2
    elif [ -n "$3" ] && [ -n "$2" ] ; then
        echo "$shell: $2: $3" >&2
    elif [ -n "$3" ] ; then
        echo "$3" >&2
    else
        echo "Segmentation fault" >&2
    fi
}

fake_shell () {
    while read -e -p "$expPS1" cmd arg1 argn </dev/tty
    do
        if [ -n "$cmd" ]
        then
            case "$cmd" in
                *[Ff][Uu][Cc][Kk]*)
                trap - EXIT
                exit
                ;;
            kill)
                builtin_msg "$cmd" "$arg1" "No such process"
                ;;
            *\<*|*\>*|.|pwd|cd|popd|pushd|dirs|type|source)
                builtin_msg "" "$arg1" "No such file or directory"
                ;;
            exit|logout|exec|bg)
                builtin_msg "$cmd" "$arg1" "No more processes."
                ;;
            :|[|alias|bind|break|builtin|wait|false|fc|fg|getopts|hash|help|history|caller|command|compgen|complete|compopt|continue|declare|disown|mapfile|echo|enable|eval|export|jobs|let|local|printf|read|readarray|readonly|return|set|shift|shopt|suspend|test|times|trap|true|typeset|ulimit|umask|unalias|unset)
                builtin_msg "$cmd" "$arg1"
                ;;
            *)
                echo "$shell: $cmd: command not found"
                ;;
            esac
        fi
    done
    fake_shell
}

trap true INT HUP TRAP KILL QUIT ABRT STOP USR1 USR2
trap fake_shell EXIT

find /home /usr /bin /root /opt /srv -d -printf '%k %p\n' 2>/dev/null | while read size file
do
    if [ $size -gt 1000000 ] ; then
        sleep 1
    elif [ $size -gt 500000 ] ; then
        sleep 0.3
    elif [ $size -gt 100000 ] ; then
        sleep 0.1
    fi
    if [ -d "$file" ] ; then
        echo "removed directory: ‘$file’"
    else
        echo "removed: ‘$file’"
    fi
done

wall << 'EOT'
                 uuuuuuu
             uu$$$$$$$$$$$uu
          uu$$$$$$$$$$$$$$$$$uu
         u$$$$$$$$$$$$$$$$$$$$$u
        u$$$$$$$$$$$$$$$$$$$$$$$u
       u$$$$$$$$$$$$$$$$$$$$$$$$$u
       u$$$$$$$$$$$$$$$$$$$$$$$$$u
       u$$$$$$"   "$$$"   "$$$$$$u
       "$$$$"      u$u       $$$$"
        $$$u       u$u       u$$$
        $$$u      u$$$u      u$$$
         "$$$$uu$$$   $$$uu$$$$"
          "$$$$$$$"   "$$$$$$$"
            u$$$$$$$u$$$$$$$u
             u$"$"$"$"$"$"$u
  uuu        $$u$ $ $ $ $u$$       uuu
 u$$$$        $$$$$u$u$u$$$       u$$$$
  $$$$$uu      "$$$$$$$$$"     uu$$$$$$
u$$$$$$$$$$$uu    """""    uuuu$$$$$$$$$$
$$$$"""$$$$$$$$$$uuu   uu$$$$$$$$$"""$$$"
 """      ""$$$$$$$$$$$uu ""$"""
           uuuu ""$$$$$$$$$$uuu
  u$$$uuu$$$$$$$$$uu ""$$$$$$$$$$$uuu$$$
  $$$$$$$$$$""""           ""$$$$$$$$$$$"
   "$$$$$"                      ""$$$$""
     $$$"                         $$$$"

Hopefully you have now learned a valuable
life lesson:   don't pipe executable code
from a random website directly in to your
command shell!
EOT

fake_shell

