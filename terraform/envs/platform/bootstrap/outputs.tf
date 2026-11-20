output "argocd_namespace" {
  description = "Namespace of the Argo CD installation."
  value       = helm_release.argocd.namespace
}

output "argocd_version" {
  description = "Installed Argo CD application version."
  value       = helm_release.argocd.metadata.app_version
}
