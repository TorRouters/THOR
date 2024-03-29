# THOR
Tor Hardware Onion Router

## What is this?
This is a script written by [torrouters.com](https://torrouters.com/) to flash openwrt compatible routers and make them part of the Tor network. 
Think about it as [torbox](https://torbox.ch/) but on openWrt routers instead of raspberry pi.

## Software Requirments for Windows
If you're on a Windows machine you will need the following installed:
* BASH Shell follow [this guide](https://itsfoss.com/install-bash-on-windows/), or
* Cygwin package from [this website](https://www.cygwin.com/).
* if you're on other operating system you probably have `bash` already

## Hardware Requirments
For this to work you need a router with OpenWrt firmware. If you're unsure what does that mean do some research about OpenWrt or grab one of our preflashed routers from website: [torrouters.com](https://torrouters.com/#details)

## How to Flash
1. Read this document
2. Connect the router via ethernet
3. The router should be at IP address `192.168.1.1` or DNS name `openwrt`
4. Double click on `flash-Tor.cmd`
5. Wait until the flashing is over
6. New Wi-Fi will appear according to the settings
    * SSID is "Toriro-2.4ghz" and "Toriro-5.0ghz"
    * PSK is "TorRouters.com"
9. All settings can be changed via web at http://change.torrouters.com/

![screen](https://github.com/TorRouters/THOR/blob/main/docs/screencast.gif)

## Testing & Troublshoot
* Sometimes Tor can be down, check at: https://status.torproject.org/
* Check if your connection is tunneled already: https://check.torproject.org/
* Check access to .onion website: 
   * Duckduckgo - https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion
   * CIA - http://ciadotgov4sjwlzihbbgxnqg3xiyrg7so2r2o3lt5wz5ypk4sxyjstad.onion/
   * Facebook - https://facebookwkhpilnemxj7asaniu7vnjjbiltxjqhye3mhbshg7kx5tfyd.onion
   * The BBC - https://www.bbcnewsd73hkzno2ini43t4gblxvycyac5aw4gnv7t2rccijh7745uqd.onion
   * more at dark.fail - https://dark.fail/
* Search in the [Issues](https://github.com/TorRouters/THOR/issues) board

## Love & Support
* This project is made possible thanks to 
  * [Tor Project](https://www.torproject.org/)
  * [OpenWrt Project](https://openwrt.org/)
* We donate portion of our sales to these projects, consider supporting us.
* We are constantly working on this script & our routers to make them more secure, available, and support all platform. 
  * Please consider making donations at https://www.buymeacoffee.com/huskyLOVE
  * and help us spread the word about this exciting project via https://TorRouters.com 💜
  * Or buy our routers on the same website: https://torRouters.com
