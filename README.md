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

# bring charts
git clone https://github.com/mkol5222/appsec-chart

# ready to deploy certificate issuer with HTTP-01 solver
MY_EMAIL_ADDRESS="someone@somewhere.net" # REPLACE
helm install letsencrypt ./appsec-chart/charts/certs/ --set letsencrypt.email=$MY_EMAIL_ADDRESS

APPSEC_TOKEN=cp-abc123... # REPLACE WITH REAL TOKEN from Infinity Portal
APPSEC_HOSTNAME=appsec1492.klaud.online # REPLACE

# prepare DNS
VMPUBLICIP=$(curl -s ip.iol.cz/ip/)
echo "Make sure DNS recort for $APPSEC_HOSTNAME points to $VMPUBLICIP"
# verify
sudo resolvectl flush-caches 
dig +short $APPSEC_HOSTNAME

helm install appsec ./appsec-chart/charts/appsec/ --set cptoken=$APPSEC_TOKEN --set hostname=$APPSEC_HOSTNAME

# monitor appsec and http-01 solver
k get po --watch

```

Cleanup:

```shell
# when want to remove VM later
az vm delete --resource-group $MY_RESOURCE_GROUP_NAME --name $MY_VM_NAME --yes
az group delete --name $MY_RESOURCE_GROUP_NAME --yes
```