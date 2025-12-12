# Installing the envoy-gateway control plane

```
kubectl create ns envoy-gateway-system
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=envoy/O=envoy"
kubectl create secret tls tls-certificate-secret --key tls.key --cert tls.crt -n envoy-gateway-system
kubectl label ns envoy-gateway-system loadbalancer.oci.oraclecloud.com/pod-readiness-gate-inject=enabled
```

```
helm install eg oci://docker.io/envoyproxy/gateway-helm -n envoy-gateway-system --create-namespace -f values.yml
kubectl wait --timeout=5m -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available
```

```
cd <folder-conf> && ./template.sh && cd ..
kubectl apply -f template
```

```
kubectl delete -f template
```