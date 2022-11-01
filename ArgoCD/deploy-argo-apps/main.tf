resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.4.1"
  namespace        = "argo-cd"
  create_namespace = true

  values = [
    "${file("argocd-value.yaml")}"
  ]


}

resource "helm_release" "argocd-apps" {

  depends_on       = [helm_release.argocd]
  name             = "argo-apps"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argocd-apps"
  version          = "0.0.1"
  namespace        = "argo-cd"
  create_namespace = true

  values = [
    "${file("argocd-apps-value.yaml")}"
  ]
}
