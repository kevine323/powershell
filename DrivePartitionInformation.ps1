#
# -------------------------------------------------------------------------------
# Drive and Partition Information
# -------------------------------------------------------------------------------
#                                MODIFICATION LOG
# -------------------------------------------------------------------------------
# 2012-11-14 WGS Initial Creation.
# 2012-12-05 WGS Add BlockSize, OffsetSectors, Export to delimited file.
# 2013-01-11 WGS Figured out how to do this all inline.
# -------------------------------------------------------------------------------
#
FUNCTION Get-DriveLetter($PartPath) {
#Get the logical disk mapping
$LogicalDisks = Get-WMIObject Win32_LogicalDiskToPartition | `
Where-Object {$_.Antecedent -eq $PartPath}
$LogicalDrive = Get-WMIObject Win32_LogicalDisk | `
Where-Object {$_.__PATH -eq $LogicalDisks.Dependent}
$LogicalDrive.DeviceID
}
FUNCTION Get-PartitionAlignment {
Get-WMIObject Win32_DiskPartition | `
Sort-Object DiskIndex, Index | `
Select-Object -Property `
@{Expression = {$_.DiskIndex};Label="Disk"},`
@{Expression = {$_.Index};Label="Partition"},`
@{Expression = {Get-DriveLetter($_.__PATH)};Label="Drive"},`
@{Expression = {$_.BootPartition};Label="BootPartition"},`
@{Expression = {"{0:N3}" -f ($_.Size/1Gb)};Label="Size_GB"},`
@{Expression = {"{0:N0}" -f ($_.BlockSize)};Label="BlockSize"},`
@{Expression = {"{0:N0}" -f ($_.StartingOffset/1Kb)};Label="Offset_KB"},`
@{Expression = {"{0:N0}" -f ($_.StartingOffset/$_.BlockSize)}; Label="OffsetSectors"},`
@{Expression = {IF (($_.StartingOffset % 64KB) -EQ 0) {" Yes"} ELSE {"  No"}};Label="64KB"}
}
# Hash table to set the alignment of the properties in the format-table
$b = `
@{Expression = {$_.Disk};Label="Disk"},`
@{Expression = {$_.Partition};Label="Partition"},`
@{Expression = {$_.Drive};Label="Drive"},`
@{Expression = {$_.BootPartition};Label="BootPartition"},`
@{Expression = {"{0:N3}" -f ($_.Size_GB)};Label="Size_GB";align="right"},`
@{Expression = {"{0:N0}" -f ($_.BlockSize)};Label="BlockSize";align="right"},`
@{Expression = {"{0:N0}" -f ($_.Offset_KB)};Label="Offset_KB";align="right"},`
@{Expression = {"{0:N0}" -f ($_.OffsetSectors)};Label="OffsetSectors";align="right"},`
@{Expression = {$_.{64KB}};Label="64KB"}
$a = Get-PartitionAlignment
# Display formatted data on the screen
$a | Format-Table $b -AutoSize
# Export to a pipe-delimited file
$a | Export-CSV $ENV:temp\PartInfo.txt -Delimiter "|" -NoTypeInformation
# Open the file in NotePad
Notepad $ENV:temp\PartInfo.txt
