#!/bin/bash

#Stops the execution of a script if a command or pipeline has an error
set -e

###################### Variables Begin ##########################
python_directory=/export/apps/python/3.6/bin
currentuser=`logname`   #used logname instead of ${USER} as  ${USER} represents the user executing the program. In case of sudo it will be root
userhome="/users/${currentuser}"
aliasname="wikigen"
installation_directory="/users/${currentuser}/wikigen"
###################### Variables End ##########################

if [ $# = 1 ]; then 
    installation_directory=$1
fi

#Check if virtualenv executable exists
if ! [ -f "$python_directory/virtualenv" ]; then 
	echo "Installing virtualenv"
	${python_directory}/pip3 install virtualenv
fi

#Check if installation directory exists
if ! [ -d $installation_directory ]; then 
	echo "Creating installation directory: $installation_directory"
	mkdir -p $installation_directory  || echo "Incorrect path:${installation_directory}. Cannot create directory"
fi

#Check if virtual env directory exists
if ! [ -d "${installation_directory}/bin" ]; then 
	echo "Creating Virtualenv"
	${python_directory}/virtualenv $installation_directory   #--system-site-packages
fi

venv_python=${installation_directory}/bin/python3.6

#Install packages
echo "Installing python packages"
source ${installation_directory}/bin/activate
${installation_directory}/bin/pip install -r requirements.txt
deactivate

: '
#Create resources folders etc
for dir in "resources" "resources/templates" "resources/avro" "resources/pages"; do
	if ! [ -d ${installation_directory}/$dir ]; then 
		echo "Creating directory ${installation_directory}/$dir"
		mkdir ${installation_directory}/$dir
	fi
'

#Install wikigen
${venv_python} setup.py install --single-version-externally-managed --root=/ --home=${installation_directory} \
	--install-purelib=${installation_directory} --install-scripts=${installation_directory}/scripts 

#rm -r /users/ptreddy/wikigen/wikigen-*.egg*/ || echo ""

#Change ownership
echo "Changing directory ownership to current user"
chown -R $currentuser  ${installation_directory}

#Check if alias exists in .bashrc, bash_profile
for file in ".bashrc" ".bash_profile"; do
	if [ -f "${userhome}/$file" ]; then 
	    #if [ "$(grep $aliasname "${userhome}/$file")" = "" ]; then
	    #	echo "adding alias ${aliasname} to ${userhome}/$file"
		#	echo "alias ${aliasname}=\"${installation_directory}/bin/python3.6\"" >> "${userhome}/$file"
		#fi
		#remove old references
		sed -i ''  "/^alias ${aliasname}=/d" ${userhome}/$file
	fi

	echo "adding alias ${aliasname} to ${userhome}/$file"
	echo "alias ${aliasname}=\"${venv_python} ${installation_directory}/wikigen/main.py\"" >> "${userhome}/$file"
	#source ${userhome}/$file
done 
