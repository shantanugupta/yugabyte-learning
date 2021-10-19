#! /bin/bash 

#"3.109.50.121"   # 10.0.0.66
#"3.6.95.250"     # 10.0.1.155
#"3.6.191.27"     # 10.0.1.108

export ADMIN_USER="centos" \
export AZ1_NODES="3.109.50.121"
export AZ2_NODES="3.6.95.250"
export AZ3_NODES="3.6.191.27"
export ALL_NODES="$AZ1_NODES $AZ2_NODES $AZ3_NODES"
export PEM="./yb/yugabyte.pem"

for ip in $ALL_NODES; do  \
   echo "**************************** $ADMIN_USER@$ip ****************************";
  
   echo "---------- Remove existing yb folder -----------";
   ssh -i $PEM $ADMIN_USER@$ip rm /home/centos/yb -dfr;

   echo "---------- Create scripts folder -----------";
   ssh -i $PEM $ADMIN_USER@$ip mkdir -p /home/centos/yb;
  
   echo "---------- PEM file copy -----------";
   sudo scp -i $PEM $PEM $ADMIN_USER@$ip:/home/centos/.ssh/;

   echo "---------- PEM file permissions CHMOD -----------";
   ssh -i $PEM $ADMIN_USER@$ip chmod 400 /home/centos/.ssh/yugabyte.pem;

   echo "---------- COPY required files to yb server -----------";
   sudo scp -i $PEM ./yb/* $ADMIN_USER@$ip:~/yb/;

   echo "----------Install required packages on $ip for debugging -----------";
   ssh -i $PEM $ADMIN_USER@$ip sudo yum install bind-utils telnet wget java-1.8.0-openjdk-src.x86_64 -y;   

   echo "---------- Load config file to session everytime you login -----------";
   command='
   if ! grep -R -q ". /home/centos/yb/configfile.bash" /home/centos/.bashrc;
   then
      echo ". /home/centos/yb/configfile.bash" >> /home/centos/.bashrc;
   fi;

   chmod 777 /home/centos/yb/configfile.bash;
   . /home/centos/yb/configfile.bash;
   '
   ssh -i $PEM $ADMIN_USER@$ip $command;

   # To remove warning: LC_CTYPE: cannot change locale (UTF-8): No such file or directory
   sudo scp -i $PEM ~/yb/environment $ADMIN_USER@$ip:~/yb/;
   ssh -i $PEM $ADMIN_USER@$ip sudo cp -f ~/yb/environment /etc/;
   
   echo "---------- Create cron job for CPU data capture -----------";
   ssh -i $PEM $ADMIN_USER@$ip crontab -l | { echo "@reboot /bin/bash /home/centos/yb/cpu.bash"; } | crontab -
   
   echo "---------- Verify cron job for CPU data capture -----------";
   ssh -i $PEM $ADMIN_USER@$ip  crontab -l
   #wget https://raw.githubusercontent.com/YugaByte/yugabyte-db/master/sample/northwind_ddl.sql
   #wget https://raw.githubusercontent.com/YugaByte/yugabyte-db/master/sample/northwind_data.sql
   #wget https://github.com/yugabyte/yb-sample-apps/releases/download/1.3.9/yb-sample-apps.jar

done

for ip in $ALL_NODES; do  \
   echo "---------- Create cron job for CPU data capture $ip-----------";
   ssh -i $PEM $ADMIN_USER@$ip crontab -l | { echo "@reboot /bin/bash /home/centos/yb/cpu.bash"; } | crontab - | crontab -l
done


pem=/Users/shangupta/Documents/git/aws-cfm/yb/yugabyte.pem
copyFrom=/home/centos/yb/metrics/*
ips="3.109.50.121 3.6.95.250 3.7.148.173 3.6.191.27" 
for ip in $ips;do
   saveAt=/Users/shangupta/Documents/git/aws-cfm/metrics/$ip
   mkdir -p $saveAt
   echo $saveAt
   scp -i $pem centos@$ip:$copyFrom $saveAt
done

