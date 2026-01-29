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

2. **Sincronizar a aplicacao**
   Para sincronizar a aplicação criada no ArgoCD e aplicar os manifests no cluster Kubernetes, use o comando:

   ```bash
   argocd app sync testapp
   ```

3. **Comandos Uteis do ArgoCD**
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
