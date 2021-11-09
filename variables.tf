// Copyright (c) 2017, 2021, Oracle and/or its affiliates. All rights reserved.
// Licensed under the Mozilla Public License v2.0

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">= 2.1.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.1.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 1.11.2"
    }
    oci = {
      source  = "hashicorp/oci"
      version = ">= 3.30.0"
    }
  }
  required_version = ">= 1.0"
}

provider "kubernetes" {
  config_path = "$HOME/.kube/config"
}

variable "compartment_ocid" {
  description = "Please provide compartment OCID."
  type        = string
}

variable "tenancy_ocid" {
  description = "Please provide tenancy OCID."
  type = string
}

variable "region" {
  description = "Please provide region for the AWX deployment."
  type        = string
}

variable "resource_naming_prefix" {
  description = "Please provide a unique name which will be used as a prefix for naming the resources."
  type        = string
}

variable "awx_cluster_name" {
  type        = string
  description = "Please provide unique cluster name for the AWX deployment."
}

variable "awx_execution_env_image_name" {
  description = "Please provide docker image name which is only required for using OCI Ansible Collections."
}

variable "image_operating_system" {
  default     = "Oracle Linux"
  description = "Please provide operating system image name."
}

variable "image_operating_system_version" {
  default     = "7.9"
  description = "Please provide operating system image version."
}

variable "instance_shape" {
  default     = "VM.Standard.E3.Flex"
  type        = string
  description = "Please select instance shape with more than 6 OCPU and 8GB of memory."
}

variable "shape_ocpus" {
  default     = 8
  type        = string
  description = "Please provide OCPUs for the desired shape."
}

variable "shape_mems" {
  default     = 10
  type        = string
  description = "Please provide Memory for the desired shape."
}

variable "awx_node_ssh_public_key" {
  default     = ""
  type        = string
  description = "Please paste the public ssh key."
}

data "oci_core_images" "node_pool_images" {
  compartment_id           = var.compartment_ocid
  operating_system         = var.image_operating_system
  operating_system_version = var.image_operating_system_version
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

data "oci_identity_availability_domain" "ad1" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}

# data "oci_identity_availability_domain" "ad2" {
#   compartment_id = var.tenancy_ocid
#   ad_number      = 2
# }

provider "oci" {
  region          = var.region
  tenancy_ocid    = var.tenancy_ocid
}