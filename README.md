# Infra

## k0s 

### Bootstrap

Initialize and customize your cluster plain YAML definition:
```bash
k0sctl init --k0s > k0sctl.yaml
```

Apply your cahnges:
```bash
k0sctl apply --config k0sctl.yaml --disable-telemetry --debug
```

Fetch the kubeconfig for your cluster
```bash
k0sctl kubeconfig --disable-telemetry
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