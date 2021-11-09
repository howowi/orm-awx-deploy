This repository aims to provide terraform scripts to deploy awx v19.3.0 on OCI using OKE.
Currently, the project is still under development.

- Scripts folder = scripts required for AWX setup
- awxip.txt      = used to store the public ip address of awx
- awxpwd.txt     = used to store the default password of awx

For dynamic inventory the common project used url is:
https://github.com/oracle/oci-ansible-collection/tree/OCI-AWX-v19.3


Notes:
1) [Only if you try to delete the stack manually]Delete the load balancer(created by kubectl apply) once the stack is deleted


Ref:
https://www.redhat.com/sysadmin/ansible-tower-terraform
https://github.com/ansible/awx-operator
https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengnetworkconfigexample.htm#example-publick8sapi-publicworkers-publiclb
https://docs.oracle.com/en-us/iaas/Content/Registry/Concepts/registryoverview.htm
https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/providers.htm
https://docs.ansible.com/ansible-tower/latest/html/towerapi/api_ref.html
https://github.com/oracle-quickstart/oci-cloudnative
https://github.com/oracle-terraform-modules/terraform-oci-oke
https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/terraformconfigresourcemanager_topic-schema.htm

