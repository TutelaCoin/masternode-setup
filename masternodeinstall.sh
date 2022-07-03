#!/bin/bash

PORT=17178
RPCPORT=17179
CONF_DIR=~/.tutela
COINZIP='https://github.com/TutelaCoin/TUTL/releases/download/v1.1.1/tutela-linux.zip'

cd ~
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

function configure_systemd {
  cat << EOF > /etc/systemd/system/tutela.service
[Unit]
Description=Tutela Service
After=network.target
[Service]
User=root
Group=root
Type=forking
ExecStart=/usr/local/bin/tutelad
ExecStop=-/usr/local/bin/tutela-cli stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  sleep 2
  systemctl enable tutela.service
  systemctl start tutela.service
}

echo ""
echo ""
DOSETUP="y"

if [ $DOSETUP = "y" ]  
then
  sudo apt-get update
  sudo apt install git zip unzip curl -y
  
  cd /usr/local/bin/
  wget $COINZIP
  unzip *.zip
  chmod +x tutela*
  rm tutela-qt tutela-tx *.zip
  
  mkdir -p $CONF_DIR
  cd $CONF_DIR
  wget https://snapshot.tutela.io/
  unzip tutl.zip
  rm tutl.zip

fi

 IP=$(curl -s4 api.ipify.org)
 echo ""
 echo "Configure your masternodes now!"
 echo "Detecting IP address:$IP"
 echo ""
 echo "Enter masternode private key"
 read PRIVKEY
 
  echo "rpcuser=user"`shuf -i 100000-10000000 -n 1` >> tutela.conf_TEMP
  echo "rpcpassword=pass"`shuf -i 100000-10000000 -n 1` >> tutela.conf_TEMP
  echo "rpcallowip=127.0.0.1" >> tutela.conf_TEMP
  echo "rpcport=$RPCPORT" >> tutela.conf_TEMP
  echo "listen=1" >> tutela.conf_TEMP
  echo "server=1" >> tutela.conf_TEMP
  echo "daemon=1" >> tutela.conf_TEMP
  echo "maxconnections=250" >> tutela.conf_TEMP
  echo "masternode=1" >> tutela.conf_TEMP
  echo "dbcache=20" >> tutela.conf_TEMP
  echo "maxorphantx=5" >> tutela.conf_TEMP
  echo "" >> tutela.conf_TEMP
  echo "port=$PORT" >> tutela.conf_TEMP
  echo "externalip=$IP:$PORT" >> tutela.conf_TEMP
  echo "masternodeaddr=$IP:$PORT" >> tutela.conf_TEMP
  echo "masternodeprivkey=$PRIVKEY" >> tutela.conf_TEMP
  mv tutela.conf_TEMP tutela.conf
  cd
  echo ""
  echo -e "Your ip is ${GREEN}$IP:$PORT${NC}"

	## Config Systemctl
	configure_systemd
  
echo ""
echo "Commands:"
echo -e "Start Tutela Service: ${GREEN}systemctl start tutela${NC}"
echo -e "Check Tutela Status Service: ${GREEN}systemctl status tutela${NC}"
echo -e "Stop Tutela Service: ${GREEN}systemctl stop tutela${NC}"
echo -e "Check Masternode Status: ${GREEN}tutela-cli getmasternodestatus${NC}"

echo ""
echo -e "${GREEN}Tutela Masternode Installation Done${NC}"
exec bash
exit
