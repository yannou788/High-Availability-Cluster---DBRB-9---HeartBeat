#!/bin/bash

#########################################
# Written by: Yann LUCCIN
# Contact at: cod4972@gmail.com
# Release 1
#########################################

# Functions
#-----------------------------------------------------------------------------
	function color {
	    while [ "$1" ]; do
	        case "$1" in 
	            -red)           color="\033[31;01m" ;;
	            -green)         color="\033[32;01m" ;;
	            -yellow)        color="\033[33;01m" ;;
	            -blue)          color="\033[49;34m" ;;
	            -n)             one_line=1;   shift ; continue ;;
	            *)              echo -n "$1"; shift ; continue ;;
	        esac

	        shift
	        echo -en "$color"
	        echo -en "$1"
	        echo -en "\033[00m"
	        shift

	    done
	    if [ ! $one_line ]; then
	        echo
	    fi
	}

	function banner_middle(){
		echo 
	        	color -blue "#---------------$1---------------#"
		echo
	}

	function is_root() {
	 if [ $EUID -ne 0 ]; then
	  color -red "Run this script as root" 1>&2
	  exit 1
	 fi
	}

	function is_succed() {
		EXIT_V="$?"
		case $EXIT_V in
			0) 
			color -green "Succed"		
			;;
			1)
			color -red "Error"
			exit		
			;;
		esac	
	}
# Parameters
# IF we on the primary or secondary server
#-----------------------------------------------------------------------------
if [ $1 ];
then
	if [ $1 == '--primary' ];
	then
		primary=1

	fi
else

	primary=0
fi

# Start Banner
#-----------------------------------------------------------------------------
	clear
	is_root
	echo
		color -green "################################################################################"
		color -green "#--------------------Cluster : PHP AND Apache2 Installation--------------------#"
		color -green "################################################################################"
	echo

# Installation of Apache2 and PHP5
#-----------------------------------------------------------------------------
	
	if [ -f /etc/ha.d/haresources ]
	then

		banner_middle "Apache2 And PHP5 Installation"
		apt-get install apache2 php5
			is_succed

		banner_middle "Remove Apache2 start launch"
		update-rc.d -f apache2 remove
			is_succed

		banner_middle "Stop the Apache2 service"
		/etc/init.d/apache2 stop
			is_succed

		if [[ $primary == 1 ]]; then
			banner_middle "Creation of the www dir in /mnt"
			mkdir /mnt/www
				is_succed
			mkdir /mnt/www/html
				is_succed
		fi

		banner_middle "Remove /var/www dir"
		rm -rvf /var/www/
			is_succed

		banner_middle "Creation of symlink /var/www to /mnt/www/"
		ln -s /mnt/www/ /var/
			is_succed

		banner_middle "Update the haresources file"
			nha=$(sed -e 's/.*/& apache2/' /etc/ha.d/haresources)
			echo $nha > /etc/ha.d/haresources
			is_succed

		banner_middle "Heartbeat Reload"
			/etc/init.d/heartbeat reload
			is_succed
	else
		echo 
			color -red "Error : The file haresources does not exist"
		echo
	fi