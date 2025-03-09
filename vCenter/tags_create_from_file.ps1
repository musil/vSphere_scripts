# Connect to your vCenter server (if not already connected)
# Connect-VIServer -Server <VCENTER_IP_OR_FQDN>

# Create the "Backup" tag category (using Single cardinality; adjust if needed)
New-TagCategory -Name "Backup" -Cardinality Single -EntityType VirtualMachine

# Read the tag names from a file (each tag on a new line)
# Make sure the file "tags.txt" exists in the current directory or provide a full path.
$tagNames = Get-Content -Path "tags_create_from_file.txt"

# Create each tag in the "Backup" category
foreach ($tag in $tagNames) {
    New-Tag -Name $tag -Category "Backup"
}