#!/usr/bin/env bash


# ------------
#
# define variables to control the script
# ------------

SCRIPTDIRECTORY=$PWD

REP_BASE=${SCRIPTDIRECTORY}/..
VERSION=${REP_BASE}/deploy.local.additionalfiles/version.txt
CONFIG=${REP_BASE}/deploy.local.additionalfiles/config

DEPLOY_PREPARE=${SCRIPTDIRECTORY}/../../deploy.prepare
#DEPLOY_PREPARE=/home/swissbib/temp/deploy.prepare
DEPLOY=${SCRIPTDIRECTORY}/../../deploy
#DEPLOY=/home/swissbib/temp/deploy
APP_DIR=/usr/local/vufind/httpd
#APP_DIR=/home/swissbib/temp/testDeployVuFind

CACHE_DIR=${APP_DIR}/local/cache
CLASSMAP_GENERATOR=${APP_DIR}/vendor/zendframework/zendframework/bin/classmap_generator.php
CSS_BUILDER=${APP_DIR}/util/cssBuilder.php

#initialize this variable if you want to create the local vufind DB
#SETCREATEDATABASE=true
#set the root password for mysql DB if you want to create a new database
rootPW=

#initialize this variable if you want to create a DB user and grant privileges
#CREATEANDGRANTDBUSER=true


function printFurtherNotes {

cat <<End-of-message



-------------------------------------
please remove content in ${APP_DIR}/local/cache and restart the apache server - you have to use root for this

configuration for Apache (you have to use root):
1) create a symbolic link in /etc/apache2/conf-enabled:
cd /etc/apache2/conf-enabled:
ln -s /usr/local/vufind/httpd/local/httpd-swissbib.conf httpd-swissbib.conf
2) restart apache (with root): service apache2 restart
3) now you should be able to call Swissbib/Vufind in your browser:
httpd://localhost/sbrd

Good Luck!

-------------------------------------
End-of-message

}


function createDB {

    echo "creating local DB for VuFind"
    mysql --user=root -p${rootPW} < ${SCRIPTDIRECTORY}/swissbib_vufind.sql
    if [ ! -z ${CREATEANDGRANTDBUSER} ]; then
        mysql --user=root -p${rootPW} < ${SCRIPTDIRECTORY}/createAndGrantUser.sql
    fi

}




if [ ! -d ${APP_DIR} ]; then
    mkdir ${APP_DIR}
fi


# Erstelle Clone des Repository 'swissbib/vufind'
# ------------
if [ -d ${DEPLOY_PREPARE} ]; then
    rm -rf ${DEPLOY_PREPARE}
fi

mkdir -p ${DEPLOY_PREPARE}
cd ${DEPLOY_PREPARE}
git clone https://github.com/swissbib/vufind.git .

# Bereite Deploy-Verzeichnis vor
# ------------
rm -rf ${DEPLOY}
if [ -d ${DEPLOY} ]; then
    rm -rf ${DEPLOY}
fi
mkdir -p ${DEPLOY}


#chose the latest current tag
git archive --format=tar --o=${DEPLOY}/deploycode.tar 26-beta-3

cd ${DEPLOY}
tar xf deploycode.tar
# Lösche überflüssigen Code
rm ${DEPLOY}/deploycode.tar
rm ${DEPLOY}/build.xml ${DEPLOY}/composer.* ${DEPLOY}/.gitignore ${DEPLOY}/import-* ${DEPLOY}/index* ${DEPLOY}/install* ${DEPLOY}/README.md ${DEPLOY}/run_vufind.bat ${DEPLOY}/vufind.sh
rm -rf ${DEPLOY}/harvest/ ${DEPLOY}/import/ ${DEPLOY}/sbDocumentation ${DEPLOY}/solr/

# Kopiere Konfigurationen und Versionsbezeichnung
# ------------
cp -r ${CONFIG} ${DEPLOY}/local/
cp ${VERSION}  ${DEPLOY}/module/Swissbib

cp ${REP_BASE}/deploy.local.additionalfiles/httpd-swissbib.conf ${DEPLOY}/local


# Setze Berechtigungen
# ------------
chmod 777 ${DEPLOY}/log/ ${DEPLOY}/local/languages/ ${DEPLOY}/local/cache/


# move sources to the APP_DIR of localhost
# ------------


if [ -d ${APP_DIR}/module ]; then
    rm -rf ${APP_DIR}/module
fi

if [ -d ${APP_DIR}/config ]; then
    rm -rf ${APP_DIR}/config
fi

if [ -d ${APP_DIR}/local/config ]; then
    rm -rf ${APP_DIR}/local/config
fi




cp -r  ${DEPLOY}/* ${APP_DIR}

if [ ! -d ${APP_DIR}/local/log ]; then
    mkdir ${APP_DIR}/local/log
fi
chmod 777 ${APP_DIR}/local/log ${APP_DIR}/log; touch ${APP_DIR}/local/log/messages.log, chmod 777 ${APP_DIR}/local/log/messages.log




cd ${APP_DIR}

${APP_DIR}/cli/createClassMapFiles.sh; php ${CSS_BUILDER}
touch ${APP_DIR}/log/error.log; chmod 777 ${APP_DIR}/log/error.log

chmod 777 ${APP_DIR}/local/cache
chmod 777 ${APP_DIR}/local/languages


if [ ! -z ${SETCREATEDATABASE} ]; then
    createDB

fi

printFurtherNotes

