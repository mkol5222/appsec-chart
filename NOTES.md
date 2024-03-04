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
chmod o= ~/.kube/config
chmod g= ~/.kube/config

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

YOUR_EMAIL_ADDRESS="someone1@outlook.com" # REPLACE

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

YOUR_HOSTNAME="microbot2.klaud.online" # REPLACE WITH YOUR HOSTNAME

# flush dns and check DNS
sudo resolvectl flush-caches
dig +short $YOUR_HOSTNAME

# ingress
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
# once certificate is issued:
k get secret -A | grep microbot-ingress-tls
k get secret microbot-ingress-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout | grep CN

# cleanup test
k delete ingress microbot-ingress
k delete svc microbot
k delete deploy microbot
# and issuer too
k delete clusterissuer lets-encrypt


# yet another service
k create deploy webik --image=nginx --replicas=2
k expose deploy webik --port 80 --type ClusterIP

# ingress
WEB_SERVICE_DOMAIN="webik123.klaud.online" # REPLACE WITH YOUR HOSTNAME
cat - <<EOF | sed "s/my-service.example.com/$WEB_SERVICE_DOMAIN/" | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
 name: webik-ingress
 annotations:
   cert-manager.io/cluster-issuer: lets-encrypt
spec:
 tls:
 - hosts:
   - my-service.example.com
   secretName: webik-ingress-tls
 rules:
 - host: my-service.example.com
   http:
     paths:
     - backend:
         service:
           name: web
           port:
             number: 80
       path: /
       pathType: Exact
EOF

k logs -f -n cert-manager deploy/cert-manager
dig +short $WEB_SERVICE_DOMAIN
k get secret webik-ingress-tls  -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout | grep CN
curl -Lkv http://$WEB_SERVICE_DOMAIN --resolve $WEB_SERVICE_DOMAIN:80:127.0.0.1 2>&1 | grep CN


# replace cluster issuer with helm driven one
k delete clusterissuer lets-encrypt
cd; mkdir w; cd w; gh repo clone mkol5222/appsec-chart
YOUR_EMAIL_ADDRESS="someone@somewhere.net" # REPLACE!!!
helm  install letsencrypt-issuer ./appsec-chart/charts/certs --set letsencrypt.email=$YOUR_EMAIL_ADDRESS
```