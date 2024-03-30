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

Generate secrets:
```bash
talosctl gen secrets
```

Generate config:
```bash
talosctl gen config talos-k8s-fredcorp https://192.168.1.130:6443
```