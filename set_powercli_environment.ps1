# Install VMware PowerCLI
Install-Module -Name VMware.PowerCLI -Scope CurrentUser

# Ignore invalid certificates if your vCenter uses self-signed certs
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
