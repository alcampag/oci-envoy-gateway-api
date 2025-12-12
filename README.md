# Installing the envoy-gateway control plane

```
helm install eg oci://docker.io/envoyproxy/gateway-helm -n envoy-gateway-system --create-namespace -f values.yml
kubectl wait --timeout=5m -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available
```