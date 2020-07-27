# Description
This script creates a service principal in Azure AD, it also generates and uploads a self signed cert for authentication.
# Usage
````powershell
createServicePrincipal.ps1 -password "asecurepasswordforgeneratingacert123!" -years 3 -DisplayName "theSPdisplayname"
````
# Requirements
- Must be run as admin to generate cert
- Must be able to log in with AzureAD rights for creating service principles

# Output
When run successfully you will receive a connection string that you can use from the computer you ran the script from.

# Notes
This script does not apply any rights to the service principal it creates, you will need to define the rights for the service principal in Azure AD, or via powershell.

Example, to give the SP Global Reader rights the following can be run.

````powershell
New-AzRoleAssignment -ApplicationId $sp.ApplicationId -RoleDefinitionName 'Reader'
````