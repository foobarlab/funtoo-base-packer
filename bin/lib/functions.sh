#!/bin/bash -uea
# vim: ts=4 sw=4 et

# ---- functions

# global var
silent=true

# silent mode by var or param
set_silent_mode() {
  if [[ -v silent ]]; then
    silent=$silent
  else 
    if [[ $@ = "" ]]; then
      silent=false
    else
      silent=true
    fi
  fi
}

# run given param when not in silent mode
if_not_silent() {
  [ ! -v "$silent" ] && [[ "$silent" = "true" ]] || "$@"
}

# check if required command is found
require_commands() {
  local command;
  for command in $@; do
    command -v $command >/dev/null 2>&1 || { error "Command '${command}' required but can not be found. Aborting." >&2; exit 1; }
  done
}

# compare version strings
version_lte() {
  [  "$1" == "`echo -e "$1\n$2" | sort -V | head -n1`" ]
}
version_lt() {
  [ "$1" = "$2" ] && return 1 || version_lte $1 $2
}

# ---- formatting / colored output

success() {
  local text="$*"
  if [ "${ANSI}" = "true" ]; then
    color="${default}"
    if [ "${ANSI_COLOR}" = "true" ]; then color="${light_green}"; fi
    text=`bracket_to_bold "${text}"`
    echo -e "${color}${bold}+++${color} ${text}${default}"
  else
    echo "+++ ${text}"
  fi
}

warn() {
  local text="$*"
  if [ "${ANSI}" = "true" ]; then
    color="${default}"
    if [ "${ANSI_COLOR}" = "true" ]; then color="${yellow}"; fi
    text=`bracket_to_bold "${text}"`
    echo -e "${color}${bold}!!!${color} ${text}${default}"
  else
    echo "!!! ${text}"
  fi
}

error() {
  local text="$*"
  if [ "${ANSI}" = "true" ]; then
    color="${default}"
    if [ "${ANSI_COLOR}" = "true" ]; then color="${light_red}"; fi
    text=`bracket_to_bold "${text}"`
    echo -e "${color}${bold}ERROR!${color} ${text}${default}"
  else
    echo "ERROR! ${text}"
  fi
}

info() {
  local text="$*"
  if [ "${ANSI}" = "true" ]; then
    color="${default}"
    if [ "${ANSI_COLOR}" = "true" ]; then color="${cyan}"; fi
    text=`bracket_to_bold "${text}"`
    echo -e "${color}    ${text}${default}"
  else
    echo "    ${text}"
  fi
}

highlight() {
  local text="$*"
  if [ "${ANSI}" = "true" ]; then
    color="${default}"
    if [ "${ANSI_COLOR}" = "true" ]; then color="${white}"; fi
    text=`bracket_to_bold "${text}"`
    echo -e "${color}${bold}>>> ${text}${default}"
  else
    echo ">>> ${text}"
  fi
}

todo() {
  local text="$*"
  if [ "${ANSI}" = "true" ]; then
    color="${default}"
    if [ "${ANSI_COLOR}" = "true" ]; then color="${light_blue}"; fi
    text=`bracket_to_bold "${text}"`
    echo -e "${color}--> ${bold}TODO${color} [ ${text} ]${default}"
  else
    echo "--> TODO [ ${text} ]"
  fi
}

do_step() {
  local text="$*"
  if [ "${ANSI}" = "true" ]; then
    color="${default}"
    if [ "${ANSI_COLOR}" = "true" ]; then color="${dark_grey}"; fi
    text=`bracket_to_bold "${text}"`
    echo -e "${color}--- ${text}${default}"
  else
    echo "--- ${text}"
  fi
}
step() {
  if_not_silent do_step "$*"
}

note() {
  local text="$*"
  if [ "${ANSI}" = "true" ]; then
    color="${default}"
    if [ "${ANSI_COLOR}" = "true" ]; then color="${light_cyan}"; fi
    text=`bracket_to_bold "${text}"`
    echo -e "${color}    ${text}${default}"
  else
    echo "    ${text}"
  fi
}

result() {
  local text="$*"
  if [ "${ANSI}" = "true" ]; then
    color="${default}"
    if [ "${ANSI_COLOR}" = "true" ]; then color="${light_magenta}"; fi
    text=`bracket_to_bold "${text}"`
    echo -e "${color}==> ${text}${default}"
  else
    echo "==> ${text}"
  fi
}

final() {
  local text="$*"
  echo
  if [ "${ANSI}" = "true" ]; then
    color="${default}"
    if [ "${ANSI_COLOR}" = "true" ]; then color="${white}"; fi
    text=`bracket_to_bold "${text}"`
    echo -e "${color}${text}${default}"
  else
    echo ${text}
  fi
}

title() {
  local text="$*"
  if [ "${ANSI}" = "true" ]; then
    color="${default}"
    text=`bracket_to_bold "${text}"`  # FIXME
    if [ "${ANSI_COLOR}" = "true" ]; then color="${dark_grey}"; text="${white}${bold}${text}${default}"; fi
    title_divider
    echo -e "${color}  ${text}${default}"
    title_divider
  else
    title_divider
    remove_ansi "  ${text}"
    title_divider
  fi
}

title_divider() {
  if [ "${ANSI}" = "true" ]; then
    color="${default}"
    if [ "${ANSI_COLOR}" = "true" ]; then color="${dark_grey}"; fi
    echo -e "${color}${bold}--------------------------------------------------------------------------------${default}"
  else
    echo "--------------------------------------------------------------------------------"
  fi
}

header() {
  local text="$*"
  if [ "${ANSI}" = "true" ]; then
    color="${default}"
    text=`bracket_to_bold "${text}"`  # FIXME
    if [ "${ANSI_COLOR}" = "true" ]; then
      color="${white}"
      text=`bracket_to_bold "${text}"`
      text="${text}${default}"
    fi
    echo -e "${color}${bold}________________________________________________________________________________${default}"
    echo -e "${color}${bold}%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%${default}"
    echo
    echo -e "${color}    ${text}${default}"
    echo -e "${color}${bold}________________________________________________________________________________${default}"
    echo -e "${color}${bold}%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%${default}"
  else
    echo "================================================================================"
    echo
    remove_ansi "    ${text}"
    echo
    echo "================================================================================"
  fi
  echo
}

remove_ansi() {
  text="$*"
  text=`printf "$text" | sed -re "s/\\x1b\\[[0-9;]*[A-Za-z]//g"`
  echo -e "${text}"
}

bracket_to_bold() {
  local text="$*"
  local bold="\\\0033[1m"
  #local default="\\\0033[0;39m"
  color="\\${color}"
  text=`echo $text | sed -re "/\'/ s/(^|\s|\.|:)+[\']/\0$bold/g"`
  text=`echo $text | sed -re "/\'/ s/[\'](\.|:|\s|$)/$color\0/g"`
  echo `echo $text`
}

# ---- debugging examples

color_test() {
  # This program is free software. It comes without any warranty, to
  # the extent permitted by applicable law. You can redistribute it
  # and/or modify it under the terms of the Do What The Fuck You Want
  # To Public License, Version 2, as published by Sam Hocevar. See
  # http://sam.zoy.org/wtfpl/COPYING for more details.
  for fgbg in 38 48 ; do # Foreground / Background
      for color in {0..255} ; do # Colors
          # Display the color
          printf "\e[${fgbg};5;%sm  %3s  \e[0m" $color $color
          # Display 6 colors per lines
          if [ $((($color + 1) % 6)) == 4 ] ; then
              echo # New line
          fi
      done
      echo # New line
  done
}

#color_test # print 256-colors
#env | sort | grep ANSI_* # print vars
#echo -e "${red}RED!${blue}BLUE!${green}GREEN!${reset}"

test_formatting() {
  # test formatting
  ANSI=true
  ANSI_COLOR=true

  header "1234567890123456789012345678901234567890123456789012345678901234567890123456"
  header "123456789012345678901234567890"
  header "Build ansi color test header"
  echo "Just an echo."
  title "Test Title"
  highlight "This is a highlight and shines bright!"
  step "Another step, another 'brick' ..."
  warn "This is a 'warning'!"
  error "This is an 'error'!"
  info "This is a 'info'. Welcome 'world'!"
  todo "To be done."
  note "'Note' this!"
  result "This is a 'result'."
  final "Done."
  echo

  # test formatting
  ANSI=true
  ANSI_COLOR=false

  header "1234567890123456789012345678901234567890123456789012345678901234567890123456"
  header "123456789012345678901234567890"
  header "Build ansi color test header"
  echo "Just an echo."
  title "Test Title"
  highlight "This is a highlight and shines bright!"
  step "Another step, another 'brick' ..."
  warn "This is a 'warning'!"
  error "This is an 'error'!"
  info "This is a 'info'. Welcome 'world'!"
  todo "To be done."
  note "'Note' this!"
  result "This is a 'result'."
  final "Done."
  echo

  # test formatting
  ANSI=false
  ANSI_COLOR=false

  header "1234567890123456789012345678901234567890123456789012345678901234567890123456"
  header "123456789012345678901234567890"
  header "Build ansi color test header"
  echo "Just an echo."
  title "Test Title"
  highlight "This is a highlight and shines bright!"
  step "Another step, another 'brick' ..."
  warn "This is a 'warning'!"
  error "This is an 'error'!"
  info "This is a 'info'. Welcome 'world'!"
  todo "To be done."
  note "'Note' this!"
  result "This is a 'result'."
  final "Done."
  echo

  note "User.......: 'test'"
  note "Box........: 'box'"
  note "Provider...: 'provider'"

  # test formatting
  ANSI=true
  ANSI_COLOR=false

  note "User.......: 'test'"
  note "Box........: 'box'"
  note "Provider...: 'provider'"

}

#test_formatting

# TODO terminal title
