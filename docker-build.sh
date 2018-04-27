#!/usr/bin/env bash

# Default constants
DOCKER_BUILD_TEMP="./DOCKER_BUILD_TEMP/";
SOURCE_PATH="./";
TARGET_PATH="./TEMP_TARGET/";
MANIFEST_FILE="./manifest.txt";
APP_NAME="java_app";
RESOURCES="./resources"

# Some colors
YELLOW='\033[1;33m';
GREEN='\033[0;32m';
NOC='\033[0m'

# Explains how to use the script
usage() {
    basicUsage="${YELLOW}$0 [OPTIONS] MAIN_FILE [TEMP_CONTEXT]${NOC}";

    basicEx="MAIN_FILE\tis the file which will be sent to javac <i.e. Main.java>, as such:\n\t\t\t\tjavac SOURCE_PATH";
    basicEx+="/MAIN_PACKAGE/MAIN_FILE -d TARGET_PATH\n";

    contextEx="TEMP_CONTEXT\tis the path which is sent to docker build as context. This path \n\t\t\tcreated, used and ";
    contextEx+="${YELLOW}removed${NOC} by the script. (default=${DOCKER_BUILD_TEMP})";

    methodDoc="The script will build and package a java program and proceed to build a docker image,\n\tit will create ";
    methodDoc+="a jar as such:\n\n\t\tjavac SOURCE_PATH/MAIN_PACKAGE/MAIN_FILE -d TARGET_PATH\n\t\tjar -cvmf "
    methodDoc+="MANIFEST_FILE APP_NAME.jar -C TARGET_PATH .\n\n\t${YELLOW}NOTE${NOC}: the TARGET_PATH and the TEMP_CONTEXT";
    methodDoc+=" will be removed, make sure the default path\n\tdoes not contain files of importance or use the options";
    methodDoc+="provided.\n\nThe docker image will be called APP_NAME and the file structure will look like this:\n\n";
    methodDoc+="\t\tapp/\n\t\t\tRESOURCES/\n\t\t\tAPP_NAME.jar\n\nWhere the app/ folder will be set as working directory.";
    methodDoc+=" Running the docker image with\n'docker run APP_NAME' will run the command 'java -jar APP_NAME.jar' to start the app".

    srcOpt="-s\tSOURCE_PATH\tpath to source, the script will start looking for MAIN_FILE in\n\t\t\t\t"
    srcOpt+="this folder <i.e. ./src> (default=${SOURCE_PATH})";
    packOpt="-p\tMAIN_PACKAGE\tpackage of main, if provided the script will look for MAIN_FILE\n\t\t\t\t"
    packOpt+="in SOURCE_PATH/MAIN_PACKAGE/ <i.e. com.example.package (\".\" will\n\t\t\t\t"
    packOpt+="be converted to \"/\" by the script)>";

    srcPackOmit="\nIt is possible to omit -s and -p and provide the full path directly to MAIN_FILE. Note that setting\n"
    srcPackOmit+="source path will not change where the script looks for the manifest file.";

    targetOpt="-t\tTARGET_PATH\ttemporary path where the build script will but the result of\n\t\t\t\tjavac. It is ";
    targetOpt+="created, used and ${YELLOW}removed${NOC} by the script. \n\t\t\t\t(default=${TARGET_PATH})";
    manifestOpt="-m\tMANIFEST_FILE\tpath to manifest file to be sent to jar (default=${MANIFEST_FILE})";
    nameOpt="-n\tAPP_NAME\tname of the application, will prefix the *.jar and name the\n\t\t\t\tdocker image (default=${APP_NAME})";
    resOpt="-r\tRESOURCES\tfiles in this folder will be copied to the docker image. The\n\t\t\t\tRESOURCES folder will ";
    resOpt+="reside on the same level as APP_NAME.jar\n\t\t\t\t(default=${RESOURCES})";

    fullUsageMessage="Usage: ${basicUsage}\n\n\t${basicEx}\n\t${contextEx}\n\nDescription:\n\t${methodDoc}\n\n";
    fullUsageMessage+="OPTIONS:\n\t${srcOpt}\n\t${packOpt}\n\t${srcPackOmit}\n\n\t${targetOpt}\n\t${manifestOpt}\n\t${nameOpt}\n\t${resOpt}"
    echo -e ${fullUsageMessage} 1>&2;
    exit 1;
}

numOptions=0;

addOption() {
    ((numOptions+=$1))
}

while getopts p:s:t:m:n:h option
do
    case "${option}"
    in
    p) MAIN_PACKAGE=${OPTARG}; addOption 2;;
    s) SOURCE_PATH=${OPTARG}; addOption 2;;
    t) TARGET_PATH=${OPTARG}; addOption 2;;
    m) MANIFEST_FILE=${OPTARG}; addOption 2;;
    n) APP_NAME=${OPTARG}; addOption 2;;
    r) RESOURCES=${OPTARG}; addOption 2;;
    h) usage;;
    \?) usage;;
    :) usage;;
    esac
done

mainIndex=$((numOptions+1));
contextIndex=$((mainIndex+1));

MAIN_FILE=${!mainIndex}
if [ -z ${MAIN_FILE} ]; then
    usage;
fi

JAR_FILE=$APP_NAME".jar"

# Making sure we have all the folders we need
DOCKER_CONTEXT_PATH=${!contextIndex};
if [ -z ${DOCKER_CONTEXT_PATH} ]; then
    DOCKER_CONTEXT_PATH=${DOCKER_BUILD_TEMP};
fi

if [ ! -d ${DOCKER_CONTEXT_PATH} ]; then
  mkdir -p ${DOCKER_CONTEXT_PATH};
  echo "Created ${DOCKER_CONTEXT_PATH}";
fi

if [ ! -d ${TARGET_PATH} ]; then
    mkdir ${TARGET_PATH};
    echo "Created ${TARGET_PATH}";
fi

# Making simple JAR
echo -e ${YELLOW}"\nCompiling Jar"${NOC}
javac ${SOURCE_PATH}/${MAIN_PACKAGE//"."/"/"}/${MAIN_FILE} -d ${TARGET_PATH}
jar -cvmf ${MANIFEST_FILE} ${JAR_FILE} -C ${TARGET_PATH} .

# Moving files needed in docker build to valid context
echo -e ${YELLOW}"\nPreparing Docker build"${NOC}
cp -r ./Dockerfile ./resources/ ${JAR_FILE} ${DOCKER_CONTEXT_PATH}
echo -e "Copied files to temp build directory (${YELLOW}${DOCKER_CONTEXT_PATH}${NOC}):"
ls -la ${DOCKER_CONTEXT_PATH}

echo -e ${YELLOW}"\nStart Docker build"${NOC}
docker build --rm -t ${APP_NAME} --build-arg JAR_FILE=${JAR_FILE} --build-arg RESOURCES=${RESOURCES} ${DOCKER_CONTEXT_PATH}/

echo -e ${YELLOW}"\nCleaning up"${NOC}"\nremoving temporary folders and files..."
rm -r ${DOCKER_CONTEXT_PATH};
rm -r ${TARGET_PATH};
rm ${JAR_FILE}

echo -e ${GREEN}"\nDone..."${NOC}