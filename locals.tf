locals {
  name = "${var.prefix}-${var.suffix}"

  mandatory_tags = {
    university = "Algebra"
    student    = var.student_email
  }

  tags = merge(local.mandatory_tags, var.tags)

  app_vnet_cidr  = "10.50.0.0/16"
  jump_vnet_cidr = "10.60.0.0/16"

  subnets = {
    appgw = "10.50.0.0/24"
    aks   = "10.50.1.0/24"
    func  = "10.50.2.0/24"
    db    = "10.50.3.0/24"
    pe    = "10.50.4.0/24"
    vm    = "10.60.0.0/24"
  }
}
