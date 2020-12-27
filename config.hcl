#Vault config file
1. after creating keys, insert location to config.hcl

$ vim /etc/vault/config.hcl

#config.hcl

storage "consul" {
        address ="127.0.0.1:8500"
        path ="vault/"
}
listener "tcp" {
        address = "0.0.0.0:443"
        tls_disable = 0
        tls_cert_file = "/etc/letsencrypt/live/<DOMAIN NAME>/fullchain.pem"
        tls_key_file = "/etc/letsencrypt/live/<DOMAIN NAME>/privkey.pem"
}
#server logs
log_level= "Debug"

ui = true
#########################

- `after adding the Debug for log entry, run below to view vault logs
$ sudo journalctl -f -b --no-pager -u vault

- To enable logs on Vault, you need 3rd party or someplace else to save the logs. To enable logs on a server :
$ vault audit enable file file_path=/var/log/vault_audit.log
$ sudo cat /var/log/vault_audit.log | jq

1. generate new key
$ ssh-keygen
$ cat /home/cloud_user/.ssh/id_rsa.pub

2. On the other Server where we gonna save the logs, add the pub key
$ sudo vim /home/cloud_user/.ssh/authorized_keys

3. enable vaule in sshd_config to yes
PubkeyAuthentication yes

4. restart sshd
$ sudo systemctl restart sshd

5. create a test file on the main server and sync it with the log server
sudo rsync -a <PATH to SYNC FILE> <USERNAME>@<DOMIN>:<PATH TO THE SYNC LOCATION>
ex :$ sudo rsync -a /home/cloud_user/testDir/test cloud_user@4afda5131e1c.mylabserver.com:/home/cloud_user/testDir/test
with rsync, it will do it once, we have to run the command everytime we change the file. To do it automatically, we use incor

6. we will download incron to monitor changes made to our log file and execute the rsync command.
Incron will allow us to create an on-change-trigger, which listens to any change made to a file and then executes a command. In our case, this will be the rsync command.

$ sudo apt install incron
$ vim /etc/incron.allow

root
:wq

7. $ sudo incrontab -e

# edit the file with the following structure. PATH: the file to montior, MASK:IN_MODIFY, means when it is changed
<PATH>            <MASK>            <COMMAND>
/var/log/vault_audit.log	IN_MODIFY		rsync -a /var/log/vault_audit.log cloud_user@4afda5131e1c.mylabserver.com:/home/cloud_user/testDir/vault_audit.log

and save.
Then list the table to verify
$ icrontab -l

8. Do some test from the server log
curl -H "X-Vault-Token: <TOKEN>" -X LIST https://<DOMAIN>/v1/secret

Then you will see the file created vault_audit.log

$ sudo cat vault_audit.log | jq

