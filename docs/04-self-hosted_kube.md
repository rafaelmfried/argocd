# Workflow local com Runner Self-Hosted + Registry privado (k3d)

Este guia mostra um fluxo completo **100% local** usando:

- **k3d** como cluster Kubernetes
- **Actions Runner Controller (ARC)** para runner self-hosted dentro do cluster
- **Registry privado dentro do cluster** (sem expor na internet)
- **ArgoCD** para aplicar os manifests

A ideia e: o runner builda a imagem, envia para o registry interno e atualiza os manifests que o ArgoCD sincroniza.

---

## 1) Aplicar os manifests de cluster (registry + nodeport do app)

Os manifests de cluster ja estao em `cluster-manifests`:

```bash
kubectl apply -k cluster-manifests
```

- **Registry**: Service `local-registry` (NodePort 30000)
- **App NodePort**: Service `testapp-nodeport` (NodePort 30080)

> Para acessar o registry pelo host (opcional):
>
> ```bash
> k3d cluster edit <nome-do-cluster> --port-add 5001:30000@loadbalancer
> ```
>
> Assim o push fica em `localhost:5001`.

---

## 2) Instalar o Actions Runner Controller (ARC)

Siga a doc oficial do ARC. Exemplo resumido:

```bash
kubectl create namespace actions-runner-system
helm repo add -n actions-runner-system actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true
helm install arc -n actions-runner-system actions-runner-controller/actions-runner-controller
```

### 2.1) Criar o GitHub PAT (token)

**Onde criar o token:**

1. Clique na sua foto (canto superior direito) → **Settings** (do _usuário_, não da organização)
2. Menu lateral → **Developer settings** → **Personal access tokens**
3. Crie um token

**Nome sugerido do token (Token name):**

```
arc-k3d-local
```

**Scopes mínimos recomendados:**

- **Fine‑grained token (recomendado):** acesso ao repositório (Read/Write) + **Actions**
- **Classic token:** `repo` e `workflow`

> Se você não vê “Developer settings”, provavelmente está nas Settings da organização. Volte para as Settings do seu usuário.

### 2.2) Criar o secret no cluster

Crie um secret com o **GitHub PAT** (repo + workflow scopes):

```bash
read -s GITHUB_PAT
kubectl create secret generic controller-manager \
  -n actions-runner-system \
  --from-literal=github_token="$GITHUB_PAT"
unset GITHUB_PAT
```

> Dica: desse jeito o PAT nao aparece no output nem fica no historico do shell.

**Proximo passo apos copiar o PAT:** cole o token quando o terminal pedir (o cursor nao mostra nada) e pressione **Enter**. Em seguida, siga para o RunnerDeployment (passo 3).

---

## 3) RunnerDeployment (com Docker-in-Docker)

Para buildar imagens, habilite Docker dentro do runner:

```yaml
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: testapp-runner
  namespace: actions-runner-system
spec:
  replicas: 1
  template:
    spec:
      image: summerwind/actions-runner-dind:latest
      repository: <seu-usuario>/<seu-repo>
      labels:
        - self-hosted
        - linux
        - k3d
      dockerdWithinRunnerContainer: true
      env:
        - name: DOCKER_INSECURE_REGISTRY
          value: "local-registry.default.svc.cluster.local:5000"
```

Aplique:

```bash
kubectl apply -f path/to/runner-deployment.yaml
```

> **Importante:** quando `dockerdWithinRunnerContainer: true`, use uma imagem com Docker embutido (ex.: `summerwind/actions-runner-dind`). Caso contrario, o runner sobe mas o Docker nao inicia (`Cannot connect to the Docker daemon`).
>
> Esse `env` gera o seguinte `daemon.json` dentro do runner:
>
> ```json
> {"insecure-registries":["local-registry.default.svc.cluster.local:5000"]}
> ```

---

## 4) Workflow completo (build + push local + update manifests)

Exemplo de workflow usando **runner self-hosted** e **registry interno**.

### 4.1) Variaveis/valores que voce precisa ter em maos

Antes de criar o workflow, separe os seguintes valores:

- **Repositorio alvo do runner**: `rafaelmfried/testapp`  
  - Vem da sua URL `git@github.com:rafaelmfried/testapp.git`.
- **Namespace do registry**: `local-registry.default.svc.cluster.local:5000`  
  - E o Service interno do cluster (`local-registry` no namespace `default`).
- **Imagem usada pelo cluster**: `localhost:30000/testapp:<TAG>`  
  - O NodePort `30000` esta em `cluster-manifests/registry.yaml`.
- **TAG da imagem**: `\${{ github.sha }}`  
  - Ja vem do GitHub Actions (commit atual).

### 4.2) Secrets (se necessario)

Este workflow **nao precisa de Docker Hub**, mas pode precisar dos seguintes secrets:

- **`ARGOCD_AUTH_TOKEN`** (opcional, so se quiser forcar sync)  
  - Crie no ArgoCD (ver `docs/01-argocd.md`) e salve no GitHub em **Settings → Secrets and variables → Actions**.
  - No workflow, use com `argocd login ... --auth-token`.

Se voce quiser adicionar o secret no GitHub:
1. Repositorio → **Settings**  
2. **Secrets and variables** → **Actions** → **New repository secret**  
3. Nome do secret (ex.: `ARGOCD_AUTH_TOKEN`) e valor do token.

```yaml
name: CI/CD Local

on:
  push:
    branches: ["main"]

permissions:
  contents: write

jobs:
  build-push-update:
    runs-on: [self-hosted, linux, k3d]

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Build image
        run: |
          docker buildx build \
            --platform linux/arm64 \
            -t local-registry.default.svc.cluster.local:5000/testapp:${{ github.sha }} \
            -f testapp/docker/Dockerfile.testapp testapp

      - name: Push image (registry interno)
        run: |
          docker push local-registry.default.svc.cluster.local:5000/testapp:${{ github.sha }}

      - name: Update manifests (imagem usada pelo cluster)
        run: |
          sed -i "s|image: localhost:30000/testapp:.*|image: localhost:30000/testapp:${{ github.sha }}|" testapp-manifests/deployment.yaml
          sed -i "s|image: localhost:30000/testapp:.*|image: localhost:30000/testapp:${{ github.sha }}|" testapp-manifests/pod.yaml

      - name: Commit e push dos manifests
        run: |
          git config user.name "github-actions"
          git config user.email "github-actions@users.noreply.github.com"
          git add testapp-manifests/deployment.yaml testapp-manifests/pod.yaml
          git commit -m "chore: update image to ${{ github.sha }}" || exit 0
          git push

      # Opcional: sincronizar via ArgoCD (requer argocd CLI no runner)
      - name: Install ArgoCD CLI
        run: |
          ARCH="$(uname -m)"
          case "$ARCH" in
            x86_64) ARCH="amd64" ;;
            aarch64|arm64) ARCH="arm64" ;;
            *) echo "Arquitetura nao suportada: $ARCH"; exit 1 ;;
          esac
          curl -sSL -o /usr/local/bin/argocd "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-${ARCH}"
          chmod +x /usr/local/bin/argocd

      - name: Sync ArgoCD
        run: |
          argocd login argocd-server.argocd.svc.cluster.local --auth-token ${{ secrets.ARGOCD_AUTH_TOKEN }} --insecure
          argocd app sync testapp
```

### Por que duas imagens/enderecos?

- O **runner** empurra para `local-registry...:5000` (Service interno do cluster).
- O **cluster** puxa usando `localhost:30000` (NodePort do registry para os nos).

> Se o push falhar com erro de HTTPS, configure o Docker-in-Docker do runner para permitir registry inseguro.

---

## 5) Acessar a aplicacao

Mapeie a porta do NodePort para o host:

```bash
k3d cluster edit <nome-do-cluster> --port-add 8081:30080@loadbalancer
```

Teste:

```bash
curl http://localhost:8081/healthz
```

---

## Observacoes

- Se o runner for **no host** (fora do cluster), troque o push para `localhost:5001`.
- Se o build falhar por tag do Node, use `--platform linux/arm64`.
- Para ambientes sem internet, mantenha as imagens base ja baixadas no host.
