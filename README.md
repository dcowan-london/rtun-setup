# Reverse Tunnel Installer
An installer script for @snsinfu's Reverse Tunnel (RTUN) (https://github.com/snsinfu/reverse-tunnel).

There is currently no support for:
* Configuring per-IP/per FQDN forwarding for the server

Features to be added:
* Add forwards for an existing client on the server side.
* Forward via multiple servers (client side)
* Edit/delete forwards (server and client side)

## Install
Run the following command as root.

The script will:
* Run an  `apt update` and `apt upgrade`,
* Install all nessecary packages
* Clone reverse-tunnel from GitHub and build
* Prompt for configuartion - this will be different on the client and the server:
    * Server:
        * Will ask you to confirm the server IP (or offer you to set another IP - or an FQDN)
        * Prompt to set up clients
    * Client:
        * Will ask for the server IP
        * Will ask for the client key genarated by the server
        * Will prompt for ports to funnel
* Both server and client configuration will then ask if you would like to create a SystemD service.

### Server
This is the server connections will be made to.

`# bash <(curl -s https://raw.githubusercontent.com/dcowan-london/public-scripts/main/reverse-tunnel-server.sh)`
### Client
This is the server recieving connections.

`# bash <(curl -s https://raw.githubusercontent.com/dcowan-london/public-scripts/main/reverse-tunnel-client.sh)`

## Usage
After install, running the command again on the server will prompt to add new clients and running on the client will prompt to add more forwards.

If the SystemD service wasn't created during install, any time the script is run it will offer to create a SystemD service.