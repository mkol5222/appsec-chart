#!/bin/bash

export RANDOM_ID="$(openssl rand -hex 3)"
export MY_RESOURCE_GROUP_NAME="appsec-$RANDOM_ID-rg"
export REGION=westeurope
export MY_VM_NAME="appsec-$RANDOM_ID"
export MY_USERNAME=azureuser
export MY_VM_IMAGE="Canonical:0001-com-ubuntu-minimal-jammy:minimal-22_04-lts-gen2:latest"

# create resource group
echo
echo "Creating resource group $MY_RESOURCE_GROUP_NAME in $REGION"
RGRESP=$(az group create --name $MY_RESOURCE_GROUP_NAME --location $REGION -o json)
if [ $? -ne 0 ]; then
  echo  -e "\033[31m Failed to create resource group $MY_RESOURCE_GROUP_NAME"
  exit 1
fi
RGSTATUS=$(echo $RGRESP | jq -r '.properties.provisioningState')
echo "Resource group status: $RGSTATUS"
echo

# get cloud-init.txt
curl -s -o cloud-init.txt https://raw.githubusercontent.com/mkol5222/appsec-chart/main/cloud-init.yml

# create VM
# https://learn.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-cli

echo "Creating VM $MY_VM_NAME in $MY_RESOURCE_GROUP_NAME"
RESPVM=$(az vm create \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --name $MY_VM_NAME \
  --image $MY_VM_IMAGE \
  --admin-username $MY_USERNAME \
  --generate-ssh-keys \
  --custom-data cloud-init.txt \
  --assign-identity \
  --size Standard_DS2_v2  \
  --public-ip-sku Standard )

if [ $? -ne 0 ]; then
  echo  -e "\033[31m Failed to create VM $MY_VM_NAME"
  exit 1
fi

VMSTATUS=$(echo $RESPVM | jq -r '.powerState')
echo
echo "VM status: $VMSTATUS"
echo

echo "Opening ports 22, 80, 443"
RESPPORTS=$(az vm open-port -g $MY_RESOURCE_GROUP_NAME -n $MY_VM_NAME --port 22,80,443)
if [ $? -ne 0 ]; then
  echo  -e "\033[31m Failed to open ports"
  exit 1
fi
echo "Ports opened"

echo "Enabling AAD login for the VM"
RESPAAD=$(az vm extension set \
    --publisher Microsoft.Azure.ActiveDirectory \
    --name AADSSHLoginForLinux \
    --resource-group $MY_RESOURCE_GROUP_NAME \
    --vm-name $MY_VM_NAME )
if [ $? -ne 0 ]; then
  echo  -e "\033[31m Failed to enable AAD login"
  exit 1
fi
echo "AAD login enabled"

echo "Getting public IP address of the VM $MY_VM_NAME"
export IP_ADDRESS=$(az vm show --show-details --resource-group $MY_RESOURCE_GROUP_NAME --name $MY_VM_NAME --query publicIps --output tsv)
echo "Public IP address: $IP_ADDRESS"

alias sshvm="ssh -o StrictHostKeyChecking=no $MY_USERNAME@$IP_ADDRESS"

echo '#!/bin/bash' > "destroyvm-$RANDOM_ID"
echo "az vm delete --resource-group $MY_RESOURCE_GROUP_NAME --name $MY_VM_NAME --yes" >> "destroyvm-$RANDOM_ID"
echo "az group delete --name $MY_RESOURCE_GROUP_NAME --yes" >> "destroyvm-$RANDOM_ID"
chmod +x "destroyvm-$RANDOM_ID"

echo '#!/bin/bash' > "sshvm-$RANDOM_ID"
echo "az ssh vm -n $MY_VM_NAME -g $MY_RESOURCE_GROUP_NAME --local-user azureuser" >> "sshvm-$RANDOM_ID"
chmod +x "sshvm-$RANDOM_ID"

echo
echo -e "\033[32m SUCCESS: VM created. You can now connect to it using 'sshvm' command"
echo "To destroy the VM, run 'destroyvm-$RANDOM_ID'"
echo
