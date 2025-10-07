//VISTA
//NOTES
--pest charge
--mt + fee
-- package
-- tenant names minors on the second line first page, lessee's on first line
/*
SELECT RTRIM(P.SCODE) PROPCODE
	,RTRIM(T.SCODE) TENANTCODE
	,COUNT(*) ROOMMATECOUNT_NONOCCUPANT
FROM tenant t
JOIN PROPERTY P ON P.HMY = T.HPROPERTY
JOIN room r ON r.hMyTenant = t.hMyPerson
JOIN person pn ON pn.hmy = r.hMyPerson
WHERE (
		ISNULL(pn.sfirstname, '') <> ''
		and ISNULL(pn.ulastname, '') <> ''
		)
	AND r.BOCCUPANT = - 1
GROUP BY RTRIM(t.scode), RTRIM(P.SCODE)
order by 3 DESC;
LEFT JOIN (
	SELECT TENANT.hmyperson
		/*
		,rtrim(PPTY.scode) PropertCode
		,rtrim(TENANT.SCODE) TenantCode
		,sfirstname + ' ' + slastname TenantName
		*/
		,COUNT(DISTINCT CASE WHEN  lh.iPortalSelection = 1 THEN lh.hMy ELSE 0 END) ProposalCount
		,SUM(CASE
				WHEN ct.sCode IN ('rent', '.rent') AND lh.iPortalSelection = 1
					THEN cr.destimated
				ELSE 0
				END) renewBaseRent
		,SUM(CASE
				WHEN ct.sCode IN ('parking', 'garage', 'park') AND lh.iPortalSelection = 1
					THEN cr.destimated
				ELSE 0
				END) renewParkingRent
		,SUM(CASE
				WHEN ct.sCode IN ('storage') AND lh.iPortalSelection = 1
					THEN cr.destimated
				ELSE 0
				END) renewStorageRent
		,SUM(CASE
				WHEN ct.sCode IN ('petrent') AND lh.iPortalSelection = 1
					THEN cr.destimated
				ELSE 0
				END) renewPetRent
		,SUM(CASE
				WHEN ct.sCode IN ('misc', 'evcs', 'Cable') AND lh.iPortalSelection = 1
					THEN cr.destimated
				ELSE 0
				END) renewOtherRent
		,SUM(CASE
				WHEN ct.sCode IN ('mtpest') AND lh.iPortalSelection = 1
					THEN cr.destimated
				ELSE 0
				END) renewMtPest
		,SUM(CASE
				WHEN ct.sCode IN ('mtplus') AND lh.iPortalSelection = 1
					THEN cr.destimated
				ELSE 0
				END) renewMTPlus
		,SUM(CASE
				WHEN ct.sCode IN ('renins') AND lh.iPortalSelection = 1
					THEN 0
				ELSE cr.destimated
				END) renewRentersInsurance
	FROM TENANT
	INNER JOIN PROPERTY p ON p.HMY = TENANT.HPROPERTY
	INNER JOIN lease_History lh ON lh.htent = TENANT.hmyperson
/*		AND (
			lh.sstatus = 'Scheduled'
			OR (
				lh.sstatus = 'Approved'
				AND lh.iportalselection <> 0
				)
			AND lh.iInactiveProposal = 0
			)
*/

	INNER JOIN CamRule_Proposals cr ON cr.htenant = TENANT.hmyperson
		AND lh.hmy = cr.hlease_history
		AND ISNULL(bdonotrenew, 0) <> 1
	INNER JOIN chargtyp ct ON ct.hmy = cr.hchargecode
	WHERE 1 = 1
		#Conditions#
		/*and sfirstname + ' ' + slastname = 'Hannah Robbins'*/
	GROUP BY TENANT.hmyperson /*, rtrim(TENANT.SCODE), rtrim(PPTY.scode), sfirstname + ' ' + slastname;*/
) renewChgs

*/

//END NOTES


//DATABASE
FillDocs

//END DATABASE


//OPTIONS
OUTPUTTOPDF

//END OPTIONS


//TITLE
Arts District Apartments Lease

//END TITLE


//VERSION
LIVE

//END VERSION


//SELECT Primary
SET NOCOUNT ON;

IF OBJECT_ID('AllCharges#@@SESSIONID#') IS NOT NULL
	DROP TABLE [AllCharges#@@SESSIONID#];

IF OBJECT_ID('Ledger#@@SESSIONID#') IS NOT NULL
	DROP TABLE [Ledger#@@SESSIONID#];

IF OBJECT_ID('GuestCardReceipt#@@SESSIONID#') IS NOT NULL
	DROP TABLE [GuestCardReceipt#@@SESSIONID#];

IF OBJECT_ID('MicBase#@@SESSIONID#') IS NOT NULL
	DROP TABLE [MicBase#@@SESSIONID#];;

WITH Ledger
AS (
	SELECT tr.hMy
		,tr.iType
		,tr.sDateOccurred
		,ct.sCode     AS chargecode
		,CT.HMY ChargeCodeId
		,RTRIM(ct.sName) sName
		,TENANT.hMyPerson
		,TENANT.sCode AS TenantCode
		,tr.sNotes
		,tr.sUserDefined1
		,tr.sUserDefined2
		,tr.bACH
		,tr.bCC
		,tr.sTotalAmount
		,d.sAmount    AS DetailAmount
		,p.sCode      AS PropCode
		,TENANT.hProperty
		,TENANT.DTLEASEFROM
		,SUM(tr.sTotalAmount - tr.sAmountPaid) OVER (
			PARTITION BY tenant.hMyPerson
			,p.hMy ORDER BY tr.sDateOccurred
				,tr.hMy ROWS UNBOUNDED PRECEDING
			)            AS running_balance
	FROM property p
	JOIN tenant ON p.hmy = TENANT.hproperty
	JOIN trans tr ON TENANT.hMyPerson = tr.hPerson
	JOIN acct a ON tr.hOffsetAcct = a.hMy
	LEFT JOIN ChargTyp ct ON tr.hRetentionAcct = ct.hMy
	LEFT JOIN detail d ON d.hInvOrRec = tr.hMy
		AND tr.iType IN (
			6
			,15
			)
	WHERE tr.iType IN (
			6
			,7
			,15
			)
		AND TENANT.ISTATUS IN (
			0
			,2
			,3
			,4
			,6
			)
		AND tr.sTotalAmount <> 0
		AND (
			(
				tr.iType = 6
				AND ISNULL(tr.void, 0) = 0
				)
			OR (
				tr.iType = 15
				AND (
					tr.hACHData IS NOT NULL
					OR tr.hCCData IS NOT NULL
					)
				)
			OR (tr.iType = 7)
			)
		AND TENANT.hProperty > 0 #Conditions#
	)
	,L1
AS (
	SELECT L.hMy
		,L.iType
		,L.hmyperson TenantId
		,L.sDateOccurred
		,L.ChargeCodeId
		,L.chargecode
		,l.sName
		,L.DTLEASEFROM
		,Charges = SUM(CASE
				WHEN L.iType = 7
					THEN L.sTotalAmount
				ELSE 0
				END)
		,Payments = SUM(CASE
				WHEN L.iType IN (
						6
						,15
						)
					THEN ISNULL(L.DetailAmount, 0)
				ELSE 0
				END)
		,Description = (
			CASE
				WHEN L.iType IN (
						6
						,15
						)
					AND COALESCE(L.sUserDefined1, '') <> ''
					THEN 'chk# ' + L.sUserDefined1 + ' '
				ELSE ''
				END
			) + ISNULL(L.sNotes, '') + (
			CASE
				WHEN L.iType = 15
					AND L.hMy BETWEEN 600000000
						AND 699999999
					AND (
						L.bACH = - 1
						OR L.bCC = - 1
						)
					THEN ' [Payment Pending]'
				ELSE ''
				END
			) + (
			CASE
				WHEN L.iType = 7
					AND COALESCE(L.sUserDefined2, '') LIKE ':UB%'
					THEN ' ' + REPLACE(REPLACE(COALESCE(L.sUserDefined2, ''), ':UB Move Out', ''), ':UB', '') + '  '
				ELSE ''
				END
			)
	FROM Ledger L
	GROUP BY L.hMy
		,L.hmyperson
		,L.iType
		,L.sDateOccurred
		,L.chargecode
		,L.ChargeCodeId
		,L.DTLEASEFROM
		,l.sName
		,(
			CASE
				WHEN L.iType IN (
						6
						,15
						)
					AND COALESCE(L.sUserDefined1, '') <> ''
					THEN 'chk# ' + L.sUserDefined1 + ' '
				ELSE ''
				END
			) + ISNULL(L.sNotes, '') + (
			CASE
				WHEN L.iType = 15
					AND L.hMy BETWEEN 600000000
						AND 699999999
					AND (
						L.bACH = - 1
						OR L.bCC = - 1
						)
					THEN ' [Payment Pending]'
				ELSE ''
				END
			) + (
			CASE
				WHEN L.iType = 7
					AND COALESCE(L.sUserDefined2, '') LIKE ':UB%'
					THEN ' ' + REPLACE(REPLACE(COALESCE(L.sUserDefined2, ''), ':UB Move Out', ''), ':UB', '') + '  '
				ELSE ''
				END
			)
		,ISNULL(L.sNotes, '')
		,(
			CASE
				WHEN L.iType = 15
					AND L.hMy BETWEEN 600000000
						AND 699999999
					AND (
						L.bACH = - 1
						OR L.bCC = - 1
						)
					THEN ' [Payment Pending]'
				ELSE ''
				END
			)
		,(
			CASE
				WHEN L.iType = 7
					AND COALESCE(L.sUserDefined2, '') LIKE ':UB%'
					THEN ' ' + REPLACE(REPLACE(COALESCE(L.sUserDefined2, ''), ':UB Move Out', ''), ':UB', '') + '  '
				ELSE ''
				END
			)
	)
SELECT *
	,RunningBalance = SUM(Charges - Payments) OVER (
		PARTITION BY TenantId ORDER BY sDateOccurred
			,iType DESC
			,hMy ROWS UNBOUNDED PRECEDING
		)
INTO [Ledger#@@SESSIONID#]
FROM (
	SELECT TENANT.HMYPERSON TenantId
		,tr.hMy
		,tr.iType
		,tr.sDateOccurred
		,Description = RTRIM(tr.sNotes) + ' (Payable)'
		,Charges = - tr.sAmountPaid
		,Payments = 0.0
		,chargecode = ''
		,ChargeCodeId = 0
		,sName = ''
		,DTLEASEFROM = NULL
	FROM trans tr
	JOIN tenant ON tr.hPerson = tenant.hMyPerson
	JOIN property p ON p.hmy = tenant.hProperty
	WHERE tr.iType = 3
		AND tr.sAmountPaid <> 0
		AND TENANT.ISTATUS IN (
			0
			,2
			,3
			,4
			,6
			) #Conditions#

	UNION ALL

	SELECT TENANT.HMYPERSON TenantId
		,tr.hMy
		,tr.iType
		,tr.sDateOccurred
		,Description = 'Chk# ' + RTRIM(LTRIM(tr.uRef))
		,Charges = 0.0
		,Payments = - tr.sTotalAmount
		,chargecode = ''
		,ChargeCodeId = 0
		,sName = ''
		,DTLEASEFROM = NULL
	FROM trans tr
	JOIN tenant ON tr.hAccrualAcct = tenant.hMyPerson
	JOIN property p ON p.hmy = tr.hProp
	WHERE tr.iType = 2
		AND TENANT.ISTATUS IN (
			0
			,2
			,3
			,4
			,6
			) #Conditions#

	UNION ALL

	SELECT TenantId
		,hMy
		,iType
		,sDateOccurred
		,Description
		,Charges
		,Payments
		,chargecode
		,ChargeCodeId
		,sName
		,DTLEASEFROM
	FROM L1
	) x
ORDER BY TenantId
	,sDateOccurred
	,iType DESC
	,hMy;
	/* === Charges that should be prorated vs not === */
	;

WITH Map (
	ColumnName
	,SCODE
	,isProrate
	)
AS (
	SELECT *
	FROM (
		VALUES (
			'BaseRent'
			,'.rent'
			,1
			)
			,(
			'SecurityDeposit'
			,'secdep'
			,0
			)
			,(
			'AdditionalSecurityDeposit'
			,'secdepad'
			,0
			)
			,(
			'RemoteDeposit'
			,'satdep'
			,0
			)
			,(
			'PetDeposit'
			,'petdep'
			,0
			)
			,(
			'NRPetFee'
			,'nrpetfee'
			,0
			)
			,(
			'PetRent'
			,'petrent'
			,1
			)
			,(
			'AdminFee'
			,'admin'
			,0
			)
			,(
			'Concession'
			,'free'
			,1
			)
			,(
			'WaiveAppFee'
			,'credit'
			,0
			)
			,(
			'CableRent'
			,'cable'
			,1
			)
			,(
			'ParkingRent'
			,'park'
			,1
			)
			,(
			'StorageRent'
			,'storage'
			,1
			)
			,(
			'TrashRent'
			,'trash'
			,1
			)
		) v(ColumnName, SCODE, isProrate)
	)
	,
	/* === Source rows: one per receipt/tenant === */
G
AS (
	SELECT RTRIM(p.scode)       AS PropCode
		,RTRIM(pr.sCode)    AS ProspectCode
		,pr.hProperty       AS PropertyId
		,TENANT.hMyPerson   AS TenantId
		,TENANT.DTLEASEFROM AS LeaseFromDate
		,pr.hMy             AS ProspectId
		,gr.HMY             AS ReceiptId
		,gr.*
	FROM GuestCard_Receipt gr
	JOIN prospect pr ON pr.hmy = gr.hCode
	JOIN PROPERTY p ON p.HMY = pr.hProperty
	JOIN TENANT ON TENANT.HPROSPECT = pr.HMY
	WHERE 0 = 0
		AND TENANT.ISTATUS IN (
			0
			,2
			,3
			,4
			,5
			,6
			) #Conditions#
	)
	,
	/* === Unpivot only the fields we care about === */
Unpvt
AS (
	SELECT g.PropertyId
		,g.ProspectId
		,g.TenantId
		,g.ReceiptId
		,g.LeaseFromDate
		,u.ColumnName
		,u.Amount
	FROM G g
	CROSS APPLY (
		VALUES (
			'BaseRent'
			,g.BaseRent
			)
			,(
			'SecurityDeposit'
			,g.SecurityDeposit
			)
			,(
			'AdditionalSecurityDeposit'
			,g.AdditionalSecurityDeposit
			)
			,(
			'RemoteDeposit'
			,g.RemoteDeposit
			)
			,(
			'PetDeposit'
			,g.PetDeposit
			)
			,(
			'NRPetFee'
			,g.NRPetFee
			)
			,(
			'PetRent'
			,g.PetRent
			)
			,(
			'AdminFee'
			,g.AdminFee
			)
			,(
			'Concession'
			,g.Concession
			)
			,(
			'WaiveAppFee'
			,g.WaiveAppFee
			)
			,(
			'CableRent'
			,g.CableRent
			)
			,(
			'ParkingRent'
			,g.ParkingRent
			)
			,(
			'StorageRent'
			,g.StorageRent
			)
			,(
			'TrashRent'
			,g.TrashRent
			)
		) u(ColumnName, Amount)
	)
	,
	/* === Attach charge code + keep money-only rows === */
Rows
AS (
	SELECT u.PropertyId
		,u.ProspectId
		,u.TenantId
		,u.ReceiptId
		,u.LeaseFromDate
		,m.isProrate
		,u.ColumnName
		,TRY_CONVERT(DECIMAL(18, 2), u.Amount) AS Amount
		,m.SCODE
	FROM Unpvt u
	JOIN Map m ON m.ColumnName = u.ColumnName
	WHERE TRY_CONVERT(DECIMAL(18, 2), u.Amount) IS NOT NULL
		AND TRY_CONVERT(DECIMAL(18, 2), u.Amount) <> 0
	)
/* === Final split: amount vs prorated amount === */
SELECT r.PropertyId
	,r.ProspectId
	,r.TenantId
	,r.ReceiptId
	,r.isProrate
	,r.ColumnName   AS receiptField
	,r.Amount       AS amount
	,CASE
		WHEN r.isProrate = 1
			THEN dbo.fn_CalcProrationForTenant(N'Move In', r.LeaseFromDate, r.TenantId, r.Amount)
		ELSE 0
		END            AS ProrateAmt
	,c.HMY          AS chargeTypeHmy
	,RTRIM(c.SCODE) AS chargeCode
	,c.SNAME        AS chargeName
INTO [GuestCardReceipt#@@SESSIONID#]
FROM Rows r
JOIN CHARGTYP c ON RTRIM(c.SCODE) = r.SCODE
ORDER BY r.ColumnName;;

WITH MicBase
AS (
	SELECT TenantId = CONVERT(VARCHAR(50), TENANT.hMyPerson)
		,ct.sCode
		,ct.sName
		,LeaseAmt = CASE
			WHEN m.bRecurring <> - 1
				THEN m.cMoveInAmt
			ELSE CAST(COALESCE(NULLIF(m.cLeaseAmt, 0), NULLIF(m.cMoveInAmt, 0), ri.cRent, 0.0) AS DECIMAL(18, 2))
			END
		,ProrateAmt = CASE
			WHEN m.bRentableItem = - 1
				AND m.bProrate = - 1
				THEN dbo.fn_CalcProrationForTenant(N'Move In', TENANT.DTLEASEFROM, TENANT.HMYPERSON, ri.cRent)
			ELSE CAST(ISNULL(m.cMoveInAmt, 0.0)                                                AS DECIMAL(18, 2))
			END
		,m.bRecurring
		,m.bProrate
		,'MoveInCharges' Source
	FROM MoveInCharges m
	JOIN TENANT ON TENANT.hMyPerson = m.hTenant
	JOIN PROPERTY p ON p.hmy = TENANT.hproperty
	JOIN chargtyp ct ON ct.hMy = m.hChargeCode
	LEFT JOIN RentableItems ri ON ri.hMy = m.hRentableItem
	WHERE ISNULL(m.bSelected, 0) <> 0 #Conditions#
		AND TENANT.ISTATUS IN (
			0
			,2
			,3
			,4
			,6
			)
		AND NOT EXISTS (
			SELECT 1
			FROM [Ledger#@@SESSIONID#]
			WHERE TenantId = TENANT.hmyperson
				AND ChargeCodeId = CT.HMY
			)

	UNION

	SELECT hmyperson TenantId
		,ChargeCode
		,sName
		,SUM(Amount) LeaseAmt
		,SUM(ProrateAmt) ProrateAmt
		,- 1 bRecurring
		,- 1 bProrate
		,'RentableItemsType' Source
	FROM (
		SELECT TENANT.hmyperson
			,pr.hProspect
			,ct.hmy ChargeCodeId
			,RTRIM(ct.sCode) ChargeCode
			,RTRIM(ct.sName) sName
			,CONVERT(NUMERIC(18, 0), ISNULL(SUM(pr.dQuan), 0))                                                                                  AS Quantity
			,CAST(ISNULL(SUM(pr.dQuan), 0) * sum(rt.cRent)                                                                                      AS DECIMAL(18, 2)) AS Amount
			,dbo.fn_CalcProrationForTenant(N'Move In', MAX(TENANT.DTLEASEFROM), TENANT.hmyperson, CAST(ISNULL(SUM(pr.dQuan), 0) * sum(rt.cRent) AS DECIMAL(18, 2))) ProrateAmt
			,TENANT.DTLEASEFROM
		FROM RentableItemsType rt
		JOIN PROPERTY p ON p.HMY = RT.HPROP
		JOIN CHARGTYP ct ON ct.hmy = rt.HCHARGECODE
		LEFT JOIN prospect_charge pr ON rt.hMy = pr.hRentSchedule
		LEFT JOIN TENANT ON TENANT.HPROSPECT = pr.hProspect
		WHERE 0 = 0 #Conditions#
			AND NOT EXISTS (
				SELECT 1
				FROM [Ledger#@@SESSIONID#]
				WHERE TenantId = TENANT.hmyperson
					AND ChargeCodeId = CT.HMY
				)
		GROUP BY rt.sDesc
			,ct.hmy
			,ct.scode
			,TENANT.hmyperson
			,pr.hProspect
			,RTRIM(ct.sName)
			,TENANT.DTLEASEFROM
		HAVING CAST(ISNULL(SUM(pr.dQuan), 0) * sum(rt.cRent) AS DECIMAL(18, 2)) > 0
		) RI
	GROUP BY ChargeCodeId
		,ChargeCode
		,hmyperson
		,hProspect
		,sName

	UNION

	SELECT TenantId
		,ChargeCode
		,sName
		,SUM(Charges) LeaseAmt
		,dbo.fn_CalcProrationForTenant(N'Move In', MAX(DTLEASEFROM), TenantId, SUM(Charges)) ProrateAmt
		,0 bRecurring
		,0 bProrate
		,'Ledger' Source
	FROM [Ledger#@@SESSIONID#]
	GROUP BY TenantId
		,ChargeCode
		,sName

	UNION

	SELECT TenantId
		,chargeCode sCode
		,chargeName sName
		,SUM(amount) LeaseAmt
		,CASE
			WHEN MAX(isProrate) = 1
				THEN SUM(ProrateAmt)
			ELSE 0
			END ProrateAmt
		,- 1 bRecurring
		,- MAX(isProrate) bProrate
		,'GuestCardReceipt' Source
	FROM [GuestCardReceipt#@@SESSIONID#]
	WHERE NOT EXISTS (
			SELECT 1
			FROM MoveInCharges m
			JOIN TENANT ON TENANT.hMyPerson = m.hTenant
			JOIN PROPERTY p ON p.hmy = TENANT.hproperty
			JOIN chargtyp ct ON ct.hMy = m.hChargeCode
			LEFT JOIN RentableItems ri ON ri.hMy = m.hRentableItem
			WHERE ISNULL(m.bSelected, 0) <> 0 #Conditions#
				AND TENANT.ISTATUS IN (
					0
					,2
					,3
					,4
					,6
					)
				AND chargeTypeHmy = ct.hMy
				AND TENANT.HMYPERSON = [GuestCardReceipt#@@SESSIONID#].TenantId
			)
		AND (
			ChargeCode IN (
				'garage'
				,'mtplus'
				,'.rent'
				,'mtpest'
				,'packge'
				,'petrent'
				,'renins'
				,'park'
				,'mtm'
				,'storage'
				)
			OR chargeTypeHmy IN (
				SELECT hMy
				FROM chargtyp
				WHERE scode LIKE '%trash%'
				)
			OR chargeTypeHmy IN (
				SELECT hMy
				FROM chargtyp
				WHERE scode LIKE '%water%'
				)
			OR chargeTypeHmy IN (
				SELECT hMy
				FROM chargtyp
				WHERE scode LIKE 'ub%'
				)
			)
		AND chargeTypeHmy NOT IN (
			SELECT HRENTCHGCODE
			FROM param
			)
		AND NOT EXISTS (
			SELECT 1
			FROM RentableItemsType rt
			JOIN CHARGTYP ct2 ON ct2.hmy = rt.HCHARGECODE
			LEFT JOIN prospect_charge prc ON rt.hMy = prc.hRentSchedule
			LEFT JOIN TENANT t ON t.HPROSPECT = prc.hProspect
			WHERE t.HMYPERSON = [GuestCardReceipt#@@SESSIONID#].TenantId
				AND ct2.hMy = [GuestCardReceipt#@@SESSIONID#].chargeTypeHmy
				AND ISNULL(prc.dQuan, 0) * ISNULL(rt.cRent, 0) > 0
			)
	GROUP BY Tenantid
		,chargeCode
		,chargeName

	UNION

	SELECT *
	FROM (
		SELECT TenantId
			,chargeCode sCode
			,chargeName sName
			,SUM(amount) LeaseAmt
			,SUM(amount) ProrateAmt
			,0 bRecurring
			,0 bProrate
			,'GuestCardReceipt' Source
		FROM [GuestCardReceipt#@@SESSIONID#]
		CROSS JOIN (
			SELECT hRentChgCode
			FROM [param]
			) rent
		OUTER APPLY (
			SELECT t.srent
			FROM tenant t
			WHERE t.hmyperson = [GuestCardReceipt#@@SESSIONID#].TenantId
			) t
		WHERE NOT EXISTS (
				SELECT 1
				FROM MoveInCharges m
				JOIN TENANT ON TENANT.hMyPerson = m.hTenant
				JOIN PROPERTY p ON p.hmy = TENANT.hproperty
				JOIN chargtyp ct ON ct.hMy = m.hChargeCode
				LEFT JOIN RentableItems ri ON ri.hMy = m.hRentableItem
				WHERE ISNULL(m.bSelected, 0) <> 0 #Conditions#
					AND TENANT.ISTATUS IN (
						0
						,2
						,3
						,4
						,6
						)
					AND chargeTypeHmy = ct.hMy
					AND TENANT.HMYPERSON = [GuestCardReceipt#@@SESSIONID#].TenantId
				)
			AND chargeTypeHmy IN (
				SELECT hMy
				FROM chargtyp
				WHERE sName LIKE '%deposit%'
				)
			AND NOT EXISTS (
				SELECT 1
				FROM RentableItemsType rt
				JOIN CHARGTYP ct2 ON ct2.hmy = rt.HCHARGECODE
				LEFT JOIN prospect_charge prc ON rt.hMy = prc.hRentSchedule
				LEFT JOIN TENANT t ON t.HPROSPECT = prc.hProspect
				WHERE t.HMYPERSON = [GuestCardReceipt#@@SESSIONID#].TenantId
					AND ct2.hMy = [GuestCardReceipt#@@SESSIONID#].chargeTypeHmy
					AND ISNULL(prc.dQuan, 0) * ISNULL(rt.cRent, 0) > 0
				)
		GROUP BY Tenantid
			,chargeCode
			,chargeName
		) X

	UNION

	SELECT TENANT.HMYPERSON TenantId
		,CHARGTYP.sCode
		,CHARGTYP.sName
		,LeaseAmt = COALESCE(secDepChg.Amount, secDep.Amount, TENANT.SDEPOSIT0, 0)
		,ProrateAmt = COALESCE(secDepChg.Amount, secDep.Amount, TENANT.SDEPOSIT0, 0)
		,0 bRecurring
		,0 bProrate
		,'UnitDet' Source
	FROM TENANT
	JOIN PROPERTY p ON p.hmy = TENANT.hproperty
	INNER JOIN UNIT ON UNIT.hProperty = P.hMy
	OUTER APPLY (
		SELECT ct.hmy ChargeCodeId
			,p.hmy PropertyId
			,tr.hPerson AS TenantId
			,Amount = SUM(tr.sTotalAmount)
			,PostDate = DATEFROMPARTS(YEAR(tr.uPostDate), MONTH(tr.uPostDate), 1)
		FROM trans tr
		JOIN property p ON p.hmy = tr.hProp
		JOIN tenant t ON t.hMyPerson = tr.hPerson
		JOIN chargtyp ct ON ct.hMy = tr.hRetentionAcct
		WHERE p.iType = 3
			AND tr.iType = 7
			AND tr.sTotalAmount <> 0
			AND t.HMYPERSON = TENANT.HMYPERSON
			AND ct.sName LIKE '%deposit%'
		GROUP BY p.hmy
			,tr.hPerson
			,DATEFROMPARTS(YEAR(tr.uPostDate), MONTH(tr.uPostDate), 1)
			,ct.hmy
		) secDepChg
	OUTER APPLY (
		SELECT CT3.HMY ChargeCodeId
			,u.HUNITTYPE "UnitTypeId"
			,ISNULL(SUM(u.DAMOUNT), 0) "Amount"
		FROM UNITDET u
		JOIN CHARGTYP CT3 ON CT3.HMY = U.hChgCode
		WHERE u.hUnitType = UNIT.hUnitType
			AND u.hChgCode > 0
			AND u.bMoveIn = - 1
			AND CT3.sName LIKE '%deposit%'
		GROUP BY u.hUnitType
			,CT3.HMY
		) secDep
	CROSS APPLY (
		SELECT HMY
			,SCODE
			,SNAME
		FROM CHARGTYP
		WHERE CHARGTYP.HMY = COALESCE(secDepChg.ChargeCodeId, secDep.ChargeCodeId, 0)
			AND NOT EXISTS (
				SELECT 1
				FROM [GuestCardReceipt#@@SESSIONID#]
				WHERE TenantId = TENANT.HMYPERSON
					AND chargeTypeHmy = CHARGTYP.HMY
				)
		) CHARGTYP
	WHERE 0 = 0 #Conditions#
		AND NOT EXISTS (
			SELECT 1
			FROM MoveInCharges m2
			JOIN chargtyp ct2 ON ct2.hMy = m2.hChargeCode
			WHERE m2.hTenant = TENANT.hMyPerson
				AND ISNULL(m2.bSelected, 0) <> 0
				AND ct2.sName LIKE '%deposit%'
			)
		AND NOT EXISTS (
			SELECT 1
			FROM [Ledger#@@SESSIONID#]
			WHERE TenantId = TENANT.hmyperson
				AND ChargeCodeId = CHARGTYP.HMY
			)
	)
SELECT *
INTO [MicBase#@@SESSIONID#]
FROM MicBase;;

WITH MthRent
AS (
	SELECT Section = 'MthRent'
		,rn = ROW_NUMBER() OVER (
			PARTITION BY TenantId ORDER BY SUM(LeaseAmt) DESC
			)
		,TenantId
		,sCode
		,sName
		,Amt = SUM(LeaseAmt)
		,Prorate = 0
		,TaxDesc = 'TAX (0.0)'
		,Tax = '$0.00'
		,TotalDesc = 'TOTAL'
		,Total = SUM(LeaseAmt)
	FROM [MicBase#@@SESSIONID#]
	WHERE sCode <> 'secdep'
		AND bRecurring = - 1
	GROUP BY TenantId
		,sCode
		,sName
	HAVING SUM(LeaseAmt) <> 0

	UNION

	SELECT Section = 'MthRent'
		,rn = ROW_NUMBER() OVER (
			PARTITION BY TENANT.HMYPERSON ORDER BY SUM(TENANT.SRENT) DESC
			)
		,TenantId = TENANT.HMYPERSON
		,ct.sCode
		,ct.sName
		,Amt = SUM(TENANT.SRENT)
		,Prorate = 0
		,TaxDesc = 'TAX (0.0)'
		,Tax = '$0.00'
		,TotalDesc = 'TOTAL'
		,Total = SUM(TENANT.SRENT)
	FROM TENANT
	JOIN PROPERTY P ON P.HMY = TENANT.HPROPERTY
	CROSS JOIN (
		SELECT ct.sCode
			,ct.sName
		FROM CHARGTYP CT
		WHERE CT.HMY IN (
				SELECT hRentChgCode
				FROM [param]
				)
		) ct
	WHERE 0 = 0 #Conditions#
	GROUP BY TENANT.HMYPERSON
		,ct.sCode
		,ct.sName
	)
	,MthRentT
AS (
	SELECT Section = 'MthRentT'
		,rn = ROW_NUMBER() OVER (
			PARTITION BY TenantId ORDER BY SUM(Amt) DESC
			)
		,TenantId
		,sCode = ''
		,sName = ''
		,Amt = SUM(Amt)
		,Prorate = 0
		,TaxDesc = ''
		,Tax = ''
		,TotalDesc = 'TOTAL MONTHLY RENTS:'
		,Total = SUM(Amt)
	FROM MthRent
	GROUP BY TenantId
	HAVING SUM(Amt) <> 0
	)
	,PRent
AS (
	SELECT Section = 'PRent'
		,rn = ROW_NUMBER() OVER (
			PARTITION BY TenantId ORDER BY SUM(ProrateAmt) DESC
			)
		,TenantId
		,sCode
		,sName
		,Amt = 0
		,Prorate = SUM(ProrateAmt)
		,TaxDesc = 'TAX (0.0)'
		,Tax = '$0.00'
		,TotalDesc = 'TOTAL'
		,Total = SUM(ProrateAmt)
	FROM [MicBase#@@SESSIONID#]
	WHERE sCode <> 'secdep'
		AND bRecurring = - 1
	GROUP BY TenantId
		,sCode
		,sName
	HAVING SUM(ProrateAmt) <> 0

	UNION

	SELECT Section = 'PRent'
		,rn = ROW_NUMBER() OVER (
			PARTITION BY TENANT.HMYPERSON ORDER BY SUM(TENANT.SRENT) DESC
			)
		,TenantId = TENANT.HMYPERSON
		,ct.sCode
		,ct.sName
		,Amt = 0
		,Prorate = dbo.fn_CalcProrationForTenant(N'Move In', MAX(TENANT.DTLEASEFROM), TENANT.HMYPERSON, NULL)
		,TaxDesc = 'TAX (0.0)'
		,Tax = '$0.00'
		,TotalDesc = 'TOTAL'
		,Total = dbo.fn_CalcProrationForTenant(N'Move In', MAX(TENANT.DTLEASEFROM), TENANT.HMYPERSON, NULL)
	FROM TENANT
	JOIN PROPERTY P ON P.HMY = TENANT.HPROPERTY
	CROSS JOIN (
		SELECT RTRIM(SCODE) sCode
			,rtrim(sName) sName
		FROM CHARGTYP CT
		WHERE CT.HMY IN (
				SELECT hRentChgCode
				FROM [param]
				)
		) ct
	WHERE 0 = 0 #Conditions#
	GROUP BY TENANT.HMYPERSON
		,ct.sCode
		,ct.sName
	)
	,PRentT
AS (
	SELECT Section = 'PRentT'
		,rn = ROW_NUMBER() OVER (
			PARTITION BY TenantId ORDER BY SUM(Prorate) DESC
			)
		,TenantId
		,sCode = ''
		,sName = ''
		,Amt = 0
		,Prorate = SUM(Prorate)
		,TaxDesc = ''
		,Tax = ''
		,TotalDesc = 'TOTAL PRORATED MONTHLY RENTS:'
		,Total = SUM(Prorate)
	FROM PRent
	GROUP BY TenantId
	HAVING SUM(Prorate) <> 0
	)
	,NRFee
AS (
	SELECT Section
		,rn
		,TenantId
		,sCode
		,sName
		,SUM(Amt) Amt
		,0 Prorate
		,TaxDesc
		,Tax
		,TotalDesc
		,SUM(Total) Total
	FROM (
		SELECT Section = 'NRFee'
			,rn = ROW_NUMBER() OVER (
				PARTITION BY TenantId ORDER BY SUM(LeaseAmt) DESC
				)
			,TenantId
			,sCode
			,sName
			,Amt = SUM(LeaseAmt)
			,Prorate = 0
			,TaxDesc = 'TAX (0.0)'
			,Tax = '$0.00'
			,TotalDesc = 'TOTAL'
			,Total = SUM(LeaseAmt)
		FROM [MicBase#@@SESSIONID#]
		WHERE sCode IN (
				'admin'
				,'credit'
				,'nrpetfee'
				)
		GROUP BY TenantId
			,sCode
			,sName
		HAVING SUM(LeaseAmt) <> 0
		) x
	GROUP BY Section
		,rn
		,TenantId
		,sCode
		,sName
		,TaxDesc
		,Tax
		,TotalDesc
	)
	,NRFeeT
AS (
	SELECT 'NRFeeT' Section
		,1 rn
		,TenantId
		,sCode = ''
		,sName = ''
		,SUM(Amt)   AS Amt
		,CAST(0     AS DECIMAL(18, 2)) AS Prorate
		,TaxDesc = ''
		,Tax = ''
		,TotalDesc = 'TOTAL NON-REFUNDABLE FEES:'
		,SUM(Total) AS Total
	FROM NRFee
	GROUP BY TenantId
	HAVING SUM(Amt) <> 0
	)
	,Dep
AS (
	SELECT *
	FROM (
		SELECT Section = 'Dep'
			,rn = ROW_NUMBER() OVER (
				PARTITION BY TenantId
				,sCode ORDER BY SUM(LeaseAmt) DESC
				)
			,TenantId
			,sCode
			,sName
			,Amt = SUM(LeaseAmt)
			,Prorate = SUM(LeaseAmt)
			,TaxDesc = 'TAX (0.0)'
			,Tax = '$0.00'
			,TotalDesc = 'TOTAL'
			,Total = SUM(LeaseAmt)
		FROM [MicBase#@@SESSIONID#]
		WHERE sCode IN (
				'secdepad'
				,'secdep'
				,'satdep'
				,'keydep'
				,'escrow'
				)
		GROUP BY TenantId
			,sCode
			,sName
		HAVING SUM(LeaseAmt) <> 0
		) Q
	WHERE Q.rn = 1
	)
	,DepT
AS (
	SELECT Section = 'DepT'
		,rn = MAX(rn)
		,TenantId
		,sCode = ''
		,sName = ''
		,SUM(Amt)          AS Amt
		,CAST(SUM(Prorate) AS DECIMAL(18, 2)) AS Prorate
		,TaxDesc = ''
		,Tax = ''
		,TotalDesc = 'TOTAL REFUNDABLE DEPOSITS:'
		,SUM(Amt)          AS Total
	FROM Dep
	GROUP BY TenantId
	HAVING SUM(Amt) <> 0
	)
	,AllRowsNormal
AS (
	SELECT 1 AS Type
		,*
	FROM MthRent

	UNION ALL

	SELECT 0 AS Type
		,*
	FROM MthRentT

	UNION ALL

	SELECT 1 AS Type
		,*
	FROM PRent

	UNION ALL

	SELECT 0 AS Type
		,*
	FROM PRentT

	UNION ALL

	SELECT 1 AS Type
		,*
	FROM NRFee

	UNION ALL

	SELECT 0 AS Type
		,*
	FROM NRFeeT

	UNION ALL

	SELECT 1 AS Type
		,*
	FROM Dep

	UNION ALL

	SELECT 0 AS Type
		,*
	FROM DepT
	)
	,
	/* Grand total move-in costs (all prorate)  */
TotalMoveIn
AS (
	SELECT 2 AS Type
		,Section = 'Total'
		,rn = ROW_NUMBER() OVER (
			PARTITION BY TenantId ORDER BY SUM(Amt) DESC
			)
		,TenantId
		,sCode = ''
		,sName = ''
		,Amt = SUM(Amt)
		,Prorate = SUM(Prorate)
		,TaxDesc = ''
		,Tax = ''
		,TotalDesc = 'TOTAL MOVE-IN COSTS:'
		,Total = SUM(Amt)
	FROM AllRowsNormal
	WHERE Type = 0
	GROUP BY TenantId
	HAVING SUM(Amt) <> 0
		AND SUM(Prorate) <> 0
	)
SELECT Type
	,Section
	,rn
	,TenantId
	,sCode
	,UPPER(sName) sName
	,Amt = CASE
		WHEN Amt IS NULL
			THEN 0
		ELSE Amt
		END
	,Prorate = CASE
		WHEN Prorate IS NULL
			THEN 0
		ELSE Prorate
		END
	,TaxDesc
	,Tax
	,TotalDesc
	,Total = CASE
		WHEN Total IS NULL
			THEN 0
		ELSE Total
		END
INTO [AllCharges#@@SESSIONID#]
FROM (
	SELECT *
	FROM AllRowsNormal

	UNION ALL

	SELECT *
	FROM TotalMoveIn
	) AllRows
ORDER BY TenantId
	,CASE Section
		WHEN 'MthRent'
			THEN 1
		WHEN 'MthRentT'
			THEN 2
		WHEN 'PRent'
			THEN 3
		WHEN 'PRentT'
			THEN 4
		WHEN 'NRFee'
			THEN 5
		WHEN 'NRFeeT'
			THEN 6
		WHEN 'Dep'
			THEN 7
		WHEN 'DepT'
			THEN 8
		WHEN 'Total'
			THEN 9
		ELSE 10
		END
	,rn;

/* =========================
   Current charges → #Chg
   ========================= */
IF OBJECT_ID('tempdb..#Chg') IS NOT NULL
	DROP TABLE [#Chg];

SELECT rn
	,hmyperson
	,SUM(baseRent)           AS baseRent
	,SUM(parkingRent)        AS parkingRent
	,SUM(fees)               AS fees
	,SUM([bldgfee])          AS [bldgfee]
	,SUM(storageRent)        AS storageRent
	,SUM(petRent)            AS petRent
	,SUM(otherRent)          AS otherRent
	,SUM(MTPackage)          AS MTPackage
	,SUM(FreeRent)           AS FreeRent
	,SUM(RentIns)            AS RentIns
	,SUM(prorateBaseRent)    AS prorateBaseRent
	,SUM(ProrateBldgfee)     AS ProrateBldgfee
	,SUM(ProrateParkingRent) AS ProrateParkingRent
	,SUM(ProrateRentIns)     AS ProrateRentIns
	,SUM(applicFee2) applicFee2
	,SUM(ProrateOtherRent) ProrateOtherRent
INTO [#Chg]
FROM (
	SELECT ROW_NUMBER() OVER (
			PARTITION BY TENANT.hmyperson
			,ct.hMy ORDER BY cr.dtFrom DESC
				,ISNULL(cr.dtto, GETDATE()) DESC
				,cr.hMy DESC
			) rn
		,TENANT.hmyperson
		,cr.dtFrom
		,TENANT.dtLeaseFrom
		,SUM(CASE
				WHEN ct.scode IN ('credit')
					THEN cr.dEstimated
				ELSE 0
				END)                                                                                                                                                                                                              AS applicFee2
		,SUM(CASE
				WHEN ct.scode IN (
						'.rent'
						,'mtm'
						)
					THEN cr.dEstimated
				ELSE 0
				END)                                                                                                                                                                                                              AS baseRent
		,SUM(CASE
				WHEN ct.sCode IN (
						'.rent'
						,'mtm'
						)
					THEN (DAY(EOMONTH(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom))) - DAY(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom))) * COALESCE(cr.dEstimated, TENANT.sRent) / CAST(DAY(EOMONTH(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom))) AS DECIMAL(18, 6))
				ELSE (DAY(EOMONTH(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom))) - DAY(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom))) * COALESCE(cr.dEstimated, TENANT.sRent) / CAST(DAY(EOMONTH(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom)))  AS DECIMAL(18, 6))
				END)                                                                                                                                                                                                              AS prorateBaseRent
		,SUM(CASE
				WHEN ct.scode IN (
						'garage'
						,'park'
						,'storage'
						)
					THEN cr.dEstimated
				ELSE 0
				END)                                                                                                                                                                                                              AS parkingRent
		,SUM(CASE
				WHEN ct.sCode IN (
						'garage'
						,'park'
						)
					AND cr.dtFrom > DATEADD(MONTH, - 1, DATEADD(DAY, 1, EOMONTH(GETDATE())))
					THEN (DAY(EOMONTH(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom))) - DAY(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom))) * ISNULL(cr.dEstimated, 0) / CAST(DAY(EOMONTH(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom)))              AS DECIMAL(18, 6))
				WHEN ct.sCode IN (
						'garage'
						,'park'
						,'storage'
						)
					THEN cr.dEstimated
				ELSE 0
				END)                                                                                                                                                                                                              AS ProrateParkingRent
		,SUM(CASE
				WHEN ct.sCode IN ('mtpest')
					THEN cr.dEstimated
				ELSE 0
				END)                                                                                                                                                                                                              AS fees
		,SUM(CASE
				WHEN ct.sCode IN ('bldgfee')
					THEN cr.dEstimated
				ELSE 0
				END)                                                                                                                                                                                                              AS [bldgfee]
		,SUM(CASE
				WHEN ct.sCode IN ('bldgfee')
					THEN (DAY(EOMONTH(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom))) - DAY(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom))) * ISNULL(cr.dEstimated, 0) / CAST(DAY(EOMONTH(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom)))              AS DECIMAL(18, 6))
				ELSE 0
				END)                                                                                                                                                                                                              AS ProrateBldgfee
		,SUM(CASE
				WHEN ct.sCode IN ('storage')
					THEN cr.dEstimated
				ELSE 0
				END)                                                                                                                                                                                                              AS storageRent
		,SUM(CASE
				WHEN ct.sCode IN ('petrent')
					THEN cr.dEstimated
				ELSE 0
				END)                                                                                                                                                                                                              AS petRent
		,SUM(CASE
				WHEN ct.sCode IN (
						'misc'
						,'evcs'
						,'cable'
						,'mtpest'
						,'mtplus'
						)
					THEN cr.dEstimated
				ELSE 0
				END)                                                                                                                                                                                                              AS otherRent
		,SUM(CASE
				WHEN ct.sCode IN (
						'misc'
						,'evcs'
						,'cable'
						,'mtpest'
						,'mtplus'
						)
					AND cr.dtFrom > DATEADD(MONTH, - 1, DATEADD(DAY, 1, EOMONTH(GETDATE())))
					THEN (DAY(EOMONTH(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom))) - DAY(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom))) * ISNULL(cr.dEstimated, 0) / CAST(DAY(EOMONTH(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom)))              AS DECIMAL(18, 6))
				WHEN ct.sCode IN (
						'misc'
						,'evcs'
						,'cable'
						,'mtpest'
						,'mtplus'
						)
					THEN cr.dEstimated
				ELSE 0
				END)                                                                                                                                                                                                              AS ProrateOtherRent
		,SUM(CASE
				WHEN ct.sCode IN ('mtplus')
					THEN cr.dEstimated
				ELSE 0
				END)                                                                                                                                                                                                              AS MTPackage
		,SUM(CASE
				WHEN ct.sCode IN ('free')
					THEN cr.dEstimated
				ELSE 0
				END)                                                                                                                                                                                                              AS FreeRent
		,SUM(CASE
				WHEN ct.hMy IN (
						236
						,239
						)
					THEN cr.dEstimated
				ELSE 0
				END)                                                                                                                                                                                                              AS RentIns
		,SUM(CASE
				WHEN ct.hMy IN (
						236
						,239
						)
					THEN (DAY(EOMONTH(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom))) - (DAY(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom)) - 1)) * ISNULL(cr.dEstimated, 0) / CAST(DAY(EOMONTH(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom)))        AS DECIMAL(18, 6))
				ELSE 0
				END)                                                                                                                                                                                                              AS ProrateRentIns
	FROM TENANT
	JOIN property p ON p.HMY = TENANT.HPROPERTY
	LEFT JOIN camrule cr ON cr.htenant = TENANT.hmyperson
	LEFT JOIN chargtyp ct ON ct.hmy = cr.hchargecode
	WHERE (
			cr.dtTo IS NULL
			OR cr.dtTo >= GETDATE()
			) #CONDITIONS#
	GROUP BY TENANT.hmyperson
		,cr.dtFrom
		,TENANT.dtLeaseFrom
		,ct.hMy
		,ISNULL(cr.dtto, GETDATE())
		,cr.hMy
	) x
WHERE x.rn = 1
GROUP BY rn
	,hmyperson;

CREATE CLUSTERED INDEX IX_Chg_h ON [#Chg] (hmyperson);

DECLARE @n NVARCHAR(2) = CHAR(13) + CHAR(10);
DECLARE @version VARCHAR(12) = '#Version#';

IF LEN(@version) = 9
	SET @version = '33';

/*SELECT 'y_Arts_District_Lease_v' + @version + '.docx' "_FILE_0"*/
SELECT DISTINCT 'y_Arts_District_Lease.docx' "_FILE_0"
	,CASE
		WHEN Guarantors = ''
			THEN NULL
		ELSE 'y_FPMG_Args_District_Guarantor_Agreement.docx'
		END "_FILE_1"
	,'y_Arts_District_TrashDisposalAddendum.docx' AS "_FILE_2"
	,pb2.PI_KEYAPT
	,GS.Guarantors                                AS 'Guarantors'
	,'$' + FORMAT(COALESCE(NULLIF(pb2.PI_ENTRYDEV, 0), 0), 'n2') PI_ENTRYDEV
	,RTRIM(UNIT.scode) + CASE
		WHEN COALESCE(conc.MR_GP_SPACE, '') <> ''
			OR COALESCE(conc.ACD_Mailbox, '') <> ''
			THEN '  '
		ELSE ''
		END 'UnitNumOnly'
	,CASE
		WHEN COALESCE(conc.ACD_Mailbox, '') = ''
			THEN ''
		ELSE ', Mailbox No. '
		END 'MailBoxNumberDesc'
	,CASE
		WHEN COALESCE(conc.ACD_Mailbox, '') = ''
			THEN ''
		ELSE conc.ACD_Mailbox
		END 'MailBoxNumber'
	,CASE
		WHEN COALESCE(conc.MR_GP_SPACE, '') = ''
			THEN ''
		ELSE ', Parking No. '
		END 'ParkingNumDesc'
	,CASE
		WHEN COALESCE(conc.MR_GP_SPACE, '') = ''
			THEN ''
		ELSE conc.MR_GP_SPACE
		END 'ParkingNumber'
	,CASE
		WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
			AND COALESCE(mic.MIC_PetRent, 0) = 0
			AND COALESCE(mic.MIC_PetDep, 0) = 0
			AND ISNULL(pet.PetCount, 0) = 0
			THEN 'No pets have been authorized at this time.'
		WHEN ISNULL(lh_cnt.LeaseRowCount, 0) > 1
			AND ISNULL(renewCharges.renewPetRent, 0) = 0
			AND ISNULL(pet.PetCount, 0) = 0
			THEN 'No pets have been authorized at this time.'
		ELSE ''
		END                                          AS 'NoPets'
	,NonOccupants = CASE
		WHEN non.NonOccupants = ''
			THEN ''
		ELSE CHAR(13) + CHAR(10) + non.NonOccupants + CHAR(13) + CHAR(10)
		END
	,dbo.fnOrdinalDayFromNumber(COALESCE(NULLIF(TENANT.iDueDay, 0), 1)) iDueDay
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(NULLIF(mic.MIC_BaseRent, 0), TENANT.sRent)
			ELSE COALESCE(NULLIF(renewCharges.renewBaseRent, 0), 0)
			END, 'N2')                                  AS MIC_BaseRent
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN dbo.fn_CalcProrationForTenant(N'Move In', TENANT.DTLEASEFROM, TENANT.HMYPERSON, NULL) + CASE
						WHEN DAY(TENANT.DTLEASEFROM) >= 25
							THEN COALESCE(NULLIF(mic.MIC_BaseRent, 0), TENANT.sRent)
						ELSE 0
						END
			ELSE dbo.fn_CalcProrationForTenant(N'Move In', renewCharges.DTLEASEFROM, renewCharges.HMYPERSON, renewCharges.renewBaseRent) + CASE
					WHEN DAY(renewCharges.DTLEASEFROM) >= 25
						THEN COALESCE(NULLIF(renewCharges.renewBaseRent, 0), TENANT.sRent)
					ELSE 0
					END
			END, 'N2')                                  AS MIC_ProrateBaseRent
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN dbo.fn_CalcProrationForTenant(N'Move In', TENANT.DTLEASEFROM, TENANT.HMYPERSON, mic.MIC_PetRent + mic.MIC_ParkingAndStorage + mic.MIC_Package + mic.MIC_MTPlus) + CASE
						WHEN DAY(TENANT.DTLEASEFROM) >= 25
							THEN ISNULL(mic.MIC_PetRent, 0) + ISNULL(mic.MIC_ParkingAndStorage, 0) + ISNULL(mic.MIC_Package, 0) + ISNULL(mic.MIC_MTPlus, 0) + ISNULL(mic.MIC_RentIns, 0)
						ELSE 0
						END
			ELSE /* Renew Amounts */
				dbo.fn_CalcProrationForTenant(N'Move In', renewCharges.DTLEASEFROM, renewCharges.HMYPERSON, ISNULL(renewCharges.renewPetRent, 0) + ISNULL(renewCharges.renewParkingRent, 0) + ISNULL(renewCharges.renewPackage, 0) + ISNULL(renewCharges.renewMTPlus, 0) + ISNULL(renewCharges.renewMTPest, 0) + COALESCE(NULLIF(renewCharges.renewRentersInsurance, 0), ri.Amount, 0)) + CASE
					WHEN DAY(renewCharges.DTLEASEFROM) >= 25
						THEN ISNULL(renewCharges.renewPetRent, 0) + ISNULL(renewCharges.renewParkingRent, 0) + ISNULL(renewCharges.renewPackage, 0) + ISNULL(renewCharges.renewMTPlus, 0) + ISNULL(renewCharges.renewMTPest, 0) + COALESCE(NULLIF(renewCharges.renewRentersInsurance, 0), ri.Amount, 0)
					ELSE 0
					END
			END, 'N2')                                  AS MIC_ProrateOther
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN ISNULL(mic.MIC_Parking, 0)
			ELSE ISNULL(renewCharges.renewParkingRent, 0)
			END, 'N2')                                  AS MIC_Parking
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN ISNULL(mic.MIC_Storage, 0)
			ELSE ISNULL(renewCharges.renewStorageRent, 0)
			END, 'N2')                                  AS MIC_Storage
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN ISNULL(dbo.fn_CalcProrationForTenant(N'Move In', TENANT.DTLEASEFROM, TENANT.HMYPERSON, NULL), 0) + ISNULL(dbo.fn_CalcProrationForTenant(N'Move In', TENANT.DTLEASEFROM, TENANT.HMYPERSON, ISNULL(mic.MIC_PetRent, 0) + ISNULL(mic.MIC_ParkingAndStorage, 0) + ISNULL(mic.MIC_Package, 0) + ISNULL(mic.MIC_MTPlus, 0)), 0) + CASE
						WHEN DAY(TENANT.DTLEASEFROM) >= 25
							THEN ISNULL(NULLIF(mic.MIC_BaseRent, 0), TENANT.sRent) + ISNULL(mic.MIC_PetRent, 0) + ISNULL(mic.MIC_ParkingAndStorage, 0) + ISNULL(mic.MIC_Package, 0) + ISNULL(mic.MIC_MTPlus, 0)
						ELSE 0
						END
			ELSE /* Renew Amounts */
				dbo.fn_CalcProrationForTenant(N'Move In', renewCharges.DTLEASEFROM, renewCharges.HMYPERSON, renewCharges.renewBaseRent) + CASE
					WHEN DAY(renewCharges.DTLEASEFROM) >= 25
						THEN COALESCE(NULLIF(renewCharges.renewBaseRent, 0), TENANT.sRent)
					ELSE 0
					END + dbo.fn_CalcProrationForTenant(N'Move In', renewCharges.DTLEASEFROM, renewCharges.HMYPERSON, renewPetRent + renewParkingRent + renewPackage + renewMTPest + renewMTPlus + COALESCE(NULLIF(renewCharges.renewRentersInsurance, 0), ri.Amount, 0)) + CASE
					WHEN DAY(renewCharges.DTLEASEFROM) >= 25
						THEN ISNULL(renewPetRent, 0) + ISNULL(renewParkingRent, 0) + ISNULL(renewPackage, 0) + ISNULL(renewMTPlus, 0) + ISNULL(renewMTPest, 0) + COALESCE(NULLIF(renewCharges.renewRentersInsurance, 0), ri.Amount, 0)
					ELSE 0
					END
			END, 'N2')                                  AS MIC_SubtotalPara
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(NULLIF(mic.MIC_ProrateNRPetFee, 0), 0)
			ELSE 0
			END, 'N2')                                  AS MIC_NRPetFee
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(NULLIF(mic.MIC_BaseRent, 0), TENANT.sRent) + COALESCE(mic.MIC_PetRent, 0) + COALESCE(mic.MIC_ParkingAndStorage, chg.parkingRent) + COALESCE(mic.MIC_Package, 0)
			ELSE COALESCE(renewCharges.renewBaseRent, 0) + COALESCE(renewCharges.renewPetRent, 0) + COALESCE(renewCharges.renewParkingRent, 0) + COALESCE(renewCharges.renewStorageRent, 0) + COALESCE(renewCharges.renewOtherRent, 0) + COALESCE(renewCharges.renewMTPlus, 0) + COALESCE(renewCharges.renewMTPest, 0) + COALESCE(NULLIF(renewCharges.renewRentersInsurance, 0), ri.Amount, 0)
			END, 'N2')                                  AS MIC_Subtotal
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(mic.MIC_Package, 0)
			ELSE 0
			END, 'N2')                                  AS MIC_Package
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(mic.MIC_ProratePackage, 0)
			ELSE 0
			END, 'N2')                                  AS MIC_ProratePackage
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(mic.MIC_ParkingAndStorage, chg.parkingRent)
			ELSE COALESCE(renewCharges.renewParkingRent, 0) + COALESCE(renewCharges.renewStorageRent, 0)
			END, 'N2')                                  AS MIC_ParkingAndStorage
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(mic.MIC_ProrateParkingAndStorage, 0)
			ELSE 0
			END, 'N2')                                  AS MIC_ProrateParkingAndStorage
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(mic.MIC_Fees, 0)
			ELSE COALESCE(renewCharges.renewMtPest, 0)
			END, 'N2')                                  AS MIC_Fees
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(mic.MIC_ProrateFees, 0)
			ELSE 0
			END, 'N2')                                  AS MIC_ProrateFees
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(mic.MIC_BldgFee, 0)
			ELSE 0
			END, 'N2')                                  AS MIC_BldgFee
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(mic.MIC_ProrateBldgFee, 0)
			ELSE 0
			END, 'N2')                                  AS MIC_ProrateBldgFee
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(mic.MIC_StorageRent, 0)
			ELSE COALESCE(renewCharges.renewStorageRent, 0)
			END, 'N2')                                  AS MIC_StorageRent
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(mic.MIC_ProrateStorageRent, 0)
			ELSE 0
			END, 'N2')                                  AS MIC_ProrateStorageRent
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(mic.MIC_PetRent, 0)
			ELSE COALESCE(renewCharges.renewPetRent, 0)
			END, 'N2')                                  AS MIC_PetRent
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(NULLIF(mic.MIC_ProratePetRent, 0), 0)
			ELSE 0
			END, 'N2')                                  AS MIC_ProratePetRent
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(mic.MIC_OtherRent, 0)
			ELSE COALESCE(renewCharges.renewOtherRent, 0)
			END, 'N2')                                  AS MIC_OtherRent
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(NULLIF(mic.MIC_ProrateOtherRent, 0), Chg.ProrateOtherRent, 0)
			ELSE 0
			END, 'N2')                                  AS MIC_ProrateOtherRent
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(mic.MIC_SubtotalMonthlyRent, 0)
			ELSE COALESCE(renewCharges.renewBaseRent, 0) + COALESCE(renewCharges.renewParkingRent, 0) + COALESCE(renewCharges.renewStorageRent, 0) + COALESCE(renewCharges.renewOtherRent, 0) + COALESCE(renewCharges.renewMtPest, 0) + COALESCE(renewCharges.renewMTPlus, 0)
			END, 'N2')                                  AS MIC_SubtotalMonthlyRent
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(mic.MIC_ProrateSubtotalMonthlyRent, 0)
			ELSE 0
			END, 'N2')                                  AS MIC_ProrateSubtotalMonthlyRent
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(NULLIF(mic.MIC_MTPlus, 0), chg.MTPackage + chg.parkingRent + chg.otherRent + chg.RentIns, 0)
			ELSE COALESCE(renewCharges.renewMTPlus, 0) + COALESCE(renewCharges.renewMtPest, 0)
			END, 'N2')                                  AS MIC_MTPlus
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(mic.MIC_ProrateMTPlus, 0)
			ELSE 0
			END, 'N2')                                  AS MIC_ProrateMTPlus
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(mic.MIC_FreeRent, 0)
			ELSE 0
			END, 'N2')                                  AS MIC_FreeRent
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(mic.MIC_ProrateFreeRent, 0)
			ELSE 0
			END, 'N2')                                  AS MIC_ProrateFreeRent
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(mic.MIC_RentIns, 0)
			ELSE COALESCE(NULLIF(renewCharges.renewRentersInsurance, 0), ri.Amount, 0)
			END, 'N2')                                  AS MIC_RentIns
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(mic.MIC_ProrateRentIns, 0)
			ELSE COALESCE(NULLIF(renewCharges.renewRentersInsurance, 0), ri.Amount, 0)
			END, 'N2')                                  AS MIC_ProrateRentIns
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(mic.MIC_TotalFees, 0)
			ELSE COALESCE(renewCharges.renewMtPest, 0) -- no bldgfee in renew; adjust if you want
			END, 'N2')                                  AS MIC_TotalFees
	,'$ ' + FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN COALESCE(mic.MIC_ProrateTotalFees, 0)
			ELSE 0
			END, 'N2')                                  AS MIC_ProrateTotalFees
	,FORMAT(CASE
			WHEN ISNULL(lh_cnt.LeaseRowCount, 0) <= 1
				THEN mic.MIC_LastChargeDate
			ELSE NULL
			END, 'MM/dd/yyyy')                          AS MIC_LastChargeDate
	,OccupantsNotResident = STUFF((
			SELECT DISTINCT ', ' + LTRIM(RTRIM(NULLIF(RTRIM(LTRIM(ISNULL(pn.sfirstname, ''))) + ' ' + RTRIM(LTRIM(ISNULL(pn.ulastname, ''))), '')))
			FROM tenant t
			JOIN room r ON r.hMyTenant = t.hMyPerson
			JOIN person pn ON pn.hmy = r.hmyperson
			WHERE t.hmyperson = TENANT.hmyperson
				AND ISNULL(r.iOccupantType, 1) = 1
				AND (
					ISNULL(pn.sfirstname, '') <> ''
					OR ISNULL(pn.ulastname, '') <> ''
					)
				AND ISNULL(r.bOccupant, 1) = 0
			FOR XML PATH('')
				,TYPE
			).value('.', 'nvarchar(max)'), 1, 2, '')
	,AllOccupants = STUFF((
			SELECT DISTINCT ', ' + LTRIM(RTRIM(NULLIF(RTRIM(LTRIM(ISNULL(pn.sfirstname, ''))) + ' ' + RTRIM(LTRIM(ISNULL(pn.ulastname, ''))), '')))
			FROM tenant t
			JOIN room r ON r.hMyTenant = t.hMyPerson
			JOIN person pn ON pn.hmy = r.hmyperson
			WHERE t.hmyperson = TENANT.hmyperson
				AND ISNULL(r.iOccupantType, 1) = 1
				AND (
					ISNULL(pn.sfirstname, '') <> ''
					OR ISNULL(pn.ulastname, '') <> ''
					)
			FOR XML PATH('')
				,TYPE
			).value('.', 'nvarchar(max)'), 1, 2, '')
	,dbo.fnOrdinalDayFromDate(GETDATE()) 'DayOrdinal'
	,FORMAT(GETDATE(), 'MMMM') + ' ' + convert(VARCHAR, DAY(GETDATE())) + ', ' + CONVERT(VARCHAR, YEAR(GETDATE())) TodayMonthFullDayAndYear
	,'$ ' + FORMAT(MIC_ProrateBaseRent + MIC_ProratePetRent + MIC_ProrateParkingAndStorage + MIC_ProratePackage + MIC_ProrateMTPlus + MIC_BaseRent + MIC_PetRent + MIC_ParkingAndStorage + MIC_Package + MIC_MTPlus, 'N2') AS 'MIC_TotalProrate'
	,GETDATE() "TODAY"
	,DAY(GETDATE()) 'TodayDay'
	,YEAR(COALESCE(lh.dtLeaseFrom, TENANT.dtLeaseFrom)) 'LeaseFromDateYear'
	,DAY(COALESCE(lh.dtLeaseFrom, TENANT.dtLeaseFrom)) 'LeaseFromDateDay'
	,YEAR(COALESCE(lh.dtLeaseTo, TENANT.dtLeaseTo)) 'LeaseToDateYear'
	,dbo.fnOrdinalDayFromDate(COALESCE(lh.dtLeaseFrom, TENANT.dtLeaseFrom)) 'LeaseFromDateOrdinal'
	,dbo.fnOrdinalDayFromDate(COALESCE(lh.dtLeaseTo, TENANT.dtLeaseTo)) 'LeaseToDateOrdinal'
	,DAY(COALESCE(lh.dtLeaseFrom, TENANT.dtLeaseFrom)) AS 'Day'
	,YEAR(COALESCE(lh.dtLeaseFrom, TENANT.dtLeaseFrom)) AS 'YearFromDate'
	,CONVERT(VARCHAR(4), YEAR(GETDATE())) 'Year'
	,DATENAME(MONTH, GETDATE()) 'MonthNameFull'
	,DATENAME(MONTH, COALESCE(lh.dtLeaseFrom, TENANT.dtLeaseFrom)) 'MonthNameFromDate'
	,DATENAME(MONTH, COALESCE(lh.dtLeaseTo, TENANT.dtLeaseTo)) 'MonthNameToDate'
	,CASE
		WHEN lh.hMy IS NOT NULL
			THEN dbo.fnLeaseTermFromHmy(lh.hMy)
		ELSE dbo.fnLeaseTermFromDates(COALESCE(lh.dtLeaseFrom, TENANT.dtLeaseFrom), COALESCE(lh.dtLeaseTo, TENANT.dtLeaseTo))
		END 'LeaseTermOrdinal'
	,'' NewTermAdditionalDollarAmt
	,'20' 'NewTermAdditionalPercent'
	,'[X]' 'SelectNewTermAddPercent'
	,'[ ]' 'SelectNewTermAddDollarAmt'
	,'65.00' "rate"
	,'$ ' + FORMAT(COALESCE(NULLIF(mic.MIC_BaseRent, 0), NULLIF(chg.baseRent, 0), TENANT.sRent), 'N2') 'baseRent'
	,chg.parkingRent
	,chg.storageRent
	,chg.otherRent
	,chg.petRent
	,'$ ' + FORMAT(ISNULL(mic.MIC_Fees, 0), 'N2') 'fees'
	,'$ ' + FORMAT(isnull(adminFee.Amount, 0), 'N2') 'adminFee'
	,'$ ' + FORMAT(COALESCE(transApplicFee.Amount, applicFee.Amount, 0), 'N2') 'applicationFee'
	,'$ ' + FORMAT(isnull(adminFee.Amount, 0), 'N2') 'subtotalNonRefundable'
	,'$ ' + FORMAT(isnull(adminFee.Amount, 0) + COALESCE(transApplicFee.Amount, applicFee.Amount, 0) + COALESCE(MIC_ProrateNRPetFee, 0), 'N2') 'TotalNRFees'
	,dbo.fnOrdinalDayFromNumber(CASE
			WHEN COALESCE(NULLIF(ISNULL(TENANT.iDueDay, 1) + COALESCE(NULLIF(TENANT.ILATEGRACE, 0), grace.hValue), 0), grace.hValue, 1) = 1
				THEN 1
			ELSE COALESCE(NULLIF(ISNULL(TENANT.iDueDay, 1) + COALESCE(NULLIF(TENANT.ILATEGRACE, 0), grace.hValue), 0), grace.hValue, 1)
			END) 'RentDueDayOrdinal'
	,'$ ' + FORMAT(COALESCE(NULLIF(TENANT.SLATEMIN, 0), p.SLATEMIN), 'N2') 'LateFeeAmount'
	,'$ ' + FORMAT(TENANT.dLateMinDueAmt, 'N2') 'dLateMinDueAmt'
	,'$ ' + FORMAT(COALESCE(NULLIF(TENANT.SLATEPERDAY, 0), p.SLATEPERDAY), 'N2') 'SecondaryLateFeeAmount'
	,'$ ' + FORMAT(COALESCE(nsf.hValue, 25.00), 'N2') 'DishonoredFunds'
	,'$ ' + FORMAT(COALESCE(NULLIF(mic.MIC_BaseRent, 0), NULLIF(chg.baseRent, 0), TENANT.sRent) * 2, 'N2') 'RentTimesTwo'
	,'.' AS 'Period'
	,CASE
		WHEN lh_cnt.LeaseRowCount <= 1
			THEN '[X]'
		ELSE '[_]'
		END INMI
	,'[_]' ITF
	,'[_]' IsChange
	,'' TF
	,CASE
		WHEN lh_cnt.LeaseRowCount > 1
			THEN '[X]'
		ELSE '[_]'
		END IR
	,'[X]' SmartYes
	,'[_]' SmartNo
	,'[X]' WiFiYes
	,'[_]' WiFiNo
	,'[X]' YesHasTrash
	,'[_]' NoTrash
	,'[X]' HasIApartments
	,'[X]' YesPackage
	,'[_]' NoPackage
	,'[X]' 'Fetch'
	,'$ ' + FORMAT(ISNULL(chg.baseRent, 0), 'N2') RentTimesTwo
	,'$ ' + FORMAT(ISNULL(chg.MTPackage, 0), 'N2') MTPackage
	,'$ ' + FORMAT(COALESCE(NULLIF(TENANT.SDEPOSIT0, 0), secDepChg.Amount, secDep.Amount, 0) + COALESCE(MIC_PetDep, 0), 'N2') 'SecDeposit'
	,'$ ' + FORMAT(COALESCE(MIC_PetDep, 0), 'N2') 'MIC_PetDep'
	,'$ ' + FORMAT(COALESCE(NewChgs.SecDep, 0), 'N2') 'SecurityDeposit'
	,'$ ' + FORMAT(COALESCE(NewChgs.SecDep, 0) + COALESCE(MIC_PetDep, 0), 'N2') 'TotalDeposit'
	,CONCAT (
		COALESCE(NULLIF(conc.FreeRentDesc, ''), 'N/A')
		,' '
		,'$ ' + FORMAT(conc.TotalFreeRentAmount, 'N2')
		) 'FreeRentDesc'
	,CASE
		WHEN isnull(gli.hsis, 'Yes') = 'Yes'
			THEN '[X] '
		ELSE '[ ] '
		END "optin"
	,CASE
		WHEN isnull(gli.hsis, 'Yes') = 'No'
			THEN '[X] '
		ELSE '[ ] '
		END "optout"
	,RTRIM(p.saddr1) 'PropertyName'
	,RTRIM(TENANT.SFIRSTNAME) + ' ' + RTRIM(TENANT.SLASTNAME) 'TenantOnly'
	,RTRIM(TENANT.SFIRSTNAME) + ' ' + RTRIM(TENANT.SLASTNAME) + ROOM.Roommates 'TenantAndRoommates'
	,RTRIM(TENANT.SFIRSTNAME) + ' ' + RTRIM(TENANT.SLASTNAME) 'TenantOnly'
	,RTRIM(CASE
			WHEN addr.saddr1 LIKE '%Unit%'
				THEN left(RTRIM(ISNULL(addr.sAddr1, '')) + ' ' + RTRIM(ISNULL(addr.sAddr2, '')), charindex('Unit', RTRIM(ISNULL(addr.sAddr1, '')) + ' ' + RTRIM(ISNULL(addr.sAddr2, ''))) - 1)
			WHEN addr.saddr1 LIKE '%#%'
				THEN left(RTRIM(ISNULL(addr.sAddr1, '')) + ' ' + RTRIM(ISNULL(addr.sAddr2, '')), charindex('#', RTRIM(ISNULL(addr.sAddr1, '')) + ' ' + RTRIM(ISNULL(addr.sAddr2, ''))) - 1)
			WHEN addr.saddr1 LIKE '%Apt%'
				THEN left(RTRIM(ISNULL(addr.sAddr1, '')) + ' ' + RTRIM(ISNULL(addr.sAddr2, '')), charindex('Apt', RTRIM(ISNULL(addr.sAddr1, '')) + ' ' + RTRIM(ISNULL(addr.sAddr2, ''))) - 1)
			WHEN addr.saddr1 LIKE '%,%'
				THEN left(RTRIM(ISNULL(addr.sAddr1, '')) + ' ' + RTRIM(ISNULL(addr.sAddr2, '')), charindex(',', RTRIM(ISNULL(addr.sAddr1, '')) + ' ' + RTRIM(ISNULL(addr.sAddr2, ''))) - 1)
			ELSE rtrim(isnull(addr.sAddr1, '')) + ' ' + rtrim(isnull(addr.sAddr2, ''))
			END) + ', ' + COALESCE(ADDR.SCITY + ', ', '') + COALESCE(ADDR.sState + ', ', '') + COALESCE(ADDR.SZIPCODE, '') 'UnitFullAddress'
	,unit.scode Ucode
	,tenant.scode Tcode
	,CASE
		WHEN addr.saddr1 LIKE '%Unit%'
			THEN left(RTRIM(ISNULL(addr.sAddr1, '')) + ' ' + RTRIM(ISNULL(addr.sAddr2, '')), charindex('Unit', RTRIM(ISNULL(addr.sAddr1, '')) + ' ' + RTRIM(ISNULL(addr.sAddr2, ''))) - 1)
		WHEN addr.saddr1 LIKE '%#%'
			THEN left(RTRIM(ISNULL(addr.sAddr1, '')) + ' ' + RTRIM(ISNULL(addr.sAddr2, '')), charindex('#', RTRIM(ISNULL(addr.sAddr1, '')) + ' ' + RTRIM(ISNULL(addr.sAddr2, ''))) - 1)
		WHEN addr.saddr1 LIKE '%Apt%'
			THEN left(RTRIM(ISNULL(addr.sAddr1, '')) + ' ' + RTRIM(ISNULL(addr.sAddr2, '')), charindex('Apt', RTRIM(ISNULL(addr.sAddr1, '')) + ' ' + RTRIM(ISNULL(addr.sAddr2, ''))) - 1)
		WHEN addr.saddr1 LIKE '%,%'
			THEN left(RTRIM(ISNULL(addr.sAddr1, '')) + ' ' + RTRIM(ISNULL(addr.sAddr2, '')), charindex(',', RTRIM(ISNULL(addr.sAddr1, '')) + ' ' + RTRIM(ISNULL(addr.sAddr2, ''))) - 1)
		ELSE rtrim(isnull(addr.sAddr1, '')) + ' ' + rtrim(isnull(addr.sAddr2, ''))
		END TAdd1
	,RTRIM(ISNULL(Tenant.sCity, '')) TAdd2
	,RTRIM(ISNULL(Tenant.sZipCode, '')) TAdd3
	,ltrim(RTRIM(ISNULL(p.saddr1, ''))) PropName
	,ltrim(RTRIM(ISNULL(p.saddr2, ''))) + ', ' + ltrim(RTRIM(ISNULL(p.scity, ''))) + ', ' + ltrim(RTRIM(ISNULL(p.SSTATE, ''))) + ', ' + ltrim(RTRIM(ISNULL(p.SZIPCODE, ''))) PropAddr
	,TENANT.sFirstName + ' ' + TENANT.sLastName "tenName"
	,ADDR.saddr1 "unitaddr1"
	,ADDR.scity "unitcity"
	,ADDR.sstate "unitstate"
	,ADDR.szipcode "unitzip"
	,RTRIM(ADDR.sAddr1) + CASE
		WHEN ISNULL(ADDR.sAddr2, '') = ''
			THEN ''
		ELSE ', ' + ADDR.sAddr2
		END + CASE
		WHEN ISNULL(ADDR.sCity, '') = ''
			THEN ''
		ELSE ', ' + ADDR.sCity
		END + CASE
		WHEN ISNULL(ADDR.sState, '') = ''
			THEN ''
		ELSE ', ' + ADDR.sState
		END + CASE
		WHEN ISNULL(ADDR.sZipCode, '') = ''
			THEN ''
		ELSE ' ' + ADDR.sZipCode
		END "UnitAddress"
	,p.saddr1 "propname"
	,pbli.INFO_COUNTY "propaddr3"
	,lh.dtleasefrom "prleasefrom"
	,lh.dtleaseto "prleaseto"
	,UNIT.scode "unitcode"
	,UNITTYPE.scode "utcode"
	,pbli.INFO_LANDLORD "OLE_INFO_LANDLORD"
	,pbli.INFO_MANAGER "OLE_INFO_MANAGER"
	,gli.C_DescO "C_DescO"
	,gli.C_AmtO "C_AmtO"
	,gli.C_DescT "C_DescT"
	,gli.c_amtT "C_AmtT"
	,gli.C_Date_From "C_Date_From"
	,gli.c_Date_To "C_Date_To"
	,(DATENAME(MONTH, lh.dtleasefrom) + RIGHT(CONVERT(VARCHAR(12), lh.dtleasefrom, 107), 9)) "TODAYLONG"
	,(DATENAME(MONTH, GETDATE()) + RIGHT(CONVERT(VARCHAR(12), GETDATE(), 107), 9)) "TODAYLONG2"
	,isnull(u_questions_name, '') "qname"
	,isnull(u_questions_phone, '') "qphone"
	,isnull(u_questions_days, '') "qdays"
	,isnull(u_questions_hours, '') "qhours"
	,gli.INFO_CREATEDBY "Createdby"
	,p.saddr1 "propaddr"
	,p.saddr2 "propstreet"
	,p.scity + ', ' + p.sstate + ' ' + p.szipcode "propaddr2"
	,pb2.pi_email "propemail"
	,dbo.FormatPhoneNumber(pb2.PI_PHONE) "propphn"
	,dbo.FormatPhoneNumber(ISNULL(NULLIF(pb2.PI_EMRGPHN, ''), pb2.PI_PHONE)) 'EmergencyPhone'
	,ltrim(RTRIM(ISNULL(p.saddr2, ''))) + ', ' + ltrim(RTRIM(ISNULL(p.scity, ''))) + ', ' + ltrim(RTRIM(ISNULL(p.SSTATE, ''))) + ', ' + ltrim(RTRIM(ISNULL(p.SZIPCODE, ''))) + ', ' + isnull(pb2.pi_phone, '') "PropAddrandPhone"
	,isnull(pbli.b_secdep_bank, '') "bankname"
	,isnull(pbli.b_secdep_addr, '') "bankaddr"
	,EmergencyName
	,TENANT.HMYPERSON "_KEY_"
FROM TENANT
JOIN property p ON p.HMY = TENANT.HPROPERTY
JOIN PROSPECT ON PROSPECT.hTenant = TENANT.HMYPERSON
LEFT JOIN propbut2 pb2 ON pb2.hcode = p.hmy
LEFT JOIN propbut_prop65 p65 ON p.hmy = p65.hcode
JOIN UNIT ON UNIT.HMY = TENANT.HUNIT
LEFT JOIN UNITTYPE ON UNIT.HUNITTYPE = UNITTYPE.HMY
LEFT JOIN ADDR ON ADDR.HPOINTER = UNIT.HMY
	AND ADDR.ITYPE = 4
LEFT JOIN PropOptions grace ON grace.hProp = p.hMy
	AND grace.sType = 'LateGraceDays'
LEFT JOIN PropOptions nsf ON nsf.hProp = p.hMy
	AND nsf.sType = 'NSFFee'
LEFT JOIN PROPBUT_LEASE_INFO pbli ON pbli.HCODE = p.HMY
LEFT JOIN PROPBUT_WA_ADDENDA_INFO pbwali ON pbwali.HCODE = p.HMY
LEFT JOIN LEASEBUT_GC_INFO gli ON gli.HCODE = PROSPECT.HMY
OUTER APPLY (
	SELECT LeaseRowCount = COUNT(*)
	FROM lease_history lh
	WHERE lh.hTent = TENANT.hMyPerson
		AND isNull(lh.iInactiveProposal, 0) < 1
	) lh_cnt
OUTER APPLY (
	SELECT TOP (1) lh.*
	FROM lease_history lh
	WHERE lh.hTent = TENANT.hMyPerson
		AND isNull(lh.iInactiveProposal, 0) < 1
	ORDER BY lh.hMy DESC
	) lh
LEFT JOIN UNITBUT_RADON R ON R.HCODE = UNIT.HMY
	AND ISNULL(R.UNIT_RADON_START_DATE, '') <> ''
OUTER APPLY (
	SELECT Roommates = isnull(STUFF((
					SELECT CASE
							WHEN isnull(room.boccupant, 0) <> 0
								THEN ' '
							ELSE ', ' + RTRIM(ISNULL(PERSON.SFIRSTNAME, '')) + ' ' + RTRIM(ISNULL(PERSON.ULASTNAME, ''))
							END
					FROM PROPERTY P2
					JOIN TENANT T2 ON P2.HMY = T2.HPROPERTY
					LEFT JOIN ROOM ON T2.HMYPERSON = ROOM.HMYTENANT
					JOIN PERSON ON ROOM.HMYPERSON = PERSON.HMY
					WHERE 0 = 0
						AND ROOM.dtmoveout IS NULL
						AND isnull(ROOM.sRelationship, '') <> 'Guarantor'
						AND T2.HMYPERSON = TENANT.hMyPerson
					FOR XML PATH('')
						,TYPE
					).value('.', 'nvarchar(max)'), 1, 0, ''), '')
	) Room
OUTER APPLY (
	SELECT Guarantors = isnull(STUFF((
					SELECT ', ' + RTRIM(ISNULL(PERSON.SFIRSTNAME, '')) + ' ' + RTRIM(ISNULL(PERSON.ULASTNAME, ''))
					FROM PROPERTY P2
					JOIN TENANT T2 ON P2.HMY = T2.HPROPERTY
					LEFT JOIN ROOM ON T2.HMYPERSON = ROOM.HMYTENANT
					JOIN PERSON ON ROOM.HMYPERSON = PERSON.HMY
					WHERE 0 = 0
						AND isnull(ROOM.sRelationship, '') = 'Guarantor'
						AND T2.HMYPERSON = TENANT.hMyPerson
					FOR XML PATH('')
						,TYPE
					).value('.', 'nvarchar(max)'), 1, 2, ''), '')
	) GS
OUTER APPLY (
	SELECT MIC_Package = SUM(CASE
				WHEN c.sCode IN ('packge')
					THEN COALESCE(NULLIF(m.cLeaseAmt, 0), ri.cRent, 0)
				ELSE 0
				END)
		,MIC_ProratePackage = SUM(CASE
				WHEN c.sCode IN ('packge')
					THEN ISNULL(m.cMoveInAmt, 0)
				ELSE 0
				END)
		,MIC_BaseRent = SUM(CASE
				WHEN c.sCode IN (
						'.rent'
						,'mtm'
						)
					THEN COALESCE(NULLIF(m.cLeaseAmt, 0), ri.cRent, 0)
				ELSE 0
				END)
		,MIC_ProrateBaseRent = SUM(CASE
				WHEN c.sCode IN (
						'.rent'
						,'mtm'
						)
					THEN ISNULL(m.cMoveInAmt, 0)
				ELSE 0
				END)
		,
		/* parking */
		MIC_ParkingAndStorage = SUM(CASE
				WHEN c.sCode IN (
						'garage'
						,'park'
						,'storage'
						)
					THEN COALESCE(NULLIF(m.cLeaseAmt, 0), ri.cRent, 0)
				ELSE 0
				END)
		,MIC_ProrateParkingAndStorage = SUM(CASE
				WHEN c.sCode IN (
						'garage'
						,'park'
						,'storage'
						)
					THEN ISNULL(m.cMoveInAmt, 0)
				ELSE 0
				END)
		,MIC_Parking = SUM(CASE
				WHEN c.sCode IN (
						'garage'
						,'park'
						)
					THEN COALESCE(NULLIF(m.cLeaseAmt, 0), ri.cRent, 0)
				ELSE 0
				END)
		,MIC_Storage = SUM(CASE
				WHEN c.sCode IN ('storage')
					THEN COALESCE(NULLIF(m.cLeaseAmt, 0), ri.cRent, 0)
				ELSE 0
				END)
		,MIC_Fees = SUM(CASE
				WHEN c.sCode IN ('mtpest')
					THEN COALESCE(NULLIF(m.cLeaseAmt, 0), ri.cRent, 0)
				ELSE 0
				END)
		,MIC_ProrateFees = SUM(CASE
				WHEN c.sCode IN ('mtpest')
					THEN ISNULL(m.cMoveInAmt, 0)
				ELSE 0
				END)
		,MIC_PetDep = SUM(CASE
				WHEN c.sCode <> 'petdep'
					THEN CAST(0                          AS DECIMAL(18, 2))
				WHEN m.bRecurring <> - 1
					THEN CAST(ISNULL(m.cMoveInAmt, 0)    AS DECIMAL(18, 2))
				ELSE COALESCE(NULLIF(CAST(m.cLeaseAmt AS DECIMAL(18, 2)), 0), NULLIF(CAST(m.cMoveInAmt AS DECIMAL(18, 2)), 0), CAST(ri.cRent AS DECIMAL(18, 2)), CAST(0 AS DECIMAL(18, 2)))
				END)
		,MIC_SecDep = SUM(CASE
				WHEN c.sCode <> 'secdep'
					THEN CAST(0                          AS DECIMAL(18, 2))
				WHEN m.bRecurring <> - 1
					THEN CAST(ISNULL(m.cMoveInAmt, 0)    AS DECIMAL(18, 2))
				ELSE COALESCE(NULLIF(CAST(m.cLeaseAmt AS DECIMAL(18, 2)), 0), NULLIF(CAST(m.cMoveInAmt AS DECIMAL(18, 2)), 0), CAST(ri.cRent AS DECIMAL(18, 2)), CAST(0 AS DECIMAL(18, 2)))
				END)
		,
		/* building fee */
		MIC_BldgFee = SUM(CASE
				WHEN c.sCode IN ('bldgfee')
					THEN COALESCE(NULLIF(m.cLeaseAmt, 0), ri.cRent, 0)
				ELSE 0
				END)
		,MIC_ProrateBldgFee = SUM(CASE
				WHEN c.sCode IN ('bldgfee')
					THEN ISNULL(m.cMoveInAmt, 0)
				ELSE 0
				END)
		,
		/* storage */
		MIC_StorageRent = SUM(CASE
				WHEN c.sCode IN ('storage')
					THEN COALESCE(NULLIF(m.cLeaseAmt, 0), ri.cRent, 0)
				ELSE 0
				END)
		,MIC_ProrateStorageRent = SUM(CASE
				WHEN c.sCode IN ('storage')
					THEN ISNULL(m.cMoveInAmt, 0)
				ELSE 0
				END)
		,
		/* pet */
		MIC_PetRent = SUM(CASE
				WHEN c.sCode IN ('petrent')
					THEN COALESCE(NULLIF(m.cLeaseAmt, 0), ri.cRent, 0)
				ELSE 0
				END)
		,MIC_ProratePetRent = SUM(CASE
				WHEN c.sCode IN ('petrent')
					THEN ISNULL(m.cMoveInAmt, 0)
				ELSE 0
				END)
		,
		/* other (misc/evcs/Cable) */
		MIC_OtherRent = SUM(CASE
				WHEN c.sCode IN (
						'misc'
						,'evcs'
						,'cable'
						,'mtpest'
						,'mtplus'
						)
					THEN COALESCE(NULLIF(m.cLeaseAmt, 0), ri.cRent, 0)
				ELSE 0
				END)
		,MIC_ProrateOtherRent = SUM(CASE
				WHEN c.sCode IN (
						'misc'
						,'evcs'
						,'cable'
						,'mtpest'
						,'mtplus'
						)
					THEN ISNULL(m.cMoveInAmt, 0)
				ELSE 0
				END)
		,
		/* monthly subtotal (rent-ish + bldgfee + misc/evcs/Cable) */
		MIC_SubtotalMonthlyRent = SUM(CASE
				WHEN c.sCode IN (
						'misc'
						,'evcs'
						,'cable'
						,'.rent'
						,'mtm'
						,'bldgfee'
						)
					THEN COALESCE(NULLIF(m.cLeaseAmt, 0), ri.cRent, 0)
				ELSE 0
				END)
		,MIC_ProrateSubtotalMonthlyRent = SUM(CASE
				WHEN c.sCode IN (
						'misc'
						,'evcs'
						,'cable'
						,'.rent'
						,'mtm'
						,'bldgfee'
						)
					THEN ISNULL(m.cMoveInAmt, 0)
				ELSE 0
				END)
		,
		/* MT Plus */
		MIC_MTPlus = SUM(CASE
				WHEN c.sCode IN (
						'mtplus'
						,'mtpest'
						)
					THEN COALESCE(NULLIF(m.cLeaseAmt, 0), ri.cRent, 0)
				ELSE 0
				END)
		,MIC_ProrateMTPlus = SUM(CASE
				WHEN c.sCode IN (
						'mtplus'
						,'mtpest'
						)
					THEN ISNULL(m.cMoveInAmt, 0)
				ELSE 0
				END)
		,
		/* Free rent */
		MIC_FreeRent = SUM(CASE
				WHEN c.sCode IN ('free')
					THEN COALESCE(NULLIF(m.cLeaseAmt, 0), ri.cRent, 0)
				ELSE 0
				END)
		,MIC_ProrateFreeRent = SUM(CASE
				WHEN c.sCode IN ('free')
					THEN ISNULL(m.cMoveInAmt, 0)
				ELSE 0
				END)
		,
		/* Renters insurance (by id) */
		MIC_RentIns = SUM(CASE
				WHEN c.hMy IN (
						236
						,239
						)
					THEN COALESCE(NULLIF(m.cLeaseAmt, 0), ri.cRent, 0)
				ELSE 0
				END)
		,MIC_ProrateRentIns = SUM(CASE
				WHEN c.hMy IN (
						236
						,239
						)
					THEN ISNULL(m.cMoveInAmt, 0)
				ELSE 0
				END)
		,
		/* total fees (mtpest + bldgfee) */
		MIC_TotalFees = SUM(CASE
				WHEN c.sCode IN (
						'mtpest'
						,'bldgfee'
						)
					THEN COALESCE(NULLIF(m.cLeaseAmt, 0), ri.cRent, 0)
				ELSE 0
				END)
		,MIC_ProrateTotalFees = SUM(CASE
				WHEN c.sCode IN (
						'mtpest'
						,'bldgfee'
						)
					THEN ISNULL(m.cMoveInAmt, 0)
				ELSE 0
				END)
		,MIC_NRPetFee = SUM(CASE
				WHEN c.sCode IN ('nrpetfee')
					THEN COALESCE(NULLIF(m.cLeaseAmt, 0), ri.cRent, 0)
				ELSE 0
				END)
		,MIC_ProrateNRPetFee = SUM(CASE
				WHEN c.sCode IN ('nrpetfee')
					THEN ISNULL(m.cMoveInAmt, 0)
				ELSE 0
				END)
		,
		/* last charge date (for reference) */
		MIC_LastChargeDate = MAX(m.dtChargeDate)
	FROM MoveInCharges m
	JOIN TENANT T ON T.HMYPERSON = M.HTENANT
	JOIN chargtyp c ON c.hMy = m.hChargeCode
	LEFT JOIN RentableItems ri ON ri.hmy = m.hRentableItem
	WHERE ISNULL(m.bSelected, 0) <> 0
		/*AND ISNULL(m.bRecurring,0) = -1*/
		AND m.hTenant = TENANT.hMyPerson
	) AS mic
OUTER APPLY (
	SELECT *
	FROM [#Chg]
	WHERE hmyperson = TENANT.hmyperson
	) chg
OUTER APPLY (
	SELECT t.hProperty PropertyId
		,t.hmyperson     AS TenantId
		,rtrim(p.sCode) PropertyCode
		,CAST(65         AS NUMERIC(18, 0)) AS ChargeCodeId
		,'free' ChargeCode
		,CONVERT(BIT, 1) AS IsFreeRent
		,gli.C_DescO 'FreeRentDesc'
		,gli.C_AmtO      AS TotalFreeRentAmount
		,gli.C_DescT     AS C_DescT
		,gli.c_amtT      AS C_AmtT
		,gli.C_Date_From AS C_Date_From
		,gli.c_Date_To   AS C_Date_To
		,t.dtMoveIn
		,t.dtLeaseFrom
		,t.dtMoveOut
		,t.dtLeaseTo
		,gli.ACD_Mailbox
		,gli.MR_GP_SPACE
	FROM GUESTCARD_LEASE_INFO gli
	JOIN prospect pr ON pr.hmy = gli.hcode
	JOIN tenant t ON t.hmyperson = pr.hTenant
	JOIN property p ON p.hmy = t.hProperty
	WHERE t.hmyperson = TENANT.HMYPERSON
		/*AND gli.C_AmtO <> 0*/
	) conc
OUTER APPLY (
	SELECT u.HUNITTYPE "UnitTypeId"
		,ISNULL(SUM(u.DAMOUNT), 0) "Amount"
	FROM UNITDET u
	WHERE u.hUnitType = UNIT.hUnitType
		AND u.hChgCode > 0
		AND u.bMoveIn = - 1
		AND EXISTS (
			SELECT 1
			FROM chargtyp
			WHERE chargtyp.hMy = u.hChgCode
				AND chargtyp.sCode = 'secdep'
			)
	GROUP BY u.hUnitType
	) secDep
OUTER APPLY (
	SELECT u.HUNITTYPE "UnitTypeId"
		,ISNULL(SUM(u.DAMOUNT), 0) "Amount"
	FROM UNITDET u
	WHERE u.hUnitType = UNIT.hUnitType
		AND u.hChgCode > 0
		AND u.bMoveIn = - 2
		AND EXISTS (
			SELECT 1
			FROM chargtyp
			WHERE chargtyp.hMy = u.hChgCode
				AND chargtyp.sCode = 'admin'
			)
	GROUP BY u.hUnitType
	) adminFee
OUTER APPLY (
	SELECT u.HUNITTYPE "UnitTypeId"
		,ISNULL(SUM(u.DAMOUNT), 0) "Amount"
	FROM UNITDET u
	WHERE u.hUnitType = UNIT.hUnitType
		AND u.hChgCode > 0
		AND u.bMoveIn = - 2
		AND EXISTS (
			SELECT 1
			FROM chargtyp
			WHERE chargtyp.hMy = u.hChgCode
				AND chargtyp.sCode = 'credit'
			)
	GROUP BY u.hUnitType
	) applicFee
OUTER APPLY (
	SELECT p.hmy PropertyId
		,tr.hPerson AS TenantId
		,Amount = SUM(tr.sTotalAmount)
		,PostDate = DATEFROMPARTS(YEAR(tr.uPostDate), MONTH(tr.uPostDate), 1)
	FROM trans tr
	JOIN property p ON p.hmy = tr.hProp
	JOIN tenant t ON t.hMyPerson = tr.hPerson
	JOIN chargtyp ct ON ct.hMy = tr.hRetentionAcct
	WHERE p.iType = 3
		AND tr.iType = 7
		AND tr.sTotalAmount <> 0
		AND t.HMYPERSON = TENANT.HMYPERSON
		AND ct.sCode = 'credit'
	GROUP BY p.hmy
		,tr.hPerson
		,DATEFROMPARTS(YEAR(tr.uPostDate), MONTH(tr.uPostDate), 1)
	) transApplicFee
OUTER APPLY (
	SELECT p.hmy PropertyId
		,tr.hPerson AS TenantId
		,Amount = SUM(tr.sTotalAmount)
		,PostDate = DATEFROMPARTS(YEAR(tr.uPostDate), MONTH(tr.uPostDate), 1)
	FROM trans tr
	JOIN property p ON p.hmy = tr.hProp
	JOIN tenant t ON t.hMyPerson = tr.hPerson
	JOIN chargtyp ct ON ct.hMy = tr.hRetentionAcct
	WHERE p.iType = 3
		AND tr.iType = 7
		AND tr.sTotalAmount <> 0
		AND t.HMYPERSON = TENANT.HMYPERSON
		AND ct.sCode = 'secdep'
	GROUP BY p.hmy
		,tr.hPerson
		,DATEFROMPARTS(YEAR(tr.uPostDate), MONTH(tr.uPostDate), 1)
	) secDepChg
OUTER APPLY (
	SELECT NonOccupants = ISNULL(STUFF((
					SELECT ', ' + LTRIM(RTRIM(CASE
									WHEN src.IsTenant = 1
										THEN src.TenantName
									ELSE src.PersonName
									END))
					FROM (
						SELECT PersonName = LTRIM(RTRIM(pn.SFIRSTNAME + ' ' + pn.ULASTNAME))
							,TenantName = NULL
							,IsTenant = 0
						FROM tenant t
						JOIN room r ON r.hMyTenant = t.hMyPerson
						JOIN person pn ON pn.hmy = r.hMyPerson
						WHERE t.hMyPerson = TENANT.hMyPerson
							AND (
								ISNULL(pn.sfirstname, '') <> ''
								OR ISNULL(pn.ulastname, '') <> ''
								)
							AND r.BOCCUPANT = - 1
						) AS src
					ORDER BY src.IsTenant DESC
						,src.PersonName
					FOR XML PATH('')
						,TYPE
					).value('.', 'nvarchar(max)'), 1, 2, ''), '')
	) non
LEFT JOIN (
	SELECT oth.hmy "Id"
		,oth.hTenant "TenantId"
		,oth.sDriversLicense "DriversLicense"
		,oth.sDLState "DriversLicenseState"
		,oth.sEmergName + CASE
			WHEN ISNULL(oth.sEmergPhone, '') = ''
				THEN ''
			ELSE ' ' + dbo.FormatPhoneNumber(oth.sEmergPhone)
			END "EmergencyName"
		,oth.sEmergRelation "EmergencyRelation"
		,oth.sEmergTelHome "EmergencyPhoneHome"
		,oth.sEmergPhone "EmergencyPhoneOther"
		,oth.sAutoType1 "AutoType1"
		,oth.sAutoType2 "AutoType2"
		,oth.sAutoModel1 "AutoModel1"
		,oth.sAutoModel2 "AutoModel2"
		,oth.dAutoYear1 "AutoYear1"
		,oth.dAutoYear2 "AutoYear2"
		,oth.sAutoColor1 "AutoColor1"
		,oth.sAutoColor2 "AutoColor2"
		,oth.sAutoLicense1 "AutoLicense1"
		,oth.sAutoLicense2 "AutoLicense2"
		,oth.sAutoState1 "AutoState1"
		,oth.sAutoState2 "AutoState2"
		,oth.sAutoType3 "AutoType3"
		,oth.sAutoType4 "AutoType4"
		,oth.sAutoModel3 "AutoModel3"
		,oth.sAutoModel4 "AutoModel4"
		,oth.dAutoYear3 "AutoYear3"
		,oth.dAutoYear4 "AutoYear4"
		,oth.sAutoColor3 "AutoColor3"
		,oth.sAutoColor4 "AutoColor4"
		,oth.sAutoLicense3 "AutoLicense3"
		,oth.sAutoLicense4 "AutoLicense4"
		,oth.sAutoState3 "AutoState3"
		,oth.sAutoState4 "AutoState4"
		,oth.sEmergAddr1 "EmergencyAddress1"
		,oth.sEmergAddr2 "EmergencyAddress2"
		,oth.sEmergCity "EmergencyCity"
		,oth.sEmergState "EmergencyState"
		,oth.sEmergZip "EmergencyZip"
		,oth.iStmtType "StatementType"
	FROM Tenant_OtherInfo oth
	JOIN TENANT ON TENANT.hmyperson = oth.hTenant
	JOIN property p ON p.HMY = TENANT.hProperty
	WHERE 1 = 1 #Conditions#
	) otherInfo ON otherInfo.TenantId = TENANT.HMYPERSON
OUTER APPLY (
	SELECT TenantId
		,SUM(CASE
				WHEN Section = 'Dep'
					THEN Amt
				ELSE 0
				END) SecDep
	FROM [AllCharges#@@SESSIONID#] sd
	WHERE sd.TenantId = TENANT.HMYPERSON
	GROUP BY TenantId
	) NewChgs
LEFT JOIN (
	SELECT TENANT.HMYPERSON
		,MAX(lh.dtLeaseFrom) dtLeaseFrom
		,MAX(lh.dtLeaseTo) dtLeaseTo
		,MAX(RTRIM(p.sCode)) PropCode
		,MAX(RTRIM(tenant.sCode)) TenCode
		,renewBaseRent = SUM(CASE
				WHEN ct.sCode IN (
						'rent'
						,'.rent'
						)
					THEN cr.dEstimated
				ELSE 0
				END)
		,renewParkingRent = SUM(CASE
				WHEN ct.sCode IN (
						'parking'
						,'garage'
						,'park'
						)
					THEN cr.dEstimated
				ELSE 0
				END)
		,renewStorageRent = SUM(CASE
				WHEN ct.sCode IN ('storage')
					THEN cr.dEstimated
				ELSE 0
				END)
		,renewPetRent = SUM(CASE
				WHEN ct.sCode IN ('petrent')
					THEN cr.dEstimated
				ELSE 0
				END)
		,renewOtherRent = SUM(CASE
				WHEN ct.sCode IN (
						'misc'
						,'evcs'
						,'Cable'
						)
					THEN cr.dEstimated
				ELSE 0
				END)
		,renewMtPest = SUM(CASE
				WHEN ct.sCode IN ('mtpest')
					THEN cr.dEstimated
				ELSE 0
				END)
		,renewMTPlus = SUM(CASE
				WHEN ct.sCode IN ('mtplus')
					THEN cr.dEstimated
				ELSE 0
				END)
		/*,renewRentersInsurance = SUM(COALESCE(NULLIF(CASE
						WHEN ct.sCode IN ('renins')
							THEN cr.dEstimated
						ELSE 0
						END, 0), ri.Amount, 0))*/
		,renewRentersInsurance = SUM(CASE
				WHEN ct.sCode IN ('renins')
					THEN cr.dEstimated
				ELSE 0
				END)
		,renewPackage = SUM(CASE
				WHEN ct.sCode IN ('package')
					THEN cr.dEstimated
				ELSE 0
				END)
	FROM lease_history AS lh
	JOIN TENANT ON TENANT.HMYPERSON = lh.hTent
	JOIN PROPERTY P ON P.HMY = TENANT.HPROPERTY
	JOIN CamRule_Proposals AS cr ON cr.hTenant = TENANT.hMyPerson
		AND cr.hlease_history = lh.hMy
		AND ISNULL(cr.bDoNotRenew, 0) <> 1
	JOIN chargtyp AS ct ON ct.hMy = cr.hChargeCode
	WHERE ISNULL(lh.iInactiveProposal, 0) < 1
		AND lh.iPortalSelection = 1 #Conditions#
	GROUP BY TENANT.HMYPERSON
	) AS renewCharges ON renewCharges.HMYPERSON = TENANT.HMYPERSON
LEFT JOIN (
	SELECT ipol.hMyPerson
		,ISNULL(ipol.sPolicyNumber, '') sPolicyNumber
		,ISNULL(ipol.sPolicyTitle, '') sPolicyTitle
		,ISNULL(ipol.dLiabilityAmount, 0.00) dLiabilityAmount
		,ISNULL(ipol.dtExpire, '') dtExpire
		,ISNULL(ipol.sInsurer, '') sInsurer
		,ISNULL(ipol.dtCancel, '') dtCancel
		,ISNULL(ipol.dtEffective, '') dtEffective
		,ISNULL(ic.sCode, '') ICCode
		,ipol.dAmount + ipol.dAdminFeeAmount + ipol.dTaxAmount AS Amount
	FROM itf_ri_policy ipol
	JOIN TENANT ON TENANT.HMYPERSON = ipol.hMyPerson
	JOIN property p ON p.hmy = TENANT.hProperty
	LEFT JOIN InterfaceConfiguration ic ON ic.hmy = ipol.hInterfaceConfig
	WHERE ISNULL(ipol.bDelete, 0) = 0
		/*AND EXISTS (
				SELECT 1
				FROM itf_ri_policy
				WHERE itf_ri_policy.hMyPerson = ipol.hMyPerson
				GROUP BY itf_ri_policy.hMyPerson
				HAVING MAX(itf_ri_policy.hMy) = ipol.hMy
			)*/
		AND ipol.hmy = (
			SELECT MAX(hmy)
			FROM itf_ri_policy
			WHERE hMyPerson = ipol.hMyPerson
			) #Conditions#
	) ri ON ri.hMyPerson = TENANT.HMYPERSON
LEFT JOIN (
	SELECT COUNT(*) AS PetCount
		,pet.hmyperson
	FROM Person_Pet pet
	JOIN tenant ON tenant.hmyperson = pet.hmyperson
	JOIN property p ON p.hmy = tenant.hproperty
	WHERE ISNULL(pet.sPetIsServiceAnimal, 'No') = 'No' #Conditions#
	GROUP BY pet.hmyPerson
	) pet ON pet.hmyperson = TENANT.HMYPERSON
WHERE 1 = 1 #CONDITIONS#
ORDER BY Tenant.HMYPERSON;

IF OBJECT_ID('tempdb..#Chg') IS NOT NULL
	DROP TABLE [#Chg];

//END SELECT


//SELECT NO CRYSTAL AFTER
IF OBJECT_ID('AllCharges#@@SESSIONID#') IS NOT NULL
	DROP TABLE [AllCharges#@@SESSIONID#];

IF OBJECT_ID('Ledger#@@SESSIONID#') IS NOT NULL
	DROP TABLE [Ledger#@@SESSIONID#];

IF OBJECT_ID('GuestCardReceipt#@@SESSIONID#') IS NOT NULL
	DROP TABLE [GuestCardReceipt#@@SESSIONID#];

IF OBJECT_ID('MicBase#@@SESSIONID#') IS NOT NULL
	DROP TABLE [MicBase#@@SESSIONID#];

//END SELECT


//Format
addendaList Multiline
parkingRent $###,##0.00
storageRent $###,##0.00
petRent $###,##0.00
otherRent $###,##0.00
OLE_INFO_E_T_FEE $###,##0.00
OLE_INFO_E_T_NOTICE_DAYS #0
OLE_INFO_E_T_FROM MM/DD/YYYY
OLE_INFO_E_T_TO MM/DD/YYYY
OLE_INFO_LATE_FEE $###,##0.00
OLE_INFO_MIN_LIABIITY $###,##0.00
OLE_INFO_MAX_DEDUCTIBLE $###,##0.00
C_Date_From MM/DD/YYYY
C_Date_To MM/DD/YYYY
prleasefrom MM/DD/YYYY
prleaseto MM/DD/YYYY
OLE_M_Other_Amt_One $###,##0.00
OLE_M_Other_Amt_Two $###,##0.00
OLE_M_Other_Amt_Three $###,##0.00
TODAY MM/DD/YYYY
OLE_U_Formula_SqFt #0.00%
OLE_U_Formula_DE #0.00%
C_AmtO $###,##0.00
C_AmtT $###,##0.00
grace #0
//End Format


//FILTER
//Type, DT, Name, Caption, Key, List,Val1,V2, Mandatory, Multi-Type, Title
C,T,hProperty,Property, , 61, p.hmy = #hProperty#, , Y, N, N,
C,      T,         hunit,       Unit,    ,      4,     TENANT.hUnit = #hunit#,     ,         	,       Y,       ,
C,T,  hTenant,  Tenant, ,  1, TENANT.hmyperson = #hTenant#, , N, N, N,
//END FILTER