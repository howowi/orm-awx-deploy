import requests
import json
import base64
import subprocess
import sys

# fetch the password set by awx
command = 'kubectl get secret awx-demo-admin-password -o jsonpath="{.data.password}" | base64 --decode'
pwd = subprocess.check_output(command, shell=True)
pwd = pwd.decode("utf-8")
print("PASSWORD IS:", pwd)

# base64 conversion of username:password
creds = "admin:" + str(pwd)
creds_bytes = creds.encode("ascii")
base64_bytes = base64.b64encode(creds_bytes)
b64_creds = base64_bytes.decode("ascii")

# fetch the external ip
command = "kubectl get services awx-demo-service --output jsonpath='{.status.loadBalancer.ingress[0].ip}'"
external_ip = subprocess.check_output(command, shell=True)
external_ip = external_ip.decode("utf-8")
print("AWX_UI_IP IS:", external_ip)
awx_url = "http://" + str(external_ip) + ":8087"

# save IP and pwd in files to print at job output
awx_pwd_file = open("awxpwd.txt", "w+")
awx_pwd_file.write(pwd)
awx_pwd_file.close()

awx_ip_file = open("awxip.txt", "w+")
awx_ip_file.write(awx_url)
awx_ip_file.close()

####################################################################################################
# Add organization
awx_org_url = awx_url + "/api/v2/organizations/"
print(awx_org_url)
payload = json.dumps(
    {
        "name": "OCI_ORG",
        "description": "Organization created by OCI",
        "max_hosts": 0,
        "default_environment": None,
    }
)
headers = {"Authorization": "Basic " + b64_creds, "Content-Type": "application/json"}
response = requests.request("POST", awx_org_url, headers=headers, data=payload)
print("\nORGANIZATION ADD COMPLETE! ", response.text)

####################################################################################################
# Add oci credential type
awx_cred_type_url = awx_url + "/api/v2/credential_types/"
payload = json.dumps(
    {
        "name": "OCI",
        "description": "Custom credential type for OCI AWX config",
        "kind": "cloud",
        "inputs": {
            "fields": [
                {"id": "user_ocid", "type": "string", "label": "User OCID"},
                {"id": "fingerprint", "type": "string", "label": "Fingerprint"},
                {"id": "tenant_ocid", "type": "string", "label": "Tenant OCID"},
                {
                    "id": "pass_phrase",
                    "type": "string",
                    "label": "Passphrase(optional)",
                },
                {"id": "region", "type": "string", "label": "Region"},
                {
                    "id": "private_user_key",
                    "type": "string",
                    "label": "Private User Key",
                    "secret": True,
                    "multiline": True,
                },
            ],
            "required": [
                "user_ocid",
                "tenant_ocid",
                "region",
                "fingerprint",
                "private_user_key",
            ],
        },
        "injectors": {
            "env": {
                "OCI_CONFIG_FILE": "{{ tower.filename.config }}",
                "OCI_USER_KEY_FILE": "{{ tower.filename.keyfile }}",
            },
            "file": {
                "template.config": "[DEFAULT]\nuser={{ user_ocid }}\nfingerprint={{ fingerprint }}\ntenancy={{ tenant_ocid }}\nregion={{ region }}\npass_phrase={{ pass_phrase }}",
                "template.keyfile": "{{ private_user_key }}",
            },
        },
    }
)
headers = {"Authorization": "Basic " + b64_creds, "Content-Type": "application/json"}
response = requests.request("POST", awx_cred_type_url, headers=headers, data=payload)
print("\nCRED TYPE ADD COMPLETE! ", response.text)

####################################################################################################
# Add execution environment
awx_ee_image_name = "empty_image_name"
if sys.argv[1]:
    awx_ee_image_name=sys.argv[1]
awx_ee_url = awx_url + "/api/v2/organizations/2/execution_environments/"
payload = json.dumps(
    {
        "name": "OCI_EXECUTION_ENVIRONMENT",
        "description": "Execution environment loaded with OCI Python SDK",
        "image": awx_ee_image_name,
        "credential": None,
        "pull": "always",
    }
)
headers = {"Authorization": "Basic " + b64_creds, "Content-Type": "application/json"}
response = requests.request("POST", awx_ee_url, headers=headers, data=payload)
print("\nEXECUTION ENVIRONMENT ADD COMPLETE! ", response.text)

####################################################################################################
# Link execution environment with the ORG
awx_org_url = awx_url + "/api/v2/organizations/2/"
print(awx_org_url)
payload = json.dumps(
    {
        "name": "OCI_ORG",
        "description": "Organization created by OCI",
        "max_hosts": 0,
        "default_environment": 3,
    }
)
headers = {"Authorization": "Basic " + b64_creds, "Content-Type": "application/json"}
response = requests.request("PUT", awx_org_url, headers=headers, data=payload)
print("\nORGANIZATION UPDATE COMPLETE! ", response.text)

####################################################################################################
# Connect ansible galaxy creds to the Organization
awx_galaxy_creds_url = awx_url + "/api/v2/organizations/2/galaxy_credentials/"
print(awx_galaxy_creds_url)
payload = json.dumps({"id": 2})
headers = {"Authorization": "Basic " + b64_creds, "Content-Type": "application/json"}
response = requests.request("POST", awx_galaxy_creds_url, headers=headers, data=payload)
print("\nORGANIZATION UPDATE FOR GALAXY_CREDENTIAL COMPLETE! ", response.text)


####################################################################################################
# Add project
awx_proj_url = awx_url + "/api/v2/projects/"
payload = json.dumps(
    {
        "name": "OCI_DEPLOYMENT_PROJECT",
        "description": "Project for deployment to OCI resources",
        "local_path": "",
        "scm_type": "git",
        "scm_url": "https://github.com/howowi/oci-awx-project",
        "scm_branch": "master",
        "scm_refspec": "",
        "scm_clean": True,
        "scm_track_submodules": False,
        "scm_delete_on_update": True,
        "credential": None,
        "timeout": 0,
        "organization": 2,
        "scm_update_on_launch": True,
        "scm_update_cache_timeout": 0,
        "allow_override": False,
        "default_environment": 3,
    }
)
headers = {"Authorization": "Basic " + b64_creds, "Content-Type": "application/json"}
response = requests.request("POST", awx_proj_url, headers=headers, data=payload)

print("\nCOMMON PROJECT ADD COMPLETE", response.text)

####################################################################################################
# Add inventory
awx_inv_url = awx_url + "/api/v2/inventories/"
payload = json.dumps(
    {
        "name": "OCI_INVENTORY",
        "description": "Dynamic inventory used for fetching the hosts and groups",
        "organization": 2,
        "kind": "",
        "host_filter": None,
        "variables": "---\nansible_connection: local",
    }
)

headers = {"Authorization": "Basic " + b64_creds, "Content-Type": "application/json"}
response = requests.request("POST", awx_inv_url, headers=headers, data=payload)
print("\nDYNAMIC INVENTORY ADD COMPLETE", response.text)

####################################################################################################
# Add inventory sources
awx_inv_src_url = awx_url + "/api/v2/inventories/2/inventory_sources/"
payload = json.dumps(
    {
        "name": "OCI Inventory Source",
        "description": "Dynamic Inventory source from a git project",
        "source": "scm",
        "source_path": "",
        "source_vars": "",
        "credential": None,
        "enabled_var": "",
        "enabled_value": "",
        "host_filter": "",
        "overwrite": True,
        "overwrite_vars": True,
        "timeout": 0,
        "verbosity": 2,
        "execution_environment": 3,
        "update_on_launch": False,
        "update_cache_timeout": 0,
        "source_project": 8,
        "update_on_project_update": True,
    }
)
headers = {"Authorization": "Basic " + b64_creds, "Content-Type": "application/json"}
response = requests.request("POST", awx_inv_src_url, headers=headers, data=payload)

print("\nINVENTORY SOURCE ADD COMPLETE!", response.text)
