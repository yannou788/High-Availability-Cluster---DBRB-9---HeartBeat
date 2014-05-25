HA Cluster DRBD9 HeartBeat
==========================

After downloading these scripts, you will need to run this in the linux console. 

*In the best case do it on a new installation with two disk*

First Disk : System

Second Disk : For the Cluster

**On the primary Server**
  
  chmod +x Cluster-installation.php
  
  ./Cluster-installation.php --primary
  
  
  chmod +x Cluster-php-installation.php
  
  ./Cluster-php-installation.php --primary
  
  
  chmod +x Mysql-installation.php 
  ./Mysql-installation.php --primary
  

**On the other Servers**

  chmod +x Cluster-installation.php
  
  ./Cluster-installation.php
  
  
  chmod +x Cluster-php-installation.php
  
  ./Cluster-php-installation.php
  
  
  chmod +x Mysql-installation.php 
  ./Mysql-installation.php
