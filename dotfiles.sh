#!/bin/bash

declare -gA df_sigil_map=(
    ["%"]="distrib-release distrib-codename codename distrib system-release system distrib-family"
    ["@"]="hostname-full hostname-short domain"
  )

declare -gA df_weight_map=(
    ["hostname-full"]=20,
    ["hostname-short"]=8
    ["distrib-release"]=5
    ["distrib-codename"]=5
    ["codename"]=3
    ["distrib"]=3
    ["distrib-family"]=2
    ["domain"]=1
    ["system-release"]=1
    ["system"]=1
  )

populate_identity_map () {
  declare -gA df_ident=()
  declare -a illegal_chars=(, + ${!df_sigil_map[@]})

  # See https://en.wikipedia.org/wiki/Uname for examples.
  df_ident["system"]="$(uname -s)"
  df_ident["system-release"]="${df_ident[system]}-$(uname -r)"

  if [[ -r "/etc/lsb-release" ]] ; then
    source "/etc/lsb-release"
    df_ident["distrib-release"]="${DISTRIB_ID}-${DISTRIB_RELEASE}"
    df_ident["distrib-codename"]="${DISTRIB_ID}-${DISTRIB_CODENAME}"
    df_ident["distrib"]="${DISTRIB_ID}"
    df_ident["codename"]="${DISTRIB_CODENAME}"
  fi

  [[ -e "/etc/debian-release" ]] && df_ident["distrib-family"]="debian"
  [[ -e "/etc/redhat-release" ]] && df_ident["distrib-family"]="redhat"
  [[ "${df_ident["distrib"],,}" = "ubuntu" ]] && df_ident["distrib-family"]="debian"
  [[ "${df_ident["distrib"],,}" = "centos" ]] && df_ident["distrib-family"]="redhat"

  df_ident["hostname-full"]="$(hostname -f)"
  df_ident["domain"]="$(hostname -d)"
  df_ident["hostname-short"]="$(hostname -s)"

  declare key
  for key in "${!df_ident[@]}" ; do
    df_ident[$key]="${df_ident[$key],,}"
    df_ident[$key]="${df_ident[$key]// /-}"
    declare illegal
    for illegal in "${illegal_chars[@]}" ; do
      df_ident[$key]="${df_ident[$key]//${illegal}/}"
    done
  done
}

populate_identity_map

identity_sigil () {
  declare ident="$1"
  declare sigil
  for sigil in ${!df_sigil_map[@]} ; do
    declare sigil_ident
    for sigil_ident in ${df_sigil_map[$sigil]} ; do
      if [[ "$ident" = "$sigil_ident" ]] ; then
        echo -n "$sigil"
        return
      fi
    done
  done
}

weight_of_file () {
  declare file="$1"
  declare -i weight=0
  declare -i identity_count=0
  declare ident
  for ident in $(file_identities "$file") ; do      
    identity_count+=1
    declare -i ident_weight="$(weight_of_identity "$ident")"
    if [[ $ident_weight -gt $weight ]] ; then
      weight=$ident_weight
    fi
  done
  if [[ $identity_count -ge 1 && $weight -eq 0 ]] ; then
    weight=-1
  fi
  echo -n "$weight"
}

weight_of_identity () {
  declare ident="$1"
  declare -i weight=0
  for part in ${ident//+/ } ; do
    declare sigil="${part:0:1}"
    part="${part:1}"
    declare key
    for key in ${df_sigil_map[$sigil]:-} ; do
      if [[ "${part,,}" = "${df_ident[$key]}" ]] ; then
        weight+=${df_weight_map[$key]:-0}
      fi
    done
  done
  echo -n "$weight"
}

file_identities () {
  declare file="$1"
  if [[ ! "$file" =~ .+~.+ ]] ; then
    return
  fi
  file="${1#*~}"
  file="${file// /}"
  declare ident
  for ident in "${file//,/ }" ; do
    echo "$ident"
  done
}

available_identities () {
  declare ident
  for ident in "${!df_ident[@]}" ; do
    printf "%s%s\n" "$(identity_sigil "$ident")" "${df_ident[$ident]}"
  done
}

best_file () {
  declare normalised_file="${1:-}"
  if [[ -z "$normalised_file" ]] ; then
    >&2 echo "Syntax: ${0##*/} <normalised_file>"; return 64
  fi
  declare -i best_weight
  declare best
  declare file
  for file in "$normalised_file" "$normalised_file"~* ; do
    declare -i weight="$(weight_of_file "$file")"
    if [[ -z "${best:-}" || $weight -gt ${best_weight:-2} ]] ; then
      best="$file"
      best_weight=$weight
    fi
  done
  echo "$best"
}

normalised_files () {
  declare path="${1:-}"
  if [[ -z "$path" || ! -e "$path" ]] ; then
    >&2 echo "Syntax: ${0##*/} <path>"; return 64
  fi
  declare -A files=()
  for file in "${path%/}"/* ; do
    files["${file%%~*}"]=1
  done
  for file in "${!files[@]}" ; do
    echo "$file"
  done
}

symlink_files () {
  declare path="${1:-}"
  if [[ -z "$path" || ! -e "$path" ]] ; then
    >&2 echo "Syntax: ${0##*/} <path>"; return 64
  fi
  declare file
  while read -r file ; do
    [[ -d "$file" ]] && continue
    printf "Symlink '%s' to '%s'.\n" "$file" "$(best_file "$file")"
  done < <(normalised_files "$path")
}

file_weights () {
  declare path="${1:-}"
  if [[ -z "$path" || ! -e "$path" ]] ; then
    >&2 echo "Syntax: ${0##*/} <path>"; return 64
  fi
  declare file
  for file in "$path"/* ; do
    printf "%d %s\n" "$(weight_of_file "$file")" "$file"
  done
}

create_self_symlinks () {
  declare link
  for link in available-identities file-weights symlink-files \
              normalised-files best-file ; do
    ln -v -f -s -T "${BASH_SOURCE[0]##*/}" "${BASH_SOURCE[0]%/*}/$link"
  done
}

if [[ "$(readlink -f -- "${BASH_SOURCE[0]}")" = "$(readlink -f -- "$0")" ]] ; then
  main () {
    if [[ $# -eq 1 && "$1" = "install" ]] ; then
      create_self_symlinks
      return $?
    fi

    declare personality="${0##*/}"
    case "${personality,,}" in
      available*) available_identities | sort -u ;;
      *file*weight*) file_weights "$@" ;;
      *symlink*file*) symlink_files "$@" ;;
      *normali[sz]ed*file*) normalised_files "$@" ;;
      *best*file*) best_file "$@" ;;
    esac
  }

  set -euo pipefail
  shopt -s nullglob
  main "$@"
  exit $?
fi

