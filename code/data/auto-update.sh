#!/bin/sh

ping -c1 -W2 1.1.1.1 || { echo "[-] - no internet!" ; exit 1; }
opkg update && opkg install tor || { echo "[-] - coudln't install packages!" ; exit 1; }