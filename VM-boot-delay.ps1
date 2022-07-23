# Set boot dalay to 7s on all VM's
#
$BootDelay = “7000” # 7000=7 seconds
Get-VM | ForEach-Object {
    $vm = Get-View $_.Id
    $vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
    $vmConfigSpec.BootOptions = New-Object VMware.Vim.VirtualMachineBootOptions
    $vmConfigSpec.BootOptions.BootDelay = $BootDelay
    $vm.ReconfigVM_Task($vmConfigSpec) 
    echo "VM name : " $vm.name
    echo "-----------------------------------------"
} 
