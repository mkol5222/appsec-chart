# CloudGuard WAF in MicroK8S on Ubuntu 22.04 LTS VM

Consider Azure Shell bash session for following commands:

```shell

# verify current Azure subsctiption (it should be ready in  Azure Shell)
az account show --output table

# Azure environment - Ubuntu LTS VM with public IP provisioning
. <(curl -s https://raw.githubusercontent.com/mkol5222/appsec-chart/main/setup-vm.sh)

# login to new VM
sshvm
# will continue IN PROVISIONED AZURE VM
```

Lets continue on Azure VM:

```shell
# IN AZURE VM (after sshvm) 

# ready to deploy AppSec WAF - FOCUS ON INPUTS AND DNS RECORD!!!
#
#
#
MY_EMAIL_ADDRESS="someone@somewhere.net" # REPLACE
APPSEC_TOKEN=cp-abc123... # REPLACE WITH REAL TOKEN from Infinity Portal
APPSEC_HOSTNAME=appsec1492.klaud.online # REPLACE

# prepare DNS
VMPUBLICIP=$(curl -s ip.iol.cz/ip/)
echo "Make sure DNS recort for $APPSEC_HOSTNAME points to $VMPUBLICIP"
# verify
sudo resolvectl flush-caches 
dig +short $APPSEC_HOSTNAME

helm install appsec https://github.com/mkol5222/appsec-chart/releases/download/appsec-0.1.1/appsec-0.1.1.tgz --set cptoken=$APPSEC_TOKEN --set hostname=$APPSEC_HOSTNAME --set letsencrypt.email=$MY_EMAIL_ADDRESS

# monitor appsec and http-01 solver
k get po --watch

```

Cleanup:

```shell
# BACK IN AZURE SHELL: when want to remove VM later
# we store ./destroyvm<RANDOMID> - look what it does
ls destroyvm*; cat destroyvm*

```