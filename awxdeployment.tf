//safety measures
resource "null_resource" "wait_for_1m" {
  depends_on = [oci_containerengine_node_pool.awx_flex_shape_node_pool]
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "sleep 60"
  }
}

resource "null_resource" "create_kubeconfig_directory" {
  depends_on = [null_resource.wait_for_1m, oci_containerengine_node_pool.awx_flex_shape_node_pool]
  provisioner "local-exec" {
    command = "mkdir -p $HOME/.kube"
    interpreter = [
      "/bin/bash",
    "-c"]
  }
}

#the version number is hardcoded as there can be breaking changes in the next version
locals {
  awx-operator-version = "0.13.0"
}

resource "null_resource" "create_kubeconfig" {
  depends_on = [null_resource.create_kubeconfig_directory]
  provisioner "local-exec" {
    command = "oci ce cluster create-kubeconfig --cluster-id ${data.oci_containerengine_cluster_kube_config.awx_cluster_kube_config.cluster_id} --file $HOME/.kube/config --region ${var.region} --token-version 2.0.0  --kube-endpoint PUBLIC_ENDPOINT"
    interpreter = [
      "/bin/bash",
    "-c"]
  }
}

resource "null_resource" "set_kubeconfig_env" {
  depends_on = [null_resource.create_kubeconfig]
  provisioner "local-exec" {
    command = "export KUBECONFIG=$HOME/.kube/config"
    interpreter = [
      "/bin/bash",
    "-c"]
  }
}

resource "null_resource" "install_awx_operator" {
  depends_on = [null_resource.set_kubeconfig_env]
  provisioner "local-exec" {
    command = "kubectl apply -f https://raw.githubusercontent.com/ansible/awx-operator/${local.awx-operator-version}/deploy/awx-operator.yaml"
    interpreter = [
      "/bin/bash",
    "-c"]
  }
}

resource "null_resource" "wait_for_200s" {
  depends_on = [null_resource.install_awx_operator]
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "sleep 200"
  }
}

resource "null_resource" "get_pod_status" {
  depends_on = [null_resource.wait_for_200s]
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "kubectl get pods --field-selector=status.phase=Running"
  }
}

data "local_file" "awx_deployment" {
  depends_on = [null_resource.get_pod_status]
  filename   = "scripts/awx_demo.yaml"
}

resource "local_file" "awx_deployment" {
  depends_on = [local_file.awx_deployment]
  content    = data.local_file.awx_deployment.content
  filename   = "scripts/awx_demo.yaml"

  provisioner "local-exec" {
    command = "kubectl apply -f ${self.filename}"
    interpreter = [
      "/bin/bash",
    "-c"]
  }
}

resource "null_resource" "wait_for_300s" {
  depends_on = [local_file.awx_deployment]
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "sleep 300"
  }
}

//AWX installation should be complete here
//now setting up AWX
resource "null_resource" "setup_awx" {
  depends_on = [null_resource.wait_for_300s]
  provisioner "local-exec" {
    command = "python3 scripts/awx-setup.py ${var.awx_execution_env_image_name}"
  }
}

data "local_file" "awx_pwd" {
  depends_on = [null_resource.setup_awx]
  filename   = "awxpwd.txt"
}

data "local_file" "awx_ip" {
  depends_on = [null_resource.setup_awx]
  filename   = "awxip.txt"
}

output "cluster" {
  value = {
    id                 = oci_containerengine_cluster.awx_cluster.id
    kubernetes_version = oci_containerengine_cluster.awx_cluster.kubernetes_version
    name               = oci_containerengine_cluster.awx_cluster.name
  }
}

output "flex_node_pool" {
  value = {
    id                 = oci_containerengine_node_pool.awx_flex_shape_node_pool.id
    kubernetes_version = oci_containerengine_node_pool.awx_flex_shape_node_pool.kubernetes_version
    name               = oci_containerengine_node_pool.awx_flex_shape_node_pool.name
  }
}

output "awx_login_password" {
  value = data.local_file.awx_pwd.content
}

output "awx_ui_ip" {
  value = data.local_file.awx_ip.content
}