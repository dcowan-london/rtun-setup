#!/bin/bash
# Reverse tunnel client setup
# One-stop script to install and set up https://github.com/snsinfu/reverse-tunnel
# Copyright (c) 2021 Dovi Cowan (Fully Networking UK) - dovi@fullynetworking.co.uk
# MIT License

# Run "# bash <(curl -s https://raw.githubusercontent.com/dcowan-london/public-scripts/main/reverse-tunnel-client.sh)"
# on a new Debian 10 server with a public IP address to set up

cd

echo "REVERSE TUNNEL CLIENT SETUP"
echo "One-stop script to install and set up https://github.com/snsinfu/reverse-tunnel"
echo ""
echo "Reverse Tunnel Copyright (c) 2018, 2021 snsinfu MIT License"
echo "Setup script Copyright (c) 2021 Dovi Cowan MIT License"
echo ""
echo "Permission is hereby granted, free of charge, to any person obtaining a copy"
echo "of this software and associated documentation files (the "Software"), to deal"
echo "in the Software without restriction, including without limitation the rights"
echo "to use, copy, modify, merge, publish, distribute, sublicense, and/or sell"
echo "copies of the Software, and to permit persons to whom the Software is"
echo "furnished to do so, subject to the following conditions:"
echo ""
echo "The above copyright notice and this permission notice shall be included in all"
echo "copies or substantial portions of the Software."
echo ""
echo "THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR"
echo "IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,"
echo "FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE"
echo "AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER"
echo "LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,"
echo "OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE"
echo "SOFTWARE."
echo

apt update
apt upgrade -y
apt install git build-essential golang -y

git clone https://github.com/snsinfu/reverse-tunnel
cd reverse-tunnel

make

SERVER_IP=0

IP_CORRECT=0

read -p "Enter server IP address/FQDN: " SERVER_IP

while [[ $IP_CORRECT -ne 1 ]]; do
    read -n 1 -p "Please confirm server IP address [$SERVER_IP] [y/n] "
    echo

    if [[ ${REPLY} == "n" ]]; then
        read -p "Enter correct server IP address/FQDN: " SERVER_IP
    elif [[ ${REPLY} == "y" ]]; then
        IP_CORRECT=1
    else
        echo "You must enter y or n!"
    fi
done;

read -p "Paste the Client Key genarated by the server: " KEY

tee rtun.yml >/dev/null <<EOF
gateway_url: ws://$(echo $SERVER_IP):10000

auth_key: $(echo $KEY)

forwards:
EOF

ADD_FORWARD=1

while [[ $ADD_FORWARD -eq 1 ]]; do

    read -N 1 -p "Add forward? [y/n] " CREATE && echo
    if [[ $CREATE == "y" ]]; then
        echo
        echo "You will be asked below to enter the server port and the local port."
        echo "The server port is the port on the server connections will be made to"
        echo "and the local port is the port that connection will be forwarded to."
        echo "The local port does not necessarily have to be on the local machine."
        echo
        read -p "Enter server port (in format port/protocol, eg 80/tcp). One port only: " SERVER_PORT
        read -p "Enter client port (in format IP:port, eg 127.0.0.1:80): " CLIENT_PORT
        echo

        tee -a rtun.yml >/dev/null <<EOF
    - port: $(echo $SERVER_PORT)
      destination: $(echo $CLIENT_PORT)

EOF
        
    elif [[ $CREATE == "n" ]]; then
        ADD_FORWARD=0
    else
        echo "You must enter y or n!"
    fi
done;

read -N 1 -p "Create service? [y/n] " SERVICE

if [[ $SERVICE == "y" ]]; then
    tee /etc/systemd/system/rtun-client.service >/dev/null <<EOF
[Unit]
Description=RTUN Client

[Service]
User=root
WorkingDirectory=/root/reverse-tunnel
ExecStart=/root/reverse-tunnel/rtun
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable rtun-client

    read -N 1 -p "Start service now? [y/n]"
    echo

    if [[ ${REPLY} == "y" ]]; then
        systemctl start rtun-client
        echo "Started server"
    fi
fi

echo "Done. Run \"./rtun-client\" to start the server."