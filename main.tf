locals {
  cert_manager_namespace = var.install_cert_manager ? (var.create_cert_manager_namespace ? kubernetes_namespace.cert_manager[0].metadata[0].name : data.kubernetes_namespace.controller[0].metadata[0].name) : null
  cert_manager_helm_release_settings = [{
    name  = "crds.enabled"
    value = "true"
  }]

  controller_namespace = var.install_controller ? (var.create_controller_namespace ? kubernetes_namespace.controller[0].metadata[0].name : data.kubernetes_namespace.controller[0].metadata[0].name) : null
  controller_helm_release_settings = [
    {
      name  = "metrics.controllerManagerAddr"
      value = ":8080"
    },
    {
      name  = "metrics.listenerAddr"
      value = ":8080"
    },
    {
      name  = "metrics.listenerEndpoint"
      value = "/metrics"
    }
  ]

  runners_namespace = var.create_runners_namespace ? kubernetes_namespace.runners[0].metadata[0].name : data.kubernetes_namespace.runners[0].metadata[0].name
  runners_helm_release_settings = [
    {
      name  = "githubConfigUrl"
      value = format("https://github.com/%s", var.organization)
    },
    {
      name  = "githubConfigSecret.github_app_id"
      value = tostring(var.github_app_id)
    },
    {
      name  = "githubConfigSecret.github_app_installation_id"
      value = tostring(var.github_app_installation_id)
    },
    {
      name  = "githubConfigSecret.github_app_private_key"
      value = var.github_app_private_key
    },
    {
      name  = "runnerGroup"
      value = "ARC"
    },
    {
      name  = "minRunners"
      value = var.min_runners != null ? tostring(var.min_runners) : "1"
    },
    {
      name  = "maxRunners"
      value = var.max_runners != null ? tostring(var.max_runners) : "10"
    },
    {
      name  = "template.spec.imagePullSecrets[0].name"
      value = var.private_registry != null && var.private_registry_username != null && var.private_registry_password != null ? kubernetes_secret.private_registry[0].metadata[0].name : ""
    },
    {
      name  = "template.spec.containers[0].name"
      value = "runner"
    },
    {
      name  = "template.spec.containers[0].command[0]"
      value = "/home/runner/run.sh"
    },
    {
      name  = "template.spec.containers[0].imagePullPolicy"
      value = "Always"
    },
    {
      name  = "template.spec.containers[0].image"
      value = "${var.runner_image}:${var.runner_version}"
    }
  ]
}

data "kubernetes_namespace" "cert_manager" {
  count = !(var.install_cert_manager && var.create_cert_manager_namespace) ? 0 : 1
  metadata {
    name = var.cert_manager_namespace
  }
}

resource "kubernetes_namespace" "cert_manager" {
  count = var.install_cert_manager && var.create_cert_manager_namespace ? 1 : 0
  metadata {
    name = var.cert_manager_namespace
  }
}

resource "helm_release" "cert_manager" {
  count      = var.install_cert_manager ? 1 : 0
  name       = var.cert_manager_helm_deployment_name
  repository = "https://charts.jetstack.io"
  namespace  = local.cert_manager_namespace
  version    = var.cert_manager_helm_chart_version
  chart      = "cert-manager"
  atomic     = true
  timeout    = 600
  set        = local.cert_manager_helm_release_settings
}

data "kubernetes_namespace" "controller" {
  count = !(var.install_controller && var.create_controller_namespace) ? 0 : 1
  metadata {
    name = var.controller_namespace
  }
}

resource "kubernetes_namespace" "controller" {
  count = var.install_controller && var.create_controller_namespace ? 1 : 0
  metadata {
    name = var.controller_namespace
  }
  depends_on = [helm_release.cert_manager]
}

resource "helm_release" "controller" {
  name       = var.controller_helm_deployment_name
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set-controller"
  version    = var.controller_helm_chart_version
  namespace  = local.controller_namespace
  set        = local.controller_helm_release_settings
}

data "kubernetes_namespace" "runners" {
  count = var.create_runners_namespace ? 0 : 1
  metadata {
    name = var.runners_namespace
  }
}

resource "kubernetes_namespace" "runners" {
  count = var.create_runners_namespace ? 1 : 0
  metadata {
    name = var.runners_namespace
  }
  depends_on = [helm_release.controller]
}

resource "kubernetes_secret" "github_auth" {
  metadata {
    name      = "arc-github-auth"
    namespace = local.runners_namespace
  }
  data = {
    "github_app_id"              = base64encode(tostring(var.github_app_id))
    "github_app_installation_id" = base64encode(tostring(var.github_app_installation_id))
    "github_app_private_key"     = base64encode(var.github_app_private_key)
  }
}

resource "kubernetes_secret" "private_registry" {
  count = var.private_registry != null && var.private_registry_username != null && var.private_registry_password != null ? 1 : 0
  type  = "kubernetes.io/dockerconfigjson"
  metadata {
    name      = "arc-private-registry"
    namespace = local.runners_namespace
  }
  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.private_registry}" = {
          username = var.private_registry_username
          password = var.private_registry_password
          email    = var.private_registry_email
          auth     = base64encode("${var.private_registry_username}:${var.private_registry_password}")
        }
      }
    })
  }
}

resource "helm_release" "runners" {
  name       = var.runners_helm_deployment_name
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set"
  version    = var.runners_helm_chart_version
  namespace  = local.runners_namespace
  set        = local.runners_helm_release_settings
  depends_on = [kubernetes_secret.github_auth, kubernetes_secret.private_registry]
}
