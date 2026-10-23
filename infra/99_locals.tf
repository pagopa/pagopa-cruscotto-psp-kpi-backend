locals {
  product = "${var.prefix}-${var.env_short}"

  apim = {
    name              = "${local.product}-apim"
    rg                = "${local.product}-api-rg"
    product_id        = "pagopa-smo-cruscotto-cert" # import from pagopa-infra
    product_id_subkey = "pagopa-smo-cruscotto-cert-subkey" # import from pagopa-infra
  }
}

