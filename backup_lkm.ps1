# Nutanix PowerShell
# v01

#Classes
class RequestParameters {
    [string]$uri_base
    [string]$uri_operator
    [string]$payload
    [string]$method
    [Hashtable]$headers
}

#Variables & initializations
$cluster_file = "c:\script\clusters.csv"
$backup_password = ""
$parameters = [RequestParameters]::new()
$parameters.headers = [Hashtable]::new()
$parameters.headers.Add("Accept", "application/json")
$parameters.headers.Add("Content-Type", "application/json")
$parameters.headers.Add("Authorization", "")

function getBackupPassword () {
    #get password that will be used to encrypt the backup file
    $backup_password = Read-Host "Enter encryption password for the backups for all clusters: "
    return $backup_password
}

function callREST () {
    param([RequestParameters]$p)
    $uri = $p.uri_base + $p.uri_operator
    try {
        If (-not ([string]::IsNullOrEmpty($r.payload))) {
            Invoke-RestMethod -Uri $uri -Headers $p.headers -Method $p.method -Body $p.payload -TimeoutSec 30 -UseBasicParsing -DisableKeepAlive
        }
        Else {
            Invoke-RestMethod -Uri $uri -Headers $p.headers -Method $p.method -TimeoutSec 30 -UseBasicParsing -DisableKeepAlive
        }
    }
    catch [System.Net.WebException] { #timeouts, missing/bad params, etc
        Write-Host "An error occurred while processing the API request."
        Write-Host $_
    }
    catch [System.Net.ProtocolViolationException] { #wrong method, e.g. GET vs POST, etc.
        Write-Host "A payload/request body error occurred while making the request."
        Write-Host $_
    }
}

# disable SSL certification verification;  you probably shouldn't do this in production ...
if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type)
{
$certCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback +=
                    delegate
                    (
                        Object obj,
                        X509Certificate certificate,
                        X509Chain chain,
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@
    Add-Type $certCallback
 }
[ServerCertificateValidationCallback]::Ignore()
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$backup_password = getBackupPassword

Import-csv $cluster_file | ForEach-Object {
    $cluster_vip = $_.vip
    $auth_header = "Basic " + $_.auth
    Write-Host ("##################################################################")
    Write-Host ("Connecting to Cluster VIP:  " + $cluster_vip)
    $parameters.uri_base = "https://" + $cluster_vip + ":9440/PrismGateway/services/rest/v2.0"
    $parameters.headers.Remove("Authorization")
    $parameters.headers.Add("Authorization", "Basic " + $_.auth)
        
    ############################################################################
    #CALL REST:  get cluster info
    $parameters.payload = ""
    $parameters.uri_operator = "/cluster"
    $parameters.method = "GET"
    $response = callREST -p $parameters
    $cluster_name = $response.name

    ############################################################################
    #CALL REST:  get host info
    $parameters.payload = ""
    $parameters.uri_operator = "/hosts"
    $parameters.method = "GET"
    $response = callREST -p $parameters
    $host_stats = @{ cores = [Int]0; ram = [Long]0 }
    $response.entities | ForEach-Object {
        $host_stats.cores += $_.num_cpu_sockets * $_.num_cpu_cores
        $host_stats.ram += [Math]::Round([Double]$_.memory_capacity_in_bytes/1GB)
        $cpu_usage_display = "{00:n2}" -f [Math]::Round([Double]$_.stats.hypervisor_cpu_usage_ppm/10000,2)
        $memory_usage_display = "{00:n2}" -f [Math]::Round([Double]$_.stats.hypervisor_memory_usage_ppm/10000,2)
        Write-Host (" . . . Host " + $_.name + ", " + $_.num_vms + " VMs, " + $cpu_usage_display + "% CPU, " + $memory_usage_display + "% RAM")
    }
    Write-Host (" . . . . . . " + $host_stats.cores + " Total CPU Cores, " )
    Write-Host (" . . . . . . " + $host_stats.ram + " Total GB RAM" )

    ############################################################################
    #CALL REST:  get vm info
    $parameters.payload = ""
    $parameters.uri_operator = "/vms"
    $parameters.method = "GET"
    $response = callREST -p $parameters
    $vm_stats = @{ num_vm = [Int]0; power_on = [Int]0; power_off = [Int]0; vcpu = [Int]0; ram = [Long]0 }
    $response.entities | ForEach-Object {
        Switch ($_.power_state) {
            "on" { $vm_stats.power_on += 1 }
            "off" { $vm_stats.power_off += 1 }
        }
        $vm_stats.vcpu += $_.num_vcpus * $_.num_cores_per_vcpu
        $vm_stats.ram += $_.memory_mb
        $vm_stats.num_vm += 1
    }
    $total_ram = [Math]::Round([Double]$vm_stats.ram/1000,0)
    Write-Host (" . . . " + $vm_stats.num_vm + " VMs")
    Write-Host (" . . . . . . " + $vm_stats.power_on + " ON, " + $vm_stats.power_off + " OFF")
    Write-Host (" . . . . . . " + $vm_stats.vcpu + " Total vCPU, " + $total_ram + " Total GB RAM")
    #$response.entities | Format-Table -Property name, power_state

    ############################################################################
    #CALL REST:  backup LKM keys
    $parameters.payload = "{ `
      ""password"":""" + $backup_password + """ `
      }"
    $parameters.uri_operator = "/data_at_rest_encryption/download_encryption_key"
    $parameters.method = "POST"
    $response = callREST -p $parameters
    $backup = $response.backup_data
    #decode and write out binary file needed by mantle_recovery_util
    $datetime = Get-Date -Format "yyyyMMddHHmm"
    $file_name = "c:\script\Nutanix_KEYBACKUP_" + $cluster_name + "_" + $datetime
    Write-Host "---"
    Write-Host ("Backup File:  " + $file_name)
    [System.Convert]::FromBase64String($backup) | Set-Content $file_name -Encoding Byte
}