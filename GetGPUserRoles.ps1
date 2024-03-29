############################################################################################
#Get Users In GP
############################################################################################
$DynConn = "server=SQLDYN\Dynamics;database=Dynamics;uid=sa;pwd="

#Edit Where Clause for Specific Users // Where userid not in ('DYNSA','DYNSECSA','SA')
$GetUsers = "Select Distinct(left(UserID, len(userid))) as Name
               From DYNAMICS.dbo.SY10500              
             Where userid in ('gdcottr','gdasout')
              order by left(UserID, len(userid))"
                                       
#Create New DataAdapter     
$UserDA  = new-object System.Data.SQLClient.SQLDataAdapter($GetUsers,$DynConn)    
#Create Data Table For Databases
$UserDT  = new-object System.Data.DataTable         
#Fill Data Table With UserID's
$UserDA.fill($UserDT)

############################################################################################
#Loop Through Users To Get Roles
############################################################################################
foreach ($UserID in $UserDT.rows) 
{
$Usr = $UserID.Name
$GetRoleInfo = " SELECT DISTINCT S.USERID [User_ID],
                        S.CMPANYID Company_ID,
                        C.CMPNYNAM Company_Name,
                        S.SECURITYROLEID Security_Role_ID,
                        coalesce(T.SECURITYTASKID,'') Security_Task_ID,
                        coalesce(TM.SECURITYTASKNAME,'') Security_Task_Name,                                    
                        coalesce(R.DICTID,SO.ASI_DICTID,'') Dictionary_ID,
                        coalesce(R.PRODNAME,'') Product_Name,
                        coalesce(R.TYPESTR,SO.ResType,'') Resource_Type,
                        coalesce(R.DSPLNAME,SO.SmartlistObject,'') Resource_Display_Name,
                        coalesce(R.RESTECHNAME,'') Resource_Technical_Name,
                        coalesce(R.Series_Name,'') Resource_Series
                   FROM SY10500 S  LEFT OUTER JOIN SY01500 C   -- company master
                     ON S.CMPANYID = C.CMPANYID
                                   LEFT OUTER JOIN SY10600 T  -- tasks in roles
                     ON S.SECURITYROLEID = T.SECURITYROLEID 
                                   LEFT OUTER JOIN SY09000 TM  -- tasks master
                     ON T.SECURITYTASKID = TM.SECURITYTASKID 
                                   LEFT OUTER JOIN SY10700 O  -- operations in tasks
                     ON T.SECURITYTASKID = O.SECURITYTASKID 
                                   LEFT OUTER JOIN SY09400 R  -- resource descriptions
                     ON R.DICTID = O.DICTID AND O.SECRESTYPE = R.SECRESTYPE
                    AND O.SECURITYID = R.SECURITYID 
                                   LEFT OUTER JOIN (SELECT SECURITYTASKID, 
                                                           SECURITYID, 
                                                           DICTID, 
                                                           SECRESTYPE,
                                                           ASI_DICTID, 
                                                           SL_OBJID, 
                                                           SmartlistObject,
                                                           'Smartlist' ResType
                                                      FROM (SELECT SECURITYTASKID, 
                                                                   SECURITYID, 
                                                                   DICTID, 
                                                                   SECRESTYPE,
                                                                   SECURITYID / 65536 ASI_DICTID, 
                                                                   SECURITYID % 65536 SL_OBJID
                                                              FROM SY10700
                                                             WHERE SECRESTYPE = 1000 AND DICTID = 1493) ST JOIN
                                                            (SELECT coalesce(TRANSVAL, ASI_Favorite_Name) SmartlistObject,
                                                                    ASI_Favorite_Dict_ID, 
                                                                    ASI_Favorite_Type
                                                               FROM ASIEXP81 F LEFT JOIN ASITAB30 A
                                                                 ON F.ASI_Favorite_Name = A.UNTRSVAL
                                                                AND A.Language_ID = 0
                                                             WHERE ASI_Favorite_Save_Level = 0) SM
                                                                ON ASI_DICTID = ASI_Favorite_Dict_ID
                                                         AND SL_OBJID = ASI_Favorite_Type) SO
                       ON SO.DICTID = O.DICTID AND O.SECRESTYPE = SO.SECRESTYPE
                      AND O.SECURITYID = SO.SECURITYID
                    Where S.UserID = '$Usr'" 
#Create New DataAdapter     
$RoleDA  = new-object System.Data.SQLClient.SQLDataAdapter($GetRoleInfo,$DynConn)
#Create Data Table For User Roles
$RoleDT  = new-object System.Data.DataTable
     
$RoleDA.fill($RoleDT)
     
$RoleDT | Format-Table -AutoSize
     
$RoleDT | Export-Csv $("S:\Temp\GP Reports\"+$Usr+"_GPAccess.csv") -NoType -ErrorAction SilentlyContinue 
}