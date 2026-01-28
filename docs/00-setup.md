# Setup

## Descricao

Para configurar o ambiente precisamos de um cluster Kubernetes funcional. Este guia irá orientá-lo através dos passos necessários para configurar o ambiente.

## Requisitos

Antes de começar, certifique-se de que você tem o seguinte:
[] k3d instalado em sua máquina. Você pode seguir as instruções de instalação no [repositório oficial do k3d](https://k3d.io/#installation).
[] kubectl instalado para interagir com o cluster Kubernetes. Instruções de instalação podem ser encontradas na [documentação oficial do kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/).

## Passos para Configuração

1. **Criar o Cluster k3d**
   Execute o seguinte comando para criar um cluster k3d com o nome `<nome-do-cluster>`:

   ```bash
   k3d cluster create <nome-do-cluster>
   ```

   Isso criará um cluster Kubernetes leve usando k3d.

2. **Verificar o Cluster**
   Após a criação do cluster, verifique se ele está funcionando corretamente com o comando:

   ```bash
   kubectl cluster-info
   ```

   Você deve ver informações sobre o cluster, confirmando que ele está ativo.

3. **Configurar o Contexto do kubectl**
   Certifique-se de que o kubectl está configurado para usar o contexto do cluster recém-criado:
   ```bash
   kubectl config use-context k3d-<nome-do-cluster>
   ```
   Substitua `<nome-do-cluster>` pelo nome que você escolheu ao criar o cluster.
4. **Verificar os Nós do Cluster**
   Verifique os nós do cluster para garantir que tudo está funcionando corretamente:
   ```bash
   kubectl get nodes
   ```
   Você deve ver uma lista dos nós do cluster com o status "Ready".
5. **Pronto para Usar**
   Agora você está pronto para usar o cluster Kubernetes criado com k3d. Você pode começar a implantar aplicativos e serviços no cluster.
