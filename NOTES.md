# AppSec deployment on K8S - helm chart


```shell
# Ubuntu VM with public IP
ssh lab1vm

# https://microk8s.io/docs/getting-started
sudo snap install microk8s --classic --channel=1.29

sudo usermod -a -G microk8s $USER
sudo mkdir -p ~/.kube
sudo chown -f -R $USER ~/.kube

# arkade
# https://github.com/alexellis/arkade?tab=readme-ov-file#getting-arkade
```