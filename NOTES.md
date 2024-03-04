# AppSec deployment on K8S - helm chart


```shell
# Ubuntu VM with public IP
ssh lab1vm

# https://microk8s.io/docs/getting-started
sudo snap install microk8s --classic --channel=1.29

sudo usermod -a -G microk8s $USER
sudo mkdir -p ~/.kube
sudo chown -f -R $USER ~/.kube
newgrp microk8s

# arkade
# https://github.com/alexellis/arkade?tab=readme-ov-file#getting-arkade
curl -sLS https://get.arkade.dev | sudo sh
ark get kubectl
ark get helm
ark get k9s

echo >> ~/.bashrc
echo 'export PATH=$PATH:$HOME/.arkade/bin/' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
source ~/.bashrc

# kube config
sudo microk8s config > ~/.kube/config

# try
kubectl get nodes
k get no

# ready?
microk8s status --wait-ready
# addons
microk8s enable dns
microk8s enable hostpath-storage
microk8s enable cert-manager
microk8s enable ingress

# certificates

# try https://microk8s.io/docs/addon-cert-manager

YOUR_EMAIL_ADDRESS="someone@outlook.com" # REPLACE

cat - <<EOF | sed "s/email: .*/email: $YOUR_EMAIL_ADDRESS/" | kubectl apply -f -
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
 name: lets-encrypt
spec:
 acme:
   email: microk8s@example.com
   server: https://acme-v02.api.letsencrypt.org/directory
   privateKeySecretRef:
     # Secret resource that will be used to store the account's private key.
     name: lets-encrypt-priviate-key
   # Add a single challenge solver, HTTP01 using nginx
   solvers:
   - http01:
       ingress:
         class: public
EOF

# service to be published using ingress
microk8s kubectl create deploy --image cdkbot/microbot:1 --replicas 3 microbot
microk8s kubectl expose deploy microbot --port 80 --type ClusterIP

# check your VM public IP
curl -s ip.iol.cz/ip/; echo
# make sure this IP is pointed to your hostname below in DNS

# publish on your hostname - pointed in DNS to your VMs public IP

YOUR_HOSTNAME="microbot.klaud.online" # REPLACE WITH YOUR HOSTNAME

# flush dns and check DNS
sudo resolvectl flush-caches
dig +short $YOUR_HOSTNAME

cat - <<EOF | sed "s/my-service.example.com/$YOUR_HOSTNAME/" | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
 name: microbot-ingress
 annotations:
   cert-manager.io/cluster-issuer: lets-encrypt
spec:
 tls:
 - hosts:
   - my-service.example.com
   secretName: microbot-ingress-tls
 rules:
 - host: my-service.example.com
   http:
     paths:
     - backend:
         service:
           name: microbot
           port:
             number: 80
       path: /
       pathType: Exact
EOF

# test ingress
k describe ingress microbot-ingress
echo curl -Lkv http://$YOUR_HOSTNAME --resolve $YOUR_HOSTNAME:80:127.0.0.1
curl -Lkv http://$YOUR_HOSTNAME --resolve $YOUR_HOSTNAME:80:127.0.0.1
# certs
curl -Lkv http://$YOUR_HOSTNAME --resolve $YOUR_HOSTNAME:80:127.0.0.1 2>&1 | grep CN

# look at certs
k get certificate microbot-ingress-tls
k describe certificaterequest

k get secret -A microbot-ingress-tls
k get secret microbot-ingress-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout

# cleanup test
k delete ingress microbot-ingress
k delete svc microbot
k delete deploy microbot
```