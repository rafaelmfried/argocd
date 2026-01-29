# ArgoCD

## Comandos

1. **Criar uma aplicação no ArgoCD**
   Para criar uma aplicação no ArgoCD que aponte para o repositório Git contendo os manifests do Kubernetes, use o seguinte comando:

   ```bash
   argocd app create testapp \
    --repo <url_do_repositorio_git> \
    --path <path_dos_manifests> \
    --dest-server <endereco_do_cluster> \
    --dest-namespace <nome_do_namespace>
   ```

   Substitua `<url_do_repositorio_git>`, `<path_dos_manifests>`, `<endereco_do_cluster>`, e `<nome_do_namespace>` pelos valores apropriados para o seu ambiente.

2. **Subir o registry no cluster**
   Aplique o manifesto do registry local:

   ```bash
   kubectl apply -f cluster-manifests/registry.yaml
   ```

3. **Expor o registry no host (k3d)**
   Mapeie a porta do host para o NodePort do registry (30000) usando o load balancer do k3d:

   ```bash
   k3d cluster edit <nome-do-cluster> --port-add 5001:30000@loadbalancer
   ```

   Se você ainda vai criar o cluster, pode usar:

   ```bash
   k3d cluster create <nome-do-cluster> --port "5001:30000@loadbalancer"
   ```

4. **Buildar e publicar a imagem no registry interno**
   Gere a imagem da aplicação e publique no registry interno (agora acessível via `localhost:5001`).
   Para k3d em Mac (arm64), use `--platform linux/arm64`:

   ```bash
   docker buildx build --platform linux/arm64 -t localhost:5001/testapp:latest -f testapp/docker/Dockerfile.testapp testapp
   docker push localhost:5001/testapp:latest
   ```

5. **Atualizar os manifests para usar o registry interno**
   Altere `image:` nos manifests para apontar para o NodePort do registry (acesso dos nós):

   ```yaml
   image: localhost:30000/testapp:latest
   ```

   O NodePort `30000` está definido em `cluster-manifests/registry.yaml`. Se você mudar a porta, atualize aqui também.

   Se o pull falhar com erro de HTTPS, configure o k3d para permitir registry inseguro em `localhost:30000` usando `registries.yaml` no cluster.

6. **Sincronizar a aplicacao**
   Para sincronizar a aplicação criada no ArgoCD e aplicar os manifests no cluster Kubernetes, use o comando:

   ```bash
   argocd app sync testapp
   ```

7. **Acessar a aplicacao no navegador (NodePort)**
   O acesso externo do `testapp` é feito pelos manifests de cluster:

   ```bash
   kubectl apply -k cluster-manifests
   k3d cluster edit <nome-do-cluster> --port-add 8081:30080@loadbalancer
   ```

   A rota disponível é `GET /healthz`, então teste em:

   ```bash
   http://localhost:8081/healthz
   ```

8. **Expor o ArgoCD sem port-forward (LoadBalancer + kustomize)**
   A documentação oficial recomenda expor o `argocd-server` via Service do tipo `LoadBalancer`. Para aplicar/remover facilmente, este repositório cria um Service adicional com esse tipo:

   ```bash
   kubectl apply -k argocd-manifests
   ```

   Confira o `EXTERNAL-IP` e a porta:

   ```bash
   kubectl get svc -n argocd argocd-server-lb
   ```

   Se o seu k3d mapeia a porta 80 do load balancer para o host 8080, acesse `https://localhost:8080`.
   Para remover:

   ```bash
   kubectl delete -k argocd-manifests
   ```

9. **Comandos Uteis do ArgoCD**
   - Listar aplicações:
     ```bash
     argocd app list
     ```
   - Sincronizar uma aplicação:
     ```bash
     argocd app sync <nome_da_aplicacao>
     ```
   - Verificar o status de uma aplicação:
     ```bash
     argocd app get <nome_da_aplicacao>
     ```
   - Excluir uma aplicação:
     ```bash
     argocd app delete <nome_da_aplicacao>
     ```
