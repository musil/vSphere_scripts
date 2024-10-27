Function Get-vCenterVersion {
<#
    .SYNOPSIS
    This function retrieves the vCenter version and build number. 
    Based on https://knowledge.broadcom.com/external/article?legacyId=2143838

    .NOTES
    File Name      : get-vcenter-version.ps1
    Author         : Stanislav Musil
    Prerequisite   : PowerShell
    Website        : https://vpxd.dc5.cz/index.php/category/blog/
    X (Twitter)    : https://www.x.com/stmusil

    .DESCRIPTION
    The script is a function that takes a single parameter, the vCenter server name. Retrieves the version and build number. 
    To use the function, you can dot-source the script and then call the function. 
    Windows:   . .\get-vcenter-version.ps1
    Mac/Linux: . ./get-vcenter-version.ps1

    .EXAMPLE
    Get-vCenterVersion -vCenterServer "vCenter.DC5.cz"
    or
    Get-vCenterVersion
#>

    Param (
        [Parameter(Mandatory=$false)]
        [VMware.VimAutomation.ViCore.Util10.VersionedObjectImpl]$vCenterServer
    )

        if(-not $vCenterServer) {
            $vCenterServer = $global:DefaultVIServer
        }

        # https://knowledge.broadcom.com/external/article?legacyId=2143838
        $vCenterVersionMappings = @{
            "24026615"="vCenter Server 7.0 Update 3r","17.06.2024","7.0.3.02000","24026615","24026615"
            "23788036"="vCenter Server 7.0 Update 3q","21.05.2024","7.0.3.01900","23788036","23788036"
            "22837322"="vCenter Server 7.0 Update 3p","07.12.2023","7.0.3.01800","22837322","22837322"
            "22357613"="vCenter Server 7.0 Update 3o","28.09.2023","7.0.3.01700","22357613","22357613"
            "21958406"="vCenter Server 7.0 Update 3n","07.07.2023","7.0.3.01600","21958406","21958406"
            "21784236"="vCenter Server 7.0 Update 3m","22.06.2023","7.0.3.01500","21784236","21784236"
            "21477706"="vCenter Server 7.0 Update 3l","30.03.2023","7.0.3.01400","21477706","21477706"
            "21290409"="vCenter Server 7.0 Update 3k","23.02.2023","7.0.3.01300","21290409","21290409"
            "20990077"="vCenter Server 7.0 Update 3j","22.12.2022","7.0.3.01200","20990077","20990077"
            "20845200"="vCenter Server 7.0 Update 3i","08.12.2022","7.0.3.01100","20845200","20845200"
            "20395099"="vCenter Server 7.0 Update 3h","13.09.2022","7.0.3.01000","20395099","20395099"
            "20150588"="vCenter Server 7.0 Update 3g","23.07.2022","7.0.3.00800","20150588","20150588"
            "20051473"="vCenter Server 7.0 Update 3f","12.07.2022","7.0.3.00700","20051473","20051473"
            "19717403"="vCenter Server 7.0 Update 3e","12.05.2022","7.0.3.00600","19717403","19717403"
            "19480866"="vCenter Server 7.0 Update 3d","29.03.2022","7.0.3.00500","19480866","19480866"
            "19234570"="vCenter Server 7.0 Update 3c","27.01.2022","7.0.3.00300","19234570","19234570"
            "18778458"="vCenter Server 7.0 Update 3a","21.10.2021","7.0.3.00100","18778458","18778458"
            "18700403"="vCenter Server 7.0 Update 3","05.10.2021","7.0.3.00000","18700403","18700403"
            "18455184"="vCenter Server 7.0 Update 2d","21.09.2021","7.0.2.00500","18455184","18455184"
            "18356314"="vCenter Server 7.0 Update 2c","24.08.2021","7.0.2.00400","18356314","18356314"
            "17958471"="vCenter Server 7.0 Update 2b","25.05.2021","7.0.2.00200","17958471","17958471"
            "17920168"="vCenter Server 7.0 Update 2a","27.04.2021","7.0.2.00100","17920168","17920168"
            "17694817"="vCenter Server 7.0 Update 2","09.03.2021","7.0.2.00000","17694817","17694817"
            "17491160"="vCenter Server 7.0 Update 1d","02.02.2021","7.0.1.00300","17491101","17491160"
            "17327586"="vCenter Server 7.0 Update 1c","17.12.2020","7.0.1.00200","17327517","17327586"
            "17005016"="vCenter Server 7.0 Update 1a","22.10.2020","7.0.1.00100","17004997","17005016"
            "16858589"="vCenter Server 7.0 Update 1","06.10.2020","7.0.1.00000","16860138","16858589"
            "16749670"="vCenter Server 7.0.0d","25.08.2020","7.0.0.10700","16749653","16749670"
            "16620013"="vCenter Server 7.0.0c","30.07.2020","7.0.0.10600","16620007","16620013"
            "16386335"="vCenter Server 7.0.0b","23.06.2020","7.0.0.10400","16386292","16386335"
            "16189207"="vCenter Server 7.0.0a","19.05.2020","7.0.0.10300","16189094","16189207"
            "15952599"="vCenter Server 7.0 GA","02.04.2020","7.0.0.10100","15952498","15952599"
            "24091160"="vCenter Server 8.0 Update 3a","18.07.2024","8.0.3.00100","24091160","24091160"
            "24022515"="vCenter Server 8.0 Update 3","25.06.2024","8.0.3.00000","24022515","24022515"
            "23929136"="vCenter Server 8.0 Update 2d","17.06.2024","8.0.2.00400","23929136","23929136"
            "23504390"="vCenter Server 8.0 Update 2c","26.03.2024","8.0.2.00300","23504390","23504390"
            "23319993"="vCenter Server 8.0 Update 2b","04.03.2024","8.0.2.00200","23319993","23319993"
            "22617221"="vCenter Server 8.0 Update 2a","26.10.2023","8.0.2.00100","22617221","22617221"
            "22385739"="vCenter Server 8.0 Update 2","21.09.2023","8.0.2.00000","22385739","22385739"
            "22368047"="vCenter Server 8.0 Update 1d","24.10.2023","8.0.1.00400","22368047","22368047"
            "22088981"="vCenter Server 8.0 Update 1c","27.07.2023","8.0.1.00300","22088981","22088981"
            "21860503"="vCenter Server 8.0 Update 1b","22.06.2023","8.0.1.00200","21860503","21860503"
            "21815093"="vCenter Server 8.0 Update 1a","01.06.2023","8.0.1.00100","21815093","21815093"
            "21560480"="vCenter Server 8.0 Update 1","18.04.2023","8.0.1.00000","21560480","21560480"
            "21457384"="vCenter Server 8.0c","30.03.2023","8.0.0.10300","21457384","21457384"
            "21216066"="vCenter Server 8.0b","14.02.2023","8.0.0.10200","21216066","21216066"
            "20920323"="vCenter Server 8.0a","16.12.2022","8.0.0.10100","20920323","20920323"
            "20519528"="vCenter Server 8.0 GA ","11.10.2022","8.0.0.10000","20519528","20519528"
            "24262322"="vCenter Server 8.0 Update 3b","17.9.2024","8.0.3.00200","24262322","24262322"
            "24201990"="vCenter Server 7.0 Update 3s","17.9.2024","7.0.3.02100","24201990","24201990"
            "24305161"="vCenter Server 8.0 Update 3c","09.10.2024","8.0.3.00300","24305161","24305161"
            "24322018"="vCenter Server 7.0 Update 3t","21.10.2024","7.0.3.02200","24322018","24322018"
            "24322831"="vCenter Server 8.0 Update 3d","21.10.2024","8.0.3.00400","24322831","24322831"
        }

        $vCenterServerVersion = $vCenterServer.Version
        $vCenterServerBuild = $vCenterServer.Build
        $vCenterVersion,$vCenterReleaseDate,$vCenterVersionFull,$vCenterReleaseDate,$vCenterMobVersion = "Unknown","Unknown","Unknown","Unknown","Unknown"
        $vCenterName = $vCenterServer.Name

    #if($vCenterVersionMappings.ContainsKey($vCenterServerBuild)) {
    if ($null -ne $vCenterServerBuild -and $vCenterVersionMappings.ContainsKey($vCenterServerBuild)) {
        ($vCenterServerVersion,$vCenterReleaseDate,$vCenterVersionFull,$VAM,$vCenterMobVersion) = $vCenterVersionMappings[$vCenterServerBuild].split(",")
    }

    
# Convert the keys to integers and sort them
$sortedKeys = $vCenterVersionMappings.Keys | ForEach-Object { [int]$_ } | Sort-Object

# Get the greatest number
$greatestKey = $sortedKeys[-1]

    $out = [pscustomobject] @{
        vCenter_Name = $vCenterName;
        vCenter_Build = $vCenterServerBuild;
        vCenter_ReleaseName = $vCenterServerVersion;
        vCenter_MOB = $vCenterMobVersion;
        vCenter_VAMI = $VAMI;
        vCenter_Version_Full = $vCenterVersionFull;
        Release_Date = $vCenterReleaseDate;

    }
    $out
# Compare $vCenterServerBuild with $greatestKey
if ($vCenterServerBuild -lt $greatestKey) {
    Write-Host "vCenter upgrade possible. `n" -ForegroundColor Red
} elseif ($vCenterServerBuild -eq $greatestKey) {
    Write-Host "Latest version/ up to date. `n" -ForegroundColor Green
} else {
    Write-Host "Update this script, looks like it's outdated. `n"  -ForegroundColor Magenta
}

}
