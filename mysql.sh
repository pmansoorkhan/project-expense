#!/bin/bash

USER_ID=$(id -u)
LOG_FOLDER="/var/log/prject-expense"
SCRIPT_NAME=$(basename "$0")
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
N="\e[0m"  
MYSQL_ROOT_PASSWORD="ExpenseApp@1"
SCRIPT_DIR=$PWD
START_TIME="$(date +%s)"
mkdir -p "$LOG_FOLDER"     # Create log directory
echo "$(date "+%Y-%m-%d %H:%M:%S")  | Script started executing at:$(date)"  | tee -a "$LOG_FILE"

if [ "$USER_ID" -ne 0 ]; then
    echo -e " $(date "+%Y-%m-%d %H:%M:%S")  | ${R} Please run the script as root user ${N}"
    exit 1
fi

VALIDATE() {
    if [ "$1" -ne 0 ]; then
        echo -e "$(date "+%Y-%m-%d %H:%M:%S")  | $2 .... ${R} failed ${N}" | tee -a "$LOG_FILE"
        exit 1
    else
        echo -e "$(date "+%Y-%m-%d %H:%M:%S")  | $2 ...... ${G} successful ${N}" | tee -a "$LOG_FILE"
    fi
}

dnf install mysql-server -y  &>> $LOG_FILE
VALIDATE $? "Installing MYSQL server"


systemctl enable mysqld   &>> $LOG_FILE
systemctl start mysqld    &>> $LOG_FILE
VALIDATE $? "Enabling and starting MYSQL server"

mysql_secure_installation --set-root-pass "$MYSQL_ROOT_PASSWORD"
VALIDATE $? "Setting MYSQL root password"

