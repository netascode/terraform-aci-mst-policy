output "dn" {
  value       = aci_rest.stpMstRegionPol.id
  description = "Distinguished name of `stpMstRegionPol` object."
}

output "name" {
  value       = aci_rest.stpMstRegionPol.content.name
  description = "MST policy name."
}
