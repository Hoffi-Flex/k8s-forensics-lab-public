# 🔍 K8s Forensics Lab

### Cloud-Native Security Testing Environment
[![Terraform Status](https://github.com/Hoffi-Flex/k8s-forensics-lab-private/actions/workflows/terraform-apply.yml/badge.svg)](https://github.com/Hoffi-Flex/k8s-forensics-lab-private/actions)  
  
[![DigitalOcean](https://img.shields.io/badge/DigitalOcean-%230167ff.svg?style=for-the-badge&logo=digitalOcean&logoColor=white)](https://www.digitalocean.com)
[![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io)
[![Flux](https://img.shields.io/badge/flux-%23316CEA.svg?style=for-the-badge&logo=flux&logoColor=white)](https://fluxcd.io)

🌊 **GitHub** → 📦 **Flux CD** → 🚢 **DigitalOcean Kubernetes** → 📱 **Applications**

## 📐 Architecture Decisions

### GitOps Implementation
- **Selected: Flux** 
  - Advantages:
    - Lower resource consumption
    - Native Kustomize integration
    - Learning opportunity
  - Alternatives considered:
    - ArgoCD (feature-rich but higher resource overhead)
    - Pure Terraform approach (rejected due to maintenance overhead)

### DNS & Certificates
- Custom domain management through Cloudflare
  - LetsEncrypt integration via cert-manager
  - Working ACME snippet available
  - Important: Deploy without `--namespace` flag for cluster-wide DNS monitoring
- External DNS configuration using Cloudflare API tokens

### Secret Management
- External cluster secrets: GitHub Secrets
- In-cluster secrets: sealed-secrets
- kubeseal for simplified secret handling

### Updates & Maintenance
- Renovate bot integration
  - Automated updates
  - Auto-merge for minor version changes
- Auto-Cluster Updates on DO

## 🌐 DigitalOcean Kubernetes Network Architecture

### Control Plane Access
- DigitalOcean automatically provides a public IP for the Kubernetes API server
- Managed by DigitalOcean; no additional configuration required
- Used for kubectl access and cluster management


## 📁 Repository Structure

```
├── namespaces/
│   ├── cert-manager-namespace.yaml
│   ├── external-dns-namespace.yaml
│   ├── ingress-nginx-namespace.yaml
│   └── kustomization.yaml
├── helm-repos/
│   ├── cert-manager-repo.yaml
│   ├── external-dns-repo.yaml
│   ├── ingress-nginx-repo.yaml
│   └── kustomization.yaml
└── infrastructure/
    ├── cert-manager/
    ├── external-dns/
    ├── ingress-nginx/
    └── kustomization.yaml
```

## 🔑 Required Environment Variables (GitHub Secrets)

### Terraform Input Variables

Terraform input variables allow you to pass values dynamically to resource attributes in your configuration or module, making it adaptable and modular. In GitHub Actions, you can set these values as environment variables using the format `TF_VAR_<variable_name>`.

These are the required input variables for our GitHub Actions workflow:

| Variable Name                         | Description                        |
|---------------------------------------|------------------------------------|
| `TF_VAR_cloudflare_access_key`        | **Cloudflare Access Key (R2)**     |
| `TF_VAR_cloudflare_secret_key`        | **Cloudflare Secret Key (R2)**     |
| `TF_VAR_do_token`                     | **DigitalOcean API Key**           |

> **Note:** Ensure these secrets are set in your GitHub Repository Settings under **Settings > Secrets and variables > Actions**.  


## 🚀 Flux Bootstrap

### Prerequisites
Install the Flux CLI:
```bash
# For macOS
brew install fluxcd/tap/flux

# For Linux
curl -s https://fluxcd.io/install.sh | sudo bash
```

### Cluster Bootstrap
The repository contains a pre-configured Flux setup in the `flux-system` directory:
```
flux-system/
├── gotk-components.yaml   # Core Flux controllers and CRDs
├── gotk-sync.yaml         # GitRepository and Kustomization resources
└── kustomization.yaml     # Kustomize configuration
```

Prepare PAT for Flux here: https://github.com/settings/tokens  

Bootstrap the cluster:
```bash
flux bootstrap github \
  --owner=Hoffi-Flex \
  --repository=k8s-forensics-lab-public \
  --branch=main \
  --path=./flux \
  --personal \
  --token-auth
```

Verify the installation:
```bash
flux check
```

## 🔒 Encrypting Secrets with Sealed-Secrets and kubeseal

This sections covers how to encrypt Kubernetes secrets locally using the Sealed-Secrets public key and kubeseal.

### Prerequisite: Install Sealed-Secrets in the Cluster

To ensure Flux can handle encrypted secrets, install Sealed-Secrets in the cluster first. You can do this with either Helm or kubectl:

#### Using Helm

```bash
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update
helm install sealed-secrets-controller sealed-secrets/sealed-secrets
```

### Requirements

- **Public Key**: Retrieve the Sealed-Secrets public key from your Kubernetes cluster and save it as `pub-cert.pem` on your local machine.
Run the following command to get the public key:
    ```bash
    kubectl get secret -n default -l sealedsecrets.bitnami.com/sealed-secrets-key -o jsonpath="{.items[0].data.tls\.crt}" | base64 --decode > pub-cert.pem
    ```

### Steps to Encrypt Secrets __locally__

1. **Prepare the Secret YAML File**  
   Create a Kubernetes Secret manifest (e.g., `mysecret.yaml`) with the data you want to encrypt. For example like this:
   ```yaml
      apiVersion: v1
      kind: Secret
      metadata:
        name: example-secret
        namespace: default
      data:
        username: dXNlcm5hbWU= # base64 encoded 'username'
        password: cGFzc3dvcmQ= # base64 encoded 'password'
    ```
2. **Encrypt the Secret using kubeseal**  
   With the `pub-cert.pem` public key, encrypt the file as follows:
    ```bash
    kubeseal --format yaml --cert pub-cert.pem < mysecret.yaml > mysecret.sealed.yaml
    ```