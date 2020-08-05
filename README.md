# network-security-toy
A script to run as cronjob that monitors hosts connected to the network.

Developed for CIS-2150 Introduction to Linux by E.Berlin

This program uses common Linux utilities including ifconfig and nmap to find the MAC addresses of systems connected to the same subnet as the machine running the script. It logs those addresses and checks entries against the log, alerting the administrator of any never-before-seen MAC addresses.
