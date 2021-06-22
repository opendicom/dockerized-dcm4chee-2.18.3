#!/bin/bash

# Set ENV Variables
export MYSQL_HOST=${MYSQL_HOST:-localhost}
export MYSQL_PORT=${MYSQL_PORT:-3306}
export MYSQL_DATABASE=${MYSQL_DATABASE:-pacsdb}
export MYSQL_USER=${MYSQL_USER:-pacs}
export MYSQL_PASSWORD=${MYSQL_PASSWORD:-pacs}
export MYSQL_CONNECT_RETRY=${MYSQL_RETRY_CONNECT:-30}


# Check mysql connection
while [ "$resu" != "${MYSQL_DATABASE}" ]; do
    echo -n "Check mysql connection...  "
    resu=$(mysql --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} -h ${MYSQL_HOST} -P ${MYSQL_PORT} --connect-timeout=5 --disable-column-names -B -e "SHOW DATABASES LIKE '${MYSQL_DATABASE}'" )
    if [ "$resu" != "${MYSQL_DATABASE}" ];then
        echo "ERROR"
        echo ${resu}
        echo "Retry in ${MYSQL_CONNECT_RETRY} seconds..."
        sleep ${MYSQL_CONNECT_RETRY}
    else 
        echo "OK"
    fi
done



# Replace mysql setting in datasource file
sed -i "s|<connection-url>.*</connection-url>|<connection-url>jdbc:mysql://${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DATABASE}</connection-url>|" /opt/dcm4chee/server/default/deploy/pacs-mysql-ds.xml
sed -i "s|<user-name>:*</user-name>|<user-name>${MYSQL_USER}</user-name>|" /opt/dcm4chee/server/default/deploy/pacs-mysql-ds.xml
sed -i "s|<password>.*</password>|<password>${MYSQL_PASSWORD}</password>|" /opt/dcm4chee/server/default/deploy/pacs-mysql-ds.xml


# turn on bash's job control
set -m
  
# Start jboss process and put it in the background
/opt/dcm4chee/bin/run.sh &
  
# Start and configure cron process
/usr/sbin/cron
crontab /crontab_file

# now we bring the primary process back into the foreground and leave it there
fg %1
