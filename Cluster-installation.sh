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
	color -green "#-----------------------------Cluster Installation-----------------------------#"
	color -green "################################################################################"
echo


# The Number of server
# The Hostname
# The Address
#-----------------------------------------------------------------------------
	nbrserver=0;
	while (( $nbrserver < 2 ))
	do
		echo -n "Number of Server : "
		read nbrserver
	done

	banner_middle "Basics Informations"

	for (( i=0; i < $nbrserver; i++ ));
	do
		while [ !  ${Tabname[$i]} ] || [ ! ${Tabaddr[$i]} ];
		do
			echo -n "1) Server["$i"] Name : "
			read Tabname[$i]
			echo -n "2) Server["$i"] Address : "
			read Tabaddr[$i]
			echo

		done
	done
	while [[ ! $drbdfilename ]]; do
		echo -n -e "\nChoose your drbd res file name {Example : drbd}: "
		read drbdfilename
	done
	while [[ ! $resourcename ]]; do
		echo -n -e "\nChoose your resource name {Example : r0}: "
		read resourcename
	done
	while [[ ! $diskressource ]]; do
		echo -n -e "\nChoose your disk {Example : sdb7}: "
		read diskressource
	done
	while [[ ! $drbdinterface ]]; do
		echo -n -e "\nChoose your interface {Example : eth0} : "
        read drbdinterface
	done
	while [[ ! $drbdport ]]; do
		echo -n -e "\nChoose your first port {Example : 7000} : "
        read drbdport
	done
	while [[ ! $bip ]]; do
		echo -n 'Balancing IP : '
		read  bip
	done
	while [[ ! $passphrase ]]; do
		echo -n -e 'Passphrase [Between Server]: '
		read passphrase
	done


# Writing servers informations in /etc/hosts
#-----------------------------------------------------------------------------
	for (( i=0; i < $nbrserver; i++ ));
	do
		echo ${Tabaddr[$i]} ${Tabname[$i]}>> /etc/hosts
	done
	is_succed

# Creation of the sdb disk
#-----------------------------------------------------------------------------

	banner_middle "Disk Installation"
	fdisk /dev/sdb
	is_succed

# Installation of the essential tools
# Make - Flex - GCC
#-----------------------------------------------------------------------------

	banner_middle "Essential Tools" 
	apt-get install make flex gcc
	is_succed

# Installation of HeartBeat
# Heartbeat is a daemon that provides cluster infrastructure
#-----------------------------------------------------------------------------

	banner_middle "HeartBeat Installation"
	apt-get install heartbeat
	is_succed

# Installation of the DRBD8-Utils
# DRBD is a replicated storage system for the Linux
#-----------------------------------------------------------------------------

	banner_middle "DRBD8 Utils Installation"
	apt-get install drbd8-utils
	is_succed

# Installation of GIT
#-----------------------------------------------------------------------------

	banner_middle "Git Installation"
	apt-get install git
	is_succed

# Installation and Configuration of the rc version of DRBD9
# You can add more than one node
#-----------------------------------------------------------------------------

	banner_middle "DRBD9 Installation"
	cd ~
	mkdir drbd9 	#Creation of a drbd9 dir
	cd drbd9 
		wget http://oss.linbit.com/drbd/drbd-utils-8.9.0rc1.tar.gz 	#Download the drbd-utils-8.9.0rc1
		is_succed
		tar xzvf drbd-utils-8.9.0rc1.tar.gz
		is_succed
		cd drbd-utils-8.9.0rc1
			./configure --prefix=/usr --localstatedir=/var --sysconfdir=/etc --with-km --with-udev
			sleep 5
			make
			is_succed
			sleep 5
			make install
			is_succed
			cd ..
		wget http://oss.linbit.com/drbd/9.0/drbd-9.0.0pre9.tar.gz
		is_succed
		sleep 2
		tar xzvf drbd-9.0.0pre9.tar.gz
		is_succed
		cd drbd-9.0.0pre9
			make
			is_succed
			sleep 2
			make install 
			is_succed
			sleep 2
	cd ~
	rm -rf drbd9
	modprobe drbd
	is_succed

	banner_middle "DRBD CONFIGURATION"

	touch /etc/drbd.d/$drbdfilename.res
	echo -e 'resource '$resourcename' {\n	device /dev/drbd0;\n	disk /dev/'$diskressource';\n	meta-disk internal;' >> /etc/drbd.d/$drbdfilename.res 
	is_succed

	HOST="hosts"

	for (( i=0; i < $nbrserver; i++ ));
        do
                echo -e '	on '${Tabname[$i]}' {\n		address '${Tabaddr[$i]}':'$(($drbdport+$i))';\n		node-id '$i';\n	}' >> /etc/drbd.d/$drbdfilename.res
		HOST+=" "${Tabname[$i]}
	done
	is_succed

	echo -e '	connection-mesh {\n		'${HOST}';\n		net{\n			use-rle no;\n		}\n	}\n}' >> /etc/drbd.d/$drbdfilename.res
	is_succed

	drbdadm create-md $resourcename
	is_succed
	drbdadm up $resourcename
	is_succed

	if [ $primary == 1 ]
	then
		drbdadm -- --overwrite-data-of-peer primary $resourcename
		is_succed
		mkfs.ext4 /dev/drbd0
		is_succed
	fi

# Configuration of HeartBeat
#-----------------------------------------------------------------------------
	banner_middle "HeartBeat Configuration"

	touch /etc/ha.d/ha.cf
	echo -e "\nbcast "$drbdinterface'\nwarntime 4\ndeadtime 5\ninitdead 15\nkeepalive 2\n\nauto_failback off\n\n' >> /etc/ha.d/ha.cf
	is_succed

	for (( i=0; i < $nbrserver; i++ ));
        do
                echo -e 'node '${Tabname[$i]}'\n' >> /etc/ha.d/ha.cf
        done
   	is_succed

	touch /etc/ha.d/haresources
	echo ${Tabname[0]}' IPaddr::'$bip'/24/'$drbdinterface' drbddisk::r0 Filesystem::/dev/drbd0::/mnt::ext4' >>  /etc/ha.d/haresources
	is_succed

	touch /etc/ha.d/authkeys
	echo -e 'auth 3\n3 md5 '$passphrase >> /etc/ha.d/authkeys
	is_succed

	chmod 600 /etc/ha.d/authkeys
	is_succed

	/etc/init.d/heartbeat start
	is_succed

