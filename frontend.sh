#!/bin/bash

USER_ID=$(id -u)
LOG_FOLDER="/var/log/project-expense"
SCRIPT_NAME=$(basename "$0")
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
N="\e[0m"  
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

dnf install nginx -y  &>> $LOG_FILE
VALIDATE $? "Installing NGINX"

systemctl enable nginx  &>> $LOG_FILE
systemctl start nginx
VALIDATE $? "Enabling and starting NGINX"

rm -rf /usr/share/nginx/html/*   &>> $LOG_FILE
VALIDATE $? "Removing default NGINX content"

curl -o /tmp/frontend.zip https://expense-joindevops.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip
VALIDATE $? "Downloading frontend zip file"

cd /usr/share/nginx/html
VALIDATE $? "Moving to NGINX html directory"

unzip /tmp/frontend.zip  &>> $LOG_FILE
VALIDATE $? "Unzipping frontend zip file"

cp "$SCRIPT_DIR/expense.conf"   /etc/nginx/default.d/expense.conf    &>> $LOG_FILE
VALIDATE $? "Copying expense.conf to NGINX default.d directory"

systemctl restart nginx  &>> $LOG_FILE
VALIDATE $? "Restarting NGINX service"

print_total_time(){
    END_TIME="$(date +%s)"
    TOTAL_TIME=$(( "$END_TIME" - "$START_TIME" ))
    echo -e "$(date "+%Y-%m-%d %H:%M:%S")  | Script executed in :"${G} $TOTAL_TIME" seconds ${N}"  | tee -a "$LOG_FILE"
}

print_total_time
