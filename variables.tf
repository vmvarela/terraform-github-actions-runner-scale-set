variable "github_app_id" {
  description = "GitHub App ID"
  type        = number
}

variable "github_app_private_key" {
  description = "GitHub App private key (PEM format)"
  type        = string
}

variable "github_app_installation_id" {
  description = "GitHub App Installation ID"
  type        = number
}

variable "organization" {
  description = "Org name."
  type        = string
  default     = null
}

variable "install_cert_manager" {
  type        = bool
  description = "If true, cert-manager will be installed in the cluster"
  default     = true
}

variable "cert_manager_namespace" {
  type        = string
  description = "The namespace to deploy cert-manager into"
  default     = "cert-manager"
}

variable "create_cert_manager_namespace" {
  type        = bool
  description = "If true, the cert-manager namespace will be created"
  default     = true
}

variable "cert_manager_helm_chart_version" {
  type        = string
  description = "The version of the cert-manager helm chart to deploy"
  default     = "v1.19.1"
}

variable "cert_manager_helm_deployment_name" {
  type        = string
  description = "The name of the cert-manager helm deployment"
  default     = "cert-manager"
}

variable "install_controller" {
  type        = bool
  description = "If true, the ARC controller will be installed in the cluster"
  default     = true
}

variable "controller_namespace" {
  type        = string
  description = "The namespace to deploy the runners into"
  default     = "arc-runners"
}

variable "create_controller_namespace" {
  type        = bool
  description = "If true, the namespace will be created"
  default     = true
}

variable "controller_helm_deployment_name" {
  type        = string
  description = "The name of the helm deployment"
  default     = "arc"
}

variable "controller_helm_chart_version" {
  type        = string
  description = "The version of the helm chart to deploy"
  default     = "0.13.0"
}

variable "runners_namespace" {
  type        = string
  description = "The namespace to deploy the runners into"
  default     = "arc-runners"
}

variable "create_runners_namespace" {
  type        = bool
  description = "If true, the namespace will be created"
  default     = true
}

variable "runners_helm_deployment_name" {
  type        = string
  description = "The name of the helm deployment"
  default     = "arc-runner-set"
}

variable "runners_helm_chart_version" {
  type        = string
  description = "The version of the helm chart to deploy"
  default     = "0.13.0"
}

variable "min_runners" {
  type        = number
  description = "Minimum number of runners to maintain"
  default     = 1
}

variable "max_runners" {
  type        = number
  description = "Maximum number of runners to maintain"
  default     = 5
}

variable "private_registry" {
  type        = string
  description = "Private container registry URL"
  default     = null
}

variable "private_registry_username" {
  type        = string
  description = "Private container registry username"
  default     = null
}

variable "private_registry_password" {
  type        = string
  description = "Private container registry password"
  default     = null
}

variable "private_registry_email" {
  type        = string
  description = "Private container registry email"
  default     = "devops@prisamedia.com"
}

variable "runner_image" {
  type        = string
  description = "The container image to use for the runner"
  default     = "docker.prisamedia.com/prisamedia/devops-platform/actions-runner"
}

variable "runner_version" {
  type        = string
  description = "The version of the runner image"
  default     = "0.2.0"
}