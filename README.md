# CloudGuard WAF in MicroK8S on Ubuntu 22.04 LTS VM

Consider Azure Shell bash session for following commands:

```shell

# verify Azure subsctiption
az account show --output table

# Azure environment
export RANDOM_ID="$(openssl rand -hex 3)"
export MY_RESOURCE_GROUP_NAME="myVMResourceGroup$RANDOM_ID"
export REGION=westeurope
export MY_VM_NAME="myVM$RANDOM_ID"
export MY_USERNAME=azureuser
export MY_VM_IMAGE="Canonical:0001-com-ubuntu-minimal-jammy:minimal-22_04-lts-gen2:latest"

# create resource group
az group create --name $MY_RESOURCE_GROUP_NAME --location $REGION

# get cloud-init.txt
curl -o cloud-init.txt https://raw.githubusercontent.com/mkol5222/appsec-chart/main/cloud-init.yml

# create VM
# https://learn.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-cli

az vm create \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --name $MY_VM_NAME \
  --image $MY_VM_IMAGE \
  --admin-username $MY_USERNAME \
  --generate-ssh-keys \
  --custom-data cloud-init.txt \
  --assign-identity \
  --public-ip-sku Standard
  
az vm extension set \
    --publisher Microsoft.Azure.ActiveDirectory \
    --name AADSSHLoginForLinux \
    --resource-group $MY_RESOURCE_GROUP_NAME \
    --vm-name $MY_VM_NAME

export IP_ADDRESS=$(az vm show --show-details --resource-group $MY_RESOURCE_GROUP_NAME --name $MY_VM_NAME --query publicIps --output tsv)

ssh -o StrictHostKeyChecking=no $MY_USERNAME@$IP_ADDRESS

# check microk8s status
sudo usermod -a -G microk8s azureuser
newgrp microk8s
microk8s status --wait-ready


```

On Azure VM:

```shell
# arkade
# https://github.com/alexellis/arkade?tab=readme-ov-file#getting-arkade
curl -sLS https://get.arkade.dev | sudo sh
ark get kubectl
ark get helm
ark get k9s

echo >> ~/.bashrc
echo 'export PATH=$PATH:$HOME/.arkade/bin/' >> ~/.bashrc
echo 'alias kubectl=microk8s.kubectl' >> ~/.bashrc
echo 'alias helm=microk8s.helm' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
source ~/.bashrc

# kube config
sudo microk8s config > ~/.kube/config
chmod o= ~/.kube/config
chmod g= ~/.kube/config
```

Cleanup:

```shell
# when want to remove VM later
az vm delete --resource-group $MY_RESOURCE_GROUP_NAME --name $MY_VM_NAME --yes
az group delete --name $MY_RESOURCE_GROUP_NAME --yes
```