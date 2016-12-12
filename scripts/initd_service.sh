#!/bin/sh
#
# chkconfig: - 99 03
# description: Starts and stops SERVICE_NAME Service
#

RUNUSER=service_user
BASEDIR=/path/to/service/home/dir
EXECBIN=${BASEDIR}/bin/service_exec_bin
CONF=${BASEDIR}/config/service_name.conf
LOGFILE=${BASEDIR}/logs/service_name.out
PIDFILE=${BASEDIR}/run/service_name.pid
RUNGREP="${BASEDIR}/bin/service_exec_bin"
RUNUID=$(id -u ${RUNUSER})

function check_root(){
  if [ $EUID -ne 0 ] && [ $EUID -ne "${RUNUID}" ]; then
    echo "This script must be run as root or ${RUNUSER}" 1>&2
    exit 1
  fi
}

status(){
  PID=$(ps aux | grep -w ${RUNGREP} | grep -Ewv 'nohup|grep' | awk '{print $2}' | xargs)
  if [ ! -z "${PID}" ]; then
    echo "SERVICE_NAME Service is running (PID:${PID})"
    exit 0
  else
    echo "SERVICE_NAME Service is not running"
    exit 2
  fi
}

start(){
  PID=$(ps aux | grep -w ${RUNGREP} | grep -Ewv 'nohup|grep' | awk '{print $2}' | xargs)
  if [ ! -z "${PID}" ]; then
    echo "SERVICE_NAME Service is already running"
  else
    echo -n "Starting SERVICE_NAME Service"
    if [ $EUID -eq "${RUNUID}" ]; then
      nohup ${EXECBIN} >> ${LOGFILE} 2>&1 &
    else
      sudo -u ${RUNUSER} nohup ${EXECBIN} >> ${LOGFILE} 2>&1 &
    fi
    sleep 1
    PID=$(ps aux | grep -w ${RUNGREP} | grep -Ewv 'nohup|grep' | awk '{print $2}' | xargs)
    if [ ! -z "${PID}" ]; then
      echo ". OK"
      echo "${PID}" > ${PIDFILE}
      chown ${RUNUSER}:${RUNUSER} ${PIDFILE}
    else
      echo ". FAILED"
      exit 2
    fi
  fi
}

stop(){
  PID=$(ps aux | grep -w ${RUNGREP} | grep -Ewv 'nohup|grep' | awk '{print $2}' | xargs)
  if [ -z "${PID}" ]; then
    echo "SERVICE_NAME Service is aready stopped"
  else
    echo -n "Stopping SERVICE_NAME Service"
    kill -TERM ${PID}
    rm ${PIDFILE}
    attempt=1
    while true
    do
      PID=$(ps aux | grep -w ${RUNGREP} | grep -Ewv 'nohup|grep' | awk '{print $2}' | xargs)
      if [ ! -z "${PID}" ]; then
        sleep 5
        echo -n "."
        if [ "${attempt}" -eq 10 ]; then
          echo " FAILED"
          exit 2
        fi
      else
        echo " OK"
        break
      fi
      attempt=$((${attempt}+1))
    done
  fi
}

check_root
case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        sleep 1
        start
        ;;
    status)
        status
        ;;
    *)
        echo $"Usage: $0 {start|stop|restart|status}"
        exit 2
esac
