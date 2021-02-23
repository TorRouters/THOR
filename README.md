# THOR
The Hardware Onion Router

## What is this?
This is a script written by torrouters.com to flash routers and make them part of the tor network. Think about it as torbox but on routers instead of raspberry pi.

## Software Requirments for Windows
If you're on a Windows machine you will need the following installed:
* BASH Shell follow [this guide](https://itsfoss.com/install-bash-on-windows/), or
* Cygwin package from [this website](https://www.cygwin.com/).

## Hardware Requirments
For this to work you need a router with OpenWrt firmware. If you're unsure what does that mean we recommand grabbing one of our ready routers from our website torrouters.com

## How to Flash
1. Read this document
2. Connect the router via ethernet
3. The router should be at IP address 192.168.1.1 or DNS name openwrt
4. run `bash flash-router.sh`
5. wait until the flashing is over
6. new Wi-Fi will appear according to the settings
    * SSID is "Toriro-2.4ghz" and "Toriro-5.0ghz"
    * PSK is "TorRouters.com"
9. All settings can be changed via web at http://change.torrouters.com/

## Love
* This project is made possible thanks to 
  * Tor Project
  * OpenWrt Project
* We donate portion of our sales to these projects, consider supporting us.
* We are constantly working on this script & our routers to make them more secure, available, and support all platform. 
  * Please consider making donations at https://www.buymeacoffee.com/huskyLOVE
  * and help us spread the word about this exciting project via TorRouters.com 💜
