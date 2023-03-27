#!/bin/bash

# User must run the script as root
if [[ $EUID -ne 0 ]]; then
	echo "Please run this script as root"
	exit 1
fi

distro=$(awk '/DISTRIB_ID=/' /etc/*-release | sed 's/DISTRIB_ID=//' | tr '[:upper:]' '[:lower:]')
thisServerIP=$(ip a s|sed -ne '/127.0.0.1/!{s/^[ \t]*inet[ \t]*\([0-9.]\+\)\/.*$/\1/p}')
networkInterfaceName=$(ip -o -4 route show to default | awk '{print $5}')

if [[ $distro != "ubuntu" ]]; then
	echo "distro not supported please use ubuntu"
	exit 1
fi

echo "Select one of the following options"
echo "   1) Server tunnel"
echo "   2) Remove the tunnel"
echo "   3) View the Forwarded IP"
echo "   3) exit"
read -r -p "Please select one [1-2-3-4]: " -e OPTION
case $OPTION in
1)
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p
    iptables -t nat -I PREROUTING -p tcp --dport 810 -j DNAT --to-destination "$thisServerIP"
    iptables -t nat -I PREROUTING -p udp --dport 810 -j DNAT --to-destination "$thisServerIP"
    iptables -t nat -I PREROUTING -p tcp --dport 4143 -j DNAT --to-destination "$thisServerIP"
    iptables -t nat -I PREROUTING -p udp --dport 4143 -j DNAT --to-destination "$thisServerIP"
    iptables -t nat -I PREROUTING -p tcp --dport 22 -j DNAT --to-destination "$thisServerIP"
    echo "Enter foreign server IP:"
    read -r foreignVPSIP
    iptables -t nat -A PREROUTING -j DNAT --to-destination "$foreignVPSIP"
    iptables -t nat -A POSTROUTING -j MASQUERADE -o "$networkInterfaceName"
    echo "tunnel is done Wait for other steps to take"
    apt update -y
    apt upgrade -y
    apt install iptables-persistent -y
    sudo netfilter-persistent save
    iptables-save > /etc/iptables/rules.v4
    ip6tables-save > /etc/iptables/rules.v6
    echo "Your tunnel finished"
    ;;
2)
sudo iptables -t nat -F
    echo "Your forward port was removed"
  ;;
  3)
iptables -t nat -L --line-numbers
  ;;
    4)
    exit
      ;;
esac
