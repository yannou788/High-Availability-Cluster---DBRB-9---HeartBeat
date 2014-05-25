HA Cluster DRBD9 HeartBeat
==========================

After downloading these scripts, you will need to run this in the linux console. 

In the best case do it on a new installation with two hard drives
-----------------------------------------------------------------

First Hard Drive : Linux System {Ubuntu}

Second Hard Drive : For the Cluster

**On the primary Server**
=========================

  - chmod +x Cluster-installation.sh
  
  - ./Cluster-installation.sh --primary
  
---
  
  - chmod +x Cluster-php-installation.sh
  
  - ./Cluster-php-installation.sh --primary
  
---  

  - chmod +x Mysql-installation.sh 
  - ./Mysql-installation.sh --primary
  

**On the other Servers**
========================

  - chmod +x Cluster-installation.sh
  
  - ./Cluster-installation.sh
  
---
  
  - chmod +x Cluster-php-installation.sh
  
  - ./Cluster-php-installation.sh

---
  
  - chmod +x Mysql-installation.sh 
  - ./Mysql-installation.sh
