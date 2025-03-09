# Connect to your vCenter server (if not already connected)
# Connect-VIServer -Server <VCENTER_IP_OR_FQDN>

# Specify the name of the VM to tag and the tag name
$vmName = "Your_VM_Name"    # Replace with the actual VM name
$tagName = "PST-WIKI"

# Retrieve the VM
$vm = Get-VM -Name $vmName

# Tag the VM with the "PST-WIKI" tag
New-TagAssignment -Entity $vm -Tag $tagName