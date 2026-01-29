# GitHub Actions com Runner Auto-Hospedado

Além de usar os runners hospedados pelo GitHub, você pode configurar seus próprios runners auto-hospedados para executar seus workflows do GitHub Actions. Isso pode ser útil se você precisar de mais controle sobre o ambiente de execução, quiser usar hardware específico ou precisar de acesso a recursos internos da sua rede como o registry privado de imagens de containers.

## Configurando um Runner Auto-Hospedado

Para configurar um runner auto-hospedado, siga estes passos:

1. Acesse o repositório no GitHub onde você deseja adicionar o runner.
2. Vá para a aba "Settings" (Configurações) do repositório.
3. No menu lateral, clique em "Actions" e depois em "Runners".
4. Clique em "Add runner" (Adicionar runner) e siga as instruções para baixar e configurar o software do runner no seu servidor.
5. Após a configuração, o runner estará disponível para ser usado nos seus workflows.

## Usando o Runner Auto-Hospedado em um Workflow

Para usar o runner auto-hospedado em um workflow, você precisa especificar o rótulo do runner na seção `runs-on` do job. Aqui está um exemplo de como fazer isso:

```yaml
name: CI with Self-Hosted Runner
on:
  push:
    branches:
      - main
jobs:
  build:
    runs-on: self-hosted
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      - name: Build Project
        run: |
          echo "Building the project..."
      - name: Run Tests
        run: |
          echo "Running tests..."
```

Neste exemplo, o job `build` será executado no runner auto-hospedado que você configurou. Certifique-se de que o runner esteja online e disponível para que o workflow possa ser executado com sucesso.

## Usando Runners Auto-Hospedados com Docker em registries Privados

Se o seu runner auto-hospedado precisa acessar um registry privado de Docker ou outros recursos em uma rede privada, você pode configurar o ambiente do runner para ter acesso a esses recursos. Isso pode incluir a configuração de variáveis de ambiente, autenticação com o registry privado e configuração de redes. Aqui está um exemplo de como configurar o login em um registry privado dentro do seu workflow:

```yaml
jobs:
  build-and-push:
    runs-on: self-hosted
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      - name: Log in to Private Docker Registry
        run: |
          echo ${{ secrets.PRIVATE_REGISTRY_PASSWORD }} | docker login myprivateregistry.com -u ${{ secrets.PRIVATE_REGISTRY_USERNAME }} --password-stdin
      - name: Build and push Docker image
        run: |
          docker build -t myprivateregistry.com/myimage:latest .
          docker push myprivateregistry.com/myimage:latest
```

## Usando Runners Auto-Hospedados com Workflows Paralelos

Você também pode configurar múltiplos runners auto-hospedados para executar jobs em paralelo. Basta adicionar mais runners ao seu repositório e configurar seus workflows para usar esses runners conforme necessário. O GitHub Actions gerenciará a distribuição dos jobs entre os runners disponíveis.

```yaml
jobs:
  test:
    runs-on: self-hosted
    strategy:
      matrix:
        runner: [runner1, runner2, runner3]
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      - name: Run Tests
        run: |
          echo "Running tests on ${{ matrix.runner }}..."
```

## Usando Runners Auto-Hospedados com Etiquetas Personalizadas

Você pode atribuir etiquetas personalizadas aos seus runners auto-hospedados para diferenciá-los e direcionar jobs específicos para determinados runners. Ao configurar o runner, você pode adicionar etiquetas que podem ser usadas na seção `runs-on` do job. Aqui está um exemplo:

```yaml
jobs:
  deploy:
    runs-on: [self-hosted, linux, high-memory]
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      - name: Deploy Application
        run: |
          echo "Deploying application on high-memory runner..."
```

## Considerações de Segurança

Ao usar runners auto-hospedados, é importante considerar as implicações de segurança. Certifique-se de que o servidor onde o runner está instalado esteja protegido e atualizado, e que apenas pessoas autorizadas tenham acesso a ele. Além disso, evite executar workflows não confiáveis em runners auto-hospedados, pois eles podem ter acesso a recursos sensíveis na sua rede.

## Monitoramento e Manutenção

Monitore o status dos seus runners auto-hospedados regularmente para garantir que eles estejam funcionando corretamente. O GitHub fornece informações sobre o status dos runners na seção de configurações do repositório. Além disso, mantenha o software do runner atualizado para aproveitar as últimas melhorias e correções de segurança.
Com essas etapas, você estará pronto para usar runners auto-hospedados com o GitHub Actions, proporcionando mais flexibilidade e controle sobre o ambiente de execução dos seus workflows.
