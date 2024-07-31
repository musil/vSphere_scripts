# vSphere scripts collection

## Description

This repository contains scripts for managing vSphere environment.

## Requirements

* You need to have PowerShell installed on your machine.
* You need to have PowerCLI installed on your machine to run these scripts.
* You need to have access to vCenter or ESXi host.
* You need to have permissions to run these scripts.
* You need to be connected to vCenter or ESXi host.

## ESXi hosts

### ESXi Description

[ESXi](./ESXi) folder contains scripts for managing ESXi hosts.

* List ESXi DNS servers
* start/stop SSH service on ESXi

## vCenter

### vCenter Description

[vCenter](./vCenter) folder contains scripts for managing vCenter.

* Alarm SSH enabled on ESXi
* Alarm ESXi shell enabled
* Get full vCenter version, release date etc.

## Virtual Machines

### VM Description

[VM](./VM) folder contains scripts for managing virtual machines.

* VM boot delay to 7sec.
* Find VM with specific MAC address

## Powershell & PowerCLI environment

* Set Execution policy
* Install PowerCLI
