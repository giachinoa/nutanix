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



