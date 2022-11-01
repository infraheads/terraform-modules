module "helm_secret" {
  source  = "../module"
  
  argocd_name = "argocd"
  argocd_app_name = "argocd-app"
  k8s_secret_name = "helm-secrets-private-keys"
  key_path = "key.txt"
  k8s_namespace = "argo-cd"
  git_repo_url = "https://github.com/Sahakanush/sops_secret.git"
  git_repo_path = "ArgoApps"
}

