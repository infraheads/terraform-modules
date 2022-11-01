# Introduction
  It's all for [GitOps](https://about.gitlab.com/topics/gitops/).
  This is a terraform module, that adds ArgoCD and Helm Secrets plugin to Kubernetes cluster.
  It allows you to encrypt any type of secret with Sops and push all codes to GitHub. 
  After which it will be secure. ArgoCD will decrypt the code using the Helm secret plugin and code will be available in the cluster.
  
# Helm Secret 

To store secrets in our Helm configs in a secure way, we used a Helm plugin called helm-secrets to decrypt, edit and encrypt our secrets in the Helm configs git repository. The helm-secrets plugin uses SOPS under the hood to encrypt or decrypt secrets using various key providers like PGP, AWS or GCP KMS, etc.

# ArgoCD Integration

Before starting to integrate helm-secrets with ArgoCD, consider using [age](https://github.com/FiloSottile/age/) over gpg.

# Prerequisites

- ArgoCD 2.3.0+, 2.2.6+, 2.1.11+
- helm-secrets [3.9.x](https://github.com/jkroepke/helm-secrets/releases/tag/v3.9.1) or higher.
- age encrypted values requires at least [3.10.0](https://github.com/jkroepke/helm-secrets/releases/tag/v3.10.0) and sops [3.7.0](https://github.com/mozilla/sops/releases/tag/v3.7.0)

# Usage

An Argo CD Application can use the downloader plugin syntax to use encrypted value files.
There are three methods how to use an encrypted value file.
- Method 1: Mount the private key from a kubernetes secret as volume
- Method 2: Fetch the private key directly from a kubernetes secret
- Method 3: Using cloud provider (GCP KMS is used here)

# Installation on Argo CD

Before using helm secrets, we are required to install `helm-secrets` on the `argocd-repo-server`. 
Depends on the secret backend, `sops` or `vals` is required on the `argocd-repo-server`, too.
There are two methods to do this. 
Either create your custom ArgoCD Docker Image or install them via an init container.

## Step 1: Customize argocd-repo-server

### Option: Init Container

Install sops or vals and helm-secret through an init container on the `argocd-repo-server` Deployment.

This is an example values file for the [ArgoCD Server Helm chart](https://github.com/argoproj/argo-helm/tree/master/charts/argo-cd).

<details>
<summary>values.yaml</summary>
<p>

```yaml
repoServer:
  env:
    - name: HELM_PLUGINS
      value: /custom-tools/helm-plugins/
    - name: HELM_SECRETS_SOPS_PATH
      value: /custom-tools/sops
    - name: HELM_SECRETS_VALS_PATH
      value: /custom-tools/vals
    - name: HELM_SECRETS_KUBECTL_PATH
      value: /custom-tools/kubectl
    - name: HELM_SECRETS_CURL_PATH
      value: /custom-tools/curl
    # https://github.com/jkroepke/helm-secrets/wiki/Security-in-shared-environments
    - name: HELM_SECRETS_VALUES_ALLOW_SYMLINKS
      value: "false"
    - name: HELM_SECRETS_VALUES_ALLOW_ABSOLUTE_PATH
      value: "false"
    - name: HELM_SECRETS_VALUES_ALLOW_PATH_TRAVERSAL
      value: "false"
    # helm secrets wrapper mode installation (optional)
    # - name: HELM_SECRETS_HELM_PATH
    #   value: /usr/local/bin/helm
  volumes:
    - name: custom-tools
      emptyDir: {}
  volumeMounts:
    - mountPath: /custom-tools
      name: custom-tools
  # helm secrets wrapper mode installation (optional)
  #  - mountPath: /usr/local/sbin/helm
  #    subPath: helm
  #    name: custom-tools

  initContainers:
    - name: download-tools
      image: alpine:latest
      command: [sh, -ec]
      env:
        - name: HELM_SECRETS_VERSION
          value: "3.12.0"
        - name: KUBECTL_VERSION
          value: "1.24.3"
        - name: VALS_VERSION
          value: "0.18.0"
        - name: SOPS_VERSION
          value: "3.7.3"
      args:
        - |
          mkdir -p /custom-tools/helm-plugins
          wget -qO- https://github.com/jkroepke/helm-secrets/releases/download/v${HELM_SECRETS_VERSION}/helm-secrets.tar.gz | tar -C /custom-tools/helm-plugins -xzf-;

          wget -qO /custom-tools/sops https://github.com/mozilla/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux
          wget -qO /custom-tools/kubectl https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl

          wget -qO- https://github.com/variantdev/vals/releases/download/v${VALS_VERSION}/vals_${VALS_VERSION}_linux_amd64.tar.gz | tar -xzf- -C /custom-tools/ vals;
          
          # helm secrets wrapper mode installation (optional)
          # RUN printf '#!/usr/bin/env sh\nexec %s secrets "$@"' "${HELM_SECRETS_HELM_PATH}" >"/usr/local/sbin/helm" && chmod +x "/custom-tools/helm"
          
          chmod +x /custom-tools/*
      volumeMounts:
        - mountPath: /custom-tools
          name: custom-tools
```

</details>

## Step 2: Allow helm-secrets schemes in argocd-cm ConfigMap

By default, ArgoCD only allows `http://` and `https://` as remote value schemes.

The [ArgoCD Server Helm chart](https://github.com/argoproj/argo-helm/tree/master/charts/argo-cd) supports defining `argocd-cm` settings through [values.yaml](https://github.com/argoproj/argo-helm/blob/6ff050f6f57edda1e6912ef0bb17d085684e103e/charts/argo-cd/values.yaml#L1155-L1157):

```yaml
server:
  config:
    helm.valuesFileSchemes: >-
      secrets+gpg-import, secrets+gpg-import-kubernetes,
      secrets+age-import, secrets+age-import-kubernetes,
      secrets,secrets+literal,
      https
```

# Configuration of ArgoCD

When using private key encryption, it is required to configure ArgoCD repo server so that it has access 
to the private key to decrypt the encrypted value file(s). When using GCP KMS, encrypted value file(s)
can be decrypted using [Application Default Credentials](https://developers.google.com/identity/protocols/application-default-credentials).

## Private key encryption (sops backend only)
There are two ways to configure ArgoCD to have access to your private key:

- mount the PGP/age key secret as a volume in the argocd-repo-server; or
- fetch the secret value (private key) directly using Kubernetes API.

Both methods depend on a Kubernetes secret holding the key in plain-text format (i.e., not encrypted or protected by a passphrase).

### Using age
#### Generating the key

```bash
age-keygen -o key.txt
```

The public key can be found in the output of the generate-key command.
Unlike gpg, age does not have an agent. [To encrypt the key with sops](https://github.com/mozilla/sops#encrypting-using-age), set the environment variables

* `SOPS_AGE_KEY_FILE="path/age/key.txt"`
* `SOPS_AGE_RECIPIENTS=public-key`

before running sops. Define `SOPS_AGE_RECIPIENTS` is only required on initial encryption of a plain file.

### Making the key accessible within ArgoCD
#### Mount the private key from a kubernetes secret as volume on the argocd-repo-server

To use the *secrets+gpg-import / secrets+age-import* syntax, the keys need to be mounted on the **argocd-repo-server**.

This is an example values file for the [ArgoCD Server Helm chart](https://argoproj.github.io/argo-helm).
```yaml
repoServer:
  volumes:
    - name: helm-secrets-private-keys
      secret:
        secretName: helm-secrets-private-keys

  volumeMounts:
    - mountPath: /helm-secrets-private-keys/
      name: helm-secrets-private-keys
```

Once mounted, your Argo CD Application should look similar to this:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app
spec:
  source:
    helm:
      valueFiles:
        # Mount the gpg key from a kubernetes secret as volume
        # secrets+gpg-import://<key-volume-mount>/<key-name>.asc?<relative/path/to/the/encrypted/secrets.yaml>
        # secrets+age-import://<key-volume-mount>/<key-name>.txt?<relative/path/to/the/encrypted/secrets.yaml>
        # Example: (Assumptions: key-volume-mount=/helm-secrets-private-keys, key-name=app, secret.yaml is in the root folder)
        - secrets+age-import:///helm-secrets-private-keys/key.txt?./ #encrypted file path
```

## External key location

sops and vals are supporting multiple cloud providers.

### AWS 

The argocd-repo-server need access to cloud services. If ArgoCD is deployed on an EKS, 
[AWS IRSA](https://docs.aws.amazon.com/eks/latest/userguide/specify-service-account-role.html) can be used here.

This is an example values file for the [ArgoCD Server Helm chart](https://argoproj.github.io/argo-helm):
```yaml
repoServer:
  serviceAccount:
    create: true
    name: "argocd-repo-server"
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::111122223333:role/iam-role-name
    automountServiceAccountToken: true
```

If IRSA is not available, move forward with static credentials.

1. Create a secret contain the `AWS_DEFAULT_REGION`, `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.
   Example: 
   ```bash
   kubectl create secret generic argocd-aws-credentials \
     --from-literal=AWS_DEFAULT_REGION=eu-central-1 \
     --from-literal=AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE \
     --from-literal=AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
   ```

2. Configure the secrets inside ArgoCD Helm Chart:
   Example:
   ```yaml
   repoServer:
     envFrom:
     - secretRef:
         name: argocd-aws-credentials
   ```
   
   
# Example
   
   You can find the example [here](https://github.com/infraheads/gymops/tree/main/IaC/Terraform/Kubernetes/HelmSecret/example)

## Useful guide

### How to create age key ?
  ####
  . age-keygen > sops-key.txt
  
  . chmod 600 sops-key.txt
  
  . export SOPS_AGE_RECIPIENTS=age1agax8s0kwdj7s28949ff5ucwswyqnmc7wtkczpzx83m5lpxrscqedk5dr
  
  . export SOPS_AGE_KEY_FILE=<key's current path>
  

### How to encrypt and decrypt locally ?
  #### . Using age key
    sops --encryp secret-dec.yaml > secret-enc.yaml
    sops --decrypt secret-enc.yaml > secret-dec.yaml
  #### . Using KMS key
    sops --kms arn:aws:kms:eu-central-1:068737609226:key/284f4099-2fb4-491e-b610-69ed22ad587 -e secret-dec-kms.yaml > secret-enc-kms.yaml
    sops --kms arn:aws:kms:eu-central-1:068737609226:key/284f4099-2fb4-491e-b610-69ed22ad587 -d secret-enc-kms.yaml > secret-dec-kms.yaml
