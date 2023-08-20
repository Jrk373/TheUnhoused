-- Homelessnes Data (Not Homeless + SUD Count)
-- This code identifies individuals who indicated "Not Homeless"
-- as thier primary address in Globalmembers.dbo.ClientAddress, then gathers
-- certain demographic information. Then in a seperate query, calls the 
-- isSABGDx indicator from Claims.dbo.SHCAVos. If 'Y' is indicated anywhere
-- the query returns 'Y'. The data from each query is then combined into
-- ##HomelessSample. This data will be used to select a random control sample.

-- Begin Program

-- Drop TempTable ##HomelessSample before starting

IF OBJECT_ID (N'tempdb.dbo.##NotHomelessSample') IS NOT NULL
	DROP TABLE ##NotHomelessSample

-- Set the Date Range

Declare @start as date = '10-01-2017'
Declare @end as date = '09-30-2021'

---- Create a TempTable

CREATE TABLE ##NotHomelessSample (
	primaryId varchar (25)
	, randomId varchar (25)
	, dob varchar (25)
	, sex varchar (25)
	, countyCode varchar (25)
	, city varchar (25)
	, zipCode varchar (25)
)

---- Insert Query into TempTable

INSERT INTO ##NotHomelessSample

-- Begin Query

SELECT
	DISTINCT ca.primaryId
	, ABS(CAST(CAST(NEWID() AS VARBINARY) AS INT)) AS randomId -- See References
	, id.dob
	, id.sex
	, countycode
	, id.city
	, ca.zipCode
	
FROM
	GlobalMembers.dbo.ClientAddress ca
		INNER JOIN GlobalMembers.dbo.ClientIdPlus id ON ca.primaryId = id.primaryId

WHERE
	ca.void = '0'
	AND ca.effDate BETWEEN @start AND @end
	AND ca.lobId = '17'
	AND ca.countyCode IN ('01','05','15','17','25')
	AND (
		ca.addr1 <> 'Homeless' OR ca.addr2 <> 'Homeless'
		)

-- Select SUD and Total Cost field from claims table

-- Drop TempTable #SUDandTotalCost before starting

IF OBJECT_ID (N'tempdb.dbo.#SUDandTotalCost') IS NOT NULL
	DROP TABLE #SUDandTotalCost

-- Create a TempTable for SUD Chunk

CREATE TABLE #SUDandTotalCost (
	primaryId varchar (25)
	, isSUDDx varchar (25)
	, calcnetPd INT
)

---- Insert Query into TempTable #SUDandTotalCost

INSERT INTO #SUDandTotalCost

SELECT
	DISTINCT primaryId AS SUDID
	, CASE WHEN isSABGDx = 'Y' THEN 'Y' ELSE 'N' END AS isSUDDx
	, SUM (calcnetpd)

FROM
Claims.dbo.SHCAVos

WHERE 
	begdate BETWEEN @start AND @end

GROUP BY
	primaryId
	, isSABGDx

-- Delete Duplicate sud.primaryId values before Joining tables

DELETE T
FROM
(
SELECT *
, DupRank = ROW_NUMBER() OVER (
              PARTITION BY primaryId
              ORDER BY (SELECT NULL)
            )
FROM #SUDandTotalCost
) AS T
WHERE DupRank > 1 

-- Add isSUDDx and Total Cost from #SUDandTotalCost to TempTable #NotHomelessSample
-- and select * into final product

SELECT
	h.primaryId
	, h.randomId
	, h.dob
	, h.sex
	, h.countyCode
	, h.city
	, h.zipCode
	, calcnetPd AS totalCost
	, sud.primaryId AS SUDId
	, sud.isSUDDx

FROM ##NotHomelessSample h
LEFT JOIN #SUDandTotalCost sud ON h.primaryId = sud.primaryId

-- Filter NULL values

WHERE sud.primaryId <> 'NULL'
	AND sud.isSUDDx <> 'NULL'

-- End of Query

---- References
-- randomId generates random numbers
-- County Codes, etc. Found in PAT Manual: https://www.azahcccs.gov/Resources/Downloads/OperationsReporting/PATManual.pdf
