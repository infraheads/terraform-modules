variable "argocd_name" {
  description = "ArgoCd chart name in Helm"
  type        = string
  default     = "argo-cd"
}

variable "argocd_app_name" {
  description = "ArgoCd app chart name in Helm"
  type        = string
  default     = "argocd-apps"
}

variable "k8s_namespace" {
  description = "The given kubernetes namespace"
  type        = string
  default     = "argo-cd"
}

variable "k8s_secret_name" {
  description = "Kubernetes secret name"
  type        = string
  default     = "helm-secrets-private-keys"
}

variable "key_path" {
  description = "Key location path"
  type        = any
  default = ""
}

variable "git_repo_url" {
  description = "The git url that argocd will connect to"
  type        = string
  default = ""
}

variable "git_repo_path" {
  description = "The path from which ArgoCd will read"
  type        = string
  default = ""
}

variable "argocd_values_path" {
  description = "The path from which ArgoCd will read"
  type        = string
  default = ""
}

variable "argocd_app_values_path" {
  description = "The path from which ArgoCd will read"
  type        = string
  default = ""
}