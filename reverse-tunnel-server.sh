#!/bin/bash
# Reverse tunnel server setup
# One-stop script to install and set up https://github.com/snsinfu/reverse-tunnel
# Copyright (c) 2021 Dovi Cowan (Fully Networking UK) - dovi@fullynetworking.co.uk
# MIT License

# Run "# bash <(curl -s https://raw.githubusercontent.com/dcowan-london/public-scripts/main/reverse-tunnel-server.sh)"
# on a new Debian 10 server with a public IP address to set up

cd

echo "REVERSE TUNNEL SERVER SETUP"
echo "One-stop script to install and set up https://github.com/snsinfu/reverse-tunnel"
echo ""
echo "Reverse Tunnel Copyright (c) 2018, 2021 snsinfu MIT License"
echo "Setup script Copyright (c) 2021 Dovi Cowan MIT License"
echo ""
echo "Permission is hereby granted, free of charge, to any person obtaining a copy"
echo "of this software and associated documentation files (the \"Software\"), to deal"
echo "in the Software without restriction, including without limitation the rights"
echo "to use, copy, modify, merge, publish, distribute, sublicense, and/or sell"
echo "copies of the Software, and to permit persons to whom the Software is"
echo "furnished to do so, subject to the following conditions:"
echo ""
echo "The above copyright notice and this permission notice shall be included in all"
echo "copies or substantial portions of the Software."
echo ""
echo "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR"
echo "IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,"
echo "FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE"
echo "AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER"
echo "LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,"
echo "OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE"
echo "SOFTWARE."
echo

if [ ! -d "reverse-tunnel/" ]; then

# Get prerequisites
apt update
apt upgrade -y
apt install git build-essential golang -y

# Get reverse-tunnel
git clone https://github.com/snsinfu/reverse-tunnel
cd reverse-tunnel

# Build reverse-tunnel
make

# Configure server
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

# Create systemd service
read -N 1 -p "Create service? [y/n] " SERVICE

if [[ $SERVICE == "y" ]]; then
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

    if [[ ${REPLY} == "y" ]]; then
        systemctl start rtun-server
        echo "Started server"
    fi
fi

fi

cd
cd reverse-tunnel

# Add client
ADD_AGENT=1

while [[ $ADD_AGENT -eq 1 ]]; do

    read -N 1 -p "Add client? [y/n] " CREATE && echo
    if [[ $CREATE == "y" ]]; then
        # Genarate client key
        KEY=$(openssl rand -hex 32)

        echo "Enter allowed ports for first client. Use format 'port/protocol', eg '80/tcp' (without the quotations). Separate ports with a comma and space, eg '80/tcp, 443/tcp'."
        read -p "Ports: " PORTS

        tee -a rtun-server.yml >/dev/null <<EOF
    - auth_key: $(echo $KEY)
      ports: [$(echo $PORTS)]

EOF

        echo -e "\033[1mClient Key: $KEY\033[0m"
        echo
        
    elif [[ $CREATE == "n" ]]; then
        ADD_AGENT=0
    else
        echo "You must enter y or n!"
    fi
done;

if [[ ! $(systemctl list-units --all -t service --full --no-legend "rtun-server.service" | cut -f1 -d' ') ]]; then
    # Create systemd service
    read -N 1 -p "Create service? [y/n] " SERVICE

    if [[ $SERVICE == "y" ]]; then
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

        if [[ ${REPLY} == "y" ]]; then
            systemctl start rtun-server
            echo "Started server"
        fi
    fi
else
    systemctl restart rtun-server
fi

echo "Done. Run \"./rtun-server\" or \"systemctl start rtun-server\" to start the server."