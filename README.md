# CloudGuard WAF in MicroK8S on Ubuntu 22.04 LTS VM

Consider Azure Shell bash session for following commands:

```shell

# verify Azure subsctiption
az account show --output table

# Azure environment - VM provisioning
. <(curl -s https://raw.githubusercontent.com/mkol5222/appsec-chart/main/setup-vm.sh)

# login to new VM
ssh -o StrictHostKeyChecking=no $MY_USERNAME@$IP_ADDRESS
# will continue IN PROVISIONED AZURE VM
```

On Azure VM:

```shell
# avoid need for sudo with microk8s
sudo usermod -a -G microk8s azureuser
newgrp microk8s

# setup user profile
. <(curl -s https://raw.githubusercontent.com/mkol5222/appsec-chart/main/setup-user.sh)

# ready to deploy certificate issuer with HTTP-01 solver - FOCUS ON EMAIL ADDRESS!!!
#
#
#
MY_EMAIL_ADDRESS="someone@somewhere.net" # REPLACE
helm install letsencrypt https://github.com/mkol5222/appsec-chart/releases/download/certs-0.1.0/certs-0.1.0.tgz --set letsencrypt.email=$MY_EMAIL_ADDRESS


# ready to deploy AppSec WAF - FOCUS ON INPUTS AND DNS RECORD!!!
#
#
#
APPSEC_TOKEN=cp-abc123... # REPLACE WITH REAL TOKEN from Infinity Portal
APPSEC_HOSTNAME=appsec1492.klaud.online # REPLACE

# prepare DNS
VMPUBLICIP=$(curl -s ip.iol.cz/ip/)
echo "Make sure DNS recort for $APPSEC_HOSTNAME points to $VMPUBLICIP"
# verify
sudo resolvectl flush-caches 
dig +short $APPSEC_HOSTNAME

helm install appsec https://github.com/mkol5222/appsec-chart/releases/download/appsec-0.1.0/appsec-0.1.0.tgz --set cptoken=$APPSEC_TOKEN --set hostname=$APPSEC_HOSTNAME

# monitor appsec and http-01 solver
k get po --watch

```

Cleanup:

```shell
# when want to remove VM later
az vm delete --resource-group $MY_RESOURCE_GROUP_NAME --name $MY_VM_NAME --yes
az group delete --name $MY_RESOURCE_GROUP_NAME --yes
```