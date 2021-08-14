locals {
  ranges = flatten([
    for instance in var.instances : [
      for range in instance.vlan_ranges != null ? instance.vlan_ranges : [] : {
        key = "${instance.name}/${range.from}"
        value = {
          instance_name = instance.name
          from          = range.from
          to            = lookup(range, "to", range.from)
        }
      }
    ]
  ])
}

resource "aci_rest" "stpMstRegionPol" {
  dn         = "uni/infra/mstpInstPol-default/mstpRegionPol-${var.name}"
  class_name = "stpMstRegionPol"
  content = {
    name    = var.name
    regName = var.region
    rev     = var.revision
  }
}

resource "aci_rest" "stpMstDomPol" {
  for_each   = { for instance in var.instances : instance.name => instance }
  dn         = "${aci_rest.stpMstRegionPol.id}/mstpDomPol-${each.value.name}"
  class_name = "stpMstDomPol"
  content = {
    name = each.value.name
    id   = each.value.id
  }
}

resource "aci_rest" "fvnsEncapBlk" {
  for_each   = { for range in local.ranges : range.key => range.value }
  dn         = "${aci_rest.stpMstDomPol[each.value.instance_name].id}/from-[vlan-${each.value.from}]-to-[vlan-${each.value.to}]"
  class_name = "fvnsEncapBlk"
  content = {
    from      = "vlan-${each.value.from}"
    to        = "vlan-${each.value.to}"
    allocMode = "inherit"
    role      = "external"
  }
}
