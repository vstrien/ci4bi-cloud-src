[CmdletBinding()]
param(
    [string]$DataFactoryName,
    [string]$ResourceGroupName,
    [string]$IntegrationRuntimeName
)

$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName      
    "Logging in to Azure..."
    $account = Add-AzAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
Write-Output $account

$Status = Get-AzDataFactoryV2IntegrationRuntime -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName -Name $IntegrationRuntimeName -ErrorAction "Stop";
Write-Output "Starting Status is: '$($Status.State)'";
while($Status.State -ne "Stopped") {
    if($Status.State -eq "Started") {
        Stop-AzDataFactoryV2IntegrationRuntime -DataFactoryName $DataFactoryName -Name $IntegrationRuntimeName -ResourceGroupName $ResourceGroupName  -Force;
        Write-Output "Status was '$($Status.State)' so gave command to stop IR";
    }
    Start-Sleep -Seconds 32 ;
    $Status = Get-AzDataFactoryV2IntegrationRuntime -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName -Name $IntegrationRuntimeName  -ErrorAction "Stop";
    Write-Output "Status evaluated after 32 second sleep, Status is now: '$($Status.State)'";
}
Write-Output "Script completed, final Status is: '$($Status.State)'";