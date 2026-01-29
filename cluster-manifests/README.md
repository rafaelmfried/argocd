# Registry local

Manifests Kubernetes para o registry interno usado no cluster.

## Como aplicar

```bash
kubectl apply -f cluster-manifests/registry.yaml
```

## Observacoes

- O Service expõe o registry via NodePort `30000` para acesso dos nós.
- Para publicar imagens pelo host com k3d, mapeie a porta do host para o NodePort:
  ```bash
  k3d cluster edit <nome-do-cluster> --port-add 5001:30000@loadbalancer
  ```
  Depois use `localhost:5001` no `docker push`.
