# Github Actions

## Descricao

Agora vamos mergulhar no mundo do GitHub Actions! Nosso objetivo é automatizar o processo de build e deploy do nosso projeto Node.js usando essa poderosa ferramenta de CI/CD integrada ao GitHub. Com o GitHub Actions, podemos criar fluxos de trabalho personalizados que serão acionados por eventos específicos, como push ou pull request.

## Configuração do Workflow

Para começar, precisamos criar um arquivo de workflow no diretório `.github/workflows` do nosso repositório. Vamos nomear esse arquivo como `ci-cd.yml`. Aqui está um exemplo básico de configuração para o nosso projeto Node.js:

```yaml
name: CI/CD Pipeline
on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      - name: Set up Node.js
        uses: actions/setup-node@v2
        with:
          node-version: "14"
      - name: Install dependencies
        run: npm install
      - name: Run tests
        run: npm test
  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      - name: Deploy to Production
        run: echo "Deploying to production server..."
```

Neste exemplo, o workflow é acionado em push ou pull request para a branch `main`. Ele consiste em dois jobs: `build` e `deploy`. O job `build` faz o checkout do código, configura o Node.js, instala as dependências e executa os testes. O job `deploy` depende do job `build` e realiza o deploy (neste caso, apenas um comando de echo como exemplo).

## Actions, Jobs e Steps

No GitHub Actions, um workflow é composto por jobs, e cada job é composto por steps. As actions são blocos reutilizáveis de código que podem ser usadas dentro dos steps para realizar tarefas específicas, como fazer checkout do código, configurar o ambiente, instalar dependências, etc.

## Configurando Push de Imagens Docker para o Registry

Para configurar o push de imagens Docker para um registry, você pode adicionar etapas adicionais ao seu workflow. Aqui está um exemplo de como fazer isso:

```yaml
build-and-push:
  runs-on: ubuntu-latest
  steps:
    - name: Checkout code
      uses: actions/checkout@v2
    - name: Log in to Docker Hub
      uses: docker/login-action@v2
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}
    - name: Build and push Docker image
      uses: docker/build-push-action@v2
      with:
        context: .
        push: true
        tags: your-dockerhub-username/your-image-name:latest
```

## Deploy para Servidor de Produção usando ArgoCD

Para fazer o deploy para um servidor de produção usando ArgoCD, você pode adicionar um job específico para isso. Aqui está um exemplo:

```yaml
deploy:
  needs: build-and-push
  runs-on: ubuntu-latest
  steps:
    - name: Checkout code
      uses: actions/checkout@v2
    - name: Deploy to Production with ArgoCD
      run: |
        argocd login your-argocd-server --username ${{ secrets.ARGOCD_USERNAME }} --password ${{ secrets.ARGOCD_PASSWORD }}
        argocd app sync your-app-name
```

## Atualizando image tag no manifesto Kubernetes

Para atualizar a tag da imagem no manifesto Kubernetes, você pode usar uma etapa adicional no seu workflow. Aqui está um exemplo de como fazer isso:

```yaml
update-k8s-manifest:
  needs: build-and-push
  runs-on: ubuntu-latest
  steps:
    - name: Checkout code
      uses: actions/checkout@v2
    - name: Update image tag in Kubernetes manifest
      run: |
        sed -i 's|image: your-dockerhub-username/your-image-name:.*|image: your-dockerhub-username/your-image-name:latest|' path/to/your/k8s-manifest.yaml
```

## Usando o robot do ArgoCD

Para usar o robot do ArgoCD, você pode configurar um token de acesso e usá-lo para autenticar suas operações. Aqui está um exemplo de como fazer isso:
Ele tem como funcao automatizar o deploy sem a necessidade de usar nome de usuario e senha.

```yaml
deploy:
  needs: build-and-push
  runs-on: ubuntu-latest
  steps:
    - name: Checkout code
      uses: actions/checkout@v2
    - name: Deploy to Production with ArgoCD Robot
      run: |
        argocd login your-argocd-server --token ${{ secrets.ARGOCD_ROBOT_TOKEN }}
        argocd app sync your-app-name
```

## Pipeline Completo

Aqui está um exemplo completo de um pipeline de CI/CD usando GitHub Actions, que inclui build, push de imagem Docker, atualização do manifesto Kubernetes e deploy com ArgoCD:

```yaml
name: CI/CD Pipeline
on:
  push:
    branches:
      - main
jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      - name: Log in to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      - name: Build and push Docker image
        uses: docker/build-push-action@v2
        with:
          context: .
          push: true
          tags: your-dockerhub-username/your-image-name:latest
  update-k8s-manifest:
    needs: build-and-push
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      - name: Update image tag in Kubernetes manifest
        run: |
          sed -i 's|image: your-dockerhub-username/your-image-name:.*|image: your-dockerhub-username/your-image-name:latest|' path/to/your/k8s-manifest.yaml
  deploy:
    needs: update-k8s-manifest
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      - name: Deploy to Production with ArgoCD Robot
        run: |
          argocd login your-argocd-server --token ${{ secrets.ARGOCD_ROBOT_TOKEN }}
          argocd app sync your-app-name
```

Neste pipeline completo, temos três jobs: `build-and-push`, `update-k8s-manifest` e `deploy`. Cada job depende do anterior, garantindo que o processo seja executado na ordem correta.

## Ponto de Atenção

Ao configurar o GitHub Actions, é importante atentar para a segurança das suas credenciais. Utilize os [GitHub Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets) para armazenar informações sensíveis, como tokens de acesso e senhas, garantindo que elas não fiquem expostas no código do seu workflow.
Verifique se o image registry privado que está utilizando é acessível a partir do ambiente onde o GitHub Actions está sendo executado. Isso pode envolver configurar autenticação adequada e/ou permissões de rede.

## Personalização

Você pode personalizar esse workflow de acordo com as necessidades do seu projeto. Por exemplo, você pode adicionar etapas para linting, geração de relatórios de cobertura de código, ou até mesmo integrar com serviços de terceiros para notificações. Além disso, você pode configurar variáveis de ambiente e segredos no GitHub para proteger informações sensíveis, como tokens de acesso.
Lembre-se de consultar a [documentação oficial do GitHub Actions](https://docs.github.com/en/actions) para explorar todas as possibilidades e recursos disponíveis. Com o GitHub Actions, você pode criar pipelines de CI/CD robustos e eficientes para garantir a qualidade e a entrega contínua do seu software!
