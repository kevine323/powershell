Import-Module FailoverClusters

Get-ClusterQuorum -Cluster SQLGPCluster

#Set-ClusterQuorum -NodeAndFileShareMajority \\fileserver\fsw


<#Reset Node Weight
$node = “AlwaysOnSrv1”
(Get-ClusterNode $node).NodeWeight = 0

$cluster = (Get-ClusterNode $node).Cluster
$nodes = Get-ClusterNode -Cluster $cluster

$nodes | Format-Table -property NodeName, State, NodeWeight
#>

