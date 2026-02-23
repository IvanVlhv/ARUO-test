data "azurerm_policy_definition" "require_tag" {
  display_name = "Require a tag on resources"
}

data "azurerm_policy_definition" "allowed_locations" {
  display_name = "Allowed locations"
}

resource "azurerm_subscription_policy_assignment" "require_tags" {
  name                 = "require-university-tag"
  subscription_id      = "/subscriptions/${var.subscription_id}"
  policy_definition_id = data.azurerm_policy_definition.require_tag.id

  parameters = jsonencode({
    tagName = { value = "university" }
  })
}

resource "azurerm_subscription_policy_assignment" "eu_only" {
  name                 = "allowed-eu-regions"
  subscription_id      = "/subscriptions/${var.subscription_id}"
  policy_definition_id = data.azurerm_policy_definition.allowed_locations.id

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = ["westeurope", "northeurope", "swedencentral", "germanywestcentral"]
    }
  })
}
