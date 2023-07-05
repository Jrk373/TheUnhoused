SELECT
gm.PrimaryId
, cid.AzAhcccsId AS AHCCCSID
, gm.ResAddr1 AS ResidentialAddress1
, gm.ResAddr2 AS ResidentialAddress2
, gm.ResCity AS ResidentialCity
, gm.ResCountyName AS ResidentialCounty
, gm.ResState AS ResidentialState
, gm.ResZipCode AS ResidentialZipCode
, gm.MailAddr1 AS MailingAddress1
, gm.MailAddr2 AS MailingAddress2
, gm.MailCity AS MailingCity
, gm.MailState AS MailingState
, gm.MailZipCode AS MailingZipCode
, gm.HomePhone
, gm.EmergencyPhone
, gm.EmailAddress
, gm.LineOfBusiness
, cid.DOB
, cid.Sex
, ge.BHHShortname
, ge.EnrollmentDate
, ge.DisenrollmentDate
, ge.EnrollmentType
, ge.EligibilityGroupBeginDate
, ge.EligibilityGroupEndDate
, ge.LineOfBusiness
, ge.CoverageType

FROM

globalmembers.dbo.dailyMembershipAllArizonaAddresses gm
LEFT JOIN globalmembers.dbo.dailyMembershipAllArizonaEnrollments ge ON gm.PrimaryID = ge.PrimaryID
LEFT JOIN globalmembers.dbo.clientIdPlus cid ON gm.primaryID = cid.PrimaryID

WHERE

ge.DisenrollmentDate IS NOT NULL