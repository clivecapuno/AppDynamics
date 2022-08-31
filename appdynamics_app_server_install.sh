#!/bin/bash

# =============================================================================================================
# AppDynamics Installation for Linux server
# Purpose: This script fully automates the installation of AppDynamics
# Development Team: Clive Capuno
#
# History:
#
#   Last Modified By: Clive Capuno
#   Last Modified: 08-16-2022
#   Initially Developed by: Clive Capuno
#   Initially Developed on: 08-16-2022
#
# Version History
#   1.0 Initial version
# =============================================================================================================

## Parameter setting
APPDYNAMICS_HOME="/opt/appdynamics"
MACHINE_AGENT="machineagent"
USER="appdynamics-machine-agent"
MACHINE_AGENT_INSTALLATION_FILE="machineagent-bundle-64bit-linux-22.3.0.3296.zip"
HOSTNAME=`hostname -s`
DATE=`date -u +"%m-%d-%Y %H:%M:%S %Z"`
URL="Sharepoint site here"
# =============================================================================================================
usage() {
    echo
    echo "______________________________________________________________________________________________________"
    echo "Usage:                                                                                                "
    echo
    echo " `basename $0` --installer linux_appdynamics_intallation.tar.gz							            "
    echo
    echo "Options:                                                                                              "
    echo
    echo " -c | --clean                Removes existing installation of AppDynamics located at /opt/appdynamics."
    echo "                             This standalone option must be run without any otheroptions to prevent   "
    echo "                             accidental usage.                                                        "
    echo
    echo " -i | --installer            File name of the AppDynamics installer.  					            "
    echo
    echo " -e | --environment          Determines which environment of Appdynamics to connect to. Values would  "
    echo "                             be either PROD OR DEV.                                                   "
    echo
    echo " -k | --key                  Access key to be used.                                                   "
    echo
    echo " -a | --apms_id              APMS_ID of this server.                                                  "
    echo
    echo " -n | --app_name             Application Name of this server.                                         "
    echo
    echo " -h | --help                 This help screen.                                                        "
    echo
}
# =============================================================================================================
if [[ "$1" = "" ]]; then
	usage
    exit
else
while [ "$1" != "" ]
do
    case $1 in
        -i | --installer )      shift
                                INSTALLATION_FILE=$1
                                ;;
        -e | --environment )    shift
                                ENV=$1
                                ;;
        -k | --key )            shift
                                ACCESS_KEY=$1
                                ;;
        -a | --apms_id )        shift
                                APMS_ID=$1
                                ;;
        -n | --app_name )       shift
                                APP_NAME=$1
                                ;;
        -c | --clean )          if [[ -z "$2" ]]; then
                                    CLEAN_INSTALL=1
                                else
                                    CLEAN_INSTALL=0
                                    echo "date=$DATE host=$HOSTNAME message=\"ERROR: -c (--clean) option must be provided as a standalone option!\""
                                    exit
                                fi
                                ;;
        -h | --help )           usage
                                exit
                                ;;
    esac
    shift
done
fi

# =============================================================================================================
## Initial checks
{
if [[ CLEAN_INSTALL -eq 1 ]]; then
    ## Uninstallsing AppDynamics
    echo "date=$DATE host=$HOSTNAME message=\"INFO: Proceeding with the un-installation of AppDynamics.\""
    echo "date=$DATE host=$HOSTNAME message=\"INFO: Stopping the AppDynamics service.\""
    systemctl stop appdynamics-machine-agent.service
    echo "date=$DATE host=$HOSTNAME message=\"INFO: Disabling the AppDynamics service.\""
    systemctl disable appdynamics-machine-agent.service
    systemctl daemon-reload
    systemctl reset-failed
    echo "date=$DATE host=$HOSTNAME message=\"INFO: Removing /etc/sysconfig/appdynamics-machine-agent.\""
    rm /etc/sysconfig/appdynamics-machine-agent
    echo "date=$DATE host=$HOSTNAME message=\"INFO: Removing /opt/appdynamics.\""
    rm -rf /opt/appdynamics 
    echo "date=$DATE host=$HOSTNAME message=\"INFO: Deleting the user $USER.\""
    userdel -rf $USER
    exit 
else
	## Checking if the AppDynamics installer file was provided as a command line parameter
	if [[ -z $INSTALLATION_FILE ]]; then
		echo "date=$DATE host=$HOSTNAME message=\"ERROR: Appdynamics Installer File not specified!\""
		exit 1
	else
		echo "date=$DATE host=$HOSTNAME message=\"INFO: Appdynamics Installer File=$INSTALLATION_FILE.\""
	fi

	## Checking if the ENVIRONMENT was provided as a command line parameter
	if [[ -z $ENV ]]; then
		echo "date=$DATE host=$HOSTNAME message=\"ERROR: ENVIRONMENT not specified!\""
		exit 1
	else
		echo "date=$DATE host=$HOSTNAME message=\"INFO: Appdynamics ENVIRONMENT=$ENV.\""
	fi

	## Checking if the AppDynamics ACCESS KEY was provided as a command line parameter
	if [[ -z $ACCESS_KEY ]]; then
		echo "date=$DATE host=$HOSTNAME message=\"ERROR: Appdynamics ACCESS KEY not specified!\""
		exit 1
	else
		echo "date=$DATE host=$HOSTNAME message=\"INFO: Appdynamics ACCESS_KEY=$ACCESS_KEY.\""
	fi

	## Checking if the APMS_ID was provided as a command line parameter
	if [[ -z $APMS_ID ]]; then
		echo "date=$DATE host=$HOSTNAME message=\"ERROR: APMS_ID not specified!\""
		exit 1
	else
		echo "date=$DATE host=$HOSTNAME message=\"INFO: APMS_ID=$APMS_ID.\""
	fi

	## Checking if the APPLICATION NAME was provided as a command line parameter
	if [[ -z $APP_NAME ]]; then
		echo "date=$DATE host=$HOSTNAME message=\"ERROR: APPLICATION NAME not specified!\""
		exit 1
	else
		echo "date=$DATE host=$HOSTNAME message=\"INFO: APPLICATION NAME=$APP_NAME.\""
	fi

	## Checking if installation file $INSTALLATION_FILE exists.
	if [[ -e $INSTALLATION_FILE ]]; then
			echo "date=$DATE host=$HOSTNAME message=\"INFO: Extracting installation files...\""
			tar -xf $INSTALLATION_FILE -C .
	else
			echo "date=$DATE host=$HOSTNAME message=\"WARN: Installer $INSTALLATION_FILE is not existing. Download the installation file from $URL\""
			exit 1
	fi
	
	## Checking if AppDynamics is installed
	if [[ `systemctl is-active appdynamics-machine-agent` == "unknown" ]] || [[ -d $APPDYNAMICS_HOME ]] ; then
		echo "date=$DATE host=$HOSTNAME message=\"INFO: Appdynamics Machine Agent is currently installed.\""
		echo "date=$DATE host=$HOSTNAME message=\"ERROR: Cannot install over existing Appdynamics Machine Agent. Please use -c (--clean) option.\""
		exit 1
	else
	
	# =============================================================================================================
		## Start of the installation
		echo "date=$DATE host=$HOSTNAME message=\"INFO: Proceeding with the installation of Appdynamics Machine Agent.\""
	
		## Checking for user "appdynamics-machine-agent"
		id -u $USER >/dev/null 2>&1
		if [[ "$?" == "0" ]]; then
			echo "date=$DATE host=$HOSTNAME message=\"INFO: User $USER already exists.\""
		else
			echo "date=$DATE host=$HOSTNAME message=\"INFO: User $USER doesn't exist. Creating user $USER\""
			adduser appdynamics-machine-agent
			echo "date=$DATE host=$HOSTNAME message=\"INFO: Succesfully created user $USER\""
		fi
	
		## Checking for $APPDYNAMICS_HOME. Creates directory appdynamics and machineagent
		if [[ -d $APPDYNAMICS_HOME ]]; then
			echo "date=$DATE host=$HOSTNAME message=\"INFO: $APPDYNAMICS_HOME is existing.\""
		else
			echo "date=$DATE host=$HOSTNAME message=\"INFO: $APPDYNAMICS_HOME is not existing. Creating the directory.\""
			mkdir $APPDYNAMICS_HOME
			mkdir $APPDYNAMICS_HOME/$MACHINE_AGENT
			chmod -R 777 $APPDYNAMICS_HOME
			echo "date=$DATE host=$HOSTNAME message=\"INFO: Succesfully created the directory $APPDYNAMICS_HOME/$MACHINE_AGENT.\""
		fi
	
	# =============================================================================================================
		## Linux AppDynamics installation machineagent
	
		## Extracting Machine Agent files
		unzip -q $MACHINE_AGENT_INSTALLATION_FILE -d $APPDYNAMICS_HOME/$MACHINE_AGENT
	
		## Modifying controller-info.xml
		echo "date=$DATE host=$HOSTNAME message=\"INFO: Updating controller info, unique host and access key\""
		sed -i 's/<controller-info>/<controller-info>\n<application-name>'"${APMS_ID}"'-'"${APP_NAME}"'<\/application-name>\n<tier-name>Tier1<\/tier-name>\n<node-name>Node1-'"${HOSTNAME}"'<\/node-name>/g' $ENV-controller-info.xml
		sed -i 's/<unique-host-id>/<unique-host-id>'"${APMS_ID}"'-'"${HOSTNAME}"'/g' $ENV-controller-info.xml
		sed -i 's/<account-access-key>/<account-access-key>'"${ACCESS_KEY}"'/g' $ENV-controller-info.xml
		echo "date=$DATE host=$HOSTNAME message=\"INFO: Copying $ENV-controller-info.xml to $APPDYNAMICS_HOME/$MACHINE_AGENT/conf\""
		cp $ENV-controller-info.xml $APPDYNAMICS_HOME/$MACHINE_AGENT/conf/controller-info.xml
		chmod -R 777 $APPDYNAMICS_HOME
		echo "date=$DATE host=$HOSTNAME message=\"INFO: Succesfully updated the controller info, unique host and access key\""
	
		echo "date=$DATE host=$HOSTNAME message=\"INFO: Copying the machine agent script to /etc/init.d\""
		cp $APPDYNAMICS_HOME/$MACHINE_AGENT/etc/init.d/appdynamics-machine-agent /etc/init.d/appdynamics-machine-agent
	
		echo "date=$DATE host=$HOSTNAME message=\"INFO: Editing the environment variables\""
		sed -i 's/\/opt\/appdynamics\/machine-agent/\/opt\/appdynamics\/machineagent/g' $APPDYNAMICS_HOME/$MACHINE_AGENT/etc/sysconfig/appdynamics-machine-agent
	
		echo "date=$DATE host=$HOSTNAME message=\"INFO: Adding the machine agent to start as a Service\""
		ln -s $APPDYNAMICS_HOME/$MACHINE_AGENT/etc/sysconfig/appdynamics-machine-agent /etc/sysconfig/appdynamics-machine-agent
	
		chkconfig --add appdynamics-machine-agent
		systemctl start appdynamics-machine-agent.service
	
		echo "date=$DATE host=$HOSTNAME message=\"INFO: Installing the AppDynamics analytics agent\""
		sed -i 's/<name>AppDynamics Analytics Agent<\/name>/<name>'"${APMS_ID}"'-'"${HOSTNAME}"'<\/name>/g' $APPDYNAMICS_HOME/$MACHINE_AGENT/monitors/analytics-agent/monitor.xml
		sed -i 's/<enabled>false<\/enabled>/<enabled>true<\/enabled>/g' $APPDYNAMICS_HOME/$MACHINE_AGENT/monitors/analytics-agent/monitor.xml
		sed -i 's/ad.agent.name=/ad.agent.name='"${APMS_ID}"'-'"${HOSTNAME}"'/g' $ENV-analytics-agent.properties
		cp $ENV-analytics-agent.properties $APPDYNAMICS_HOME/$MACHINE_AGENT/monitors/analytics-agent/conf/analytics-agent.properties
		systemctl restart appdynamics-machine-agent.service
		echo "date=$DATE host=$HOSTNAME message=\"INFO: Succesfully installed the AppDynamics analytics agent\""
	
		echo "date=$DATE host=$HOSTNAME message=\"INFO: Installing the network agent\""
		$APPDYNAMICS_HOME/$MACHINE_AGENT/extensions/NetVizExtension/install-extension.sh
		echo "date=$DATE host=$HOSTNAME message=\"INFO: Succesfully installed the network agent\""
	
		systemctl restart appdynamics-machine-agent.service
		chmod -R 755 $APPDYNAMICS_HOME
		chown -R appdynamics-machine-agent:appdynamics-machine-agent $APPDYNAMICS_HOME

        ## Removing extracted installation files
        rm *analytics-agent.properties
        rm *controller-info.xml
        rm machineagent-bundle-64bit-linux-22.3.0.3296.zip

	fi ## End of installation
fi ## End of condition for installation or uninstallation
} | tee -a appdynamics_app_server_install.log ## Logging to a log file for reference

exit 0
