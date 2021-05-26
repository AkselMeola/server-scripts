# ftpup - a dead simple ftp server

A simple ftp server to quickly allow ftp connections to a pointed directory. 

## Requirements

- Root privileges to open connection on port 21
- Python (either 2 or 3)
- pyftpdlib (according to the version of your python) (https://pypi.org/project/pyftpdlib/)


## Install

Download the script and allow execution right

```
sudo curl https://raw.githubusercontent.com/AkselMeola/server-scripts/main/ftpup/ftpup > /usr/local/bin/ftpup
sudo chmod +x /usr/local/bin/ftpup
```

## Running server

Run the server with a document root directory
```
sudo ftpup /path/to/be/your/ftp/root
```

You should now have the FTP server running, and the ftp root directory is the directory you specified. 

## Connecting to server

Server runs on an anonymous account with write privileges. 
So to connect to a server point your ftp client to localhost at port 21

```
Host: 127.0.0.1
Port: 21
Username: anonymous
Password: something@random.com
```

## Connecting from outside

To connect to a server from outside network you need to enable the connections to the port 21 from firewall. 

**Simple option**

If you want to connect to the server from outside then you need to temporarily disable the firewall. 

It should go something like this (depending on your linux):
Fedora: `systemctl stop firewalld`

**A good option**

TODO: Write example for iptables rules
