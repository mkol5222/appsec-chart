# CloudGuard WAF in MicroK8S on Ubuntu 22.04 LTS VM

Consider Azure Shell bash session for following commands:

```shell

# verify current Azure subsctiption (it should be ready in  Azure Shell)
az account show --output table

# Azure environment - Ubuntu LTS VM with public IP provisioning
cd $(mktemp -d)
. <(curl -s https://raw.githubusercontent.com/mkol5222/appsec-chart/main/setup-vm.sh)

# login to new VM
sshvm
# will continue IN PROVISIONED AZURE VM
```

Lets continue on Azure VM:

```shell
# IN AZURE VM (after sshvm) 

# make sure machine is ready (it returns to prompt, once ready)
microk8s status --wait-ready

# ready to deploy AppSec WAF - FOCUS ON INPUTS AND DNS RECORD!!!
#
#
#
MY_EMAIL_ADDRESS="someone@somewhere.net" # REPLACE - used for Let's Encrypt
# REPLACE WITH REAL TOKEN from Infinity Portal - Docker simple MANAGED profile token
APPSEC_TOKEN=cp-67c2... 
APPSEC_HOSTNAME=appsec1493.klaud.online # REPLACE

# prepare DNS record for the service
# check DNS util properly configured
verify-dns

# ready to install
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