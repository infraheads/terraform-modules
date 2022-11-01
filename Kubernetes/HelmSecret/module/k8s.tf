resource "helm_release" "argocd" {
  name       = var.argocd_name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version = "5.4.3"
  namespace = kubernetes_namespace.ns.metadata[0].name
  values = [
    "${file("../module/argocd-values.yaml")}"
  ]

  depends_on = [
    kubernetes_secret.helm_secret
  ]
}

resource "helm_release" "argocd-apps" {
  name       = var.argocd_app_name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version = "0.0.1"
  namespace = kubernetes_namespace.ns.metadata[0].name

  values = [
    "${file("../module/argocd-app-value.yaml")}"
  ]

  set {
    name = "applications[0].source.repoURL"
    value = var.git_repo_url
  }

  set {
    name = "applications[0].destination.namespace"
    value = var.k8s_namespace
  }

  set {
    name = "applications[0].source.path"
    value = var.git_repo_path
  }
  
  depends_on = [
    helm_release.argocd
  ]
}

resource "kubernetes_namespace" "ns" {
  metadata {
    name = var.k8s_namespace
  }
}

resource "kubernetes_secret" "helm_secret" {
  metadata {
    name = var.k8s_secret_name
    namespace = kubernetes_namespace.ns.metadata[0].name
  }
  data = {
    "key.txt" = file(var.key_path)
  }
}