SET NOCOUNT ON;

IF OBJECT_ID('PropCtx14a053ff-f900-4bc6-860f-2bd1c1a526c2') IS NOT NULL
	DROP TABLE [PropCtx14a053ff-f900-4bc6-860f-2bd1c1a526c2];

IF OBJECT_ID('Labeled14a053ff-f900-4bc6-860f-2bd1c1a526c2') IS NOT NULL
	DROP TABLE [Labeled14a053ff-f900-4bc6-860f-2bd1c1a526c2];

IF OBJECT_ID('PivotCols14a053ff-f900-4bc6-860f-2bd1c1a526c2') IS NOT NULL
	DROP TABLE [PivotCols14a053ff-f900-4bc6-860f-2bd1c1a526c2];

IF OBJECT_ID('tempdb..#TenStatus') IS NOT NULL
	DROP TABLE #TenStatus;

IF OBJECT_ID('PivotResults14a053ff-f900-4bc6-860f-2bd1c1a526c2') IS NOT NULL
	DROP TABLE [PivotResults14a053ff-f900-4bc6-860f-2bd1c1a526c2];

IF OBJECT_ID('MonthSeries14a053ff-f900-4bc6-860f-2bd1c1a526c2') IS NOT NULL
	DROP TABLE [MonthSeries14a053ff-f900-4bc6-860f-2bd1c1a526c2];

IF OBJECT_ID('ConcessionsAgg14a053ff-f900-4bc6-860f-2bd1c1a526c2') IS NOT NULL
	DROP TABLE [ConcessionsAgg14a053ff-f900-4bc6-860f-2bd1c1a526c2];

IF OBJECT_ID('Base14a053ff-f900-4bc6-860f-2bd1c1a526c2') IS NOT NULL
	DROP TABLE [Base14a053ff-f900-4bc6-860f-2bd1c1a526c2];

IF OBJECT_ID('FutureTenants14a053ff-f900-4bc6-860f-2bd1c1a526c2') IS NOT NULL
	DROP TABLE [FutureTenants14a053ff-f900-4bc6-860f-2bd1c1a526c2];

IF OBJECT_ID('Renewals14a053ff-f900-4bc6-860f-2bd1c1a526c2') IS NOT NULL
	DROP TABLE [Renewals14a053ff-f900-4bc6-860f-2bd1c1a526c2];

IF OBJECT_ID('FreeLedgerMonthly14a053ff-f900-4bc6-860f-2bd1c1a526c2') IS NOT NULL
	DROP TABLE [FreeLedgerMonthly14a053ff-f900-4bc6-860f-2bd1c1a526c2];

IF OBJECT_ID('LabeledFreeFromLedger14a053ff-f900-4bc6-860f-2bd1c1a526c2') IS NOT NULL
	DROP TABLE [LabeledFreeFromLedger14a053ff-f900-4bc6-860f-2bd1c1a526c2];

IF OBJECT_ID('LedgerMonthly14a053ff-f900-4bc6-860f-2bd1c1a526c2') IS NOT NULL
	DROP TABLE [LedgerMonthly14a053ff-f900-4bc6-860f-2bd1c1a526c2];

IF OBJECT_ID('CurrentMonthlyChargesAndProration14a053ff-f900-4bc6-860f-2bd1c1a526c2') IS NOT NULL
	DROP TABLE [CurrentMonthlyChargesAndProration14a053ff-f900-4bc6-860f-2bd1c1a526c2];

IF OBJECT_ID('LabeledFuture14a053ff-f900-4bc6-860f-2bd1c1a526c2') IS NOT NULL
	DROP TABLE [LabeledFuture14a053ff-f900-4bc6-860f-2bd1c1a526c2];

IF OBJECT_ID('LabeledAll14a053ff-f900-4bc6-860f-2bd1c1a526c2') IS NOT NULL
	DROP TABLE [LabeledAll14a053ff-f900-4bc6-860f-2bd1c1a526c2];

SELECT p.hMy           AS PropertyId
	,RTRIM(p.sCode) AS PropertyCode
	,dtChargePost = CASE
		WHEN TRY_CONVERT(DATE, '') IS NULL
			OR YEAR(TRY_CONVERT(DATE, '')) = 1900
			THEN lo.dtChargePost
		ELSE TRY_CONVERT(DATE, '')
		END
	,lo.dtMMYY1     AS ArDate
	,StartMonth = DATEFROMPARTS(YEAR(x.EffDate), MONTH(x.EffDate), 1)
	,EndMonth = EOMONTH(x.EffDate)
	,WindowEnd12 = DATEADD(MONTH, 11, DATEFROMPARTS(YEAR(x.EffDate), MONTH(x.EffDate), 1))
INTO [PropCtx14a053ff-f900-4bc6-860f-2bd1c1a526c2]
FROM Property p
JOIN Lockout lo ON lo.hProp = p.hMy
CROSS APPLY (
	SELECT EffDate = CASE
			WHEN TRY_CONVERT(DATE, '') IS NULL
				OR YEAR(TRY_CONVERT(DATE, '')) = 1900
				THEN lo.dtChargePost
			ELSE TRY_CONVERT(DATE, '')
			END
	) AS x
WHERE p.hMy IN (1882)
	AND p.iType = 3;

/* ===== PropCtx ===== */
CREATE UNIQUE CLUSTERED INDEX [CIX_PropCtx_14a053ff-f900-4bc6-860f-2bd1c1a526c2] ON [PropCtx14a053ff-f900-4bc6-860f-2bd1c1a526c2] (PropertyId);

CREATE NONCLUSTERED INDEX [IX_PropCtx_Start_14a053ff-f900-4bc6-860f-2bd1c1a526c2] ON [PropCtx14a053ff-f900-4bc6-860f-2bd1c1a526c2] (
	StartMonth
	,WindowEnd12
	,dtChargePost
	);

SELECT *
INTO #TenStatus
FROM TenStatus ts
WHERE 0 = 0
	AND ts.[STATUS] IN (
		'Current'
		,'Future'
		,'Eviction'
		,'Notice'
		,'Applicant'
		)
	AND ts.STATUS IN (
		'Future'
		,'Applicant'
		);;

WITH N (n)
AS (
	SELECT 1

	UNION ALL

	SELECT 2

	UNION ALL

	SELECT 3

	UNION ALL

	SELECT 4

	UNION ALL

	SELECT 5

	UNION ALL

	SELECT 6

	UNION ALL

	SELECT 7

	UNION ALL

	SELECT 8

	UNION ALL

	SELECT 9

	UNION ALL

	SELECT 10

	UNION ALL

	SELECT 11

	UNION ALL

	SELECT 12
	)
SELECT QUOTENAME('Month' + CAST(n AS VARCHAR(2))) AS ColName
	,n                               AS MonthIdx
INTO [PivotCols14a053ff-f900-4bc6-860f-2bd1c1a526c2]
FROM N
OPTION (MAXRECURSION 0);

IF OBJECT_ID('Labeled14a053ff-f900-4bc6-860f-2bd1c1a526c2') IS NULL
	CREATE TABLE [Labeled14a053ff-f900-4bc6-860f-2bd1c1a526c2] (
		[Id] NUMERIC(18, 0) IDENTITY(1, 1) NOT NULL
		,[PropertyId] NUMERIC(18, 0) NULL
		,[PropertyCode] VARCHAR(8) NULL
		,[TenantId] NUMERIC(18, 0) NULL
		,[ChargeCodeId] NUMERIC(18, 0) NULL
		,[ChargeCode] VARCHAR(8) NULL
		,[MonthIdx] BIGINT NULL
		,[MonthLabel] VARCHAR(8) NULL
		,[AmountPerMonth] FLOAT NULL
		,[IsFreeRent] BIT NULL CONSTRAINT [PK_Labeled14a053ff-f900-4bc6-860f-2bd1c1a526c2] PRIMARY KEY NONCLUSTERED ([Id] ASC) WITH (
			PAD_INDEX = OFF
			,STATISTICS_NORECOMPUTE = OFF
			,IGNORE_DUP_KEY = OFF
			,ALLOW_ROW_LOCKS = ON
			,ALLOW_PAGE_LOCKS = ON
			) ON [PRIMARY]
		) ON [PRIMARY];

CREATE INDEX IX_LabeledAll_tenant_month ON [Labeled14a053ff-f900-4bc6-860f-2bd1c1a526c2] (
	TenantId
	,ChargeCodeId
	,MonthIdx
	) INCLUDE (
	AmountPerMonth
	,IsFreeRent
	);;

WITH Base
AS (
	SELECT pc.PropertyId
		,Source = 'Base'
		,pc.PropertyCode
		,t.hMyPerson                                                                                             AS TenantId
		,ct.hMy                                                                                                  AS ChargeCodeId
		,RTRIM(ct.sCode)                                                                                         AS ChargeCode
		,DATEFROMPARTS(YEAR(cr.dtFrom), MONTH(cr.dtFrom), 1)                                                     AS OrigFromDate
		,CASE
			WHEN t.iStatus IN (4)
				THEN t.dtMoveOut
			ELSE CASE
					WHEN cr.dtTo IS NULL
						THEN DATEADD(YEAR, 1, pc.dtChargePost)
					ELSE COALESCE(cr.dtTo, EOMONTH(maxTrans.MonthStart), t.dtMoveOut, DATEADD(YEAR, 1, pc.dtChargePost))
					END
			END                                                                                                     AS OrigToDate
		,MoveInAmt = (DAY(EOMONTH(t.dtLeaseFrom)) - (DAY(t.dtLeaseFrom) - 1)) / CAST(DAY(EOMONTH(t.dtLeaseFrom)) AS FLOAT) * (cr.dEstimated)
		,LeaseAmt = cr.dEstimated
		,CASE
			WHEN cr.dtTo IS NULL
				THEN 1
			ELSE 0
			END                                                                                                     AS IsOpenEnded
		,TenantCapDate = COALESCE(t.dtMoveOut, cr.dtTo, DATEADD(YEAR, 1, pc.dtChargePost))
	FROM tenant t
	INNER JOIN #TenStatus ts ON ts.iStatus = t.iStatus
	JOIN [PropCtx14a053ff-f900-4bc6-860f-2bd1c1a526c2] pc ON pc.PropertyId = t.hProperty
	JOIN LOCKOUT lo ON lo.hProp = pc.PropertyId
	JOIN [PARAM] pr ON pr.HCHART = lo.hchart
	JOIN camrule cr ON cr.hTenant = t.hMyPerson
	JOIN chargtyp ct ON cr.hChargeCode = ct.hMy
	LEFT JOIN hmTenant hmt ON t.hMyPerson = hmt.hTenant
	LEFT JOIN camcharg cc ON cc.hCamRule = cr.hMy
		AND cc.dtMMYY = pc.dtChargePost
		AND cr.hChargeCode = cc.hChargeCode
		AND cr.hChargeCode = cc.hChargeCode
		AND cc.htenant = t.hmyperson
	LEFT JOIN trans tr ON tr.hMy = cc.hPostRef
	OUTER APPLY (
		SELECT TOP (1) tr.sDateOccurred
			,MonthStart = DATEFROMPARTS(YEAR(tr.uPostDate), MONTH(tr.uPostDate), 1)
		FROM dbo.trans AS tr
		LEFT JOIN dbo.chargtyp AS ct ON ct.hMy = tr.hRetentionAcct
		WHERE tr.hPerson = t.hMyPerson
			AND tr.hUnit = t.hUnit
			AND tr.iType = 7
			AND tr.sTotalAmount <> 0
			AND (
				cr.dtTo IS NULL
				OR ct.iType IN (
					2
					,3
					)
				)
			AND tr.uPostDate >= pc.StartMonth
		ORDER BY tr.sDateOccurred DESC
			,tr.uPostDate DESC
		) AS maxTrans
	WHERE cr.dEstimated <> 0
		AND pc.PropertyId IN (1882)
		AND t.hmyperson IN (277666)
		AND ts.STATUS IN (
			'Future'
			,'Applicant'
			)
		AND (
			pc.dtChargePost BETWEEN cr.dtfrom
				AND ISNULL(cr.dtto, DATEADD(yyyy, 1000, GETDATE()))
			OR cr.dtTo IS NULL
			)
	)
SELECT *
INTO [Base14a053ff-f900-4bc6-860f-2bd1c1a526c2]
FROM Base;;

WITH Renewals
AS (
	SELECT pc.PropertyId
		,Source = 'Renewal'
		,pc.PropertyCode
		,lh.hTent                                                                                       AS TenantId
		,DATEFROMPARTS(YEAR(lh.dtLeaseFrom), MONTH(lh.dtLeaseFrom), 1)                                  AS OrigFromDate
		,lh.dtLeaseTo OrigToDate
		,MoveInAmt = cr.dEstimated
		,LeaseAmt = cr.dEstimated
		,CASE
			WHEN cr.dtTo IS NULL
				THEN 1
			ELSE 0
			END IsOpenEnded
		,(DAY(EOMONTH(lh.dtLeaseFrom)) - (DAY(lh.dtLeaseFrom) - 1)) / CAST(DAY(EOMONTH(lh.dtLeaseFrom)) AS FLOAT) * (cr.dEstimated) ProratedAmount
		,lh.*
		,TenantCapDate = COALESCE(lh.dtLeaseTo, DATEADD(YEAR, 1, pc.dtChargePost))
		,RTRIM(ct.sCode) ChargeCode
		,ct.hMy ChargeCodeId
	FROM property p
	INNER JOIN unit u ON u.hProperty = p.hmy
	INNER JOIN tenant t ON t.hProperty = p.hmy
	INNER JOIN #TenStatus ts ON ts.iStatus = t.iStatus
		AND t.hUnit = u.hMy
		AND t.iStatus = 0
		AND t.dtMoveOut IS NULL
	JOIN [PropCtx14a053ff-f900-4bc6-860f-2bd1c1a526c2] pc ON pc.PropertyId = t.hProperty
	INNER JOIN lease_history lh ON t.hmyperson = lh.htent
		AND (
			lh.iStatus IN (2)
			OR (
				lh.iStatus = 1
				AND lh.iPortalSelection = 1
				)
			)
	INNER JOIN camrule_proposals cr ON cr.hlease_history = lh.hMy
	INNER JOIN chargtyp ct ON ct.hmy = cr.hChargeCode
		AND (
			ct.iType IN (
				2
				,3
				)
			)
	WHERE 1 = 1
		AND u.iRentalType NOT IN (9)
		AND pc.PropertyId IN (1882)
		AND t.hmyperson IN (277666)
	)
SELECT *
INTO [Renewals14a053ff-f900-4bc6-860f-2bd1c1a526c2]
FROM Renewals;;

WITH FutureTenants
AS (
	SELECT pc.PropertyId
		,Source = 'Future'
		,pc.PropertyCode
		,t.hMyPerson                                                                                 AS TenantId
		,DATEFROMPARTS(YEAR(t.dtMoveIn), MONTH(t.dtMoveIn), 1)                                       AS OrigFromDate
		,DATEADD(YEAR, 1, ct.dtChargeDate)                                                           AS OrigToDate
		,MoveInAmt = ct.cMoveInAmt
		,LeaseAmt = ct.cLeaseAmt
		,1 IsOpenEnded
		,t.dtLeaseFrom
		,(DAY(EOMONTH(t.dtLeaseFrom)) - (DAY(t.dtLeaseFrom) - 1)) / CAST(DAY(EOMONTH(t.dtLeaseFrom)) AS FLOAT) * (ct.cLeaseAmt) ProratedAmount
		,ct.*
		,TenantCapDate = COALESCE(t.dtMoveOut, t.dtLeaseTo, DATEADD(YEAR, 1, pc.dtChargePost))
	FROM property p
	JOIN [PropCtx14a053ff-f900-4bc6-860f-2bd1c1a526c2] pc ON pc.PropertyId = p.hMy
	INNER JOIN tenant t ON t.hProperty = p.hMy
	INNER JOIN unit u ON u.hMy = t.hUnit
	LEFT JOIN prospect pr ON pr.hmy = t.hProspect
		AND pr.sStatus IN (
			'Applied'
			,'Approved'
			,'Resident'
			)
	OUTER APPLY (
		SELECT m.hMy
			,m.hTenant
			,m.hProspect
			,m.hRecord
			,rtrim(ct.sCode) ChargeCode
			,m.hChargeCode ChargeCodeId
			,ISNULL(m.cLeaseAmt, 0) cLeaseAmt
			,ISNULL(m.cMoveInAmt, 0) cMoveInAmt
			,m.dtChargeDate
		FROM MoveInCharges m
		INNER JOIN chargtyp ct ON ct.hMy = m.hChargeCode
		WHERE ISNULL(m.bSelected, 0) <> 0
			AND ISNULL(m.bRecurring, 0) = - 1
			AND m.hTenant = t.hmyperson
		) AS ct
	WHERE 1 = 1
		AND (
			(
				t.iStatus IN (
					2
					,6
					)
				AND ISNULL(t.hProspect, 0) = (
					SELECT CASE
							WHEN t.istatus = 2
								THEN ISNULL(t.hProspect, 0)
							ELSE pr.hmy
							END
					)
				AND DATEFROMPARTS(YEAR(t.dtMoveIn), MONTH(t.dtMoveIn), 1) BETWEEN pc.StartMonth
					AND pc.WindowEnd12
				)
			)
		AND t.hmyperson IN (277666)
		OR (
			EXISTS (
				SELECT 1
				FROM Trans
				JOIN tenant t2 ON t2.hmyperson = trans.hPerson
				WHERE trans.iType = 7
					AND trans.hPerson = t.hmyperson
					AND t.hmyperson IN (277666)
				)
			)
	)
SELECT *
INTO [FutureTenants14a053ff-f900-4bc6-860f-2bd1c1a526c2]
FROM FutureTenants;;

WITH Concessions
AS (
	SELECT t.hProperty PropertyId
		,t.hmyperson     AS TenantId
		,rtrim(p.sCode) PropertyCode
		,CAST(65         AS NUMERIC(18, 0)) AS ChargeCodeId
		,'free' ChargeCode
		,CONVERT(BIT, 1) AS IsFreeRent
		,gli.C_DescO
		,gli.C_AmtO      AS TotalFreeRentAmount
		,gli.C_DescT     AS C_DescT
		,gli.c_amtT      AS C_AmtT
		,gli.C_Date_From AS C_Date_From
		,gli.c_Date_To   AS C_Date_To
		,t.dtMoveIn
		,t.dtLeaseFrom
		,t.dtMoveOut
		,t.dtLeaseTo
	FROM GUESTCARD_LEASE_INFO gli
	INNER JOIN prospect pr ON pr.hmy = gli.hcode
	INNER JOIN tenant t ON t.hmyperson = pr.hTenant
	INNER JOIN property p ON p.hmy = t.hProperty
	WHERE EXISTS (
			SELECT 1
			FROM (
				SELECT TenantId
				FROM [Base14a053ff-f900-4bc6-860f-2bd1c1a526c2]

				UNION

				SELECT TenantId
				FROM [FutureTenants14a053ff-f900-4bc6-860f-2bd1c1a526c2]

				UNION

				SELECT TenantId
				FROM [Renewals14a053ff-f900-4bc6-860f-2bd1c1a526c2]
				) bt
			WHERE bt.TenantId = t.hmyperson
			)
		AND gli.C_AmtO <> 0
	)
	,ConcessionsAgg
AS (
	SELECT MIN(c.PropertyId)            AS PropertyId
		,MIN(c.PropertyCode)        AS PropertyCode
		,c.TenantId
		,MAX(t.dtMoveIn) dtMoveIn
		,SUM(c.TotalFreeRentAmount) AS TotalFreeRentAmount
	FROM Concessions c
	INNER JOIN tenant t ON t.hmyperson = c.TenantId
	INNER JOIN #TenStatus ts ON ts.iStatus = t.iStatus
	INNER JOIN [PropCtx14a053ff-f900-4bc6-860f-2bd1c1a526c2] ct ON ct.PropertyId = t.hProperty
	GROUP BY c.TenantId
	)
SELECT *
INTO [ConcessionsAgg14a053ff-f900-4bc6-860f-2bd1c1a526c2]
FROM ConcessionsAgg;

CREATE UNIQUE CLUSTERED INDEX [CIX_ConcessionsAgg_14a053ff-f900-4bc6-860f-2bd1c1a526c2] ON [ConcessionsAgg14a053ff-f900-4bc6-860f-2bd1c1a526c2] (
	PropertyId
	,TenantId
	);;

WITH Clipped
AS (
	SELECT MAX(PropertyId)     AS PropertyId
		,MAX(Source)       AS Source
		,MAX(PropertyCode) AS PropertyCode
		,(TenantId)        AS TenantId
		,(ChargeCodeId)    AS ChargeCodeId
		,(ChargeCode)      AS ChargeCode
		,MIN(RuleStart)    AS RuleStart
		,MIN(FromDate)     AS FromDate
		,CASE
			WHEN iStatus = 4
				THEN MIN(ToDate)
			ELSE MAX(ToDate)
			END               AS ToDate
		,MAX(MoveInAmt)    AS MoveInAmt
		,MAX(LeaseAmt)     AS LeaseAmt
		,IsRenew
		,iStatus
	FROM (
		SELECT b.PropertyId
			,b.Source
			,b.PropertyCode
			,b.TenantId
			,b.ChargeCodeId
			,b.ChargeCode
			,RuleStart = b.OrigFromDate
			,FromDate = pc.StartMonth
			,ToDate = CASE
				WHEN t.iStatus = 4
					AND t.dtMoveOut IS NOT NULL
					THEN DATEFROMPARTS(YEAR(t.dtMoveOut), MONTH(t.dtMoveOut), 1)
				WHEN b.IsOpenEnded = 1
					THEN CASE
							WHEN b.OrigFromDate > pc.WindowEnd12
								THEN b.OrigFromDate
							ELSE pc.WindowEnd12
							END
				ELSE CASE
						WHEN b.OrigToDate IS NULL
							THEN pc.WindowEnd12
						WHEN EOMONTH(b.OrigToDate) < pc.WindowEnd12
							THEN EOMONTH(b.OrigToDate)
						ELSE pc.WindowEnd12
						END
				END
			,b.MoveInAmt
			,b.LeaseAmt
			,0 IsRenew
			,CASE
				WHEN t.iStatus = 4
					THEN 1
				ELSE 0
				END IsNotice
			,t.iStatus
		FROM [Base14a053ff-f900-4bc6-860f-2bd1c1a526c2] b
		INNER JOIN tenant t ON t.hmyperson = b.TenantId
		JOIN [PropCtx14a053ff-f900-4bc6-860f-2bd1c1a526c2] pc ON pc.PropertyId = b.PropertyId

		UNION ALL

		SELECT b.PropertyId
			,b.Source
			,b.PropertyCode
			,b.TenantId
			,b.ChargeCodeId
			,b.ChargeCode
			,RuleStart = b.OrigFromDate
			,FromDate = pc.StartMonth
			,ToDate = CASE
				WHEN b.IsOpenEnded = 1
					THEN CASE
							WHEN b.OrigFromDate > pc.WindowEnd12
								THEN b.OrigFromDate
							ELSE pc.WindowEnd12
							END
				ELSE COALESCE(EOMONTH(b.OrigToDate), pc.WindowEnd12)
				END
			,b.MoveInAmt
			,b.LeaseAmt
			,0 IsRenew
			,0 IsNotice
			,t.iStatus
		FROM [FutureTenants14a053ff-f900-4bc6-860f-2bd1c1a526c2] b
		INNER JOIN tenant t ON t.hmyperson = b.TenantId
		JOIN [PropCtx14a053ff-f900-4bc6-860f-2bd1c1a526c2] pc ON pc.PropertyId = b.PropertyId
		WHERE (
				b.OrigToDate >= pc.StartMonth
				OR b.OrigToDate IS NULL
				)

		UNION ALL

		SELECT b.PropertyId
			,b.Source
			,b.PropertyCode
			,b.TenantId
			,b.ChargeCodeId
			,b.ChargeCode
			,RuleStart = b.OrigFromDate
			,FromDate = pc.StartMonth
			,ToDate = CASE
				WHEN b.IsOpenEnded = 1
					THEN CASE
							WHEN b.OrigFromDate > pc.WindowEnd12
								THEN b.OrigFromDate
							ELSE pc.WindowEnd12
							END
				ELSE COALESCE(EOMONTH(b.OrigToDate), pc.WindowEnd12)
				END
			,b.MoveInAmt
			,b.LeaseAmt
			,1 IsRenew
			,0 IsNotice
			,t.iStatus
		FROM [Renewals14a053ff-f900-4bc6-860f-2bd1c1a526c2] b
		INNER JOIN tenant t ON t.hmyperson = b.TenantId
		JOIN [PropCtx14a053ff-f900-4bc6-860f-2bd1c1a526c2] pc ON pc.PropertyId = b.PropertyId
		WHERE b.OrigToDate >= pc.StartMonth
		) AS allTens
	GROUP BY TenantId
		,ChargeCodeId
		,ChargeCode
		,IsRenew
		,iStatus
	)
	,MonthSeries
AS (
	SELECT PropertyId
		,PropertyCode
		,TenantId
		,ChargeCodeId
		,ChargeCode
		,RuleStart
		,FromDate
		,ToDate
		,MoveInAmt
		,LeaseAmt
		,Source
		,MonthStart = FromDate
		,iStatus
	FROM Clipped

	UNION ALL

	SELECT MonthSeries.PropertyId
		,MonthSeries.PropertyCode
		,TenantId
		,ChargeCodeId
		,ChargeCode
		,RuleStart
		,FromDate
		,ToDate
		,MoveInAmt
		,LeaseAmt
		,Source
		,MonthStart = DATEADD(MONTH, 1, MonthStart)
		,t.iStatus
	FROM MonthSeries
	JOIN [PropCtx14a053ff-f900-4bc6-860f-2bd1c1a526c2] pc ON pc.PropertyId = MonthSeries.PropertyId
	INNER JOIN tenant t ON t.hmyperson = MonthSeries.TenantId
	WHERE MonthSeries.MonthStart < MonthSeries.ToDate
		AND MonthSeries.MonthStart < pc.WindowEnd12
	)
SELECT *
INTO [MonthSeries14a053ff-f900-4bc6-860f-2bd1c1a526c2]
FROM MonthSeries;

/* ===== MonthSeries ===== */
CREATE CLUSTERED INDEX [CIX_MonthSeries_14a053ff-f900-4bc6-860f-2bd1c1a526c2] ON [MonthSeries14a053ff-f900-4bc6-860f-2bd1c1a526c2] (
	PropertyId
	,TenantId
	,ChargeCodeId
	,MonthStart
	);

CREATE NONCLUSTERED INDEX [IX_MonthSeries_Rule_14a053ff-f900-4bc6-860f-2bd1c1a526c2] ON [MonthSeries14a053ff-f900-4bc6-860f-2bd1c1a526c2] (
	RuleStart
	,Source
	) INCLUDE (
	LeaseAmt
	,MoveInAmt
	);

CREATE INDEX IX_MonthSeries_main ON [MonthSeries14a053ff-f900-4bc6-860f-2bd1c1a526c2] (
	PropertyId
	,TenantId
	,ChargeCodeId
	,MonthStart
	,Source
	);;

WITH FreeLedgerMonthly
AS (
	SELECT pc.PropertyId
		,tr.hPerson AS TenantId
		,MonthIdx = DATEDIFF(MONTH, pc.StartMonth, DATEFROMPARTS(YEAR(tr.uPostDate), MONTH(tr.uPostDate), 1)) + 1
		,FreeAmt = SUM(tr.sTotalAmount)
		,MonthStart = DATEFROMPARTS(YEAR(tr.uPostDate), MONTH(tr.uPostDate), 1)
	FROM trans tr
	JOIN property p ON p.hmy = tr.hProp
	JOIN [PropCtx14a053ff-f900-4bc6-860f-2bd1c1a526c2] pc ON pc.PropertyId = p.hMy
	JOIN tenant t ON t.hMyPerson = tr.hPerson
	JOIN chargtyp ct ON ct.hMy = tr.hRetentionAcct
	WHERE p.iType = 3
		AND tr.iType = 7
		AND tr.sTotalAmount <> 0
		AND tr.uPostDate >= pc.StartMonth
		AND ct.hMy = 65
		AND pc.PropertyId IN (1882)
		AND t.hmyperson IN (277666)
	GROUP BY pc.PropertyId
		,tr.hPerson
		,pc.StartMonth
		,DATEFROMPARTS(YEAR(tr.uPostDate), MONTH(tr.uPostDate), 1)

	UNION ALL

	SELECT pc.PropertyId
		,tr.hPerson AS TenantId
		,MonthIdx = DATEDIFF(MONTH, pc.StartMonth, DATEFROMPARTS(YEAR(tr.uPostDate), MONTH(tr.uPostDate), 1)) + 1
		,FreeAmt = SUM(tr.sTotalAmount)
		,MonthStart = DATEFROMPARTS(YEAR(tr.uPostDate), MONTH(tr.uPostDate), 1)
	FROM trans tr
	LEFT JOIN chargtyp ct ON tr.hRetentionAcct = ct.hMy
	INNER JOIN acct ac ON (tr.hOffsetAcct = ac.hMy)
	INNER JOIN property p ON tr.hprop = p.hMy
	INNER JOIN [PropCtx14a053ff-f900-4bc6-860f-2bd1c1a526c2] pc ON pc.PropertyId = p.hmy
	LEFT JOIN person r ON tr.hPerson = r.hMy
	INNER JOIN tenant t ON t.hmyperson = tr.hPerson
	INNER JOIN #TenStatus ts ON t.istatus = ts.istatus
	WHERE p.iType = 3
		AND tr.uPostDate < StartMonth
		AND tr.iType IN (7)
		AND tr.sTotalamount <> 0
		AND t.hProperty > 0
		AND pc.PropertyId IN (1882)
		AND t.hmyperson IN (277666)
		AND ct.hMy = 65 /*AND ( EXISTS (SELECT 1 FROM [Renewals14a053ff-f900-4bc6-860f-2bd1c1a526c2] where TenantId = t.hmyperson) OR t.iStatus IN (2, 6) )*/
	GROUP BY pc.PropertyId
		,tr.hPerson
		,pc.StartMonth
		,DATEFROMPARTS(YEAR(tr.uPostDate), MONTH(tr.uPostDate), 1)
	)
SELECT *
INTO [FreeLedgerMonthly14a053ff-f900-4bc6-860f-2bd1c1a526c2]
FROM FreeLedgerMonthly;

CREATE CLUSTERED INDEX [CIX_FreeLedgerMonthly_14a053ff-f900-4bc6-860f-2bd1c1a526c2] ON [FreeLedgerMonthly14a053ff-f900-4bc6-860f-2bd1c1a526c2] (
	PropertyId
	,TenantId
	,MonthIdx
	);

CREATE NONCLUSTERED INDEX [IX_FreeLedgerMonthly_Start_14a053ff-f900-4bc6-860f-2bd1c1a526c2] ON [FreeLedgerMonthly14a053ff-f900-4bc6-860f-2bd1c1a526c2] (
	TenantId
	,MonthIdx
	) INCLUDE (
	FreeAmt
	,MonthStart
	);

SELECT flm.PropertyId
	,pc.PropertyCode
	,flm.TenantId
	,CAST(65                     AS NUMERIC(18, 0)) AS ChargeCodeId
	,'free'                      AS ChargeCode
	,flm.MonthIdx
	,'Month' + CAST(flm.MonthIdx AS VARCHAR(3)) AS MonthLabel
	,flm.FreeAmt                 AS AmountPerMonth
	,CONVERT(BIT, 1)             AS IsFreeRent
INTO [LabeledFreeFromLedger14a053ff-f900-4bc6-860f-2bd1c1a526c2]
FROM [FreeLedgerMonthly14a053ff-f900-4bc6-860f-2bd1c1a526c2] flm
JOIN [PropCtx14a053ff-f900-4bc6-860f-2bd1c1a526c2] pc ON pc.PropertyId = flm.PropertyId;

CREATE CLUSTERED INDEX [CIX_LabeledFreeFromLedger_14a053ff-f900-4bc6-860f-2bd1c1a526c2] ON [LabeledFreeFromLedger14a053ff-f900-4bc6-860f-2bd1c1a526c2] (
	PropertyId
	,TenantId
	,MonthIdx
	);

SELECT pc.PropertyId
	,tr.hPerson AS TenantId
	,ct.hMy     AS ChargeCodeId
	,MonthStart = DATEFROMPARTS(YEAR(tr.uPostDate), MONTH(tr.uPostDate), 1)
	,LedgerAmt = SUM(tr.sTotalAmount)
INTO [LedgerMonthly14a053ff-f900-4bc6-860f-2bd1c1a526c2]
FROM trans tr
LEFT JOIN chargtyp ct ON tr.hRetentionAcct = ct.hMy
INNER JOIN acct ac ON (tr.hOffsetAcct = ac.hMy)
INNER JOIN property p ON tr.hprop = p.hMy
INNER JOIN [PropCtx14a053ff-f900-4bc6-860f-2bd1c1a526c2] pc ON pc.PropertyId = p.hmy
LEFT JOIN person r ON tr.hPerson = r.hMy
INNER JOIN tenant t ON t.hmyperson = tr.hPerson
INNER JOIN #TenStatus ts ON t.istatus = ts.istatus
WHERE p.iType = 3
	AND (
		ct.iType IN (
			2
			,3
			)
		)
	AND tr.uPostDate >= StartMonth
	AND tr.iType IN (7)
	AND tr.sTotalamount <> 0
	AND t.hProperty > 0
	AND pc.PropertyId IN (1882)
	AND t.hmyperson IN (277666)
GROUP BY pc.PropertyId
	,tr.hPerson
	,ct.hMy
	,DATEFROMPARTS(YEAR(tr.uPostDate), MONTH(tr.uPostDate), 1);

CREATE CLUSTERED INDEX [CIX_LedgerMonthly_14a053ff-f900-4bc6-860f-2bd1c1a526c2] ON [LedgerMonthly14a053ff-f900-4bc6-860f-2bd1c1a526c2] (
	PropertyId
	,TenantId
	,ChargeCodeId
	,MonthStart
	);

CREATE NONCLUSTERED INDEX [IX_LedgerMonthly_Amt_14a053ff-f900-4bc6-860f-2bd1c1a526c2] ON [LedgerMonthly14a053ff-f900-4bc6-860f-2bd1c1a526c2] (
	TenantId
	,MonthStart
	) INCLUDE (LedgerAmt);

SELECT ms.PropertyId
	,ms.PropertyCode
	,ms.TenantId
	,ms.ChargeCodeId
	,ms.ChargeCode
	,ms.MonthStart
	,ms.RuleStart
	,ix.MonthIdx
	,MonthLabel = 'Month' + CAST(ix.MonthIdx AS VARCHAR(3))
	,AmountPerMonth = CASE
		WHEN ms.MonthStart < ms.RuleStart
			THEN 0.0 /* FREE (65) should never come from CMP; ledger FREE is added later. */
		WHEN ms.ChargeCodeId = 65
			THEN 0.0 /* For rent/other recurring, honor ledger override */
		WHEN lm.LedgerAmt IS NOT NULL
			THEN lm.LedgerAmt
		WHEN ms.MonthStart = ms.RuleStart
			THEN ms.MoveInAmt
		WHEN t.iStatus = 4
			AND t.dtMoveOut IS NOT NULL
			AND ms.MonthStart = DATEFROMPARTS(YEAR(t.dtMoveOut), MONTH(t.dtMoveOut), 1)
			AND t.dtMoveOut < EOMONTH(t.dtMoveOut)
			THEN ms.LeaseAmt * (DAY(t.dtMoveOut) * 1.0 / DAY(EOMONTH(t.dtMoveOut)))
		ELSE ms.LeaseAmt
		END
INTO [CurrentMonthlyChargesAndProration14a053ff-f900-4bc6-860f-2bd1c1a526c2]
FROM [MonthSeries14a053ff-f900-4bc6-860f-2bd1c1a526c2] ms
JOIN [PropCtx14a053ff-f900-4bc6-860f-2bd1c1a526c2] pc ON pc.PropertyId = ms.PropertyId
LEFT JOIN [LedgerMonthly14a053ff-f900-4bc6-860f-2bd1c1a526c2] lm ON lm.PropertyId = ms.PropertyId
	AND lm.TenantId = ms.TenantId
	AND lm.ChargeCodeId = ms.ChargeCodeId
	AND lm.MonthStart = ms.MonthStart
LEFT JOIN tenant t ON t.hmyperson = ms.TenantId
CROSS APPLY (
	SELECT MonthIdx = DATEDIFF(MONTH, pc.StartMonth, ms.MonthStart) + 1
	)                                        AS ix
WHERE ms.Source = 'Base';

CREATE CLUSTERED INDEX [CIX_CMP_14a053ff-f900-4bc6-860f-2bd1c1a526c2] ON [CurrentMonthlyChargesAndProration14a053ff-f900-4bc6-860f-2bd1c1a526c2] (
	PropertyId
	,TenantId
	,ChargeCodeId
	,MonthStart
	);

CREATE NONCLUSTERED INDEX [IX_CMP_View_14a053ff-f900-4bc6-860f-2bd1c1a526c2] ON [CurrentMonthlyChargesAndProration14a053ff-f900-4bc6-860f-2bd1c1a526c2] (MonthIdx) INCLUDE (
	AmountPerMonth
	,ChargeCodeId
	,ChargeCode
	);

SELECT ms.PropertyId
	,ms.PropertyCode
	,ms.TenantId
	,ms.ChargeCodeId
	,ms.ChargeCode
	,ms.MonthStart
	,ms.RuleStart
	,ix.MonthIdx
	,MonthLabel = 'Month' + CAST(ix.MonthIdx AS VARCHAR(3))
	,AmountPerMonth = CASE
		WHEN ms.MonthStart < ms.RuleStart
			THEN 0.0
		WHEN ms.MonthStart = ms.RuleStart
			THEN ms.MoveInAmt
		ELSE ms.LeaseAmt
		END
INTO [LabeledFuture14a053ff-f900-4bc6-860f-2bd1c1a526c2]
FROM [MonthSeries14a053ff-f900-4bc6-860f-2bd1c1a526c2] ms
JOIN [PropCtx14a053ff-f900-4bc6-860f-2bd1c1a526c2] pc ON pc.PropertyId = ms.PropertyId
CROSS APPLY (
	SELECT MonthIdx = DATEDIFF(MONTH, pc.StartMonth, ms.MonthStart) + 1
	) AS ix
WHERE ms.Source = 'Future'
	AND NOT EXISTS (
		SELECT 1
		FROM [MonthSeries14a053ff-f900-4bc6-860f-2bd1c1a526c2] x
		WHERE x.PropertyId = ms.PropertyId
			AND x.TenantId = ms.TenantId
			AND x.ChargeCodeId = ms.ChargeCodeId
			AND x.MonthStart = ms.MonthStart
			AND x.Source IN (
				'Base'
				,'Renewal'
				)
		);

CREATE CLUSTERED INDEX [CIX_LabeledFuture_14a053ff-f900-4bc6-860f-2bd1c1a526c2] ON [LabeledFuture14a053ff-f900-4bc6-860f-2bd1c1a526c2] (
	PropertyId
	,TenantId
	,ChargeCodeId
	,MonthIdx
	);

SELECT *
INTO [LabeledAll14a053ff-f900-4bc6-860f-2bd1c1a526c2]
FROM (
	SELECT lb.PropertyId
		,lb.PropertyCode
		,lb.TenantId
		,lb.ChargeCodeId
		,lb.ChargeCode
		,lb.MonthIdx
		,lb.MonthLabel
		,lb.AmountPerMonth
		,IsFreeRent = CASE
			WHEN lb.ChargeCode = 'free'
				THEN 1
			ELSE 0
			END
	FROM [CurrentMonthlyChargesAndProration14a053ff-f900-4bc6-860f-2bd1c1a526c2] lb

	UNION ALL

	SELECT lf.PropertyId
		,lf.PropertyCode
		,lf.TenantId
		,lf.ChargeCodeId
		,lf.ChargeCode
		,lf.MonthIdx
		,lf.MonthLabel
		,lf.AmountPerMonth
		,CASE
			WHEN lf.ChargeCode = 'free'
				THEN 1
			ELSE 0
			END
	FROM [LabeledFuture14a053ff-f900-4bc6-860f-2bd1c1a526c2] lf
	) x;

CREATE CLUSTERED INDEX [CIX_LabeledAll_14a053ff-f900-4bc6-860f-2bd1c1a526c2] ON [LabeledAll14a053ff-f900-4bc6-860f-2bd1c1a526c2] (
	PropertyId
	,TenantId
	,ChargeCodeId
	,MonthIdx
	);;

WITH Tally
AS (
	SELECT 1 AS n

	UNION ALL

	SELECT 2

	UNION ALL

	SELECT 3

	UNION ALL

	SELECT 4

	UNION ALL

	SELECT 5

	UNION ALL

	SELECT 6

	UNION ALL

	SELECT 7

	UNION ALL

	SELECT 8

	UNION ALL

	SELECT 9

	UNION ALL

	SELECT 10

	UNION ALL

	SELECT 11

	UNION ALL

	SELECT 12
	)
	,RentPerMonth
AS (
	SELECT la.PropertyId
		,la.PropertyCode
		,la.TenantId
		,la.ChargeCodeId
		,la.ChargeCode
		,la.MonthIdx
		,la.MonthLabel
		,la.AmountPerMonth
	FROM [LabeledAll14a053ff-f900-4bc6-860f-2bd1c1a526c2] la
	JOIN ChargTyp ct ON ct.hMy = la.ChargeCodeId
	WHERE ct.hMy = (
			SELECT HRENTCHGCODE
			FROM [PARAM]
			)
	)
	,RentPerMonthTotal
AS (
	SELECT PropertyId
		,TenantId
		,MonthIdx
		,RentPerMonthAmt = SUM(AmountPerMonth)
	FROM RentPerMonth
	GROUP BY PropertyId
		,TenantId
		,MonthIdx
	)
	,Candidates
AS (
	SELECT ca.PropertyId
		,ca.PropertyCode
		,ca.TenantId
		,ca.TotalFreeRentAmount /* ,ca.NumFreeRentMonths*/
		,pc.StartMonth
		,
		/* Month 1 = lease start month; then +1 per tally */
		MonthIdx = DATEDIFF(MONTH, pc.StartMonth, DATEADD(MONTH, t.n - 1, DATEFROMPARTS(YEAR(ca.dtMoveIn), MONTH(ca.dtMoveIn), 1))) + 1
		,n = t.n
	FROM [ConcessionsAgg14a053ff-f900-4bc6-860f-2bd1c1a526c2] ca
	JOIN [PropCtx14a053ff-f900-4bc6-860f-2bd1c1a526c2] pc ON pc.PropertyId = ca.PropertyId
	JOIN tenant t2 ON t2.hmyperson = ca.TenantId /* AND t2.iStatus IN (2, 6) */
	JOIN Tally t ON t.n <= 12
	)
	,CandidatesWindow
AS (
	SELECT *
	FROM Candidates
	WHERE MonthIdx BETWEEN 1
			AND 12 /* keep within the 12-mo report window */
	)
	,FreePostedBeforeWindow
AS (
	SELECT PropertyId
		,TenantId
		,PostedBefore = SUM(ABS(FreeAmt))
	FROM [FreeLedgerMonthly14a053ff-f900-4bc6-860f-2bd1c1a526c2]
	WHERE MonthIdx <= 0
	GROUP BY PropertyId
		,TenantId
	) /* Carry a remaining amount into the per-month spread pipeline */
	,CandidatesWithRemaining
AS (
	SELECT c.PropertyId
		,c.PropertyCode
		,c.TenantId
		,
		/* Remaining free after subtracting posts before the window */
		RemainingTotal = CASE
			WHEN c.TotalFreeRentAmount - ISNULL(fp.PostedBefore, 0) < 0
				THEN 0
			ELSE c.TotalFreeRentAmount - ISNULL(fp.PostedBefore, 0)
			END
		,c.MonthIdx
		,c.n
	FROM CandidatesWindow c
	LEFT JOIN FreePostedBeforeWindow fp ON fp.PropertyId = c.PropertyId
		AND fp.TenantId = c.TenantId
	)
	,CandidatesWithCap
AS (
	SELECT cw.PropertyId
		,cw.PropertyCode
		,cw.TenantId
		,cw.MonthIdx
		,cw.n
		,cw.RemainingTotal
		,Cap = CASE
			WHEN ISNULL(flm.FreeAmt, 0) <> 0
				THEN 0.0
			ELSE ISNULL(rpt.RentPerMonthAmt, 0.0)
			END
	FROM CandidatesWithRemaining cw
	LEFT JOIN RentPerMonthTotal rpt ON rpt.PropertyId = cw.PropertyId
		AND rpt.TenantId = cw.TenantId
		AND rpt.MonthIdx = cw.MonthIdx
	LEFT JOIN [FreeLedgerMonthly14a053ff-f900-4bc6-860f-2bd1c1a526c2] flm ON flm.PropertyId = cw.PropertyId
		AND flm.TenantId = cw.TenantId
		AND flm.MonthIdx = cw.MonthIdx
	)
	,LedgerWindow
AS (
	SELECT PropertyId
		,TenantId
		,MonthIdx
		,AbsFree = ABS(FreeAmt)
	FROM [FreeLedgerMonthly14a053ff-f900-4bc6-860f-2bd1c1a526c2]
	WHERE MonthIdx BETWEEN 0
			AND 12 /* Only in the report window */
	)
	,Running
AS (
	SELECT cwc.PropertyId
		,cwc.PropertyCode
		,cwc.TenantId
		,cwc.MonthIdx
		,cwc.n
		,cwc.RemainingTotal
		,cwc.Cap
		,RunningCap = SUM(cwc.Cap) OVER (
			PARTITION BY cwc.PropertyId
			,cwc.TenantId ORDER BY cwc.n ROWS UNBOUNDED PRECEDING
			)
		,PrevRunningCap = SUM(cwc.Cap) OVER (
			PARTITION BY cwc.PropertyId
			,cwc.TenantId ORDER BY cwc.n ROWS BETWEEN UNBOUNDED PRECEDING
					AND 1 PRECEDING
			)
		,
		/* NEW: cumulative FREE posted in-window before this month */
		LedgerToDatePrev = COALESCE((
				SELECT SUM(ABS(f.FreeAmt))
				FROM [FreeLedgerMonthly14a053ff-f900-4bc6-860f-2bd1c1a526c2] f
				WHERE f.PropertyId = cwc.PropertyId
					AND f.TenantId = cwc.TenantId
					AND f.MonthIdx BETWEEN 1
						AND cwc.MonthIdx - 1
				), 0)
	FROM CandidatesWithCap cwc
	)
	,ConcessionSpread
AS (
	SELECT PropertyId
		,PropertyCode
		,TenantId
		,ChargeCodeId = CAST(65               AS NUMERIC(18, 0))
		,ChargeCode = 'free'
		,IsFreeRent = CONVERT(BIT, 1)
		,MonthIdx
		,MonthLabel = 'Month' + CAST(MonthIdx AS VARCHAR(3))
		,AmountPerMonth = - CASE
			WHEN RemainingTotal <= (LedgerToDatePrev + PrevRunningCap)
				THEN 0
			WHEN RemainingTotal >= (LedgerToDatePrev + RunningCap)
				THEN Cap
			ELSE RemainingTotal - (LedgerToDatePrev + PrevRunningCap)
			END
	FROM Running
	)
INSERT INTO [Labeled14a053ff-f900-4bc6-860f-2bd1c1a526c2] (
	PropertyId
	,PropertyCode
	,TenantId
	,ChargeCodeId
	,ChargeCode
	,MonthIdx
	,MonthLabel
	,AmountPerMonth
	,IsFreeRent
	)
SELECT PropertyId
	,PropertyCode
	,TenantId
	,ChargeCodeId
	,ChargeCode
	,MonthIdx
	,MonthLabel
	,AmountPerMonth
	,CONVERT(BIT, 0)
FROM (
	SELECT *
	FROM [CurrentMonthlyChargesAndProration14a053ff-f900-4bc6-860f-2bd1c1a526c2]

	UNION ALL

	SELECT *
	FROM [LabeledFuture14a053ff-f900-4bc6-860f-2bd1c1a526c2]
	) x

UNION ALL

/* NEW: include posted FREE from the ledger (so Aug = -1471.35, Sep = -1520.40 will show) */
SELECT PropertyId
	,PropertyCode
	,TenantId
	,ChargeCodeId
	,ChargeCode
	,MonthIdx
	,MonthLabel
	,AmountPerMonth
	,IsFreeRent
FROM [LabeledFreeFromLedger14a053ff-f900-4bc6-860f-2bd1c1a526c2]

UNION ALL

/* keep your existing forecasted spread, but only where ledger-free doesn't already exist */
SELECT s.PropertyId
	,s.PropertyCode
	,s.TenantId
	,s.ChargeCodeId
	,s.ChargeCode
	,s.MonthIdx
	,s.MonthLabel
	,s.AmountPerMonth
	,s.IsFreeRent
FROM ConcessionSpread s
WHERE s.AmountPerMonth <> 0
	AND NOT EXISTS (
		SELECT 1
		FROM [LabeledFreeFromLedger14a053ff-f900-4bc6-860f-2bd1c1a526c2] L
		WHERE L.PropertyId = s.PropertyId
			AND L.TenantId = s.TenantId
			AND L.MonthIdx = s.MonthIdx
		);;

WITH PrevFreeBeforeWindow
AS (
	SELECT pc.PropertyId
		,tr.hPerson AS TenantId
		,PrevFreeAmt = SUM(tr.sTotalAmount)
	FROM trans tr
	JOIN property p ON p.hmy = tr.hProp
	JOIN [PropCtx14a053ff-f900-4bc6-860f-2bd1c1a526c2] pc ON pc.PropertyId = p.hMy
	JOIN chargtyp ct ON ct.hMy = tr.hRetentionAcct
	WHERE p.iType = 3
		AND tr.iType = 7
		AND tr.sTotalAmount <> 0
		AND tr.uPostDate < pc.StartMonth
		AND ct.hMy = 65
	GROUP BY pc.PropertyId
		,tr.hPerson
	)
	,NeedFreeRow
AS (
	SELECT pf.PropertyId
		,pf.TenantId
	FROM PrevFreeBeforeWindow pf
	WHERE NOT EXISTS (
			SELECT 1
			FROM [Labeled14a053ff-f900-4bc6-860f-2bd1c1a526c2] L
			WHERE L.PropertyId = pf.PropertyId
				AND L.TenantId = pf.TenantId
				AND L.ChargeCodeId = 65
			)
	)
INSERT INTO [Labeled14a053ff-f900-4bc6-860f-2bd1c1a526c2] (
	PropertyId
	,PropertyCode
	,TenantId
	,ChargeCodeId
	,ChargeCode
	,MonthIdx
	,MonthLabel
	,AmountPerMonth
	,IsFreeRent
	)
SELECT nfr.PropertyId
	,pc.PropertyCode
	,nfr.TenantId
	,CAST(65                     AS NUMERIC(18, 0)) AS ChargeCodeId
	,'free'                      AS ChargeCode
	,pcx.MonthIdx
	,'Month' + CAST(pcx.MonthIdx AS VARCHAR(3)) AS MonthLabel
	,CAST(0.0                    AS FLOAT) AS AmountPerMonth
	,CONVERT(BIT, 1)             AS IsFreeRent
FROM NeedFreeRow nfr
JOIN [PropCtx14a053ff-f900-4bc6-860f-2bd1c1a526c2] pc ON pc.PropertyId = nfr.PropertyId
JOIN [PivotCols14a053ff-f900-4bc6-860f-2bd1c1a526c2] pcx ON 1 = 1;

DECLARE @cols NVARCHAR(max)
	,@sumCols NVARCHAR(max)
	,@sumCols_Name NVARCHAR(max);

SELECT @cols = STUFF((
			SELECT ',' + ColName
			FROM [PivotCols14a053ff-f900-4bc6-860f-2bd1c1a526c2]
			ORDER BY MonthIdx
			FOR XML PATH('')
				,TYPE
			).value('.', 'NVARCHAR(max)'), 1, 1, '');

SELECT @sumCols = STUFF((
			SELECT ',SUM(' + ColName + ')'
			FROM [PivotCols14a053ff-f900-4bc6-860f-2bd1c1a526c2]
			ORDER BY MonthIdx
			FOR XML PATH('')
				,TYPE
			).value('.', 'NVARCHAR(max)'), 1, 1, '');

SELECT @sumCols_Name = STUFF((
			SELECT ',SUM(COALESCE(' + ColName + ', 0)) ' + ColName
			FROM [PivotCols14a053ff-f900-4bc6-860f-2bd1c1a526c2]
			ORDER BY MonthIdx
			FOR XML PATH('')
				,TYPE
			).value('.', 'NVARCHAR(max)'), 1, 1, '');

IF @cols IS NULL
	OR @cols = ''
BEGIN
	RAISERROR (
			'No month columns found to pivot.'
			,11
			,1
			);

	DROP TABLE [PivotCols14a053ff-f900-4bc6-860f-2bd1c1a526c2];

	DROP TABLE [Labeled14a053ff-f900-4bc6-860f-2bd1c1a526c2];

	RETURN;
END;

DECLARE @sumCols_TotalExpr NVARCHAR(MAX);

SELECT @sumCols_TotalExpr = STUFF((
			SELECT '+SUM(COALESCE(' + ColName + ',0))'
			FROM [PivotCols14a053ff-f900-4bc6-860f-2bd1c1a526c2]
			ORDER BY MonthIdx
			FOR XML PATH('')
				,TYPE
			).value('.', 'NVARCHAR(max)'), 1, 1, '');

IF @cols IS NULL
	OR @cols = ''
BEGIN
	RAISERROR (
			'No month columns found to pivot.'
			,11
			,1
			);

	DROP TABLE [PivotCols14a053ff-f900-4bc6-860f-2bd1c1a526c2];

	DROP TABLE [Labeled14a053ff-f900-4bc6-860f-2bd1c1a526c2];

	RETURN;
END;

DECLARE @sql NVARCHAR(max) = N' SELECT PropertyId, PropertyCode, TenantId, ChargeCodeId, ChargeCode, CASE WHEN ChargeCode = ''free'' THEN 1 ELSE 0 END AS IsFreeRent, RentCharges = CASE WHEN ChargeCode IN (''.rent'',''free'',''eerent'') THEN 1 ELSE -1 END, ' + @sumCols_Name + N', TotalFreeRent = CASE WHEN ChargeCode = ''free'' THEN ' + @sumCols_TotalExpr + N' ELSE NULL END INTO [PivotResults14a053ff-f900-4bc6-860f-2bd1c1a526c2] FROM ( SELECT PropertyId, PropertyCode, TenantId, ChargeCodeId, ChargeCode, Col = MonthLabel, Val = SUM(AmountPerMonth) FROM [Labeled14a053ff-f900-4bc6-860f-2bd1c1a526c2] GROUP BY PropertyId, PropertyCode, TenantId, ChargeCodeId, ChargeCode, MonthLabel ) src PIVOT (SUM(Val) FOR Col IN (' + @cols + N')) p GROUP BY PropertyId, PropertyCode, TenantId, ChargeCodeId, ChargeCode HAVING ' + @sumCols_TotalExpr + N' <> 0 ';

EXEC sp_executesql @sql;

SELECT ROW_NUMBER() OVER (
		ORDER BY r.PropertyId
			,CASE ts.iStatus
				WHEN 2
					THEN 999
				ELSE ts.iStatus
				END
			,u.hMy
			,r.TenantId
			,IsFreeRent ASC
			,r.ChargeCodeId
		)                                   AS rn
	,r.*
	,rtrim(p.scode)                      AS PropCode
	,p.saddr1                            AS PropName
	,rtrim(t.sCode)                      AS TenantCode
	,format(t.dtLeaseFrom, 'MM/dd/yyyy') AS FromFormat
	,format(t.dtLeaseTo, 'MM/dd/yyyy')   AS ToFormat
	,CONVERT(VARCHAR, t.dtMoveOut, 101)  AS dtMoveOut
	,t.sfirstname + ' ' + t.slastname    AS TenantName
	,ts.[STATUS]                         AS 'Status'
	,rtrim(u.scode)                      AS unitcode
	,RTRIM(ad.saddr1)                    AS UnitAddress
	,CONVERT(VARCHAR, t.dtMoveOut, 101)  AS MoveOutDate
	,CASE
		WHEN r.IsFreeRent = 1
			THEN 'Free Rent'
		ELSE ct.sName
		END                                 AS ChargeName
	,'SCREEN' OutputType
	,u.hMy UnitId
	,1 Total
	,CASE
		WHEN lh.Id IS NOT NULL
			THEN 'Yes'
		ELSE ''
		END                                 AS HasRenew
	,lh.Id                               AS lhIds
	,pr.hmy                              AS ProspectId
	,COALESCE(prevFree.FreeAmt, 0)       AS PrevFreeAmt
FROM [PivotResults14a053ff-f900-4bc6-860f-2bd1c1a526c2] r
INNER JOIN property p ON p.hmy = r.PropertyId
INNER JOIN tenant t ON t.hmyperson = r.TenantId
INNER JOIN #TenStatus ts ON ts.iStatus = t.iStatus
INNER JOIN prospect pr ON pr.hTenant = r.TenantId
INNER JOIN unit u ON u.hmy = t.hUnit
LEFT JOIN chargtyp ct ON ct.hmy = r.ChargeCodeId
LEFT JOIN addr ad ON ad.hPointer = u.hMy
	AND ad.iType = 4
OUTER APPLY (
	SELECT MAX(lh.hMy) Id
	FROM lease_history lh
	WHERE lh.hTent = t.hMyPerson
		AND (
			lh.iStatus IN (2)
			OR (
				lh.iStatus = 1
				AND lh.iPortalSelection = 1
				)
			)
	) lh
LEFT JOIN (
	SELECT pc.PropertyId
		,tr.hPerson AS TenantId
		,FreeAmt = SUM(tr.sTotalAmount)
		,ct.hMy ChargeCodeId
	FROM trans tr
	LEFT JOIN chargtyp ct ON tr.hRetentionAcct = ct.hMy
	INNER JOIN acct ac ON (tr.hOffsetAcct = ac.hMy)
	INNER JOIN property p ON tr.hprop = p.hMy
	INNER JOIN [PropCtx14a053ff-f900-4bc6-860f-2bd1c1a526c2] pc ON pc.PropertyId = p.hmy
	LEFT JOIN person r ON tr.hPerson = r.hMy
	INNER JOIN tenant t ON t.hmyperson = tr.hPerson
	INNER JOIN #TenStatus ts ON t.istatus = ts.istatus
	WHERE p.iType = 3
		AND tr.uPostDate < StartMonth
		AND tr.iType IN (7)
		AND tr.sTotalamount <> 0
		AND t.hProperty > 0
		AND pc.PropertyId IN (1882)
		AND t.hmyperson IN (277666)
		AND ct.hMy = 65
	GROUP BY pc.PropertyId
		,tr.hPerson
		,ct.hMy
	) prevFree ON prevFree.TenantId = t.hmyperson
	AND prevFree.ChargeCodeId = ct.hMy
WHERE (
		ISNULL('0', '0') <> '1'
		OR lh.Id IS NOT NULL
		)
	AND (
		ISNULL('0', '0') <> '1'
		OR t.dtMoveOut IS NOT NULL
		)
	AND (
		ISNULL('0', '0') <> '1'
		OR EXISTS (
			SELECT 1
			FROM [PivotResults14a053ff-f900-4bc6-860f-2bd1c1a526c2]
			WHERE TenantId = r.TenantId
				AND ChargeCode = 'free'
			)
		)
	AND t.hmyperson IN (277666)
	AND ts.STATUS IN (
		'Future'
		,'Applicant'
		);
