#!/usr/bin/env bash
# shellcheck shell=bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202407281713-git
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.pro
# @@License          :  LICENSE.md
# @@ReadME           :  05-php-fpm.sh --help
# @@Copyright        :  Copyright: (c) 2024 Jason Hempstead, Casjays Developments
# @@Created          :  Sunday, Jul 28, 2024 17:13 EDT
# @@File             :  05-php-fpm.sh
# @@Description      :
# @@Changelog        :  New script
# @@TODO             :  Better documentation
# @@Other            :
# @@Resource         :
# @@Terminal App     :  no
# @@sudo/root        :  no
# @@Template         :  other/start-service
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# shellcheck disable=SC2016
# shellcheck disable=SC2031
# shellcheck disable=SC2120
# shellcheck disable=SC2155
# shellcheck disable=SC2199
# shellcheck disable=SC2317
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# run trap command on exit
trap 'retVal=$?;[ "$SERVICE_IS_RUNNING" != "yes" ] && [ -f "$SERVICE_PID_FILE" ] && rm -Rf "$SERVICE_PID_FILE";exit $retVal' SIGINT SIGTERM EXIT
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# setup debugging - https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
[ -f "/config/.debug" ] && [ -z "$DEBUGGER_OPTIONS" ] && export DEBUGGER_OPTIONS="$(<"/config/.debug")" || DEBUGGER_OPTIONS="${DEBUGGER_OPTIONS:-}"
{ [ "$DEBUGGER" = "on" ] || [ -f "/config/.debug" ]; } && echo "Enabling debugging" && set -xo pipefail -x$DEBUGGER_OPTIONS && export DEBUGGER="on" || set -o pipefail
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
export PATH="/usr/local/etc/docker/bin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
SCRIPT_FILE="$0"
SERVICE_NAME="php"
SCRIPT_NAME="$(basename "$SCRIPT_FILE" 2>/dev/null)"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# exit if __start_init_scripts function hasn't been Initialized
if [ ! -f "/run/__start_init_scripts.pid" ]; then
  echo "__start_init_scripts function hasn't been Initialized" >&2
  SERVICE_IS_RUNNING="no"
  exit 1
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# import the functions file
if [ -f "/usr/local/etc/docker/functions/entrypoint.sh" ]; then
  . "/usr/local/etc/docker/functions/entrypoint.sh"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# import variables
for set_env in "/root/env.sh" "/usr/local/etc/docker/env"/*.sh "/config/env"/*.sh; do
  [ -f "$set_env" ] && . "$set_env"
done
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
printf '%s\n' "# - - - Initializing $SERVICE_NAME - - - #"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Run any pre-execution checks
__run_pre_execute_checks() {
  # Set variables
  local exitStatus=0

  # Put command to execute in parentheses
  {
    true
  } && exitStatus=0 || exitStatus=5
  if [ $exitStatus -ne 0 ]; then
    echo "The pre-execution check has failed" >&2
    [ -f "$SERVICE_PID_FILE" ] && rm -Rf "$SERVICE_PID_FILE"
    exit 1
  fi
  return $exitStatus
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Custom functions

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Script to execute
START_SCRIPT="/usr/local/etc/docker/exec/$SERVICE_NAME"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Reset environment before executing service
RESET_ENV="yes"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Show message before execute
PRE_EXEC_MESSAGE=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set the database root dir
DATABASE_BASE_DIR="${DATABASE_BASE_DIR:-/data/db}"
# set the database directory
DATABASE_DIR="${DATABASE_DIR_PHP:-/data/db/sqlite}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set webroot
WWW_ROOT_DIR="/usr/local/share/httpd/default"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Default predefined variables
DATA_DIR="/data/php"   # set data directory
CONF_DIR="/config/php" # set config directory
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# set the containers etc directory
ETC_DIR="/etc/php"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
TMP_DIR="/tmp/php"
RUN_DIR="/run/php"       # set scripts pid dir
LOG_DIR="/data/logs/php" # set log directory
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set the working dir
WORK_DIR="" # set working directory
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Where to save passwords to
ROOT_FILE_PREFIX="/config/secure/auth/root" # directory to save username/password for root user
USER_FILE_PREFIX="/config/secure/auth/user" # directory to save username/password for normal user
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# root/admin user info password/random]
root_user_name="${PHP_ROOT_USER_NAME:-}" # root user name
root_user_pass="${PHP_ROOT_PASS_WORD:-}" # root user password
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Normal user info [password/random]
user_name="${PHP_USER_NAME:-}"      # normal user name
user_pass="${PHP_USER_PASS_WORD:-}" # normal user password
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# port which service is listening on
SERVICE_PORT="9000"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# User to use to launch service - IE: postgres
RUNAS_USER="root" # normally root
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# User and group in which the service switches to - IE: nginx,apache,mysql,postgres
SERVICE_USER="root"  # execute command as another user
SERVICE_GROUP="root" # Set the service group
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set user and group ID
SERVICE_UID="0" # set the user id
SERVICE_GID="0" # set the group id
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# execute command variables - keep single quotes variables will be expanded later
EXEC_CMD_BIN='php-fpm'                                                    # command to execute
EXEC_CMD_ARGS='--allow-to-run-as-root --fpm-config $ETC_DIR/php-fpm.conf' # command arguments
EXEC_PRE_SCRIPT=''                                                        # execute script before
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Is this service a web server
IS_WEB_SERVER="no"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Is this service a database server
IS_DATABASE_SERVICE="no"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Update path var
PATH="./bin:$PATH"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Load variables from config
[ -f "/config/env/php.script.sh" ] && . "/config/env/php.script.sh" # Generated by my dockermgr script
[ -f "/config/env/php.sh" ] && . "/config/env/php.sh"               # Overwrite the variabes
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional predefined variables

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional variables
PHP_DEV_SERVER_PORT="80"
PHP_DEV_SERVER_START="yes"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Specifiy custom directories to be created
ADD_APPLICATION_FILES=""
ADD_APPLICATION_DIRS=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
APPLICATION_FILES="$LOG_DIR/$SERVICE_NAME.log"
APPLICATION_DIRS="$RUN_DIR $ETC_DIR $CONF_DIR $LOG_DIR $TMP_DIR"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional config dirs - will be Copied to /etc/$name
ADDITIONAL_CONFIG_DIRS=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# define variables that need to be loaded into the service - escape quotes - var=\"value\",other=\"test\"
CMD_ENV=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Overwrite based on file/directory
[ -d "/data/htdocs" ] && WWW_ROOT_DIR="/data/htdocs"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Per Application Variables or imports

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Custom prerun functions - IE setup WWW_ROOT_DIR

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# use this function to update config files - IE: change port
__update_conf_files() {
  local exitCode=0                                               # default exit code
  local sysname="${SERVER_NAME:-${FULL_DOMAIN_NAME:-$HOSTNAME}}" # set hostname

  # CD into temp to bybass any permission errors
  cd /tmp || false # lets keep shellcheck happy by adding false

  # delete files
  #__rm ""

  # execute if directory is empty
  #__is_dir_empty "" && true || false

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Create base directories
  __setup_directories
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Initialize templates
  if [ ! -d "$CONF_DIR" ] || __is_dir_empty "$CONF_DIR"; then
    if [ -d "$ETC_DIR" ]; then
      mkdir -p "$CONF_DIR"
      __copy_templates "$ETC_DIR/." "$CONF_DIR/"
    else
      __copy_templates "$ETC_DIR" "$CONF_DIR"
    fi
  fi
  [ -d "/usr/local/etc/docker/exec" ] || mkdir -p "/usr/local/etc/docker/exec"

  # replace variables
  # __replace "" "" "$CONF_DIR/php.conf"
  # replace variables recursively
  #  __find_replace "" "" "$CONF_DIR"

  # custom commands

  # define actions

  # exit function
  return $exitCode
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# function to run before executing
__pre_execute() {
  local exitCode=0                                               # default exit code
  local sysname="${SERVER_NAME:-${FULL_DOMAIN_NAME:-$HOSTNAME}}" # set hostname

  # define commands

  # execute if directories is empty
  __is_dir_empty "" && true
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # create user if needed
  __create_service_user "$SERVICE_USER" "$SERVICE_GROUP" "${WORK_DIR:-/home/$SERVICE_USER}" "${SERVICE_UID:-}" "${SERVICE_GID:-}"
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Modify user if needed
  __set_user_group_id $SERVICE_USER ${SERVICE_UID:-} ${SERVICE_GID:-}
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Set permissions
  __fix_permissions "$SERVICE_USER" "$SERVICE_GROUP"
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Copy /config to /etc
  for config_2_etc in $CONF_DIR $ADDITIONAL_CONFIG_DIRS; do
    __initialize_system_etc "$config_2_etc" |& tee -p -a "$LOG_DIR/init.txt" &>/dev/null
  done
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Replace variables
  HOSTNAME="$sysname" __initialize_replace_variables "$ETC_DIR" "$CONF_DIR" "$WWW_ROOT_DIR"
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # unset unneeded variables
  unset filesperms filename config_2_etc change_user change_user ADDITIONAL_CONFIG_DIRS application_files filedirs
  # Lets wait a few seconds before continuing
  sleep 10
  return $exitCode
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# function to run after executing
__post_execute() {
  local waitTime=60                                               # how long to wait before executing
  local postMessageST="Running post commands for $SERVICE_NAME"   # message to show at start
  local postMessageEnd="Finished post commands for $SERVICE_NAME" # message to show at completion
  local sysname="${SERVER_NAME:-${FULL_DOMAIN_NAME:-$HOSTNAME}}"  # set hostname
  PHP_DEV_SERVER_ROOT="${PHP_DEV_SERVER_ROOT:-$WWW_ROOT_DIR}"
  # execute commands
  (
    # wait
    sleep $waitTime
    # show message
    __banner "$postMessageST"
    # commands to execute
    {
      if [ -z "$PHP_DEV_SERVER_ROOT" ]; then
        { [ -d "/data/htdocs/www" ] && PHP_DEV_SERVER_ROOT="/data/htdocs/www"; } || { [ -d "/data/www" ] && PHP_DEV_SERVER_ROOT="/data/www"; }
      fi
      PHP_DEV_SERVER_ROOT="${PHP_DEV_SERVER_ROOT:-/usr/local/share/httpd}"
      [ "$PHP_DEV_SERVER_START" = "yes" ] && { [ -n "$PHP_DEV_SERVER_ROOT" ] && mkdir -p "$PHP_DEV_SERVER_ROOT" && __start_php_dev_server "$PHP_DEV_SERVER_ROOT" "$PHP_DEV_SERVER_START" || return 1; }
    }
    # set exitCode
    retVal=$?
    # show exit message
    __banner "$postMessageEnd: Status $retVal"
  ) 2>"/dev/stderr" | tee -p -a "$LOG_DIR/init.txt" >/dev/null &
  return
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# use this function to update config files - IE: change port
__pre_message() {
  local exitCode=0
  [ -n "$user_name" ] && echo "username:               $user_name" && echo "$user_name" >"${USER_FILE_PREFIX}/${SERVICE_NAME}_name"
  [ -n "$user_pass" ] && __printf_space "40" "password:" "saved to ${USER_FILE_PREFIX}/${SERVICE_NAME}_pass" && echo "$user_pass" >"${USER_FILE_PREFIX}/${SERVICE_NAME}_pass"
  [ -n "$root_user_name" ] && echo "root username:     $root_user_name" && echo "$root_user_name" >"${ROOT_FILE_PREFIX}/${SERVICE_NAME}_name"
  [ -n "$root_user_pass" ] && __printf_space "40" "root password:" "saved to ${ROOT_FILE_PREFIX}/${SERVICE_NAME}_pass" && echo "$root_user_pass" >"${ROOT_FILE_PREFIX}/${SERVICE_NAME}_pass"
  [ -n "$PRE_EXEC_MESSAGE" ] && eval echo "$PRE_EXEC_MESSAGE"
  # execute commands

  # set exitCode
  return $exitCode
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# use this function to setup ssl support
__update_ssl_conf() {
  local exitCode=0
  local sysname="${SERVER_NAME:-${FULL_DOMAIN_NAME:-$HOSTNAME}}" # set hostname
  # execute commands

  # set exitCode
  return $exitCode
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__create_service_env() {
  cat <<EOF | tee -p "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.sh" &>/dev/null
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# root/admin user info [password/random]
#ENV_ROOT_USER_NAME="${ENV_ROOT_USER_NAME:-$PHP_ROOT_USER_NAME}"   # root user name
#ENV_ROOT_USER_PASS="${ENV_ROOT_USER_NAME:-$PHP_ROOT_PASS_WORD}"   # root user password
#root_user_name="${ENV_ROOT_USER_NAME:-$root_user_name}"                              #
#root_user_pass="${ENV_ROOT_USER_PASS:-$root_user_pass}"                              #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#Normal user info [password/random]
#ENV_USER_NAME="${ENV_USER_NAME:-$PHP_USER_NAME}"                  #
#ENV_USER_PASS="${ENV_USER_PASS:-$PHP_USER_PASS_WORD}"             #
#user_name="${ENV_USER_NAME:-$user_name}"                                             # normal user name
#user_pass="${ENV_USER_PASS:-$user_pass}"                                             # normal user password

EOF
  __file_exists_with_content "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.sh" || return 1
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# script to start server
__run_start_script() {
  local runExitCode=0
  local workdir="$(eval echo "${WORK_DIR:-}")"                   # expand variables
  local cmd="$(eval echo "${EXEC_CMD_BIN:-}")"                   # expand variables
  local args="$(eval echo "${EXEC_CMD_ARGS:-}")"                 # expand variables
  local name="$(eval echo "${EXEC_CMD_NAME:-}")"                 # expand variables
  local pre="$(eval echo "${EXEC_PRE_SCRIPT:-}")"                # expand variables
  local extra_env="$(eval echo "${CMD_ENV//,/ }")"               # expand variables
  local lc_type="$(eval echo "${LANG:-${LC_ALL:-$LC_CTYPE}}")"   # expand variables
  local home="$(eval echo "${workdir//\/root/\/tmp\/docker}")"   # expand variables
  local path="$(eval echo "$PATH")"                              # expand variables
  local message="$(eval echo "")"                                # expand variables
  local sysname="${SERVER_NAME:-${FULL_DOMAIN_NAME:-$HOSTNAME}}" # set hostname
  [ -f "$CONF_DIR/$SERVICE_NAME.exec_cmd.sh" ] && . "$CONF_DIR/$SERVICE_NAME.exec_cmd.sh"
  #
  __run_pre_execute_checks 2>/dev/stderr | tee -a -p "/data/logs/entrypoint.log" "$LOG_DIR/init.txt" >/dev/null || return 20
  #
  if [ -z "$cmd" ]; then
    __post_execute 2>"/dev/stderr" | tee -p -a "$LOG_DIR/init.txt" >/dev/null
    retVal=$?
    echo "Initializing $SCRIPT_NAME has completed"
    exit $retVal
  else
    # ensure the command exists
    if [ ! -x "$cmd" ]; then
      echo "$name is not a valid executable"
      return 2
    fi
    # set working directories
    [ -z "$home" ] && home="${workdir:-/tmp/docker}"
    [ "$home" = "/root" ] && home="/tmp/docker"
    [ "$home" = "$workdir" ] && workdir=""
    # create needed directories
    [ -n "$home" ] && { [ -d "$home" ] || { mkdir -p "$home" && chown -Rf $SERVICE_USER:$SERVICE_GROUP "$home"; }; }
    [ -n "$workdir" ] && { [ -d "$workdir" ] || { mkdir -p "$workdir" && chown -Rf $SERVICE_USER:$SERVICE_GROUP "$workdir"; }; }

    [ "$user" != "root " ] && [ -d "$home" ] && chmod -f 777 "$home"
    [ "$user" != "root " ] && [ -d "$workdir" ] && chmod -f 777 "$workdir"
    # check and exit if already running
    if __proc_check "$name" || __proc_check "$cmd"; then
      echo "$name is already running" >&2
      return 0
    else
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      # cd to dir
      __cd "${workdir:-$home}"
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      # show message if env exists
      if [ -n "$cmd" ]; then
        [ -n "$SERVICE_USER" ] && echo "Setting up $cmd to run as $SERVICE_USER" || SERVICE_USER="root"
        [ -n "$SERVICE_PORT" ] && echo "$name will be running on $SERVICE_PORT" || SERVICE_PORT=""
      fi
      if [ -n "$pre" ] && [ -n "$(command -v "$pre" 2>/dev/null)" ]; then
        export cmd_exec="$pre $cmd $args"
        message="Starting service: $name $args through $pre"
      else
        export cmd_exec="$cmd $args"
        message="Starting service: $name $args"
      fi
      [ -n "$su_exec" ] && echo "using $su_exec" | tee -a -p "$LOG_DIR/init.txt"
      echo "$message" | tee -a -p "$LOG_DIR/init.txt"
      su_cmd touch "$SERVICE_PID_FILE"
      __post_execute 2>"/dev/stderr" | tee -p -a "$LOG_DIR/init.txt" >/dev/null &
      if [ "$RESET_ENV" = "yes" ]; then
        env_command="$(echo "env -i HOME=\"$home\" LC_CTYPE=\"$lc_type\" PATH=\"$path\" HOSTNAME=\"$sysname\" USER=\"${SERVICE_USER:-$RUNAS_USER}\" $extra_env")"
        execute_command="$(__trim "$su_exec $env_command $cmd_exec")"
        if [ ! -f "$START_SCRIPT" ]; then
          cat <<EOF >"$START_SCRIPT"
#!/usr/bin/env bash
trap 'exitCode=\$?;[ \$exitCode -ne 0 ] && [ -f "\$SERVICE_PID_FILE" ] && rm -Rf "\$SERVICE_PID_FILE";exit \$exitCode' EXIT
#
set -Eeo pipefail
# Setting up $cmd to run as ${SERVICE_USER:-root} with env
retVal=10
cmd="$cmd"
SERVICE_PID_FILE="$SERVICE_PID_FILE"
$execute_command 2>"/dev/stderr" >>"$LOG_DIR/$SERVICE_NAME.log" &
execPid=\$!
sleep 10
[ -n "\$execPid"  ] && echo "\$execPid" >"\$SERVICE_PID_FILE"
ps ax | awk '{print \$1}' | grep -v grep | grep -q \$execPid$ && retVal=0
[ "\$retVal" = 0 ] && echo "\$cmd has been started" || echo "\$cmd has failed to start - args: \$args" >&2
exit \$retVal

EOF
        fi
      else
        if [ ! -f "$START_SCRIPT" ]; then
          execute_command="$(__trim "$su_exec $cmd_exec")"
          cat <<EOF >"$START_SCRIPT"
#!/usr/bin/env bash
trap 'exitCode=\$?;[ \$exitCode -ne 0 ] && [ -f "\$SERVICE_PID_FILE" ] && rm -Rf "\$SERVICE_PID_FILE";exit \$exitCode' EXIT
#
set -Eeo pipefail
# Setting up $cmd to run as ${SERVICE_USER:-root}
retVal=10
cmd="$cmd"
SERVICE_PID_FILE="$SERVICE_PID_FILE"
$execute_command 2>>"/dev/stderr" >>"$LOG_DIR/$SERVICE_NAME.log" &
execPid=\$!
sleep 10
[ -n "\$execPid"  ] && echo \$execPid >"\$SERVICE_PID_FILE"
ps ax | awk '{print \$1}' | grep -v grep | grep \$execPid$ && retVal=0
[ "\$retVal" = 0 ] && echo "\$cmd has been started" || echo "\$cmd has failed to start - args: \$args" >&2
exit \$retVal

EOF
        fi
      fi
    fi
    [ -x "$START_SCRIPT" ] || chmod 755 -Rf "$START_SCRIPT"
    [ "$CONTAINER_INIT" = "yes" ] || eval sh -c "$START_SCRIPT"
    runExitCode=$?
    return $runExitCode
  fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# username and password actions
__run_secure_function() {
  if [ -n "$user_name" ] || [ -n "$user_pass" ]; then
    for filesperms in "${USER_FILE_PREFIX}"/*; do
      if [ -e "$filesperms" ]; then
        chmod -Rf 600 "$filesperms"
        chown -Rf $SERVICE_USER:$SERVICE_USER "$filesperms"
      fi
    done |& tee -p -a "$LOG_DIR/init.txt" &>/dev/null
  fi
  if [ -n "$root_user_name" ] || [ -n "$root_user_pass" ]; then
    for filesperms in "${ROOT_FILE_PREFIX}"/*; do
      if [ -e "$filesperms" ]; then
        chmod -Rf 600 "$filesperms"
        chown -Rf $SERVICE_USER:$SERVICE_USER "$filesperms"
      fi
    done |& tee -p -a "$LOG_DIR/init.txt" &>/dev/null
  fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# simple cd function
__cd() { mkdir -p "$1" && builtin cd "$1" || exit 1; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# process check functions
__pcheck() { [ -n "$(type -P pgrep 2>/dev/null)" ] && pgrep -x "$1" &>/dev/null && return 0 || return 10; }
__pgrep() { __pcheck "${1:-$EXEC_CMD_BIN}" || __ps aux 2>/dev/null | grep -Fw " ${1:-$EXEC_CMD_BIN}" | grep -qv ' grep' | grep '^' && return 0 || return 10; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# check if process is already running
__proc_check() {
  cmd_bin="$(type -P "${1:-$EXEC_CMD_BIN}")"
  cmd_name="$(basename "${cmd_bin:-$EXEC_CMD_NAME}")"
  if __pgrep "$cmd_bin" || __pgrep "$cmd_name"; then
    SERVICE_IS_RUNNING="yes"
    touch "$SERVICE_PID_FILE"
    echo "$cmd_name is already running"
    return 0
  else
    return 1
  fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Allow ENV_ variable - Import env file
__file_exists_with_content "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.sh" && . "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.sh"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
SERVICE_EXIT_CODE=0 # default exit code
# application specific
EXEC_CMD_NAME="$(basename "$EXEC_CMD_BIN")"                                # set the binary name
SERVICE_PID_FILE="/run/init.d/$EXEC_CMD_NAME.pid"                          # set the pid file location
SERVICE_PID_NUMBER="$(__pgrep)"                                            # check if running
EXEC_CMD_BIN="$(type -P "$EXEC_CMD_BIN" || echo "$EXEC_CMD_BIN")"          # set full path
EXEC_PRE_SCRIPT="$(type -P "$EXEC_PRE_SCRIPT" || echo "$EXEC_PRE_SCRIPT")" # set full path
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# create auth directories
[ -n "$USER_FILE_PREFIX" ] && { [ -d "$USER_FILE_PREFIX" ] || mkdir -p "$USER_FILE_PREFIX"; }
[ -n "$ROOT_FILE_PREFIX" ] && { [ -d "$ROOT_FILE_PREFIX" ] || mkdir -p "$ROOT_FILE_PREFIX"; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ "$IS_WEB_SERVER" = "yes" ] && RESET_ENV="yes"
[ -n "$RUNAS_USER" ] || RUNAS_USER="root"
[ -n "$SERVICE_USER" ] || SERVICE_USER="${RUNAS_USER:-root}"
[ -n "$SERVICE_GROUP" ] || SERVICE_GROUP="${RUNAS_USER:-root}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Database env
if [ "$IS_DATABASE_SERVICE" = "yes" ]; then
  RESET_ENV="no"
  DATABASE_CREATE="${ENV_DATABASE_CREATE:-$DATABASE_CREATE}"
  DATABASE_USER="${ENV_DATABASE_USER:-${DATABASE_USER:-$user_name}}"
  DATABASE_PASSWORD="${ENV_DATABASE_PASSWORD:-${DATABASE_PASSWORD:-$user_pass}}"
  DATABASE_ROOT_USER="${ENV_DATABASE_ROOT_USER:-${DATABASE_ROOT_USER:-$root_user_name}}"
  DATABASE_ROOT_PASSWORD="${ENV_DATABASE_ROOT_PASSWORD:-${DATABASE_ROOT_PASSWORD:-$root_user_pass}}"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Allow per init script usernames and passwords
__file_exists_with_content "$ETC_DIR/auth/user/name" && user_name="$(<"$ETC_DIR/auth/user/name")"
__file_exists_with_content "$ETC_DIR/auth/user/pass" && user_pass="$(<"$ETC_DIR/auth/user/pass")"
__file_exists_with_content "$ETC_DIR/auth/root/name" && root_user_name="$(<"$ETC_DIR/auth/root/name")"
__file_exists_with_content "$ETC_DIR/auth/root/pass" && root_user_pass="$(<"$ETC_DIR/auth/root/pass")"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# set password to random if variable is random
[ "$user_pass" = "random" ] && user_pass="$(__random_password)"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ "$root_user_pass" = "random" ] && root_user_pass="$(__random_password)"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Allow setting initial users and passwords via environment
user_name="$(eval echo "${ENV_USER_NAME:-$user_name}")"
user_pass="$(eval echo "${ENV_USER_PASS:-$user_pass}")"
root_user_name="$(eval echo "${ENV_ROOT_USER_NAME:-$root_user_name}")"
root_user_pass="$(eval echo "${ENV_ROOT_USER_PASS:-$root_user_pass}")"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Allow variables via imports - Overwrite existing
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ -f "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.sh" ] && . "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.sh"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__initialize_db_users
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Only run check
if [ "$1" = "check" ]; then
  shift $#
  __proc_check "$EXEC_CMD_NAME" || __proc_check "$EXEC_CMD_BIN"
  exit $?
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# set switch user command
if [ "$RUNAS_USER" = "root" ]; then
  su_cmd() {
    su_exec=""
    eval "$@" || return 1
  }
elif [ "$(builtin type -P gosu)" ]; then
  su_exec="gosu $RUNAS_USER"
  su_cmd() { gosu $RUNAS_USER "$@" || return 1; }
elif [ "$(builtin type -P runuser)" ]; then
  su_exec="runuser -u $RUNAS_USER"
  su_cmd() { runuser -u $RUNAS_USER "$@" || return 1; }
elif [ "$(builtin type -P sudo)" ]; then
  su_exec="sudo -u $RUNAS_USER"
  su_cmd() { sudo -u $RUNAS_USER "$@" || return 1; }
elif [ "$(builtin type -P su)" ]; then
  su_exec="su -s /bin/sh - $RUNAS_USER"
  su_cmd() { su -s /bin/sh - $RUNAS_USER -c "$@" || return 1; }
else
  su_cmd() {
    su_exec=""
    echo "Can not switch to $RUNAS_USER: attempting to run as root" && eval "$@" || return 1
  }
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Change to working directory
[ -n "$WORK_DIR" ] && [ -n "$EXEC_CMD_BIN" ] && [ "$PWD" != "$WORK_DIR" ] && __cd "$WORK_DIR" && echo "Setting the working directory to: $PWD"
[ -z "$WORK_DIR" ] && [ "$HOME" = "/root" ] && [ "$RUNAS_USER" != "root" ] && [ "$PWD" != "/tmp" ] && __cd "/tmp" && echo "Setting the working directory to: $PWD"
[ -z "$WORK_DIR" ] && [ "$HOME" = "/root" ] && [ "$SERVICE_USER" != "root" ] && [ "$PWD" != "/tmp" ] && __cd "/tmp" && echo "Setting the working directory to: $PWD" && WORK_DIR="" || WORK_DIR="${WORK_DIR:-$PWD}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# show init message
__pre_message
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Initialize ssl
__update_ssl_conf
__update_ssl_certs
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Updating config files
__create_service_env
__update_conf_files
__initialize_database
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__run_secure_function
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# run the pre execute commands
__pre_execute
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__run_start_script 2>>/dev/stderr | tee -p -a "/data/logs/entrypoint.log" >/dev/null && errorCode=0 || errorCode=10
if [ -n "$EXEC_CMD_BIN" ]; then
  if [ "$errorCode" -ne 0 ]; then
    echo "Failed to execute: ${cmd_exec:-$EXEC_CMD_BIN $EXEC_CMD_ARGS}" | tee -p -a "/data/logs/entrypoint.log" "$LOG_DIR/init.txt"
    rm -Rf "$SERVICE_PID_FILE"
    SERVICE_EXIT_CODE=10
    SERVICE_IS_RUNNING="no"
  else
    SERVICE_EXIT_CODE=0
    SERVICE_IS_RUNNING="no"
  fi
  SERVICE_EXIT_CODE=0
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__banner "Initializing of $SERVICE_NAME has completed with statusCode: $SERVICE_EXIT_CODE" | tee -p -a "/data/logs/entrypoint.log" "$LOG_DIR/init.txt"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exit $SERVICE_EXIT_CODE
