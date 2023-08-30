#Get-ADUser -Filter {name -like "*eckart*"}

#get-adgroupmember "Enterprise Admins" -recursive

#get-adgroupmember "DTC FN SQL Reporting"  -recursive | ft name

Get-ADPrincipalGroupMembership "wkeckha" | ft name

Get-ADPrincipalGroupMembership -identity "wkeckha" | ft name

Get-ADGroup -Filter{name -like "*fuel*"}