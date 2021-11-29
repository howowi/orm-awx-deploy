
resource "oci_core_vcn" "webapp_vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = "${var.resource_naming_prefix}_webapp_vcn"
  dns_label      = "webapp"
}

resource "oci_core_internet_gateway" "webapp_ig" {
  depends_on     = [oci_core_vcn.webapp_vcn]
  compartment_id = var.compartment_ocid
  display_name   = "${var.resource_naming_prefix}_webapp_ig"
  vcn_id         = oci_core_vcn.webapp_vcn.id
  enabled        = true
}

resource "oci_core_route_table" "webapp_route_table" {
  depends_on     = [oci_core_vcn.webapp_vcn, oci_core_internet_gateway.webapp_ig]
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.webapp_vcn.id
  display_name   = "${var.resource_naming_prefix}_webapp_route_table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.webapp_ig.id
  }
}

resource "oci_core_security_list" "webapp_public_security_list" {
  depends_on     = [oci_core_vcn.webapp_vcn]
  display_name   = "${var.resource_naming_prefix}_webapp_public_security_list"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.webapp_vcn.id

  egress_security_rules {
    protocol    = "ALL"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "ALL"
    source   = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "webapp_regional_subnet" {
  depends_on = [oci_core_vcn.webapp_vcn, oci_core_security_list.webapp_public_security_list, oci_core_route_table.webapp_route_table]
  #Required
  cidr_block     = "10.0.1.0/24"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.webapp_vcn.id

  # Provider code tries to maintain compatibility with old versions.
  security_list_ids = [oci_core_vcn.webapp_vcn.default_security_list_id, oci_core_security_list.webapp_public_security_list.id]
  display_name      = "${var.resource_naming_prefix}_webapp_regional_subnet"
  route_table_id    = oci_core_route_table.awx_route_table.id
}
