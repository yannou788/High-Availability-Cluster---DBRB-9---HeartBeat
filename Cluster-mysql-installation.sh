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
		color -green "#-------------------------Cluster : Mysql Installation-------------------------#"
		color -green "################################################################################"
	echo

# Installation of Apache2 and PHP5
#-----------------------------------------------------------------------------

	if [ -f /etc/ha.d/haresources ]
	then

		banner_middle "Mysql Installation"
		apt-get install mysql-server
			is_succed

		banner_middle "Remove Mysql start launch"
		update-rc.d -f mysql remove
			is_succed

		banner_middle "Stop the Mysql service"
		/etc/init.d/mysql stop
			is_succed

		if [[ $primary == 1 ]]; then
			banner_middle "Move /var/lib/mysql to /mnt/"
			mv /var/lib/mysql/ /mnt/
			is_succed

			banner_middle "Move /etc/mysql/debian.cnf to /mnt/mysql/"
			mv /etc/mysql/debian.cnf /mnt/mysql/
			is_succed

		else
			banner_middle "Remove /var/lib/mysql/"
			rm -rvf /var/lib/mysql/
			is_succed

			banner_middle "Remove /etc/mysql/debian.cnf"
			rm -vf /etc/mysql/debian.cnf
			is_succed

			banner_middle "Creation of symlink /etc/mysql/ to /mnt/mysql/debian.cnf"
			ln -s /mnt/mysql/debian.cnf /etc/mysql/
			is_succed
		fi

		banner_middle "Update the /etc/apparmor.d/usr.sbin.mysqld"
		sed -i 's/^  \/var\/lib\/mysql\/ r,*$/\/mnt\/mysql\/ r,/' /etc/apparmor.d/usr.sbin.mysqld
			is_succed
		sed -i 's/^  \/var\/lib\/mysql\/\*\* rwk,*$/\/mnt\/mysql\/\*\* rwk,/' /etc/apparmor.d/usr.sbin.mysqld
			is_succed

		banner_middle "Update the /etc/mysql/my.cnf"
		sed -i 's/^datadir.*/datadir=\/mnt\/mysql/' /etc/mysql/my.cnf
			is_succed

		banner_middle "Update the haresources file"
		nha=$(sed -e 's/.*/& mysql/' /etc/ha.d/haresources)
		echo $nha > /etc/ha.d/haresources
			is_succed

		banner_middle "Apparmor Reload"
		/etc/init.d/apparmor reload
			is_succed

		if [[ $primary == 1 ]]; then
				banner_middle "Mysql Start"
				/etc/init.d/mysql start
				is_succed
		fi

		banner_middle "Heartbeat Reload"
		/etc/init.d/heartbeat reload
			is_succed

	else
		echo 
			color -red "Error : The file haresources does not exist"
		echo
	fi

