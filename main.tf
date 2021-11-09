// Copyright (c) 2017, 2021, Oracle and/or its affiliates. All rights reserved.
// Licensed under the Mozilla Public License v2.0

resource "oci_containerengine_cluster" "awx_cluster" {
  depends_on = [oci_core_vcn.awx_vcn, oci_core_subnet.awx_cluster_regional_subnet]
  #Required
  compartment_id = var.compartment_ocid
  #fetching latest k8s version
  kubernetes_version = data.oci_containerengine_cluster_option.awx_cluster_option.kubernetes_versions[length(data.oci_containerengine_cluster_option.awx_cluster_option.kubernetes_versions) - 1]
  name               = var.awx_cluster_name
  vcn_id             = oci_core_vcn.awx_vcn.id

  endpoint_config {
    subnet_id            = oci_core_subnet.awx_cluster_regional_subnet.id
    is_public_ip_enabled = "true"
  }

  #Optional
  options {
    service_lb_subnet_ids = [oci_core_subnet.awx_cluster_regional_subnet.id]

    #Optional
    add_ons {
      #Optional
      is_kubernetes_dashboard_enabled = "true"
      is_tiller_enabled               = "true"
    }

    kubernetes_network_config {
      #Optional
      pods_cidr     = "10.1.0.0/16"
      services_cidr = "10.2.0.0/16"
    }
  }
}

resource "oci_containerengine_node_pool" "awx_flex_shape_node_pool" {
  depends_on = [oci_core_vcn.awx_vcn, oci_containerengine_cluster.awx_cluster, oci_core_subnet.awx_nodePool_Subnet_1]
  #Required
  cluster_id         = oci_containerengine_cluster.awx_cluster.id
  compartment_id     = var.compartment_ocid
  kubernetes_version = data.oci_containerengine_cluster_option.awx_cluster_option.kubernetes_versions[length(data.oci_containerengine_cluster_option.awx_cluster_option.kubernetes_versions) - 1]
  name               = "${var.resource_naming_prefix}flexShapePool"
  node_shape         = var.instance_shape

  node_config_details {
    placement_configs {
      #Required
      availability_domain = data.oci_identity_availability_domain.ad1.name
      subnet_id           = oci_core_subnet.awx_nodePool_Subnet_1.id
    }
    size = 1
  }

  node_source_details {
    #Required
    image_id    = lookup(data.oci_core_images.node_pool_images.images[0], "id")
    source_type = "IMAGE"
  }

  node_shape_config {
    ocpus         = var.shape_ocpus
    memory_in_gbs = var.shape_mems
  }

  ssh_public_key = var.awx_node_ssh_public_key
}

data "oci_containerengine_cluster_option" "awx_cluster_option" {
  cluster_option_id = "all"
}

data "oci_containerengine_cluster_kube_config" "awx_cluster_kube_config" {
  depends_on = [oci_containerengine_node_pool.awx_flex_shape_node_pool]
  #Required
  cluster_id = oci_containerengine_cluster.awx_cluster.id
  #Optional
  token_version = "2.0.0"
}