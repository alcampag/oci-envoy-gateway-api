# OCI Envoy Gateway API

A collection of Kubernetes manifests and configuration templates for deploying the [Envoy Gateway API](https://gateway.envoyproxy.io/) controller on Oracle Cloud Infrastructure (OCI) with optimized networking and load balancing configurations.

## Overview

This project provides sample configurations for running Envoy Gateway on OCI Kubernetes clusters with different networking setups. It includes OCI-specific optimizations for load balancers, network security groups, SSL/TLS termination, and high availability across availability domains.

The configurations support both public and private load balancer deployments using either Flannel CNI or OCI VCN-native pod networking.

## Features

- **OCI-Optimized Load Balancers**: Flexible Load Balancer for public traffic, Network Load Balancer for private/internal traffic
- **Network Security Groups**: Automated NSG configuration and security rule management
- **SSL/TLS Termination**: Full SSL offloading with custom cipher suites and TLS 1.2/1.3 support
- **High Availability**: Topology spread constraints across OCI availability domains/fault domains
- **Auto-scaling**: Horizontal Pod Autoscaler (HPA) configuration for Envoy proxies
- **Pod Disruption Budgets**: Ensures availability during cluster maintenance
- **Client IP Detection**: Proper X-Forwarded-For header configuration for OCI load balancers, and Proxy Protocol for Network Load Balancer
- **TLS Redirect**: Automatic HTTP to HTTPS redirection

## Configuration Scenarios

### Directory Structure

- **`oci-public-flannel/`** - Public load balancer with Flannel CNI networking
- **`oci-public-vcn-native/`** - Public load balancer with OCI VCN-native pod networking
- **`oci-private-flannel/`** - Private/internal load balancer with Flannel CNI networking
- **`oci-private-vcn-native/`** - Private/internal load balancer with OCI VCN-native pod networking

### Public vs Private Configurations

**Public configurations** (`oci-public-*`):
- Use OCI Flexible Load Balancer (LB)
- Support SSL/TLS termination
- Require reserved public IPs
- Include HTTP to HTTPS redirect

**Private configurations** (`oci-private-*`):
- Use OCI Network Load Balancer (NLB)
- Internal load balancer (not internet-facing)
- Optimized for private network traffic
- No SSL termination (handled by applications)
- Proxy Protocol v2

### Flannel vs VCN-Native Networking

**Flannel CNI** (`*-flannel`):
- Traditional Kubernetes networking with overlay
- Requires additional network policy configurations

**VCN-Native** (`*-vcn-native`):
- Direct pod networking using OCI VCN subnets
- Better performance and native cloud integration
- Requires `loadbalancer.oci.oraclecloud.com/pod-readiness-gate-inject=enabled` namespace label

## Prerequisites

- OCI Kubernetes cluster (OKE)
- `kubectl` configured to access your cluster
- `helm` 3.x
- `openssl` for TLS certificate generation
- OCI CLI (optional, for resource management)

### OCI Resources Required

- VCN with appropriate subnets
- Network Security Groups (NSGs) for frontend and backend traffic
- Reserved public IP (for public configurations)
- TLS certificate (for public SSL configurations)

## Quick Start

1. **Install Envoy Gateway control plane:**

   ```bash
   # Create namespace
   kubectl create ns envoy-gateway-system

   # Generate self-signed certificate (replace with your own cert in production)
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=envoy/O=envoy"
   kubectl create secret tls tls-certificate-secret --key tls.key --cert tls.crt -n envoy-gateway-system

   # For VCN-native networking only
   kubectl label ns envoy-gateway-system loadbalancer.oci.oraclecloud.com/pod-readiness-gate-inject=enabled

   # Install Envoy Gateway using Helm
   helm install eg oci://docker.io/envoyproxy/gateway-helm -n envoy-gateway-system --create-namespace -f values.yml

   # Wait for deployment
   kubectl wait --timeout=5m -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available
   ```

2. **Choose your configuration scenario and deploy:**

   ```bash
   # For public load balancer with VCN-native CNI
   cd oci-public-vcn-native

   # Or for private load balancer with Flannel networking
   # cd oci-public-flannel
   ```

3. **Set environment variables (see Environment Variables section below)**

4. **Generate and deploy manifests:**

   ```bash
   ./template.sh
   kubectl apply -f ../template
   ```

5. **Test the deployment:**

   ```bash
   # For public configurations, get the load balancer IP
   kubectl get svc -n envoy-gateway-system

   # Access the echo application at https://echo.<LB_IP>.nip.io
   ```

## Environment Variables

Set these environment variables before running `template.sh`. The required variables differ by configuration type.

### Common Variables (All Configurations)

```bash
export CERTIFICATE_SECRET_NAME="tls-certificate-secret"  # Kubernetes secret name for TLS cert
export ECHO_IMAGE="registry.k8s.io/echoserver:1.8"      # Container image for test app
```

### Public Configurations (`oci-public-*`)

```bash
export LB_PUBLIC_IP=""           # Reserved public IP address
export LB_PUBLIC_SUBNET_ID=""    # Public subnet OCID
export LB_PUBLIC_SUBNET_CIDR=""  # Public subnet CIDR (e.g., 10.0.1.0/24)
export FRONTEND_NSG_ID=""        # Frontend Network Security Group OCID
export BACKEND_NSG_ID=""         # Backend Network Security Group OCID
```

### Private Configurations (`oci-private-*`)

```bash
export LB_PRIVATE_SUBNET_ID=""   # Private subnet OCID
export FRONTEND_NSG_ID=""        # Frontend Network Security Group OCID
export BACKEND_NSG_ID=""         # Backend Network Security Group OCID
```

### Getting OCI Resource IDs

Use OCI CLI or Console to find these values:

```bash
# List subnets
oci network subnet list --compartment-id <compartment-ocid> --vcn-id <vcn-ocid>

# List Network Security Groups
oci network nsg list --compartment-id <compartment-ocid>

# Create reserved public IP (if needed)
oci network public-ip create --compartment-id <compartment-ocid> --lifetime RESERVED
```

## Deployment Steps

### Step 1: Prepare OCI Resources

1. Create or identify your VCN and subnets
2. Create Network Security Groups with appropriate rules
3. Reserve a public IP (for public configurations)
4. Create or obtain TLS certificates

### Step 2: Deploy Envoy Gateway

Follow the Quick Start section above to install the control plane.

### Step 3: Configure Environment

```bash
cd <chosen-configuration-directory>
export LB_PUBLIC_IP="203.0.113.10"  # Example values
export LB_PUBLIC_SUBNET_ID="ocid1.subnet.oc1.phx..."
# ... set other required variables
```

### Step 4: Generate Manifests

```bash
./template.sh
```

This creates templated YAML files in the `../template/` directory.

### Step 5: Deploy Application

```bash
kubectl apply -f ../template
```

### Step 6: Verify Deployment

```bash
# Check gateway status
kubectl get gateway -n envoy-gateway-system

# Check envoy proxy service
kubectl get svc -n envoy-gateway-system

# Check application pods
kubectl get pods -n default
```

### Step 7: Test Access

For public configurations:
- Get the load balancer IP: `kubectl get svc -n envoy-gateway-system`
- Access `https://echo.<LB_IP>.nip.io`

For private configurations, access via private IP within your VCN.

## Customization

### Adding Your Own Applications

1. Create HTTPRoute resources referencing your Gateway
2. Deploy your application Services and Deployments
3. Update hostnames in the HTTPRoute (replace `*.${LB_PUBLIC_IP}.nip.io`)

Example HTTPRoute for your app:
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-app
  namespace: default
spec:
  parentRefs:
    - name: oci-public-apps
      namespace: envoy-gateway-system
      sectionName: https
  hostnames:
    - "my-app.${LB_PUBLIC_IP}.nip.io"
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: my-app-service
          port: 80
```

### Modifying Load Balancer Settings

Edit the `oci-*-apps-envoyProxy.yml` files to customize:
- Load balancer shape and size
- SSL/TLS settings
- Health check configurations
- Connection timeouts
- Security rules

### Scaling Configuration

The configurations include HPA settings. Adjust `minReplicas` and `maxReplicas` in the EnvoyProxy manifests.

## Troubleshooting

### Common Issues

**Load Balancer Not Provisioned**
- Check subnet and NSG configurations
- Verify OCI permissions for load balancer creation
- Check namespace labels for VCN-native networking

**SSL Certificate Issues**
- Ensure certificate secret exists in `envoy-gateway-system` namespace
- Verify certificate format and validity
- Check load balancer annotations for SSL port configuration

**Gateway Not Accepting Routes**
- Verify Gateway status: `kubectl describe gateway -n envoy-gateway-system`
- Check listener configurations
- Ensure HTTPRoute namespace is allowed (check `allowedRoutes`)

**Application Not Accessible**
- Verify HTTPRoute status: `kubectl describe httproute`
- Check backend service exists and is healthy
- Confirm hostname resolution

### Logs and Debugging

```bash
# Envoy Gateway controller logs
kubectl logs -n envoy-gateway-system deployment/envoy-gateway

# Envoy proxy logs
kubectl logs -n envoy-gateway-system deployment/oci-*-apps

# Check Gateway API resources
kubectl get gatewayapi -A
```

### Network Connectivity

For private configurations, ensure:
- NLB is properly configured as internal
- Subnet has correct route tables
- NSGs allow traffic between load balancer and backend pods

## Cleanup

To remove the deployment:

```bash
kubectl delete -f ../template
helm uninstall eg -n envoy-gateway-system
kubectl delete ns envoy-gateway-system
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with different configuration scenarios
5. Submit a pull request

### Testing

Test your changes across all four configuration scenarios:
- Public + Flannel
- Public + VCN-native
- Private + Flannel
- Private + VCN-native

## Support

For issues and questions:
- Open a GitHub issue
- Check Envoy Gateway documentation: https://gateway.envoyproxy.io/
- Review OCI Kubernetes documentation: https://docs.oracle.com/en-us/iaas/Content/ContEng/home.htm
