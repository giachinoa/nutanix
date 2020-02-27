# Nutanix LKM
# PowerShell (tested with 5.1)
#
# Purpose:
#    Code for backing up Nutanix LKM files across clusters
#
#    Note:  this just uses basic authentication method
#
# Files:
#
#    clusters.csv
#    Holds list of cluster VIPs and basic authentication info
#
#    get_auth.ps1
#    Generate basic authentication header info
#
#    backup_lkm.ps1
#    Get password for encrypting backup file (this is used for all clusters and backup files).
#    Reads data from clusters.csv file and iterates over VIP's.
#    Connect to cluster, get cluster name.
#    Connect to cluster, get basic info on hosts and VM's, print stats.
#    Connect to cluster, send backup password, get backup file data, write to binary file.
#
<#
TESTING WITH BACKUP FILE:
USE THE mantle_recovery_util TO PRINT OUT THE KEYS THAT ARE IN THE FILE
nutanix@NTNX-16SM6B260126-C-CVM:10.10.50.11:~$ mantle_recovery_util --list_key_ids --backup_file_path=/home/nutanix/Nutanix_KEYBACKUP_PHX-POC034_202002121027.bin --password=mypassword
I0213 02:27:32.621577  1789 mantle_interface.cc:141] Creating Mantle Rpc Server Stub for peer 127.0.0.1:9880
I0213 02:27:32.660023  1789 mantle_recovery_util.cc:203] Key ID: 12432a43-1cdc-44e8-96c4-f1d6d3791c5a
I0213 02:27:32.660068  1789 mantle_recovery_util.cc:203] Key ID: 1e318519-36bb-49e4-95f8-17c231a82314
I0213 02:27:32.660079  1789 mantle_recovery_util.cc:203] Key ID: 2b29499b-6aa0-4207-89ec-dae5dbfcd512
I0213 02:27:32.660087  1789 mantle_recovery_util.cc:203] Key ID: cb20af0d-197d-432e-89d8-3100670d0fbe
I0213 02:27:32.660095  1789 mantle_recovery_util.cc:203] Key ID: d203d223-ac78-48c2-bfd2-114f288113f8
I0213 02:27:32.660106  1789 mantle_recovery_util.cc:145] Recovery is done
I0213 02:27:32.660120  1789 mantle_recovery_util.cc:368] Exiting
#>



