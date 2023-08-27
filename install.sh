#!/usr/bin/env bash
# shellcheck shell=bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202308271918-git
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.pro
# @@License          :  LICENSE.md
# @@ReadME           :  install.sh --help
# @@Copyright        :  Copyright: (c) 2023 Jason Hempstead, Casjays Developments
# @@Created          :  Sunday, Aug 27, 2023 19:18 EDT
# @@File             :  install.sh
# @@Description      :
# @@Changelog        :  New script
# @@TODO             :  Better documentation
# @@Other            :
# @@Resource         :
# @@Terminal App     :  no
# @@sudo/root        :  no
# @@Template         :  shell/bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# shellcheck disable=SC2016
# shellcheck disable=SC2031
# shellcheck disable=SC2120
# shellcheck disable=SC2155
# shellcheck disable=SC2199
# shellcheck disable=SC2317
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# script variables
APPNAME="$(basename "$0" 2>/dev/null)"
VERSION="202308271918-git"
RUN_USER="$USER"
SET_UID="$(id -u)"
SCRIPT_SRC_DIR="${BASH_SOURCE%/*}"
INSTALL_SH_CWD="$(realpath "$PWD")"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# check for command
__cmd_exists() { which $1 >/dev/null 2>&1 || return 1; }
__function_exists() { builtin type $1 >/dev/null 2>&1 || return 1; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# custom functions

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
INSTALL_SH_EXIT_STATUS=0
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Define Variables
TEMPLATE_NAME="php"
TMP_DIR="/tmp/config-$TEMPLATE_NAME"
GIT_REPO="https://github.com/templatemgr/$TEMPLATE_NAME"
CONFIG_DIR="/usr/local/share/template-files/config/$TEMPLATE_NAME"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Main application
[ -d "$CONFIG_DIR" ] && mkdir -p "$CONFIG_DIR"
git clone -q "$GIT_REPO" "$TMP_DIR/" || exit 1
[ -f "$TMP_DIR/config/.gitkeep" ] && rm -Rf "$TMP_DIR/config/.gitkeep"
cp -Rf "$TMP_DIR/config/." "$CONFIG_DIR/" && [ -f "$CONFIG_DIR/php.ini" ] || INSTALL_SH_EXIT_STATUS=1
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End application
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# lets exit with code
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exit $INSTALL_SH_EXIT_STATUS
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# ex: ts=2 sw=2 et filetype=sh
