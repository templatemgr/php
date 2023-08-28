#!/usr/bin/env sh
# shellcheck shell=sh
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
# check for command
__cmd_exists() { command "$1" >/dev/null 2>&1 || return 1; }
__function_exists() { command -v "$1" 2>&1 | grep -q "is a function" || return 1; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# custom functions

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
INSTALL_SH_EXIT_STATUS=0
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Define Variables
TEMPLATE_NAME="php"
CONFIG_CHECK_FILE="php.ini"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
TMP_DIR="/tmp/config-$TEMPLATE_NAME"
CONFIG_DIR="/usr/local/share/template-files/config/$TEMPLATE_NAME"
INIT_DIR="/usr/local/etc/docker/init.d"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
GIT_REPO="https://github.com/templatemgr/$TEMPLATE_NAME"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ "$TEMPLATE_NAME" = "sample-template" ] && exit 1
[ -n "$DEFAULT_CONF_DIR" ] && DEFAULT_CONF_DIR="$DEFAULT_CONF_DIR/$TEMPLATE_NAME" || DEFAULT_CONF_DIR="$CONFIG_DIR"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
git clone "$GIT_REPO" "$TMP_DIR" || exit 1
[ -f "/etc/$TEMPLATE_NAME" ] && rm -Rf /etc/${TEMPLATE_NAME:?} || true
[ -d "/etc/$TEMPLATE_NAME" ] && rm -Rf /etc/${TEMPLATE_NAME:?}/* || true
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Main application
mkdir -p "/etc/$TEMPLATE_NAME" "$DEFAULT_CONF_DIR" "$INIT_DIR"
[ -f "$TMP_DIR/config/.gitkeep" ] && rm -Rf "$TMP_DIR/config/.gitkeep" || true
[ -f "$TMP_DIR/init-scripts/.gitkeep" ] && rm -Rf "$TMP_DIR/init-scripts/.gitkeep" || true
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ -d "$TMP_DIR/config" ] && cp -Rf "$TMP_DIR/config/." "/etc/$TEMPLATE_NAME/" || true
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ -d "$TMP_DIR/config" ] && cp -Rf "$TMP_DIR/config/." "$DEFAULT_CONF_DIR/" || true
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ -d "$TMP_DIR/init-scripts" ]; then
  init_scripts="$(ls -A "$TMP_DIR/init-scripts/" | grep '^' || false)"
  if [ -n "$init_scripts" ]; then
    for init_script in $; do
      if [ ! -f "$INIT_DIR/$init_script" ]; then
        cp -Rf "$TMP_DIR/init-scripts/$init_script" "$INIT_DIR/$init_script" || true
      fi
    done
  fi
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ -d "$INIT_DIR" ] && chmod -Rf 755 "$INIT_DIR"/*.sh || true
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ -d "$TMP_DIR" ] && rm -Rf "$TMP_DIR"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ -f "$DEFAULT_CONF_DIR/$CONFIG_CHECK_FILE" ] || INSTALL_SH_EXIT_STATUS=1
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End application
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# lets exit with code
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exit $INSTALL_SH_EXIT_STATUS
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# ex: ts=2 sw=2 et filetype=sh
