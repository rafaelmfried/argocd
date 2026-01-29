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

6. **Criar um Namespace para ArgoCD**
   É uma boa prática criar um namespace dedicado para o ArgoCD:

   ```bash
   kubectl create namespace argocd
   ```

7. **Instalar o Manifesto do ArgoCD**
   Instale o manifesto oficial do ArgoCD para configurar o ArgoCD no cluster:

   ```bash
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```

8. **Instalar o ArgoCD CLI**
   Se desejar interagir com o ArgoCD via linha de comando, você pode instalar o ArgoCD CLI seguindo as instruções na [documentação oficial do ArgoCD](https://argo-cd.readthedocs.io/en/stable/cli_installation/).

9. **Fazer PortFowarding do ArgoCD**
   Para acessar a interface web do ArgoCD, você pode fazer o port forwarding do serviço ArgoCD Server:

   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```

   Agora você pode acessar o ArgoCD em seu navegador através do endereço `https://localhost:8080`.

10. **Pegar o Initial Secret do ArgoCD**
    O nome de usuário padrão é `admin`. Para obter a senha inicial, execute o seguinte comando:

    ```bash
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
    ```

    Use essa senha para fazer login na interface web do ArgoCD.

11. **Logar no ArgoCD cli**
    Para logar no ArgoCD via CLI, use o comando:

    ```bash
    argocd login localhost:8080
    ```

    Insira o nome de usuário `admin` e a senha obtida no passo anterior.

12. **Verificar em que Cluster o ArgoCD está Apontando**
    Para verificar em qual cluster o ArgoCD está apontando, use o comando:

    ```bash
    argocd cluster list
    ```

13. **Apontar para o nosso Cluster k3d**
    13.1. **Pegar o Context do kubectl**
    Primeiro, obtenha o contexto atual do kubectl com o comando:

    ```bash
    kubectl config current-context
    ```

    13.2. **Adicionar o Cluster ao ArgoCD**
    Se o ArgoCD não estiver apontando para o cluster k3d, você pode adicioná-lo com o comando:

    ```bash
    argocd cluster add k3d-<nome-do-cluster>
    ```

    Substitua `<nome-do-cluster>` pelo nome do seu cluster k3d.

14. **Puxar os repositorios de exemplo**
    Agora você pode começar a puxar os repositórios de exemplo para o ArgoCD e começar a gerenciar suas aplicações.

15. **Dicas Adicionais**
    - Para listar todos os clusters k3d existentes, use:
      ```bash
      k3d cluster list
      ```
    - Para excluir um cluster k3d, use:
      ```bash
      k3d cluster delete <nome-do-cluster>
      ```
    - Para verificar os deployments de um namespace, use:
      ```bash
      kubectl get deploy -n <namespace>
      ```
    - Para verificar info dos servicos rodando dentro de um namespace, use:

      ```bash
      kubectl get svc -n <namespace>
      ```

- Para obter o endereço do servidor do cluster atual, use:
  ```bash
  kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'
  ```
