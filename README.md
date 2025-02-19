# Infra

## k0s 
### Prepare SSH

Add user to sudo group:
```
sudo usermod -aG sudo $USER
```
Edit sudoers file:
```
sudo visudo
```

Ensure these lines exists:
```
fred ALL=(ALL) NOPASSWD: ALL
%sudo   ALL=(ALL:ALL) NOPASSWD:ALL
```

### Bootstrap a cluster

Initialize and customize your cluster plain YAML definition:
```bash
k0sctl init --k0s > fullstack.yaml
```

Apply your cahnges:
```bash
k0sctl apply --config fullstack.yaml --disable-telemetry --debug
```

Fetch the kubeconfig for your cluster
```bash
k0sctl kubeconfig --config fullstack.yaml
```

## Talos

### Bootstrap a cluster

Generate secrets:
```bash
talosctl gen secrets
```

Generate manifests for Cilium CNI:
```bash
helm template cilium cilium/cilium --namespace kube-system \
--set ipam.mode=kubernetes \
--set=kubeProxyReplacement=true \
--set=securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
--set=securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
--set=cgroup.autoMount.enabled=false \
--set=cgroup.hostRoot=/sys/fs/cgroup \
--set=k8sServiceHost=localhost \
--set=k8sServicePort=7445 > cilium.yaml
```

Get disk:
```bash
talosctl disks -n 192.168.1.131 --insecure
```

Generate config:
```bash
talosctl gen config talos-k8s-fredcorp https://192.168.1.130:6443 --with-secrets secrets.yaml \
--config-patch @patches/allow-controlplane-workloads.yaml \
--config-patch @patches/cni.yaml \
--config-patch @patches/dhcp.yaml \
--config-patch @patches/install-disk.yaml \
--config-patch @patches/interface-names.yaml \
--config-patch @patches/kubelet-certs.yaml \
--config-patch @patches/custom-ca.yaml \
--config-patch-control-plane @patches/vip.yaml \
--output rendering/
```

Apply config:
```bash
talosctl apply-config -f rendering/controlplane.yaml -n 192.168.1.131 --insecure
talosctl apply-config -f rendering/controlplane.yaml -n 192.168.1.132 --insecure
talosctl apply-config -f rendering/controlplane.yaml -n 192.168.1.133 --insecure
```

Copy config:
```bash
cp rendering/talosconfig ~/.talos/config
```

Check config:
```bash
talosctl config contexts
```

Enable load blancing:
```bash
talosctl config endpoint 192.168.1.131 192.168.1.132 192.168.1.133
```

Monitor dashboard:
```bash
talosctl dashboard -n 192.168.1.131
```

Check joining:
```bash
talosctl get members -n 192.168.1.131
```

Bootstrap kubernetes:
```bash
talosctl bootstrap -n 192.168.1.131
```

Get the kubeconfig file:
```bash
talosctl kubeconfig -n 192.168.1.131
```

### Checking

You can chech services health:
```console
~#@❯ talosctl -n 192.168.1.130 services
NODE            SERVICE      STATE     HEALTH   LAST CHANGE    LAST EVENT
192.168.1.130   apid         Running   OK       9h7m12s ago    Health check successful
192.168.1.130   containerd   Running   OK       9h7m17s ago    Health check successful
192.168.1.130   cri          Running   OK       9h7m11s ago    Health check successful
192.168.1.130   dashboard    Running   ?        9h7m13s ago    Process Process(["/sbin/dashboard"]) started with PID 1564
192.168.1.130   etcd         Running   OK       8h59m31s ago   Health check successful
192.168.1.130   kubelet      Running   OK       9h6m26s ago    Health check successful
192.168.1.130   machined     Running   OK       9h7m22s ago    Health check successful
192.168.1.130   trustd       Running   OK       9h7m11s ago    Health check successful
192.168.1.130   udevd        Running   OK       9h7m14s ago    Health check successful
```

```console
~#@❯ talosctl containers -k -n 192.168.1.130
NODE            NAMESPACE   ID                                                                                         IMAGE                                                                     PID    STATUS
192.168.1.130   k8s.io      kube-system/cilium-lv7x5                                                                   registry.k8s.io/pause:3.8                                                 2528   SANDBOX_READY
192.168.1.130   k8s.io      └─ kube-system/cilium-lv7x5:cilium-agent:6c26406c01e1                                      sha256:1272788a112d1333fe684ab53b2784dc833e7bf6733238d651c7c9d0b7af6a49   3039   CONTAINER_RUNNING
192.168.1.130   k8s.io      └─ kube-system/cilium-lv7x5:clean-cilium-state:7a7461a4136e                                sha256:1272788a112d1333fe684ab53b2784dc833e7bf6733238d651c7c9d0b7af6a49   0      CONTAINER_EXITED
192.168.1.130   k8s.io      └─ kube-system/cilium-lv7x5:config:bc616221448d                                            sha256:1272788a112d1333fe684ab53b2784dc833e7bf6733238d651c7c9d0b7af6a49   0      CONTAINER_EXITED
192.168.1.130   k8s.io      └─ kube-system/cilium-lv7x5:install-cni-binaries:43d352e56863                              sha256:1272788a112d1333fe684ab53b2784dc833e7bf6733238d651c7c9d0b7af6a49   0      CONTAINER_EXITED
192.168.1.130   k8s.io      └─ kube-system/cilium-lv7x5:mount-bpf-fs:d15aa90c0326                                      sha256:1272788a112d1333fe684ab53b2784dc833e7bf6733238d651c7c9d0b7af6a49   0      CONTAINER_EXITED
192.168.1.130   k8s.io      kube-system/cilium-operator-7c6d7db485-6lpbs                                               registry.k8s.io/pause:3.8                                                 2526   SANDBOX_READY
192.168.1.130   k8s.io      └─ kube-system/cilium-operator-7c6d7db485-6lpbs:cilium-operator:7f5ad1a74097               sha256:ee1b5fd4c83a6d7dd4db7a77ebcbca0c1bb99b7ca68b042f7b3052b4f4846441   2746   CONTAINER_RUNNING
192.168.1.130   k8s.io      kube-system/kube-apiserver-talos-k8s-03                                                    registry.k8s.io/pause:3.8                                                 1992   SANDBOX_READY
192.168.1.130   k8s.io      └─ kube-system/kube-apiserver-talos-k8s-03:kube-apiserver:d87c068f8e28                     registry.k8s.io/kube-apiserver:v1.29.3                                    2136   CONTAINER_RUNNING
192.168.1.130   k8s.io      kube-system/kube-controller-manager-talos-k8s-03                                           registry.k8s.io/pause:3.8                                                 1996   SANDBOX_READY
192.168.1.130   k8s.io      └─ kube-system/kube-controller-manager-talos-k8s-03:kube-controller-manager:ae67cd1876f5   registry.k8s.io/kube-controller-manager:v1.29.3                           2401   CONTAINER_RUNNING
192.168.1.130   k8s.io      └─ kube-system/kube-controller-manager-talos-k8s-03:kube-controller-manager:c0e0982099b3   registry.k8s.io/kube-controller-manager:v1.29.3                           0      CONTAINER_EXITED
192.168.1.130   k8s.io      kube-system/kube-proxy-hm6w6                                                               registry.k8s.io/pause:3.8                                                 2539   SANDBOX_READY
192.168.1.130   k8s.io      └─ kube-system/kube-proxy-hm6w6:kube-proxy:15e11808cf06                                    registry.k8s.io/kube-proxy:v1.29.3                                        2585   CONTAINER_RUNNING
192.168.1.130   k8s.io      kube-system/kube-scheduler-talos-k8s-03                                                    registry.k8s.io/pause:3.8                                                 1995   SANDBOX_READY
192.168.1.130   k8s.io      └─ kube-system/kube-scheduler-talos-k8s-03:kube-scheduler:1e36ee2cf145                     registry.k8s.io/kube-scheduler:v1.29.3                                    0      CONTAINER_EXITED
192.168.1.130   k8s.io      └─ kube-system/kube-scheduler-talos-k8s-03:kube-scheduler:d096574d5f00                     registry.k8s.io/kube-scheduler:v1.29.3                                    2361   CONTAINER_RUNNING
```

If you need to patch a machine after install :
```bash
talosctl -n 192.168.1.133 patch mc -p @patches/example.yaml
```

or inline:
```bash
talosctl -n 192.168.1.131 patch mc -p '[{"op": "remove", "path": "/cluster/network/cni/urls"}]' -p '[{"op": "replace", "path": "/cluster/network/cni/name", "value": "none"}]'
```

### Upgrade Talos
Upgrade first node to new Talos OS version:
```bash
talosctl upgrade -i ghcr.io/siderolabs/installer:v1.8.1 -n 192.168.1.131
```

Cordon should start :

```console
NAME           STATUS                     ROLES           AGE    VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE         KERNEL-VERSION   CONTAINER-RUNTIME
talos-k8s-01   Ready,SchedulingDisabled   control-plane   200d   v1.29.3   192.168.1.131   <none>        Talos (v1.6.7)   6.1.82-talos     containerd://1.7.13
```

And once ready should display:
```console
NAME           STATUS   ROLES           AGE    VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE         KERNEL-VERSION   CONTAINER-RUNTIME
talos-k8s-01   Ready    control-plane   200d   v1.29.3   192.168.1.131   <none>        Talos (v1.8.1)   6.6.54-talos     containerd://2.0.0-rc.5
```

Keep updating other nodes.

Now you can upgrade Kubernetes version. First check out the correct path with `--dry-run` option:

```console
~#@❯ talosctl upgrade-k8s --to=1.31.1 -n 192.168.1.131 --dry-run
automatically detected the lowest Kubernetes version 1.29.3
unsupported upgrade path 1.29->1.31 (from "1.29.3" to "1.31.1")
```
Then adjust and upgrade finally:

```bash
talosctl upgrade-k8s --to=1.30.0 -n 192.168.1.131
```

### ArgoCD and ESO

First install ArgoCD with the init `values.yaml`:
```bash
helm upgrade -i argocd talos/bootstrap/ -f talos/bootstrap/values-init.yaml -n argocd --create-namespace 
```

then install `ApplicationSet` for External Secrets Operator:
```bash
kubectl apply -f talos/argoApps/external-secrets.yaml
```

Grant ESO SA for token reviwer permission on k8s API:
```bash
kubectl apply -f - <<EOF
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: role-tokenreview-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
  - kind: ServiceAccount
    name: eso-auth
    namespace: external-secrets
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: eso-auth
  namespace: external-secrets
---
apiVersion: v1
kind: Secret
type: kubernetes.io/service-account-token
metadata:
  name: eso-auth
  namespace: external-secrets
  annotations:
    kubernetes.io/service-account.name: "eso-auth"
EOF
```

Configure Vault k8s auth:
```bash
vault login -tls-skip-verify -address=https://vault.fredcorp.com
        
kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 --decode > ca.crt
TOKEN="$(kubectl get secret -n external-secrets eso-auth -o jsonpath='{.data.token}' | base64 -d)"

vault write -tls-skip-verify -address=https://vault.fredcorp.com auth/kubernetes/config token_reviewer_jwt="${TOKEN}" kubernetes_host="https://192.168.1.130:6443" kubernetes_ca_cert=@ca.crt disable_issuer_verification=true
```

```bash      
vault write -tls-skip-verify -address=https://vault.fredcorp.com auth/kubernetes/role/external-secrets bound_service_account_names=eso-auth bound_service_account_namespaces=external-secrets policies=secretstore ttl=24h
```

Create configMap for Vault certificate:
```bash
kubectl apply -f - <<EOF
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: fredcorp-pki-certs
  namespace: external-secrets
data:
  vault-pki-certs.pem: |
    -----BEGIN CERTIFICATE-----
    MIIErzCCA5egAwIBAgIUOCzHnMA4TtM2IzVN+JB7DKwX97cwDQYJKoZIhvcNAQEL
    BQAwazELMAkGA1UEBhMCRlIxDTALBgNVBAgTBE5vcmQxDjAMBgNVBAcTBUxpbGxl
    MREwDwYDVQQKEwhGUkVEQ09SUDELMAkGA1UECxMCSVQxHTAbBgNVBAMTFGZyZWRj
    b3JwLmNvbSBSb290IENBMB4XDTIxMTEwODEyNDEzMFoXDTM2MTEwNDEyNDIwMFow
    ajELMAkGA1UEBhMCRlIxDTALBgNVBAgTBE5vcmQxDjAMBgNVBAcTBUxpbGxlMREw
    DwYDVQQKEwhGUkVEQ09SUDELMAkGA1UECxMCSVQxHDAaBgNVBAMTE2ZyZWRjb3Jw
    LmNvbSBJTlQgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCTnpT1
    gke64n1Xs80SeRT/YDNTvuh6iZFPVP71I8JKEffHqQFzBwdsz5NnnW46ZOIp+jHK
    HbgZq1XjQYGqNzUrTM6mbUTDfmeJ0vcNieGq7vY0c4hPr+4u0HbP21Cj2Kv+cE0l
    TuP63ro4QN15aE+IbnUin2uZO6152x08tgl+DmsQ08ek5EFlsuYMoZJvKBSKqNRq
    VQC8+sJx4AbJv/NHhw6OwtLNgEqvlb9rv72G6QmBkXbwofSBxChBJwXzULByXHdA
    iWAUAsplkF7mVHzc7M7bKKbNvve+9tpXYiJ9vTtbmlqhvuej0NWga/9sAWE+MZ2q
    iKA+RktYizXqUg0TAgMBAAGjggFKMIIBRjAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0T
    AQH/BAUwAwEB/zAdBgNVHQ4EFgQU3t6Xv6DuBTsQTl06yhwgLXmkxjUwHwYDVR0j
    BBgwFoAU6X0TA2ic6+vcWFsH1GUyUPpz2z4wdwYIKwYBBQUHAQEEazBpMDUGCCsG
    AQUFBzAChilodHRwczovL3ZhdWx0LmZyZWRjb3JwLmNvbTo4MjAwL3YxL3BraS9j
    YTAwBggrBgEFBQcwAoYkaHR0cHM6Ly92YXVsdC5mcmVkY29ycC5jb20vdjEvcGtp
    L2NhMGoGA1UdHwRjMGEwMaAvoC2GK2h0dHBzOi8vdmF1bHQuZnJlZGNvcnAuY29t
    OjgyMDAvdjEvcGtpL2NybCIwLKAqoCiGJmh0dHBzOi8vdmF1bHQuZnJlZGNvcnAu
    Y29tL3YxL3BraS9jcmwiMA0GCSqGSIb3DQEBCwUAA4IBAQCFROitTOJp1sb9o6x4
    dfrH4uUH2k7voe8OIqD8KjmunKjRE6VvnDPXV3wHnjJIqEUbnvFWscKZmKN5dYLc
    1p6EB8m+Xggpwt+dM1iXJ3rzrYH5t6BeD1WSwGOVQNFSEg5ty3QrdccwtJ3jXhXo
    6U9zc7Uc7B1OJYWi/NHfdn1aSBNUEAglaACG7h9rb7FBKlt2hGsQ9SGnEFtEvJmk
    0MbXaB+HWZveVMODKTllyMiQTG0QWquEcAWGkBrn2XmwGmIP2wDQtAZKuiEVjw5N
    Phg9QLyjizbOqHj7w7kNs4uyXBKl6QFxOt55SvpVZ+0N2EDRFsdF8WJGqElLP3F1
    Ugv3
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    MIIDxzCCAq+gAwIBAgIUAIOOFp/kn//KT5+E9YsoAgi4h0YwDQYJKoZIhvcNAQEL
    BQAwazELMAkGA1UEBhMCRlIxDTALBgNVBAgTBE5vcmQxDjAMBgNVBAcTBUxpbGxl
    MREwDwYDVQQKEwhGUkVEQ09SUDELMAkGA1UECxMCSVQxHTAbBgNVBAMTFGZyZWRj
    b3JwLmNvbSBSb290IENBMB4XDTIxMTEwODEyMzUxMFoXDTM2MTEwNDEyMzU0MFow
    azELMAkGA1UEBhMCRlIxDTALBgNVBAgTBE5vcmQxDjAMBgNVBAcTBUxpbGxlMREw
    DwYDVQQKEwhGUkVEQ09SUDELMAkGA1UECxMCSVQxHTAbBgNVBAMTFGZyZWRjb3Jw
    LmNvbSBSb290IENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2cJC
    8i4Ep06zWa2IJBomIQKQwCQCuWbGvHG1iFfsCJ4tRC8QC4BYWo0298TJklpogBat
    +TQsy50wH+Xhxtcw+N84EKF3sVpNlNZOwrqlpcK04TNzcXGGXzB9DPTfobAx50t7
    /VgEJAncDAXFsN91s7IZs16mSP53e5tOfUeJE92z45+idqgGHJ/173d66t34KBGy
    /tvuts5+gain0wkgaz44ZKdyM4jVKWk+HccpG9qf3TbhwQvFmqPbzcHIUmJTgdZh
    KnJ/KthAUVTwvMi57ZlemKv2fVLTOCbgjdtjqdcCJcpdHSXN858uRSuGoyMW+uac
    R+yXRe2GmWJf+vK9bwIDAQABo2MwYTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/
    BAUwAwEB/zAdBgNVHQ4EFgQU6X0TA2ic6+vcWFsH1GUyUPpz2z4wHwYDVR0jBBgw
    FoAU6X0TA2ic6+vcWFsH1GUyUPpz2z4wDQYJKoZIhvcNAQELBQADggEBAEvcAI41
    3vYDbpQbB7kL/teuW/Smxx/mOMyTmNxKOotUDf47Z0U8/1n7yApmbAHP3myHdxtT
    ieQ0ia4fi+gRoueCAZXOzctptrnZ57Ocd5uuX8Hzwxwa+diqi5+HwhJsfYdAX062
    x+fN/NknYnP11RoJlHwm9EAf9mjqqW6AspHV1zAaf2sPCKyGqWyuTpGAgnkbR0x6
    G1bl4NAeZk+x9SvvHM8E/B7OQ1Xq03RyEVJylFqJZnb2TGPPcpNLRWya8L422vaw
    GF1wBuQQrmjqX7I1ix3TeYdcxqsJJVslR7iTrdyzgz8KMU4yBjNKdOF1eMx/xIAu
    xw+ozAYOQ7kyZD0=
    -----END CERTIFICATE-----
EOF
```

Create ClusterSecretStore:
```bash
kubectl apply -f - <<EOF
---
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: admin
spec:
  provider:
    vault:
      server: "https://vault.fredcorp.com"
      path: "admin"
      version: "v2"
      caProvider:
        type: "ConfigMap"
        namespace: "external-secrets"
        name: "fredcorp-pki-certs"
        key: "vault-pki-certs.pem"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "external-secrets"
          serviceAccountRef:
            name: "eso-auth"
            namespace: external-secrets
          secretRef:
            name: "eso-auth"
            key: "token"
            namespace: external-secrets
EOF
```

Then bootstrap final ArgoCD app of apps:
```bash
helm upgrade -i argocd talos/bootstrap/ -f talos/bootstrap/values-full.yaml -n argocd --create-namespace --set apps.enabled=false --set updater.enabled=false
helm upgrade -i argocd talos/bootstrap/ -f talos/bootstrap/values-full.yaml -n argocd --create-namespace --set apps.enabled=true --set updater.enabled=true
```
### Metallb
Some applications (e.g. Prometheus node exporter or storage solutions) require more relaxed Pod Security Standards, which can be configured by either updating the Pod Security Admission plugin configuration, or by using the pod-security.kubernetes.io/enforce label on the namespace level:

- https://kubernetes.io/docs/concepts/security/pod-security-admission/

```bash
kubectl label namespace NAMESPACE-NAME pod-security.kubernetes.io/enforce=privileged
```
For `metallb` for example you can add following SyncOption:
```yaml
        managedNamespaceMetadata:
          labels:
            pod-security.kubernetes.io/enforce: privileged
```
### Certmanager

Update ClusterRoleBinding and create SA and token:
```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: role-tokenreview-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
  - kind: ServiceAccount
    name: eso-auth
    namespace: external-secrets
  - kind: ServiceAccount
    name: certmanager-auth
    namespace: cert-manager
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: certmanager-auth
  namespace: cert-manager
---
apiVersion: v1
kind: Secret
type: kubernetes.io/service-account-token
metadata:
  name: certmanager-auth
  namespace: cert-manager
  annotations:
    kubernetes.io/service-account.name: "certmanager-auth"
```

For Cert manager:
```bash
vault write -tls-skip-verify -address=https://vault.fredcorp.com auth/kubernetes/role/cert-manager bound_service_account_names=certmanager-auth bound_service_account_namespaces=cert-manager policies=pki_fredcorp ttl=24h
```

You can now deploy Nginx ingress controller and set `ingress.enabled=true` for ArgoCD.