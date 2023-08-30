#Get cluster info
get-cluster | format-list *

#Get the name of the cluster
Get-Cluster

#Get the cluster resources
Get-ClusterResource

#Get cluser resource detail
Get-ClusterResource | fl *  #or for one resource Get-ClusterResource "SQLGP_AG" | fl *  

#Get Cluster Logs
Get-ClusterLog -Destination c:\temp -TimeSpan 1000 -Cluster SQLGPCLUSTER

#Get Resource Group Info
Get-ClusterGroup 

#Get Quorum Model
Get-ClusterQuorum

#Change Quorum Model
Set-ClusterQuorum -NodeMajority
Set-ClusterQuorum -NodeAndFileShareMajority \\vbdswitness\GPSQLQuorum

#Change or Add Owners to a resource or node
Get-ClusterResource "Cluster IP Address" | Set-ClusterOwnerNode -Owners VBDSGPSQL1, DFWSGPSQL1

#Start Cluster Withour Quorum
#start-clusternode -name DFWSGPSQL -cluster SQLGPCluster -FixQuorum

#Move Cluster Group
Move-ClusterGroup MyPrintServer -Node node2

#Get Cluster Resource Dependencies
Get-ClusterResourceDependency "SQLGP_AG_SQLGP"

#Get Registered DNS Servers
Get-DnsClientServerAddress