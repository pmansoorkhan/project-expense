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
MYSQL_HOST="mysql.shannu.online"
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

dnf module disable nodejs -y     &>> $LOG_FILE
VALIDATE $? "Disabling NODEJS default version"

dnf module enable nodejs:20 -y    &>> $LOG_FILE
VALIDATE $? "Enabling required NODEJS version"

dnf install nodejs -y      &>> $LOG_FILE
VALIDATE $? "Installing NODEJS"

dnf update -y openssh openssh-server openssh-clients
VALIDATE  $? "Updating SSH packages"

id expense  &>> $LOG_FILE
if [ "$?" -ne 0 ]; then 
   useradd --system --home /app --shell /sbin/nologin --comment "expense system user" expense  | tee -a "$LOG_FILE"
   VALIDATE $? "Adding expense user"
else 
   echo -e " $(date "+%Y-%m-%d %H:%M:%S") ${B} User already exist ${N} .... ${Y} Skipping ${N} " | tee -a "$LOG_FILE"
fi

mkdir -p /app   &>> $LOG_FILE
VALIDATE $? "Creating app directory"

curl -o /tmp/backend.zip https://expense-joindevops.s3.us-east-1.amazonaws.com/expense-backend-v2.zip
VALIDATE $? "Downloading backend zip file"

cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/* &>> "$LOG_FILE"
VALIDATE "$?" "Removing old content from app directory"

unzip /tmp/backend.zip   &>> $LOG_FILE
VALIDATE $? "Unzipping backend zip file"

npm install    &>> $LOG_FILE
VALIDATE $? "Installing nodejs depencencies"

cp "$SCRIPT_DIR/backend.service"   /etc/systemd/system/backend.service
VALIDATE $? "Copying backend service file"

systemctl daemon-reload  &>> $LOG_FILE
systemctl enable backend  &>> $LOG_FILE
systemctl start backend
VALIDATE $? "Enabling and starting backend service"


dnf install mysql -y   &>> $LOG_FILE
VALIDATE $? "Installing MYSQL client package"

# mysql -h $MYSQL_HOST -uroot -pExpenseApp@1 < /app/schema/backend.sql
# VALIDATE $? "Creating backend database and tables"

# INDEX=$(mongosh --host $MONGODB_HOST --quiet  --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
Index=$(mysql -h $MYSQL_HOST -uroot -pExpenseApp@1 -e 'show databases;' | grep backend | wc -l)

if [ "$Index" -le 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pExpenseApp@1 < /app/schema/backend.sql
    VALIDATE $? "Creating backend database and tables"
else
    echo -e " $(date "+%Y-%m-%d %H:%M:%S")  | ${G}backend database already exists${N}......${Y}Skipping${N}"  
fi

# if [ "$INDEX" -le  0 ]; then 
#     mongosh --host "$MONGODB_HOST" </app/db/master-data.js &>> "$LOG_FILE"
#     VALIDATE "$?" "Loading catalogue products"
# else
#     echo -e " $(date "+%Y-%m-%d %H:%M:%S")  | ${G}catalogue products already loaded${N}......${Y}Skipping${N}"  
# fi


systemctl restart backend   &>> $LOG_FILE
VALIDATE $? "Restarting backend service"


print_total_time(){
    END_TIME="$(date +%s)"
    TOTAL_TIME=$(( "$END_TIME" - "$START_TIME" ))
    echo -e "$(date "+%Y-%m-%d %H:%M:%S")  | Script executed in :"${G} $TOTAL_TIME" seconds ${N}"  | tee -a "$LOG_FILE"
}

print_total_time