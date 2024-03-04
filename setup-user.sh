#!/bin/bash

# check microk8s status
microk8s status --wait-ready


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
mkdir ~/.kube; sudo microk8s config > ~/.kube/config
chmod o= ~/.kube/config
chmod g= ~/.kube/config
