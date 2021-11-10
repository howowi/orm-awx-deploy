## Deploy AWX v19.3.0 on OCI using OKE

This repository aims to provide terraform scripts to deploy awx v19.3.0 on OCI using OKE.
Currently, the project is still under development.

- Scripts folder = scripts required for AWX setup
- awxip.txt      = used to store the public ip address of awx
- awxpwd.txt     = used to store the default password of awx

For dynamic inventory the common project used url is:
https://github.com/howowi/oci-awx-project


Notes:
1) Only if you try to delete the stack manually
2) Delete the load balancer(created by kubectl apply) once the stack is deleted

