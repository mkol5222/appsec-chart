# Secondary ingress - one more hostname on same AppSec agent

```shell
# run on AppSec VM:

# secondary hostname on same agent
export APPSEC_HOSTNAME=secondary.klaud.online
export HOST_TAG=$(echo $APPSEC_HOSTNAME | tr '.' '-')
echo $HOST_TAG
verify-dns


cat - <<EOF | sed "s/APPSEC_HOSTNAME/$APPSEC_HOSTNAME/" | sed "s/HOST_TAG/$HOST_TAG/" | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: HOST_TAG-appsec-ingress
  annotations:
    cert-manager.io/cluster-issuer: lets-encrypt
spec:
  tls:
  - hosts:
    - APPSEC_HOSTNAME
    secretName: HOST_TAG-appsec-ingress-tls
  rules:
  - host: APPSEC_HOSTNAME
    http:
      paths:
      - backend:
          service:
            name: appsec
            port:
              number: 80
        path: /
        pathType: Prefix
EOF
```