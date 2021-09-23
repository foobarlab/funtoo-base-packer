#!/bin/bash -uea
# vim: ts=4 sw=4 et

ANSI=true         # ANSI codes enabled (bold, underline, ...)
ANSI_COLOR=true   # ANSI color codes enabled

# ---- Colors

# see: https://misc.flogisoft.com/bash/tip_colors_and_formatting

# ansi sequences
ANSI_START="\033["
ANSI_END="m"

# formatting
ANSI_RESET="0"
ANSI_BOLD="1"
ANSI_DIM="2"
ANSI_UL="4"
ANSI_BLINK="5"
ANSI_INVERT="7"
ANSI_HIDDEN="8"

# expand background horizontally
ANSI_BG_EXPAND="K"

# default color
ANSI_DEFAULT="39"

# regular colors
ANSI_BLACK="30"
ANSI_RED="31"
ANSI_GREEN="32"
ANSI_YELLOW="33"
ANSI_BLUE="34"
ANSI_MAGENTA="35"
ANSI_CYAN="36"
ANSI_LIGHT_GREY="37"
ANSI_DARK_GREY="90"
ANSI_LIGHT_RED="91"
ANSI_LIGHT_GREEN="92"
ANSI_LIGHT_YELLOW="93"
ANSI_LIGHT_BLUE="94"
ANSI_LIGHT_MAGENTA="95"
ANSI_LIGHT_CYAN="96"
ANSI_WHITE="97"

# default background
ANSI_BG_DEFAULT="49"

# background colors
ANSI_BG_BLACK="40"
ANSI_BG_RED="41"
ANSI_BG_GREEN="42"
ANSI_BG_YELLOW="43"
ANSI_BG_BLUE="44"
ANSI_BG_MAGENTA="45"
ANSI_BG_CYAN="46"
ANSI_BG_LIGHT_GREY="47"
ANSI_BG_DARK_GREY="100"
ANSI_BG_LIGHT_RED="101"
ANSI_BG_LIGHT_GREEN="102"
ANSI_BG_LIGHT_YELLOW="103"
ANSI_BG_LIGHT_BLUE="104"
ANSI_BG_LIGHT_MAGENTA="105"
ANSI_BG_LIGHT_CYAN="106"
ANSI_BG_WHITE="107"

# special colors (number followed 0..255)
ANSI_256_FG="38;5;"
ANSI_256_BG="48;5;"

# 256 colors: first for compatibility
ANSI_256_BLACK="0"
ANSI_256_RED="1"
ANSI_256_GREEN="2"
ANSI_256_YELLOW="3"
ANSI_256_BLUE="4"
ANSI_256_MAGENTA="5"
ANSI_256_CYAN="6"
ANSI_256_LIGHT_GREY="7"
ANSI_256_DARK_GREY="8"
ANSI_256_LIGHT_RED="9"
ANSI_256_LIGHT_GREEN="10"
ANSI_256_LIGHT_YELLOW="11"
ANSI_256_LIGHT_BLUE="12"
ANSI_256_LIGHT_MAGENTA="13"
ANSI_256_LIGHT_CYAN="14"
ANSI_256_WHITE="15"

reset="${ANSI_START}${ANSI_RESET}${ANSI_END}"
bold="${ANSI_START}${ANSI_BOLD}${ANSI_END}"
underline="${ANSI_START}${ANSI_UL}${ANSI_END}"
blink="${ANSI_START}${ANSI_BLINK}${ANSI_END}"
expand="${ANSI_START}${ANSI_BG_EXPAND}"

default="${ANSI_START}${ANSI_RESET};${ANSI_DEFAULT}${ANSI_END}"
color="${default}"

black="${ANSI_START}${ANSI_RESET};${ANSI_BLACK}${ANSI_END}"
red="${ANSI_START}${ANSI_RESET};${ANSI_RED}${ANSI_END}"
green="${ANSI_START}${ANSI_RESET};${ANSI_GREEN}${ANSI_END}"
yellow="${ANSI_START}${ANSI_RESET};${ANSI_YELLOW}${ANSI_END}"
blue="${ANSI_START}${ANSI_RESET};${ANSI_BLUE}${ANSI_END}"
magenta="${ANSI_START}${ANSI_RESET};${ANSI_MAGENTA}${ANSI_END}"
cyan="${ANSI_START}${ANSI_RESET};${ANSI_CYAN}${ANSI_END}"
light_grey="${ANSI_START}${ANSI_RESET};${ANSI_LIGHT_GREY}${ANSI_END}"
dark_grey="${ANSI_START}${ANSI_RESET};${ANSI_DARK_GREY}${ANSI_END}"
light_red="${ANSI_START}${ANSI_RESET};${ANSI_LIGHT_RED}${ANSI_END}"
light_green="${ANSI_START}${ANSI_RESET};${ANSI_LIGHT_GREEN}${ANSI_END}"
light_yellow="${ANSI_START}${ANSI_RESET};${ANSI_LIGHT_YELLOW}${ANSI_END}"
light_blue="${ANSI_START}${ANSI_RESET};${ANSI_LIGHT_BLUE}${ANSI_END}"
light_magenta="${ANSI_START}${ANSI_RESET};${ANSI_LIGHT_MAGENTA}${ANSI_END}"
light_cyan="${ANSI_START}${ANSI_RESET};${ANSI_LIGHT_CYAN}${ANSI_END}"
white="${ANSI_START}${ANSI_RESET};${ANSI_WHITE}${ANSI_END}"

bg_black="${ANSI_START}${ANSI_RESET};${ANSI_BG_BLACK}${ANSI_END}"
bg_red="${ANSI_START}${ANSI_RESET};${ANSI_BG_RED}${ANSI_END}"
bg_green="${ANSI_START}${ANSI_RESET};${ANSI_BG_GREEN}${ANSI_END}"
bg_yellow="${ANSI_START}${ANSI_RESET};${ANSI_BG_YELLOW}${ANSI_END}"
bg_blue="${ANSI_START}${ANSI_RESET};${ANSI_BG_BLUE}${ANSI_END}"
bg_magenta="${ANSI_START}${ANSI_RESET};${ANSI_BG_MAGENTA}${ANSI_END}"
bg_cyan="${ANSI_START}${ANSI_RESET};${ANSI_BG_CYAN}${ANSI_END}"
bg_light_gray="${ANSI_START}${ANSI_RESET};${ANSI_BG_LIGHT_GREY}${ANSI_END}"
bg_dark_grey="${ANSI_START}${ANSI_RESET};${ANSI_BG_DARK_GREY}${ANSI_END}"
bg_light_red="${ANSI_START}${ANSI_RESET};${ANSI_BG_LIGHT_RED}${ANSI_END}"
bg_light_green="${ANSI_START}${ANSI_RESET};${ANSI_BG_LIGHT_GREEN}${ANSI_END}"
bg_light_yellow="${ANSI_START}${ANSI_RESET};${ANSI_BG_LIGHT_YELLOW}${ANSI_END}"
bg_light_blue="${ANSI_START}${ANSI_RESET};${ANSI_BG_LIGHT_BLUE}${ANSI_END}"
bg_light_magenta="${ANSI_START}${ANSI_RESET};${ANSI_BG_LIGHT_MAGENTA}${ANSI_END}"
bg_light_cyan="${ANSI_START}${ANSI_RESET};${ANSI_BG_LIGHT_CYAN}${ANSI_END}"
bg_white="${ANSI_START}${ANSI_RESET};${ANSI_BG_WHITE}${ANSI_END}"

# TODO terminal title

# ---- Functions

set_silent_mode() {
    if [[ $@ = "" ]]; then
        silent=false
    else
        silent=true
    fi
}
# TODO explicit let scripts set silent mode
set_silent_mode "$*"

# run given param if not $silent=true
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

# ---- Formatting / Colored output

success() {
  local text="$*"
  if [ "${ANSI}" = "true" ]; then
    color="${default}"
    if [ "${ANSI_COLOR}" = "true" ]; then color="${light_magenta}"; fi
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
    if [ "${ANSI_COLOR}" = "true" ]; then color="${light_yellow}"; fi
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
    if [ "${ANSI_COLOR}" = "true" ]; then color="${default}"; fi
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

step() {
  local text="$*"
  if [ "${ANSI}" = "true" ]; then
    color="${default}"
    if [ "${ANSI_COLOR}" = "true" ]; then color="${default}"; fi
    text=`bracket_to_bold "${text}"`
    echo -e "${color}--- ${text}${default}"
  else
    echo "--- ${text}"
  fi
}

note() {
  local text="$*"
  if [ "${ANSI}" = "true" ]; then
    color="${default}"
    if [ "${ANSI_COLOR}" = "true" ]; then color="${white}"; fi
    text=`bracket_to_bold "${text}"`
    echo -e "${color} #  ${text}${default}"
  else
    echo " #  ${text}"
  fi
}

result() {
  local text="$*"
  if [ "${ANSI}" = "true" ]; then
    color="${default}"
    if [ "${ANSI_COLOR}" = "true" ]; then color="${light_green}"; fi
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
    if [ "${ANSI_COLOR}" = "true" ]; then color="${default}"; fi
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
    echo -e "${color}${bold}================================================================================${default}"
    echo
    echo -e "${color}    ${text}${default}"
    echo
    echo -e "${color}${bold}================================================================================${default}"
  else
    echo "================================================================================"
    echo
    remove_ansi "    ${text}"
    echo
    echo "================================================================================"
  fi
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

# ---- Debugging examples

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
