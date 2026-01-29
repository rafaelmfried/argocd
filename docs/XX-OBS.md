# Observações Gerais

Este documento contém algumas observações gerais e dicas úteis para trabalhar com o ArgoCD e o k3d.

## ArgoCD

- Nos instanciamos aplicacoes no argocd para poder ele gerenciar o deploy delas no cluster.
- Sempre que fizermos alteracoes nos manifests, precisamos fazer o "sync" da aplicacao no ArgoCD para que as alteracoes sejam aplicadas no cluster.
- Podemos configurar o ArgoCD para fazer o "auto-sync" das aplicacoes, ou seja, ele aplica automaticamente as alteracoes nos manifests sem precisar fazer o "sync" manualmente.
