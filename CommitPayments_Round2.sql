IF OBJECT_ID('tempdb..#tempDetails') IS NOT NULL
	DROP TABLE #tempDetails;
GO

DECLARE @PropertyCount INT = 1
	,@PropertyHmys VARCHAR(max) = NULL
	,@ToDate DATE = '09/01/2004';;

WITH JournalBase
AS (
	SELECT
	    tr.hProp                             AS hProp
		,CAST((tr.hMy - 1000000000)         AS BIGINT) AS TranIdCtrl
		,CAST(tr.hMy                        AS BIGINT) AS TranId
		,TRIM(ac.sCode)                     AS Account
		,ac.sDesc                           AS AccountDesc
		,TRIM(p.sCode)                      AS Property
		,d.sNotes                           AS Notes
		,tr.sOtherDate1                     AS [Date]
		,tr.uPostDate                       AS PostMonth
		,FORMAT(tr.uPostDate, 'MM/dd/yyyy') AS PostMonthFormat
		,d.sAmount                          AS dAmount
		,CASE 
			WHEN d.sAmount > 0
				THEN d.sAmount
			ELSE 0
			END                                AS Debit
		,CASE 
			WHEN d.sAmount < 0
				THEN ABS(d.sAmount)
			ELSE 0
			END                                AS Credit
		,CASE 
			WHEN MONTH(tr.uPostDate) = 1
				OR MONTH(tr.uPostDate) = 12
				THEN 1
			ELSE 0
			END                                AS IsNetIncomeEligible
	FROM trans tr
	JOIN detail d ON tr.hMy = d.hInvorRec
	JOIN property p ON d.hProp = p.hMy
	LEFT JOIN acct ac ON d.hAcct = ac.hMy
	WHERE tr.iType = 10
		AND tr.hMy IN (
			SELECT
			    g.hTran
			FROM gldetail g
			INNER JOIN acct a ON g.hAcct = a.hmy
			INNER JOIN property p ON g.hprop = p.hmy
			INNER JOIN trans tr ON tr.hMy = g.hTran
			WHERE a.hMy IN (
					1985
					,1105
					) /* 148570 / 435500 */
				AND g.iBook = 0
				AND g.iType = 10
				AND (p.sCode = 'i0000194')
			)
		AND ac.hMy IN (
			1985
			,1105
			)
		AND (
			@ToDate IS NULL
			OR tr.uPostDate = @ToDate
			)
	)
	,Rollup
AS (
	SELECT
	    TranId
		,SUM(CASE 
				WHEN Account = '435500'
					THEN (Credit - Debit) /* revenue: credit=+income, debit=loss */
				ELSE 0
				END) AS Net435500
		,SUM(CASE 
				WHEN Account = '148570'
					THEN (Debit - Credit) /* capital: debit=+to capital, credit=-from capital */
				ELSE 0
				END) AS Total148570
	FROM JournalBase
	GROUP BY TranId
	)
SELECT
    b.TranId
	,b.Property
	,b.Account
	,b.Notes
	,
	/* FORMAT(b.[Date], 'MM/dd/yyyy') Date, */
	/* FORMAT(b.PostMonth, 'MM/dd/yyyy') PostMonth, */
	b.DATE
	,b.PostMonth
	,
	/* b.dAmount */
	b.Debit
	,b.Credit
	,b.IsNetIncomeEligible
	,r.Net435500
	,r.Total148570
	,(r.Total148570 - r.Net435500) AS RemainderForDrawsContribs
INTO #tempDetails
FROM JournalBase b
JOIN Rollup r ON r.TranId = b.TranId
WHERE b.Account IN (
		'148570'
		,'435500'
		)
ORDER BY b.TranId
	,b.Notes
	,b.dAmount;

SELECT

    CAST(MAX(tr.hMy)             AS BIGINT) AS TranId
	,TRIM(p.sCode)               AS Property
	,STRING_AGG(d.sNotes, ' | ') AS Notes
	,tr.sOtherDate1              AS [Date]
	,tr.uPostDate                AS PostMonth
	,SUM(d.sAmount)              AS Amount
FROM trans tr
JOIN detail d ON tr.hMy = d.hInvorRec
JOIN property p ON d.hProp = p.hMy
LEFT JOIN acct ac ON d.hAcct = ac.hMy
WHERE tr.iType = 10
	AND tr.hMy IN (
		SELECT
		    g.hTran
		FROM gldetail g
		INNER JOIN acct a ON g.hAcct = a.hmy
		INNER JOIN property p ON g.hprop = p.hmy
		INNER JOIN trans tr ON tr.hMy = g.hTran
		WHERE a.hMy = 1985
			AND g.iBook = 0
			AND g.iType = 10
			AND (p.sCode = 'i0000194')
		)
	AND ac.hMy = 1985
	AND (
		@ToDate IS NULL
		OR tr.uPostDate = @ToDate
		)
GROUP BY tr.uPostDate
	,tr.sOtherDate1
	,TRIM(p.sCode)
ORDER BY tr.uPostDate;
