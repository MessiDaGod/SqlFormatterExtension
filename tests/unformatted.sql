/* exclude resident */
SELECT pr.hMy                       AS PayeeId
	,MAX(isnull(b.bInactive, 0)) AS IsInactiveBank
	,CASE
		WHEN max(isnull(co.iInsuranceLevel, 0)) = 1
			THEN CASE
					WHEN min(isnull(co.iInsuranceLevel, 0)) = 1
						THEN 0
					ELSE CASE
							WHEN isnull(v.DDATEWCINSUR, convert(DATETIME, '09/30/2025', 101)) >= convert(DATETIME, '09/30/2025', 101)
								THEN 0
							ELSE - 1
							END
					END
		ELSE CASE
				WHEN isnull(v.DDATEWCINSUR, convert(DATETIME, '09/30/2025', 101)) >= convert(DATETIME, '09/30/2025', 101)
					THEN 0
				ELSE - 1
				END
		END                         AS VendorWCInsur
	,CASE
		WHEN max(isnull(co.iInsuranceLevel, 0)) = 1
			THEN CASE
					WHEN min(isnull(co.iInsuranceLevel, 0)) = 1
						THEN NULL
					ELSE CASE
							WHEN isnull(v.DDATEWCINSUR, convert(DATETIME, '09/30/2025', 101)) >= convert(DATETIME, '09/30/2025', 101)
								THEN NULL
							ELSE v.DDATEWCINSUR
							END
					END
		ELSE CASE
				WHEN isnull(v.DDATEWCINSUR, convert(DATETIME, '09/30/2025', 101)) >= convert(DATETIME, '09/30/2025', 101)
					THEN NULL
				ELSE v.DDATEWCINSUR
				END
		END                         AS VendorWCInsurDate
	,CASE
		WHEN max(isnull(co.iInsuranceLevel, 0)) = 1
			THEN CASE
					WHEN min(isnull(co.iInsuranceLevel, 0)) = 1
						THEN 0
					ELSE CASE
							WHEN isnull(v.DDATELIABINSUR, convert(DATETIME, '09/30/2025', 101)) >= convert(DATETIME, '09/30/2025', 101)
								THEN 0
							ELSE - 1
							END
					END
		ELSE CASE
				WHEN isnull(v.DDATELIABINSUR, convert(DATETIME, '09/30/2025', 101)) >= convert(DATETIME, '09/30/2025', 101)
					THEN 0
				ELSE - 1
				END
		END                         AS VendorLiabInsur
	,CASE
		WHEN max(isnull(co.iInsuranceLevel, 0)) = 1
			THEN CASE
					WHEN min(isnull(co.iInsuranceLevel, 0)) = 1
						THEN NULL
					ELSE CASE
							WHEN isnull(v.DDATELIABINSUR, convert(DATETIME, '09/30/2025', 101)) >= convert(DATETIME, '09/30/2025', 101)
								THEN NULL
							ELSE v.DDATELIABINSUR
							END
					END
		ELSE CASE
				WHEN isnull(v.DDATELIABINSUR, convert(DATETIME, '09/30/2025', 101)) >= convert(DATETIME, '09/30/2025', 101)
					THEN NULL
				ELSE v.DDATELIABINSUR
				END
		END                         AS VendorLiabInsurDate
FROM CommitPayments cp
JOIN detail d ON cp.hdetail = d.hmy
	AND d.bRet = 0
	AND ISNULL(d.hchkorchg, 0) = 0
JOIN trans t ON t.hMy = cp.hTran
JOIN person pr ON pr.hMy = cp.hPerson
JOIN vendor v ON v.hMyperson = pr.hMy
LEFT JOIN RemittanceVendor rv ON rv.hMyperson = t.hRemittanceVendor
JOIN bank b ON b.hMy = d.hBank
JOIN acct a ON a.hMy = d.hOffset
JOIN property p ON p.hMy = cp.hProp
LEFT JOIN trans_int ti ON ti.hTran = t.hMy
LEFT JOIN caparam cap ON cap.hchart = a.hchart
LEFT JOIN property f ON f.hMy = t.hFunding
LEFT JOIN [contract] co ON co.hmy = d.hContract
	AND ISNULL(co.hContract, 0) = 0
LEFT JOIN Job j ON j.hmy = d.hJob
LEFT JOIN glinvregtrans InvReg ON InvReg.hPayable = t.hMy
LEFT JOIN cmdetail cmret ON cmret.hRetDetail = d.hmy
LEFT JOIN cmdetail cmnoret ON cmnoret.hdetail = d.hmy
LEFT JOIN vendor v2ret ON v2ret.HMYPERSON = cmret.h2ndVendor
LEFT JOIN vendor v2noret ON v2noret.HMYPERSON = cmnoret.h2ndVendor
LEFT JOIN PayablePaymentMethod apm ON apm.ivalue = t.CashReceipt
LEFT JOIN country_info ci ON ci.hmy = pr.hCountry
WHERE 1 = 1
	AND cp.bpaid = 0
	AND t.Voider = 0
	AND t.Voided = 0
	AND isnull(t.uRef, '') NOT LIKE ':CIS%'
	AND cp.hTran IN (
		SELECT CASE isNull(wf.iStatus, 1)
				WHEN 1
					THEN x.hMy
				ELSE - 1
				END
		FROM trans x
		LEFT JOIN wf_tran_header wf ON (
				wf.hRecord = x.hMy
				AND wf.iType = 30
				)
		WHERE 1 = 1
			AND x.iType = 3
			AND x.hMy = cp.hTran
		)
	AND isnull(p.bInactive, 0) = 0
	AND (
		v.DDATEWCINSUR IS NOT NULL
		AND v.DDATEWCINSUR < CAST(GETDATE() AS DATE)
		OR v.DDATELIABINSUR IS NOT NULL
		AND v.DDATELIABINSUR < CAST(GETDATE() AS DATE)
		)
GROUP BY pr.hMy
	,cp.hTran
	,pr.uLastName
	,cp.sInvoiceNumber
	,t.sOtherDate1
	,a.hMy
	,a.hChart
	,a.sCode
	,b.sCode
	,b.hMy
	,t.bAch
	,t.CashReceipt
	,t.holdPayment
	,pr.ucode
	,isNull(ti.sGAcctAmount, 0)
	,ISNULL(t.ConsolidateCheck, 0)
	,t.sDiscountAmt
	,t.iSubType
	,t.adjustment
	,t.uPostDate
	,t.isubtype
	,v.dDateWcInsur
	,v.dDateLiabInsur
	,isnull(cmret.s2ndVendor, isnull(cmnoret.s2ndvendor, ''))
	,isnull(cmret.h2ndVendor, isnull(cmnoret.h2ndVendor, 0))
HAVING MAX(isnull(b.bInactive, 0)) = 0;

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