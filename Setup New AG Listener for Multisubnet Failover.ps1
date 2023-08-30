Import-Module FailoverClusters
Get-ClusterResource SQLGP_AG_SQLGP_List | Set-ClusterParameter RegisterAllProvidersIP 0 
Get-ClusterResource SQLGP_AG_SQLGP_List | Set-ClusterParameter HostRecordTTL 300
Stop-ClusterResource SQLGP_AG_SQLGP_List
Start-ClusterResource SQLGP_AG_SQLGP_List
Start-ClusterResource SQLGP_AG

#$clust = Get-Cluster; $clust.CrossSubnetDelay = 3000; $clust.CrossSubnetThreshold = 7


