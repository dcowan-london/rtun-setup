#!/bin/bash
# Reverse tunnel server setup
# One-stop script to install and set up https://github.com/snsinfu/reverse-tunnel
# Copyright (c) 2021 Dovi Cowan (Fully Networking UK) - dovi@fullynetworking.co.uk
# MIT License

cd

apt update
apt upgrade -y
apt install git build-essential golang -y

git clone https://github.com/snsinfu/reverse-tunnel
cd reverse-tunnel

make

SERVER_IP=$(hostname -I | awk '{print $1}')

IP_CORRECT=0

while [[ $IP_CORRECT -ne 1 ]]; do
    read -n 1 -p "Please confirm server IP address [$SERVER_IP] [y/n] "
    echo

    if [[ ${REPLY} == "n" ]]; then
        read -p "Enter correct server IP: " SERVER_IP
    elif [[ ${REPLY} == "y" ]]; then
        IP_CORRECT=1
    else
        echo "You must enter y or n!"
    fi
done;

tee rtun-server.yml >/dev/null <<EOF
control_address: $(echo $SERVER_IP):10000

agents:
EOF

ADD_AGENT=1

while [[ $ADD_AGENT -eq 1 ]] do

    read -N 1 -p "Add client? [y/n] " CREATE && echo
    if [[ $CREATE == "y" ]] then
        KEY=$(openssl rand -hex 32)
        echo "Enter allowed ports for first client. Use format 'port/protocol', eg '80/tcp' (without the quotations). Separate ports with a comma and space, eg '80/tcp, 443/tcp'."
        read -p "Ports: " PORTS

        tee -a rtun-server.yml >/dev/null <<EOF
    - auth_key: $(echo $KEY)
      ports: [$(echo $PORTS)]

EOF

        echo -e "\033[1mClient Key: $KEY\033[0m"
        echo
        
    elif [[ $CREATE == "n" ]] then
        ADD_AGENT=0
    else
        echo "You must enter y or n!"
    fi
done;

read -N 1 -p "Create service? [y/n] " SERVICE

if [[ $SERVICE == "y" ]] then
    tee /etc/systemd/system/rtun-server.service >/dev/null <<EOF
[Unit]
Description=RTUN

[Service]
User=root
WorkingDirectory=/root/reverse-tunnel
ExecStart=/root/reverse-tunnel/rtun-server
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable rtun-server

    read -N 1 -p "Start service now? [y/n]"
    echo

    if [[ ${REPLY} == "y" ]] then
        systemctl start rtun-server
        echo "Started server"
    fi
fi

echo "Done. Run \"./rtun-server\" to start the server."