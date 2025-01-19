Function Set-WelcomeMessage {
    <#
        .SYNOPSIS
        This function set Welcome Message on the ESXi server.
        
    
        .NOTES
        File Name      : set_welcome_message.ps1
        Author         : Stanislav Musil
        Prerequisite   : PowerShell
        Website        : https://vpxd.dc5.cz/
        X (Twitter)    : https://www.x.com/stmusil
    
        .DESCRIPTION
        The script is a function that takes two parameters, the ESXi server name and welcome message. And set the welcome message on the ESXi server.
        To use the function, you can dot-source the script and then call the function. 
        Windows:   . .\set_welcome_message.ps1
        Mac/Linux: . ./set_welcome_message.ps1
    
        .EXAMPLE
        Set-WelcomeMessage -Hostname "ESXi.example.com" -WelcomeMessage "Welcome to {{hostname}"

    #>
    param (
        [string]$HostName,
        [string]$WelcomeMessage
    )
   
    # Ensure PowerCLI module is imported
    if (-not (Get-Module -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue)) {
        Import-Module VMware.VimAutomation.Core
    }`

# Define the target host and the parameter values
$ESXihost = Get-VMHost -Name $HostName
$paramName = "Annotations.WelcomeMessage"

$current = Get-AdvancedSetting -Entity $ESXihost -Name $paramName
Write-Host "Current Weclome message:"  $current.Value

# Set the advanced parameter
Get-AdvancedSetting -Entity $ESXihost -Name $paramName | Set-AdvancedSetting -Value $WelcomeMessage -Confirm:$false

# Verify the change
$updatedSetting = Get-AdvancedSetting -Entity $ESXihost -Name $paramName
Write-Output "New $paramName value on $ESXihost : $($updatedSetting.Value)"

}
