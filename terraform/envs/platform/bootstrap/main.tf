# Argo CD bootstrap (ADR-0001): Terraform installs and upgrades Argo CD and
# creates one root Application. Everything after that (projects, namespaces,
# operators, data services and the app) is reconciled by Argo CD from
# gitops/ in this repository. Argo CD does not manage itself.

locals {
  # Autopilot assigns large defaults to containers without requests, so
  # every component gets explicit small requests.
  small = {
    requests = { cpu = "100m", memory = "256Mi" }
    limits   = { memory = "512Mi" }
  }

  argocd_values = {
    global        = { domain = "argocd.internal" }
    dex           = { enabled = false }
    notifications = { enabled = false }
    applicationSet = {
      replicas  = 1
      resources = local.small
    }
    controller = { resources = { requests = { cpu = "250m", memory = "512Mi" }, limits = { memory = "1Gi" } } }
    repoServer = { resources = local.small }
    server     = { resources = local.small }
    redis      = { resources = { requests = { cpu = "50m", memory = "128Mi" }, limits = { memory = "256Mi" } } }
    configs = {
      params = {
        # UI and API are reached through kubectl port-forward until an
        # authenticated ingress is designed; no public exposure.
        "server.insecure" = true
      }
    }
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  values           = [yamlencode(local.argocd_values)]
  wait             = true
  timeout          = 900
}

resource "helm_release" "root" {
  name       = "argocd-root"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = var.argocd_apps_chart_version

  values = [yamlencode({
    applications = {
      root = {
        namespace = "argocd"
        project   = "default"
        source = {
          repoURL        = var.gitops_repo_url
          targetRevision = var.gitops_revision
          path           = "gitops/bootstrap"
        }
        destination = {
          server    = "https://kubernetes.default.svc"
          namespace = "argocd"
        }
        syncPolicy = {
          automated   = { prune = true, selfHeal = true }
          syncOptions = ["CreateNamespace=false"]
        }
      }
    }
  })]

  depends_on = [helm_release.argocd]
}

# Read-only access for the plan identity to Helm's release records, so
# plans can refresh these releases without write permissions.
resource "kubernetes_role_v1" "plan_reader" {
  metadata {
    name      = "terraform-plan-reader"
    namespace = "argocd"
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch"]
  }

  depends_on = [helm_release.argocd]
}

resource "kubernetes_role_binding_v1" "plan_reader" {
  metadata {
    name      = "terraform-plan-reader"
    namespace = "argocd"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.plan_reader.metadata[0].name
  }

  subject {
    kind      = "User"
    name      = var.plan_identity
    api_group = "rbac.authorization.k8s.io"
  }
}
