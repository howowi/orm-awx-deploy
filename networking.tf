// Copyright (c) 2017, 2021, Oracle and/or its affiliates. All rights reserved.
// Licensed under the Mozilla Public License v2.0

resource "oci_core_vcn" "awx_vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = "${var.resource_naming_prefix}VcnForClusters"
  dns_label      = "awx"
}

resource "oci_core_internet_gateway" "awx_ig" {
  depends_on     = [oci_core_vcn.awx_vcn]
  compartment_id = var.compartment_ocid
  display_name   = "${var.resource_naming_prefix}ClusterInternetGateway"
  vcn_id         = oci_core_vcn.awx_vcn.id
  enabled        = true
}

resource "oci_core_route_table" "awx_route_table" {
  depends_on     = [oci_core_vcn.awx_vcn, oci_core_internet_gateway.awx_ig]
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.awx_vcn.id
  display_name   = "${var.resource_naming_prefix}ClustersRouteTable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.awx_ig.id
  }
}

#required for service_gateway
data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_service_gateway" "awx_service_gateway" {
  depends_on = [oci_core_vcn.awx_vcn, data.oci_core_services.all_services]
  #Required
  compartment_id = var.compartment_ocid
  services {
    service_id = data.oci_core_services.all_services.services[0]["id"]
  }
  vcn_id = oci_core_vcn.awx_vcn.id
  #Optional
  display_name = "${var.resource_naming_prefix}ServiceGateway"
}

resource "oci_core_nat_gateway" "awx_nat_gateway" {
  depends_on = [oci_core_vcn.awx_vcn]
  #Required
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.awx_vcn.id

  #Optional
  display_name = "${var.resource_naming_prefix}NatGateway"
}

#for private subnet to internet
resource "oci_core_default_route_table" "awx_default_route_table" {
  depends_on                 = [oci_core_vcn.awx_vcn, oci_core_nat_gateway.awx_nat_gateway]
  manage_default_resource_id = oci_core_vcn.awx_vcn.default_route_table_id
  compartment_id             = var.compartment_ocid

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.awx_nat_gateway.id
  }
}

resource "oci_core_security_list" "awx_cluster_public_security_list" {
  depends_on     = [oci_core_vcn.awx_vcn]
  display_name   = "${var.resource_naming_prefix}_cluster_public_security_list"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.awx_vcn.id

  egress_security_rules {
    protocol    = "ALL"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = 6
    source   = "0.0.0.0/0"
  }
}

#used for Kubernetes API Endpoint
resource "oci_core_subnet" "awx_cluster_regional_subnet" {
  depends_on = [oci_core_vcn.awx_vcn, oci_core_security_list.awx_cluster_public_security_list, oci_core_route_table.awx_route_table]
  #Required
  cidr_block     = "10.0.26.0/24"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.awx_vcn.id

  # Provider code tries to maintain compatibility with old versions.
  security_list_ids = [oci_core_vcn.awx_vcn.default_security_list_id, oci_core_security_list.awx_cluster_public_security_list.id]
  display_name      = "${var.resource_naming_prefix}_clusterRegionalSubnet"
  route_table_id    = oci_core_route_table.awx_route_table.id
}

resource "oci_core_security_list" "awx_pool_public_security_list" {
  depends_on     = [oci_core_vcn.awx_vcn]
  display_name   = "${var.resource_naming_prefix}_pool_public_security_list"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.awx_vcn.id

  egress_security_rules {
    protocol    = "All"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = 6
    source   = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "awx_nodePool_Subnet_1" {
  depends_on = [oci_core_vcn.awx_vcn, oci_core_default_route_table.awx_default_route_table]
  #Required
  availability_domain = data.oci_identity_availability_domain.ad1.name
  cidr_block          = "10.0.22.0/24"
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.awx_vcn.id
  dns_label           = "${var.resource_naming_prefix}flexpool1"

  # Provider code tries to maintain compatibility with old versions.
  security_list_ids = [oci_core_vcn.awx_vcn.default_security_list_id, oci_core_security_list.awx_pool_public_security_list.id]
  display_name      = "${var.resource_naming_prefix}SubNet1ForNodePool"
  route_table_id    = oci_core_default_route_table.awx_default_route_table.id
}
