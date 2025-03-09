# Connect to your vCenter server (if not already connected)
# Connect-VIServer -Server <VCENTER_IP_OR_FQDN>

# Create the "Backup" tag category (using Single cardinality; adjust if needed)
New-TagCategory -Name "Backup" -Cardinality Single -EntityType VirtualMachine

# Create the tags within the "Backup" category
New-Tag -Name "PST-WIKI" -Category "Backup"
New-Tag -Name "PST-PROD" -Category "Backup"
