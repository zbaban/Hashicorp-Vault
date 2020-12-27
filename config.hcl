#Vault config file - NOTES
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


#LAB STEP BY STEP

TO configure HashiCorp logging, and set up log file syncing with a remote server.

Solution

Log in to the server using the credentials provided:

ssh cloud_user@<PUBLIC_IP_ADDRESS>
Enable HashiCorp Vault Logs

In the Vault Server, retrieve the vault keys:
cat Keys
Unseal the vaults:
vault operator unseal
<UNSEAL_KEY_1>
vault operator unseal
<UNSEAL_KEY_2>
vault operator unseal
<UNSEAL_KEY_3>
Log in with the Initial Root Token:
vault login
<INITIAL_ROOT_TOKEN>
Enable logs:
vault audit enable file file_path=/var/log/vault_audit.log
Access the logs:
sudo cat /var/log/vault_audit.log | jq
Enable Key-Based SSH Authentication to a Backup Server

In the Vault Server, generate a new key:
ssh-keygen
Copy the new ssh-rsa key:
cat /home/cloud_user/.ssh/id_rsa.pub
In the Client Server, add the key to the authorized_keys file.
sudo vim /home/cloud_user/.ssh/authorized_keys
Save the file:
ESC
:wq
ENTER
Open the sshd_config file:
sudo vim /etc/ssh/sshd_config
Enable key-based authentication by uncommenting the following line:
PubkeyAuthentication yes
Save the file:
ESC
:wq
ENTER
Apply the changes:
sudo systemctl restart sshd
Use Rsync to Create Log Backups on the Vault Server

In the Vault Server, make a new directory:
mkdir /home/cloud_user/testDir/
Create a test file in the directory:
touch /home/cloud_user/testDir/test
Populate the file with generic data:
echo "THIS IS A TEST RUN!" > /home/cloud_user/testDir/test
Using rsync, sync the test file between the two servers:
rsync -a /home/cloud_user/testDir/test cloud_user@<CLIENT_PRIVATE_SERVER_IP>:/home/cloud_user
In the Vault Server, configure a trigger for file sync:
sudo apt install incron
Add the cloud_user to the incron.allow file:
sudo vim /etc/incron.allow
cloud_user
Save the file:
ESC
:wq
ENTER
Create a directory on the Client server to hold the logs:
mkdir /home/cloud_user/vault/
In the Vault Server, update the log permissions:
chmod +r /var/log/vault_audit.log
In the Vault Server, create a new job:
incrontab -e
In the new file, paste the following:
/var/log/vault_audit.log IN_MODIFY rsync -a /var/log/vault_audit.log cloud_user@<CLIENT_PRIVATE_SERVER_PRIVATE_IP>:/home/cloud_user/vault/
In the Vault Server, enable a kv secrets engine:
vault secrets enable -path=secret kv
In the Client server, run the following command to test the setup:

curl \
-H "Authorization: Bearer <INITIAL_ROOT_TOKEN>" \
-H "Content-Type: application/json" \
-X POST \
-d '{"bla":"bla"}' \
<VAULT_SERVER_DOMAIN_NAME>/v1/secret/test | jq
Note: You can find the Vault Server domain by running cat Domain.

Generate a GET request and check if the logs have been synced:

curl -H "X-Vault-Token: <INITIAL_ROOT_TOKEN>" -X LIST <VAULT_SERVER_DOMAIN_NAME>/v1/secret
