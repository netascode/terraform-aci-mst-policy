terraform {
  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }

    aci = {
      source  = "netascode/aci"
      version = ">=0.2.0"
    }
  }
}

module "main" {
  source = "../.."

  name     = "MST1"
  region   = "REG1"
  revision = 1
  instances = [{
    name = "INST1"
    id   = 1
    vlan_ranges = [{
      from = 10
      to   = 20
    }]
  }]
}

data "aci_rest" "stpMstRegionPol" {
  dn = "uni/infra/mstpInstPol-default/mstpRegionPol-${module.main.name}"

  depends_on = [module.main]
}

resource "test_assertions" "stpMstRegionPol" {
  component = "stpMstRegionPol"

  equal "name" {
    description = "name"
    got         = data.aci_rest.stpMstRegionPol.content.name
    want        = module.main.name
  }

  equal "regName" {
    description = "regName"
    got         = data.aci_rest.stpMstRegionPol.content.regName
    want        = "REG1"
  }

  equal "rev" {
    description = "rev"
    got         = data.aci_rest.stpMstRegionPol.content.rev
    want        = "1"
  }
}

data "aci_rest" "stpMstDomPol" {
  dn = "${data.aci_rest.stpMstRegionPol.id}/mstpDomPol-INST1"

  depends_on = [module.main]
}

resource "test_assertions" "stpMstDomPol" {
  component = "stpMstDomPol"

  equal "name" {
    description = "name"
    got         = data.aci_rest.stpMstDomPol.content.name
    want        = "INST1"
  }

  equal "id" {
    description = "id"
    got         = data.aci_rest.stpMstDomPol.content.id
    want        = "1"
  }
}

data "aci_rest" "fvnsEncapBlk" {
  dn = "${data.aci_rest.stpMstDomPol.id}/from-[vlan-10]-to-[vlan-20]"

  depends_on = [module.main]
}

resource "test_assertions" "fvnsEncapBlk" {
  component = "fvnsEncapBlk"

  equal "from" {
    description = "from"
    got         = data.aci_rest.fvnsEncapBlk.content.from
    want        = "vlan-10"
  }

  equal "to" {
    description = "to"
    got         = data.aci_rest.fvnsEncapBlk.content.to
    want        = "vlan-20"
  }

  equal "allocMode" {
    description = "allocMode"
    got         = data.aci_rest.fvnsEncapBlk.content.allocMode
    want        = "inherit"
  }

  equal "role" {
    description = "role"
    got         = data.aci_rest.fvnsEncapBlk.content.role
    want        = "external"
  }
}
