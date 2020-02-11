# get the user's credentials
$cluster_vip = Read-Host " . . . Enter cluster VIP: "
$user = Read-Host " . . . Enter cluster user name: "
$secure_pwd = Read-Host " . . . Enter cluster password: " -AsSecureString
$binary_string = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure_pwd)
$plaintext_password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($binary_string)
    
# create the HTTP Basic Authorization header
$pair = $user + ":" + $plaintext_password
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)

Write-Host ("vip,auth")
Write-Host ($cluster_vip + "," + $base64)
