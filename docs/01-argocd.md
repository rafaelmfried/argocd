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

9. **Criar o ARGOCD_AUTH_TOKEN (para automacao)**
   Para gerar um token de API e usar em automacoes (ex.: GitHub Actions):

   ```bash
   argocd login localhost:8080 --username admin --password <SENHA> --insecure
   argocd account generate-token --account admin
   ```

   Copie o token gerado e salve como secret no GitHub:
   - Repositorio → **Settings** → **Secrets and variables** → **Actions**
   - **New repository secret** → `ARGOCD_AUTH_TOKEN`

   > Dica: se voce tiver RBAC, crie uma conta dedicada ao CI com permissao apenas de sync.

10. **Robot do ArgoCD (conta de automacao)**
    Um _robot_ e uma conta dedicada para CI/CD, com permissao **minima** e token proprio.
    Vantagens:

- Evita usar o token do admin
- Permissoes controladas por RBAC
- Facilita rotacao e revogacao

**Passo 1: criar a conta no argocd-cm**

```bash
kubectl -n argocd patch configmap argocd-cm --type merge -p '
data:
  accounts.ci-bot: apiKey
'
```

**Passo 2: dar permissoes minimas no argocd-rbac-cm**
Exemplo: permitir `get` e `sync` apenas na app `default/testapp`:

```bash
kubectl -n argocd patch configmap argocd-rbac-cm --type merge -p '
data:
  policy.csv: |
    p, role:ci-bot, applications, get, default/testapp, allow
    p, role:ci-bot, applications, sync, default/testapp, allow
    g, ci-bot, role:ci-bot
'
```

**Passo 3: gerar o token do robot**

```bash
argocd login localhost:8080 --username admin --password <SENHA> --insecure
argocd account generate-token --account ci-bot
```

Salve o token no GitHub (Secrets → Actions) como `ARGOCD_AUTH_TOKEN`.

**Uso tipico no CI:**

```bash
argocd login argocd-server.argocd.svc.cluster.local --auth-token $ARGOCD_AUTH_TOKEN --insecure
argocd app sync testapp
```

**Revogar/rotacionar:**

- Gere um novo token e atualize o secret no GitHub.
- Para revogar, remova a conta `accounts.ci-bot` e o RBAC correspondente.

11. **Comandos Uteis do ArgoCD**

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

- PortForward do ArgoCD Server:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
