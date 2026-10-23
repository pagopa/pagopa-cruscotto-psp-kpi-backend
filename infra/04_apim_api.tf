locals {
  repo_name = "pagopa-cruscotto-pspkpi-backend"

  host     = "api.${var.apim_dns_zone_prefix}.${var.external_domain}"
  hostname = var.hostname

  # API con Subscription Key
  pspkpi_subkey = {
    display_name = "Cruscotto psp-kpi pagoPA backend service API (Subscription Key)"
    description  = "Cruscotto psp-kpi pagoPA backend service API (Subscription Key)"
    path         = "smo/cruscotto-pspkpi-subkey"
  }

  # API senza Subscription Key
  pspkpi = {
    display_name = "Cruscotto psp-kpi pagoPA backend service API"
    description  = "Cruscotto psp-kpi pagoPA backend service API"
    path         = "smo/cruscotto-pspkpi"
  }
}

resource "azurerm_api_management_group" "api_group" {
  name                = local.apim.product_id
  resource_group_name = local.apim.rg
  api_management_name = local.apim.name
  display_name        = local.pspkpi.display_name
  description         = local.pspkpi.description
}

# ----------------------------------------------------
# 1. PSP-KPI API (Subscription Key)
# ----------------------------------------------------
resource "azurerm_api_management_api_version_set" "api_version_set_pspkpi_subkey" {
  name                = format("%s-${local.repo_name}-pspkpi-subkey", var.env_short)
  resource_group_name = local.apim.rg
  api_management_name = local.apim.name
  display_name        = local.pspkpi_subkey.display_name
  versioning_scheme   = "Segment"
}

resource "time_sleep" "wait_after_pspkpi_subkey_vs" {
  depends_on = [
    azurerm_api_management_api_version_set.api_version_set_pspkpi_subkey
  ]

  triggers = {
    rollout = "2026-09-14-apim-api-create-v2"
  }

  create_duration = "120s"
}

module "api_pspkpi_subkey_v1" {
  source                = "git::https://github.com/pagopa/terraform-azurerm-v4.git//api_management_api?ref=v10.22.0"

  name                  = format("%s-${local.repo_name}-pspkpi-subkey", var.env_short)
  api_management_name   = local.apim.name
  resource_group_name   = local.apim.rg
  product_ids           = [local.apim.product_id_subkey]

  subscription_required = true // Subscription key required

  version_set_id = azurerm_api_management_api_version_set.api_version_set_pspkpi_subkey.id
  api_version    = "v1"

  description  = local.pspkpi_subkey.description
  display_name = local.pspkpi_subkey.display_name
  path         = local.pspkpi_subkey.path
  protocols    = ["https"]

  service_url = null

  content_format = "openapi+json"
  content_value = templatefile("../openapi/openapi_pspkpi_subkey.json", {
    host = local.host
  })

  xml_content = templatefile("./policy/_base_policy.xml", {
    hostname   = var.hostname
    origin     = var.origin
  })

  depends_on = [
    azurerm_api_management_api_version_set.api_version_set_pspkpi_subkey,
    time_sleep.wait_after_pspkpi_subkey_vs
  ]
}

# ----------------------------------------------------
# 2. PSP-KPI API (No Subscription Key)
# ----------------------------------------------------
resource "azurerm_api_management_api_version_set" "api_version_set_pspkpi" {
  name                = format("%s-${local.repo_name}", var.env_short)
  resource_group_name = local.apim.rg
  api_management_name = local.apim.name
  display_name        = local.pspkpi.display_name
  versioning_scheme   = "Segment"
}

resource "time_sleep" "wait_after_pspkpi_vs" {
  depends_on = [
    azurerm_api_management_api_version_set.api_version_set_pspkpi
  ]

  triggers = {
    rollout = "2026-09-14-apim-api-create-v2"
  }

  create_duration = "120s"
}

module "api_pspkpi_v1" {
  source = "git::https://github.com/pagopa/terraform-azurerm-v4.git//api_management_api?ref=v10.22.0"

  name                  = format("%s-${local.repo_name}", var.env_short)
  api_management_name   = local.apim.name
  resource_group_name   = local.apim.rg
  product_ids           = [local.apim.product_id]

  subscription_required = false // No subscription key required JWT validation

  version_set_id = azurerm_api_management_api_version_set.api_version_set_pspkpi.id
  api_version    = "v1"

  description  = local.pspkpi.description
  display_name = local.pspkpi.display_name
  path         = local.pspkpi.path
  protocols    = ["https"]

  service_url = null

  content_format = "openapi+json"
  content_value = templatefile("../openapi/openapi_pspkpi.json", {
    host = local.host
  })

  xml_content = templatefile("./policy/_base_policy_jwt.xml", {
    hostname   = var.hostname
    origin     = var.origin
  })

  depends_on = [
    azurerm_api_management_api_version_set.api_version_set_pspkpi,
    time_sleep.wait_after_pspkpi_vs,
    module.api_pspkpi_subkey_v1
  ]
}
