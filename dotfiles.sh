#!/bin/bash

declare -gA df_sigil_map=(
    ["%"]="distrib-release distrib-codename codename distrib system-release system distrib-family"
    ["@"]="hostname-full hostname-short domain"
  )

declare -gA df_weight_map=(
    ["hostname-full"]=20
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
  [[ -z "$normalised_file" ]] && return 64
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
  [[ -z "$path" || ! -e "$path" ]] && return 64
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
  declare target="${2:-}"
  if [[ -z "$path" || ! -e "$path" || -z "$target" || ! -e "$target" ]] ; then
    return 64
  fi
  declare file
  while read -r file ; do
    if [[ -d "$file" ]] && ! compgen -G "$file~*" >/dev/null ; then
      symlink_files "$file" "$target"
    else
      declare link_name="${target%/}/$file"
      declare link_target="$(best_file "$file")"
      declare relative_link_target="$(relative_path "$link_name" "$link_target")"
      ln -v -s -f "$(readlink -m "$link_name")" "$relative_link_target"
    fi
  done < <(normalised_files "$path")
}

file_weights () {
  declare path="${1:-}"
  [[ -z "$path" || ! -e "$path" ]] && return 64
  declare file
  for file in "$path"/* ; do
    printf "%d %s\n" "$(weight_of_file "$file")" "$file"
  done
}

create_self_symlinks () {
  declare link
  for link in available-identities file-weights symlink-files \
              normalised-files best-file relative-path ; do
    ln -v -f -s -T "${BASH_SOURCE[0]##*/}" "${BASH_SOURCE[0]%/*}/$link"
  done
}

relative_path () {
  # http://stackoverflow.com/questions/2564634/convert-absolute-path-into-relative-path-given-a-current-directory-using-bash
  declare source="$(readlink -m "${1:-}")"
  declare target="$(readlink -m "${2:-}")"
  [[ -z "$source" || -z "$target" ]] && return 64

  # When working with files, remove the file parts to calculate relative paths
  # only. We will append the file to the calculated path at the end.
  declare source_path="$source"
  declare target_path="$target"
  if [[ ! -d "$target" ]] ; then
    source_path="${source_path%/*}"
    target_path="${target_path%/*}"
  fi

  declare common_part="$source_path" # for now
  declare result="" # for now
  while [[ "${target_path#$common_part}" == "$target_path" ]] ; do
    # No match, means that candidate common part is not correct.
    # Go up one level (reduce common part).
    common_part="$(dirname $common_part)"
    # Record that we went back, with correct / handling.
    if [[ -z "$result" ]]; then
      result=".."
    else
      result="../$result"
    fi
  done

  if [[ $common_part == "/" ]]; then
    # Special case for root (no common path).
    result="$result/"
  fi

  # Since we now have identified the common part, compute the non-common part.
  forward_part="${target_path#$common_part}"

  # Now stick all parts together.
  if [[ -n "$result" ]] && [[ -n "$forward_part" ]]; then
    result="$result$forward_part"
  elif [[ -n "$forward_part" ]]; then
    # Extra slash removal.
    result="${forward_part:1}"
  fi
  # Append the filename to the resulting path if the target is a file vs dir.
  result="${result}${target#$target_path}"

  echo "$result"
}

if [[ "$(readlink -f -- "${BASH_SOURCE[0]}")" = "$(readlink -f -- "$0")" ]] ; then
  main () {
    if [[ $# -eq 1 && "$1" = "install" ]] ; then
      create_self_symlinks
      return $?
    fi

    declare syntax
    declare personality="${0##*/}"
    declare -i rc=0
    {
      case "${personality,,}" in
        available*) available_identities | sort -u ;;
        file-weight) file_weights "$@" ;;
        best-file) best_file "$@" ;;
        normali[sz]ed-file*) normalised_files "$@" ;;
        relative-path)
          syntax="<source_path> <target_path>"
          relative_path "$@" ;;
        symlink-file*)
          syntax="<src_dotfiles_path> <links_path>"
          symlink_files "$@" ;;
      esac
    } || rc=$?

    if [[ $rc -eq 64 ]] ; then
      >&2 echo "Syntax: ${0##*/} ${syntax:-<path>}"
    fi
    return $rc
  }

  set -euo pipefail
  shopt -s nullglob
  #trap caller ERR
  main "$@"
  exit $?
fi

