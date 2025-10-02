IF OBJECT_ID('AllCharges10032790') IS NOT NULL
DROP TABLE [AllCharges10032790];


IF OBJECT_ID('Ledger10032790') IS NOT NULL
DROP TABLE [Ledger10032790];


IF OBJECT_ID('GuestCardReceipt10032790') IS NOT NULL
DROP TABLE [GuestCardReceipt10032790];


IF OBJECT_ID('MicBase10032790') IS NOT NULL
DROP TABLE [MicBase10032790];


IF OBJECT_ID('tempdb..#Chg') IS NOT NULL
DROP TABLE [#Chg];


/* ========================= Current charges → #Chg ========================= */
SELECT
    rn
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
,SUM(applicFee2)         AS applicFee2
,SUM(ProrateOtherRent)   AS ProrateOtherRent
,SUM(ValetTrash)         AS ValetTrash
,SUM(rentersInsurance)   AS rentersInsurance
,INTO [#Chg]

FROM
    (
        SELECT
            ROW_NUMBER() OVER (
,PARTITION BY
,TENANT.hmyperson
,ct.hMy
,ORDER BY
,cr.dtFrom DESC
,ISNULL(cr.dtto, GETDATE()) DESC
,cr.hMy DESC
,) rn
,TENANT.hmyperson
,cr.dtFrom
,TENANT.dtLeaseFrom
,SUM( ,CASE ,WHEN ct.scode IN ('credit') THEN cr.dEstimated ,ELSE 0 ,END ,)                                                                                                                                                                                                                                                                                     AS applicFee2
,SUM( ,CASE ,WHEN ct.scode IN ('.rent', 'mtm') THEN cr.dEstimated ,ELSE 0 ,END ,)                                                                                                                                                                                                                                                                               AS baseRent
,SUM( ,CASE ,WHEN ct.sCode IN ('.rent', 'mtm') THEN ( ,DAY(EOMONTH(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom))) - DAY(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom)) ,) * COALESCE(cr.dEstimated, TENANT.sRent) / CAST( ,DAY(EOMONTH(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom)))                                                                                           AS DECIMAL(18, 6) ,) ,ELSE ( ,DAY(EOMONTH(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom))) - DAY(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom)) ,) * COALESCE(cr.dEstimated, TENANT.sRent) / CAST( ,DAY(EOMONTH(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom))) AS DECIMAL(18, 6) ,) ,END ,) AS prorateBaseRent
,SUM( ,CASE ,WHEN ct.scode IN ('garage', 'park', 'storage') THEN cr.dEstimated ,ELSE 0 ,END ,)                                                                                                                                                                                                                                                                  AS parkingRent
,SUM( ,CASE ,WHEN ct.sCode IN ('garage', 'park') ,AND cr.dtFrom > DATEADD(MONTH, - 1, DATEADD(DAY, 1, EOMONTH(GETDATE()))) THEN ( ,DAY(EOMONTH(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom))) - DAY(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom)) ,) * ISNULL(cr.dEstimated, 0) / CAST( ,DAY(EOMONTH(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom)))                            AS DECIMAL(18, 6) ,) ,WHEN ct.sCode IN ('garage', 'park', 'storage') THEN cr.dEstimated ,ELSE 0 ,END ,) AS ProrateParkingRent
,SUM( ,CASE ,WHEN ct.sCode IN ('mtpest') THEN cr.dEstimated ,ELSE 0 ,END ,)                                                                                                                                                                                                                                                                                     AS fees
,SUM( ,CASE ,WHEN ct.sCode IN ('bldgfee') THEN cr.dEstimated ,ELSE 0 ,END ,)                                                                                                                                                                                                                                                                                    AS [bldgfee]
,SUM( ,CASE ,WHEN ct.sCode IN ('bldgfee') THEN ( ,DAY(EOMONTH(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom))) - DAY(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom)) ,) * ISNULL(cr.dEstimated, 0) / CAST( ,DAY(EOMONTH(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom)))                                                                                                             AS DECIMAL(18, 6) ,) ,ELSE 0 ,END ,) AS ProrateBldgfee
,SUM( ,CASE ,WHEN ct.sCode IN ('vtrash') THEN cr.dEstimated ,ELSE 0 ,END ,)                                                                                                                                                                                                                                                                                     AS ValetTrash
,SUM( ,CASE ,WHEN ct.sCode IN ('vtrash') THEN ( ,DAY(EOMONTH(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom))) - DAY(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom)) ,) * ISNULL(cr.dEstimated, 0) / CAST( ,DAY(EOMONTH(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom)))                                                                                                              AS DECIMAL(18, 6) ,) ,ELSE 0 ,END ,) AS ProrateValetTrash
,SUM( ,CASE ,WHEN ct.sCode IN ('storage') THEN cr.dEstimated ,ELSE 0 ,END ,)                                                                                                                                                                                                                                                                                    AS storageRent
,SUM( ,CASE ,WHEN ct.sCode IN ('petrent') THEN cr.dEstimated ,ELSE 0 ,END ,)                                                                                                                                                                                                                                                                                    AS petRent
,SUM( ,CASE ,WHEN ct.sCode IN ('renins') THEN cr.dEstimated ,ELSE 0 ,END ,)                                                                                                                                                                                                                                                                                     AS rentersInsurance
,SUM( ,CASE ,WHEN ct.sCode IN ('misc', 'evcs', 'Cable', 'mtpest', 'mtplus') THEN cr.dEstimated ,ELSE 0 ,END ,)                                                                                                                                                                                                                                                  AS otherRent
,SUM( ,CASE ,WHEN ct.sCode IN ('misc', 'evcs', 'Cable', 'mtpest', 'mtplus') ,AND cr.dtFrom > DATEADD(MONTH, - 1, DATEADD(DAY, 1, EOMONTH(GETDATE()))) THEN ( ,DAY(EOMONTH(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom))) - DAY(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom)) ,) * ISNULL(cr.dEstimated, 0) / CAST( ,DAY(EOMONTH(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom))) AS DECIMAL(18, 6) ,) ,WHEN ct.sCode IN ('misc', 'evcs', 'Cable', 'mtpest', 'mtplus') THEN cr.dEstimated ,ELSE 0 ,END ,) AS ProrateOtherRent
,SUM( ,CASE ,WHEN ct.sCode IN ('mtplus') THEN cr.dEstimated ,ELSE 0 ,END ,)                                                                                                                                                                                                                                                                                     AS MTPackage
,SUM( ,CASE ,WHEN ct.sCode IN ('free') THEN cr.dEstimated ,ELSE 0 ,END ,)                                                                                                                                                                                                                                                                                       AS FreeRent
,SUM( ,CASE ,WHEN ct.hMy IN (236, 239) THEN cr.dEstimated ,ELSE 0 ,END ,)                                                                                                                                                                                                                                                                                       AS RentIns
,SUM( ,CASE ,WHEN ct.hMy IN (236, 239) THEN ( ,DAY(EOMONTH(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom))) - (DAY(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom)) - 1) ,) * ISNULL(cr.dEstimated, 0) / CAST( ,DAY(EOMONTH(COALESCE(cr.dtFrom, TENANT.dtLeaseFrom)))                                                                                                          AS DECIMAL(18, 6) ,) ,ELSE 0 ,END ,) AS ProrateRentIns

FROM TENANT
JOIN PROPERTY P ON P.HMY = TENANT.HPROPERTY
LEFT JOIN camrule cr ON cr.htenant = TENANT.hmyperson
LEFT JOIN chargtyp ct ON ct.hmy = cr.hchargecode
        WHERE (
                cr.dtTo IS NULL
                OR cr.dtTo >= GETDATE()
            )
            AND p.hmy IN (1882)
            AND TENANT.hmyperson IN (277666)
            AND TENANT.ISTATUS IN (0, 2, 3, 4, 6)
        GROUP BY
            TENANT.hmyperson,
            cr.dtFrom,
            TENANT.dtLeaseFrom,
            ct.hMy,
            ISNULL(cr.dtto, GETDATE()),
            cr.hMy
    ) x
WHERE x.rn = 1
GROUP BY
    rn,
    hmyperson;


CREATE CLUSTERED INDEX IX_Chg_h ON [#Chg] (hmyperson);


;


WITH
    Ledger AS (
        SELECT
            tr.hMy
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
,PARTITION BY
,tenant.hMyPerson
,p.hMy
,ORDER BY
,tr.sDateOccurred
,tr.hMy ROWS UNBOUNDED PRECEDING
,)            AS running_balance

FROM property p
JOIN tenant ON p.hmy = TENANT.hproperty
JOIN trans tr ON TENANT.hMyPerson = tr.hPerson
JOIN acct a ON tr.hOffsetAcct = a.hMy
LEFT JOIN ChargTyp ct ON tr.hRetentionAcct = ct.hMy
LEFT JOIN detail d ON d.hInvOrRec = tr.hMy
    AND tr.iType IN (6, 15)
        WHERE tr.iType IN (6, 7, 15)
            AND TENANT.ISTATUS IN (0, 2, 3, 4, 6)
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
            AND TENANT.hProperty > 0
            AND p.hmy IN (1882)
            AND TENANT.hmyperson IN (277666)
    ),
    L1 AS (
        SELECT
            L.hMy
,L.iType
,L.hmyperson TenantId
,L.sDateOccurred
,L.ChargeCodeId
,L.chargecode
,l.sName
,L.DTLEASEFROM
,Charges = SUM( ,CASE ,WHEN L.iType = 7 THEN L.sTotalAmount ,ELSE 0 ,END ,)
,Payments = SUM( ,CASE ,WHEN L.iType IN (6, 15) THEN ISNULL(L.DetailAmount, 0) ,ELSE 0 ,END ,)
,Description = (
,CASE
,WHEN L.iType IN (6, 15)
,AND COALESCE(L.sUserDefined1, '') <> '' THEN 'chk# ' + L.sUserDefined1 + ' '
,ELSE ''
,END
,) + ISNULL(L.sNotes, '') + (
,CASE
,WHEN L.iType = 15
,AND L.hMy BETWEEN 600000000 AND 699999999
,AND (
,L.bACH = - 1
,OR L.bCC = - 1
,) THEN ' [Payment Pending]'
,ELSE ''
,END
,) + (
,CASE
,WHEN L.iType = 7
,AND COALESCE(L.sUserDefined2, '') LIKE ':UB%' THEN ' ' + REPLACE(
,REPLACE(COALESCE(L.sUserDefined2, ''), ':UB Move Out', '')
,':UB'
,''
,) + ' '
,ELSE ''
,END
,)

FROM Ledger L
        GROUP BY
            L.hMy,
            L.hmyperson,
            L.iType,
            L.sDateOccurred,
            L.chargecode,
            L.ChargeCodeId,
            L.DTLEASEFROM,
            l.sName,
            (
                CASE WHEN L.iType IN (6, 15)
                    AND COALESCE(L.sUserDefined1, '') <> '' THEN 'chk# ' + L.sUserDefined1 + ' '
                    ELSE ''
                END
            ) + ISNULL(L.sNotes, '') + (
                CASE WHEN L.iType = 15
                    AND L.hMy BETWEEN 600000000 AND 699999999
                    AND (
                        L.bACH = - 1
                        OR L.bCC = - 1
                    ) THEN ' [Payment Pending]'
                    ELSE ''
                END
            ) + (
                CASE WHEN L.iType = 7
                    AND COALESCE(L.sUserDefined2, '') LIKE ':UB%' THEN ' ' + REPLACE(
                        REPLACE(COALESCE(L.sUserDefined2, ''), ':UB Move Out', ''),
                        ':UB',
                        ''
                    ) + ' '
                    ELSE ''
                END
            ),
            ISNULL(L.sNotes, ''),
            (
                CASE WHEN L.iType = 15
                    AND L.hMy BETWEEN 600000000 AND 699999999
                    AND (
                        L.bACH = - 1
                        OR L.bCC = - 1
                    ) THEN ' [Payment Pending]'
                    ELSE ''
                END
            ),
            (
                CASE WHEN L.iType = 7
                    AND COALESCE(L.sUserDefined2, '') LIKE ':UB%' THEN ' ' + REPLACE(
                        REPLACE(COALESCE(L.sUserDefined2, ''), ':UB Move Out', ''),
                        ':UB',
                        ''
                    ) + ' '
                    ELSE ''
                END
            )
    )
SELECT
    RunningBalance = SUM(Charges - Payments) OVER (
,PARTITION BY
,TenantId
,ORDER BY
,sDateOccurred
,iType DESC
,hMy ROWS UNBOUNDED PRECEDING
,)
,RowNum = ROW_NUMBER() OVER (
,PARTITION BY
,TenantId
,ORDER BY
,sDateOccurred DESC
,iType ASC
,hMy DESC
,)
,*
,INTO [Ledger10032790]

FROM
    (
        SELECT
            TENANT.HMYPERSON TenantId
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
            AND TENANT.ISTATUS IN (0, 2, 3, 4, 6)
            AND p.hmy IN (1882)
            AND TENANT.hmyperson IN (277666)
        UNION ALL
        SELECT
            TENANT.HMYPERSON TenantId
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
            AND TENANT.ISTATUS IN (0, 2, 3, 4, 6)
            AND p.hmy IN (1882)
            AND TENANT.hmyperson IN (277666)
        UNION ALL
        SELECT
            TenantId
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

FROM
            L1
    ) x
ORDER BY
    TenantId,
    sDateOccurred,
    iType DESC,
    hMy;


/* === Charges that should be prorated vs not === */;


WITH
    Map (ColumnName, SCODE, isProrate) AS (
        SELECT
            *

FROM
            (
                VALUES
                    ('BaseRent', '.rent', 1),
                    ('SecurityDeposit', 'secdep', 0),
                    ('AdditionalSecurityDeposit', 'secdepad', 0),
                    ('RemoteDeposit', 'satdep', 0),
                    ('PetDeposit', 'petdep', 0),
                    ('NRPetFee', 'nrpetfee', 0),
                    ('PetRent', 'petrent', 1),
                    ('AdminFee', 'admin', 0),
                    ('Concession', 'free', 1),
                    ('WaiveAppFee', 'credit', 0),
                    ('CableRent', 'cable', 1),
                    ('ParkingRent', 'park', 1),
                    ('StorageRent', 'storage', 1),
                    ('TrashRent', 'trash', 1)
            ) v (ColumnName, SCODE, isProrate)
    ),
    /* === Source rows: one per receipt/tenant === */
    G AS (
        SELECT
            RTRIM(p.scode) AS PropCode
,RTRIM(pr.sCode)           AS ProspectCode
,pr.hProperty              AS PropertyId
,TENANT.hMyPerson          AS TenantId
,TENANT.DTLEASEFROM        AS LeaseFromDate
,pr.hMy                    AS ProspectId
,gr.HMY                    AS ReceiptId
,gr.*

FROM GuestCard_Receipt gr
JOIN prospect pr ON pr.hmy = gr.hCode
JOIN PROPERTY p ON p.HMY = pr.hProperty
JOIN TENANT ON TENANT.HPROSPECT = pr.HMY
        WHERE 0 = 0
            AND TENANT.ISTATUS IN (0, 2, 3, 4, 5, 6)
            AND p.hmy IN (1882)
            AND TENANT.hmyperson IN (277666)
    ),
    /* === Unpivot only the fields we care about === */
    Unpvt AS (
        SELECT
            g.PropertyId
,g.ProspectId
,g.TenantId
,g.ReceiptId
,g.LeaseFromDate
,u.ColumnName
,u.Amount

FROM G g
        CROSS APPLY (
                VALUES
                    ('BaseRent', g.BaseRent),
                    ('SecurityDeposit', g.SecurityDeposit),
                    (
                        'AdditionalSecurityDeposit',
                        g.AdditionalSecurityDeposit
                    ),
                    ('RemoteDeposit', g.RemoteDeposit),
                    ('PetDeposit', g.PetDeposit),
                    ('NRPetFee', g.NRPetFee),
                    ('PetRent', g.PetRent),
                    ('AdminFee', g.AdminFee),
                    ('Concession', g.Concession),
                    ('WaiveAppFee', g.WaiveAppFee),
                    ('CableRent', g.CableRent),
                    ('ParkingRent', g.ParkingRent),
                    ('StorageRent', g.StorageRent),
                    ('TrashRent', g.TrashRent)
            ) u (ColumnName, Amount)
    ),
    /* === Attach charge code + keep MONEY-only rows === */
    Rows AS (
        SELECT
            u.PropertyId
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
    ) /* === Final split: amount vs prorated amount === */
SELECT
    r.PropertyId
,r.ProspectId
,r.TenantId
,r.ReceiptId
,r.isProrate
,r.ColumnName   AS receiptField
,r.Amount       AS amount
,CASE
,WHEN r.isProrate = 1 THEN dbo.fn_CalcProrationForTenant (N'Move In', r.LeaseFromDate, r.TenantId, r.Amount)
,ELSE 0
,END            AS ProrateAmt
,c.HMY          AS chargeTypeHmy
,RTRIM(c.SCODE) AS chargeCode
,c.SNAME        AS chargeName
,INTO [GuestCardReceipt10032790]

FROM Rows r
JOIN CHARGTYP c ON RTRIM(c.SCODE) = r.SCODE
ORDER BY
    r.ColumnName;


;


WITH
    MicBase AS (
        SELECT
            TenantId = CONVERT(VARCHAR(50), TENANT.hMyPerson)
,ct.sCode
,ct.sName
,LeaseAmt = CASE
,WHEN m.bRecurring <> - 1 THEN m.cMoveInAmt
,ELSE CAST(
,COALESCE( ,NULLIF(m.cLeaseAmt, 0) ,NULLIF(m.cMoveInAmt, 0) ,ri.cRent ,0.0 ,) AS DECIMAL(18, 2)
,)
,END
,ProrateAmt = CASE
,WHEN m.bRentableItem = - 1
,AND m.bProrate = - 1 THEN dbo.fn_CalcProrationForTenant (
,N'Move In'
,TENANT.DTLEASEFROM
,TENANT.HMYPERSON
,ri.cRent
,)
,ELSE CAST(ISNULL(m.cMoveInAmt, 0.0)                                          AS DECIMAL(18, 2))
,END
,m.bRecurring
,m.bProrate
,'MoveInCharges' Source

FROM MoveInCharges m
JOIN TENANT ON TENANT.hMyPerson = m.hTenant
JOIN PROPERTY p ON p.hmy = TENANT.hproperty
JOIN chargtyp ct ON ct.hMy = m.hChargeCode
LEFT JOIN RentableItems ri ON ri.hMy = m.hRentableItem
        WHERE ISNULL(m.bSelected, 0) <> 0
            AND p.hmy IN (1882)
            AND TENANT.hmyperson IN (277666)
            AND TENANT.ISTATUS IN (0, 2, 3, 4, 6)
            AND NOT EXISTS (
                SELECT
                    1

FROM [Ledger10032790]
                WHERE TenantId = TENANT.hmyperson
                    AND ChargeCodeId = CT.HMY
            )
        UNION
        SELECT
            hmyperson TenantId
,ChargeCode
,sName
,SUM(Amount) LeaseAmt
,SUM(ProrateAmt) ProrateAmt
,- 1 bRecurring
,- 1 bProrate
,'RentableItemsType' Source

FROM
            (
                SELECT
                    TENANT.hmyperson
,pr.hProspect
,ct.hmy ChargeCodeId
,RTRIM(ct.sCode) ChargeCode
,RTRIM(ct.sName) sName
,CONVERT(NUMERIC(18, 0), ISNULL(SUM(pr.dQuan), 0)) AS Quantity
,CAST(
,ISNULL(SUM(pr.dQuan), 0) * SUM(rt.cRent)          AS DECIMAL(18, 2)
,)                                                 AS Amount
,dbo.fn_CalcProrationForTenant (
,N'Move In'
,MAX(TENANT.DTLEASEFROM)
,TENANT.hmyperson
,CAST(
,ISNULL(SUM(pr.dQuan), 0) * SUM(rt.cRent)          AS DECIMAL(18, 2)
,)
,) ProrateAmt
,TENANT.DTLEASEFROM

FROM RentableItemsType rt
JOIN PROPERTY p ON p.HMY = RT.HPROP
JOIN CHARGTYP ct ON ct.hmy = rt.HCHARGECODE
LEFT JOIN prospect_charge pr ON rt.hMy = pr.hRentSchedule
LEFT JOIN TENANT ON TENANT.HPROSPECT = pr.hProspect
                WHERE 0 = 0
                    AND p.hmy IN (1882)
                    AND TENANT.hmyperson IN (277666) /*AND NOT EXISTS (SELECT 1
FROM [Ledger10032790] WHERE TenantId = TENANT.hmyperson AND ChargeCodeId = CT.HMY)*/
                GROUP BY
                    rt.sDesc,
                    ct.hmy,
                    ct.scode,
                    TENANT.hmyperson,
                    pr.hProspect,
                    RTRIM(ct.sName),
                    TENANT.DTLEASEFROM
                HAVING  CAST(
                        ISNULL(SUM(pr.dQuan), 0) * SUM(rt.cRent) AS DECIMAL(18, 2)
                    ) > 0
            ) RI
        GROUP BY
            ChargeCodeId,
            ChargeCode,
            hmyperson,
            hProspect,
            sName
        UNION
        SELECT
            TenantId
,ChargeCode
,sName
,SUM(Charges) LeaseAmt
,dbo.fn_CalcProrationForTenant (
,N'Move In'
,MAX(DTLEASEFROM)
,TenantId
,SUM(Charges)
,) ProrateAmt
,0 bRecurring
,0 bProrate
,'Ledger' Source

FROM [Ledger10032790]
        GROUP BY
            TenantId,
            ChargeCode,
            sName
        UNION
        SELECT
            TenantId
,chargeCode sCode
,chargeName sName
,SUM(amount) LeaseAmt
,CASE
,WHEN MAX(isProrate) = 1 THEN SUM(ProrateAmt)
,ELSE 0
,END ProrateAmt
,- 1 bRecurring
,- MAX(isProrate) bProrate
,'GuestCardReceipt' Source

FROM [GuestCardReceipt10032790]
        WHERE NOT EXISTS (
                SELECT
                    1

FROM MoveInCharges m
JOIN TENANT ON TENANT.hMyPerson = m.hTenant
JOIN PROPERTY p ON p.hmy = TENANT.hproperty
JOIN chargtyp ct ON ct.hMy = m.hChargeCode
LEFT JOIN RentableItems ri ON ri.hMy = m.hRentableItem
                WHERE ISNULL(m.bSelected, 0) <> 0
                    AND p.hmy IN (1882)
                    AND TENANT.hmyperson IN (277666)
                    AND TENANT.ISTATUS IN (0, 2, 3, 4, 6)
                    AND chargeTypeHmy = ct.hMy
                    AND TENANT.HMYPERSON = [GuestCardReceipt10032790].TenantId
            )
            AND (
                ChargeCode IN (
                    'garage',
                    'mtplus',
                    '.rent',
                    'mtpest',
                    'packge',
                    'petrent',
                    'renins' /*,'free'*/,
                    'park',
                    'mtm',
                    'storage'
                )
                OR chargeTypeHmy IN (
                    SELECT
                        hMy

FROM chargtyp
                    WHERE scode LIKE '%trash%'
                )
                OR chargeTypeHmy IN (
                    SELECT
                        hMy

FROM chargtyp
                    WHERE scode LIKE '%water%'
                )
                OR chargeTypeHmy IN (
                    SELECT
                        hMy

FROM chargtyp
                    WHERE scode LIKE 'ub%'
                )
            )
            AND chargeTypeHmy NOT IN (
                SELECT
                    HRENTCHGCODE

FROM
                    param
            )
            AND NOT EXISTS (
                SELECT
                    1

FROM RentableItemsType rt
JOIN CHARGTYP ct2 ON ct2.hmy = rt.HCHARGECODE
LEFT JOIN prospect_charge prc ON rt.hMy = prc.hRentSchedule
LEFT JOIN TENANT t ON t.HPROSPECT = prc.hProspect
                WHERE t.HMYPERSON = [GuestCardReceipt10032790].TenantId
                    AND ct2.hMy = [GuestCardReceipt10032790].chargeTypeHmy
                    AND ISNULL(prc.dQuan, 0) * ISNULL(rt.cRent, 0) > 0
            )
        GROUP BY
            Tenantid,
            chargeCode,
            chargeName
        UNION
        SELECT
            *

FROM
            (
                SELECT
                    TenantId
,chargeCode sCode
,chargeName sName
,SUM(amount) LeaseAmt
,SUM(amount) ProrateAmt
,0 bRecurring
,0 bProrate
,'GuestCardReceipt' Source

FROM [GuestCardReceipt10032790]
                    CROSS JOIN (
                        SELECT
                            hRentChgCode

FROM
                            [param]
                    ) rent
                        OUTER APPLY (
                        SELECT
                            t.srent

FROM tenant t
                        WHERE t.hmyperson = [GuestCardReceipt10032790].TenantId
                    ) t
                WHERE NOT EXISTS (
                        SELECT
                            1

FROM MoveInCharges m
JOIN TENANT ON TENANT.hMyPerson = m.hTenant
JOIN PROPERTY p ON p.hmy = TENANT.hproperty
JOIN chargtyp ct ON ct.hMy = m.hChargeCode
LEFT JOIN RentableItems ri ON ri.hMy = m.hRentableItem
                        WHERE ISNULL(m.bSelected, 0) <> 0
                            AND p.hmy IN (1882)
                            AND TENANT.hmyperson IN (277666)
                            AND TENANT.ISTATUS IN (0, 2, 3, 4, 6)
                            AND chargeTypeHmy = ct.hMy
                            AND TENANT.HMYPERSON = [GuestCardReceipt10032790].TenantId
                    )
                    AND chargeTypeHmy IN (
                        SELECT
                            hMy

FROM chargtyp
                        WHERE sName LIKE '%deposit%'
                    )
                    AND NOT EXISTS (
                        SELECT
                            1

FROM RentableItemsType rt
JOIN CHARGTYP ct2 ON ct2.hmy = rt.HCHARGECODE
LEFT JOIN prospect_charge prc ON rt.hMy = prc.hRentSchedule
LEFT JOIN TENANT t ON t.HPROSPECT = prc.hProspect
                        WHERE t.HMYPERSON = [GuestCardReceipt10032790].TenantId
                            AND ct2.hMy = [GuestCardReceipt10032790].chargeTypeHmy
                            AND ISNULL(prc.dQuan, 0) * ISNULL(rt.cRent, 0) > 0
                    )
                GROUP BY
                    Tenantid,
                    chargeCode,
                    chargeName
            ) X
        UNION
        SELECT
            TENANT.HMYPERSON TenantId
,CHARGTYP.sCode
,CHARGTYP.sName
,LeaseAmt = COALESCE( ,secDepChg.Amount ,secDep.Amount ,TENANT.SDEPOSIT0 ,0 ,)
,ProrateAmt = COALESCE( ,secDepChg.Amount ,secDep.Amount ,TENANT.SDEPOSIT0 ,0 ,)
,0 bRecurring
,0 bProrate
,'UnitDet' Source

FROM TENANT
JOIN PROPERTY p ON p.hmy = TENANT.hproperty
INNER JOIN UNIT ON UNIT.hProperty = P.hMy
        OUTER APPLY (
                SELECT
                    ct.hmy ChargeCodeId
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
                GROUP BY
                    p.hmy,
                    tr.hPerson,
                    DATEFROMPARTS(YEAR(tr.uPostDate), MONTH(tr.uPostDate), 1),
                    ct.hmy
            ) secDepChg
            OUTER APPLY (
                SELECT
                    CT3.HMY ChargeCodeId
,u.HUNITTYPE "UnitTypeId"
,ISNULL(SUM(u.DAMOUNT), 0) "Amount"

FROM UNITDET u
JOIN CHARGTYP CT3 ON CT3.HMY = U.hChgCode
                WHERE u.hUnitType = UNIT.hUnitType
                    AND u.hChgCode > 0
                    AND u.bMoveIn = - 1
                    AND CT3.sName LIKE '%deposit%'
                GROUP BY
                    u.hUnitType,
                    CT3.HMY
            ) secDep
            CROSS APPLY (
                SELECT
                    HMY
,SCODE
,SNAME

FROM CHARGTYP
                WHERE CHARGTYP.HMY = COALESCE(secDepChg.ChargeCodeId, secDep.ChargeCodeId, 0)
                    AND NOT EXISTS (
                        SELECT
                            1

FROM [GuestCardReceipt10032790]
                        WHERE TenantId = TENANT.HMYPERSON
                            AND chargeTypeHmy = CHARGTYP.HMY
                    )
            ) CHARGTYP
        WHERE 0 = 0
            AND p.hmy IN (1882)
            AND TENANT.hmyperson IN (277666)
            AND NOT EXISTS (
                SELECT
                    1

FROM MoveInCharges m2
JOIN chargtyp ct2 ON ct2.hMy = m2.hChargeCode
                WHERE m2.hTenant = TENANT.hMyPerson
                    AND ISNULL(m2.bSelected, 0) <> 0
                    AND ct2.sName LIKE '%deposit%'
            )
            AND NOT EXISTS (
                SELECT
                    1

FROM [Ledger10032790]
                WHERE TenantId = TENANT.hmyperson
                    AND ChargeCodeId = CHARGTYP.HMY
            )
    )
SELECT
    *
,INTO [MicBase10032790]

FROM
    MicBase;


;


WITH
    MthRent AS (
        SELECT
            Section = 'MthRent'
,rn = ROW_NUMBER() OVER (
,PARTITION BY
,TenantId
,ORDER BY
,SUM(LeaseAmt) DESC
,)
,TenantId
,sCode
,sName
,Amt = SUM(LeaseAmt)
,Prorate = 0
,TaxDesc = 'TAX (0.0)'
,Tax = '$0.00'
,TotalDesc = 'TOTAL'
,Total = SUM(LeaseAmt)

FROM [MicBase10032790]
        WHERE sCode <> 'secdep'
            AND bRecurring = - 1
        GROUP BY
            TenantId,
            sCode,
            sName
        HAVING  SUM(LeaseAmt) <> 0
        UNION
        SELECT
            Section = 'MthRent'
,rn = ROW_NUMBER() OVER (
,PARTITION BY
,hmyperson
,ORDER BY
,SUM(rentersInsurance) DESC
,)
,hmyperson
,sCode = 'renins'
,sName = 'Renters Insurance'
,Amt = SUM(rentersInsurance)
,Prorate = SUM(rentersInsurance)
,TaxDesc = 'TAX (0.0)'
,Tax = '$0.00'
,TotalDesc = 'TOTAL'
,Total = SUM(rentersInsurance)

FROM
            [#Chg]
        GROUP BY
            hmyperson
        HAVING  SUM(rentersInsurance) <> 0
        UNION
        SELECT
            Section = 'MthRent'
,rn = ROW_NUMBER() OVER (
,PARTITION BY
,TENANT.HMYPERSON
,ORDER BY
,SUM(TENANT.SRENT) DESC
,)
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
                SELECT
                    ct.sCode
,ct.sName

FROM CHARGTYP CT
                WHERE CT.HMY IN (
                        SELECT
                            hRentChgCode

FROM
                            [param]
                    )
            ) ct
        WHERE 0 = 0
            AND p.hmy IN (1882)
            AND TENANT.hmyperson IN (277666)
        GROUP BY
            TENANT.HMYPERSON,
            ct.sCode,
            ct.sName
    ),
    MthRentT AS (
        SELECT
            Section = 'MthRentT'
,rn = ROW_NUMBER() OVER (
,PARTITION BY
,TenantId
,ORDER BY
,SUM(Amt) DESC
,)
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
        GROUP BY
            TenantId
        HAVING  SUM(Amt) <> 0
    ),
    PRent AS (
        SELECT
            Section = 'PRent'
,rn = ROW_NUMBER() OVER (
,PARTITION BY
,TenantId
,ORDER BY
,SUM(ProrateAmt) DESC
,)
,TenantId
,sCode
,sName
,Amt = 0
,Prorate = SUM(ProrateAmt)
,TaxDesc = 'TAX (0.0)'
,Tax = '$0.00'
,TotalDesc = 'TOTAL'
,Total = SUM(ProrateAmt)

FROM [MicBase10032790]
        WHERE sCode <> 'secdep'
            AND bRecurring = - 1
        GROUP BY
            TenantId,
            sCode,
            sName
        HAVING  SUM(ProrateAmt) <> 0
        UNION
        SELECT
            Section = 'PRent'
,rn = ROW_NUMBER() OVER (
,PARTITION BY
,hmyperson
,ORDER BY
,SUM(rentersInsurance) DESC
,)
,hmyperson
,sCode = 'renins'
,sName = 'Renters Insurance'
,Amt = SUM(rentersInsurance)
,Prorate = SUM(rentersInsurance)
,TaxDesc = 'TAX (0.0)'
,Tax = '$0.00'
,TotalDesc = 'TOTAL'
,Total = SUM(rentersInsurance)

FROM
            [#Chg]
        GROUP BY
            hmyperson
        HAVING  SUM(rentersInsurance) <> 0
        UNION
        SELECT
            Section = 'PRent'
,rn = ROW_NUMBER() OVER (
,PARTITION BY
,TENANT.HMYPERSON
,ORDER BY
,SUM(TENANT.SRENT) DESC
,)
,TenantId = TENANT.HMYPERSON
,ct.sCode
,ct.sName
,Amt = 0
,Prorate = dbo.fn_CalcProrationForTenant (
,N'Move In'
,MAX(TENANT.DTLEASEFROM)
,TENANT.HMYPERSON
,NULL
,)
,TaxDesc = 'TAX (0.0)'
,Tax = '$0.00'
,TotalDesc = 'TOTAL'
,Total = dbo.fn_CalcProrationForTenant (
,N'Move In'
,MAX(TENANT.DTLEASEFROM)
,TENANT.HMYPERSON
,NULL
,)

FROM TENANT
JOIN PROPERTY P ON P.HMY = TENANT.HPROPERTY
            CROSS JOIN (
                SELECT
                    RTRIM(SCODE) sCode
,rtrim(sName) sName

FROM CHARGTYP CT
                WHERE CT.HMY IN (
                        SELECT
                            hRentChgCode

FROM
                            [param]
                    )
            ) ct
        WHERE 0 = 0
            AND p.hmy IN (1882)
            AND TENANT.hmyperson IN (277666)
        GROUP BY
            TENANT.HMYPERSON,
            ct.sCode,
            ct.sName
    ),
    PRentT AS (
        SELECT
            Section = 'PRentT'
,rn = ROW_NUMBER() OVER (
,PARTITION BY
,TenantId
,ORDER BY
,SUM(Prorate) DESC
,)
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
        GROUP BY
            TenantId
        HAVING  SUM(Prorate) <> 0
    ),
    NRFee AS (
        SELECT
            Section
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

FROM
            (
                SELECT
                    Section = 'NRFee'
,rn = ROW_NUMBER() OVER (
,PARTITION BY
,TenantId
,ORDER BY
,SUM(LeaseAmt) DESC
,)
,TenantId
,sCode
,sName
,Amt = SUM(LeaseAmt)
,Prorate = 0
,TaxDesc = 'TAX (0.0)'
,Tax = '$0.00'
,TotalDesc = 'TOTAL'
,Total = SUM(LeaseAmt)

FROM [MicBase10032790]
                WHERE sCode IN ('admin', 'credit', 'nrpetfee')
                GROUP BY
                    TenantId,
                    sCode,
                    sName
                HAVING  SUM(LeaseAmt) <> 0
            ) x
        GROUP BY
            Section,
            rn,
            TenantId,
            sCode,
            sName,
            TaxDesc,
            Tax,
            TotalDesc
    ),
    NRFeeT AS (
        SELECT
            'NRFeeT' Section
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
        GROUP BY
            TenantId
        HAVING  SUM(Amt) <> 0
    ),
    Dep AS (
        SELECT
            *

FROM
            (
                SELECT
                    Section = 'Dep'
,rn = ROW_NUMBER() OVER (
,PARTITION BY
,TenantId
,sCode
,ORDER BY
,SUM(LeaseAmt) DESC
,)
,TenantId
,sCode
,sName
,Amt = SUM(LeaseAmt)
,Prorate = SUM(LeaseAmt)
,TaxDesc = 'TAX (0.0)'
,Tax = '$0.00'
,TotalDesc = 'TOTAL'
,Total = SUM(LeaseAmt)

FROM [MicBase10032790]
                WHERE sName LIKE '%deposit%'
                GROUP BY
                    TenantId,
                    sCode,
                    sName
                HAVING  SUM(LeaseAmt) <> 0
            ) Q
        WHERE Q.rn = 1
    ),
    DepT AS (
        SELECT
            Section = 'DepT'
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
        GROUP BY
            TenantId
        HAVING  SUM(Amt) <> 0
    ),
    AllRowsNormal AS (
        SELECT
            1 AS
,TYPE
,*

FROM MthRent
        UNION ALL
        SELECT
            0 AS
,TYPE
,*

FROM MthRentT
        UNION ALL
        SELECT
            1 AS
,TYPE
,*

FROM PRent
        UNION ALL
        SELECT
            0 AS
,TYPE
,*

FROM PRentT
        UNION ALL
        SELECT
            1 AS
,TYPE
,*

FROM NRFee
        UNION ALL
        SELECT
            0 AS
,TYPE
,*

FROM NRFeeT
        UNION ALL
        SELECT
            1 AS
,TYPE
,*

FROM Dep
        UNION ALL
        SELECT
            0 AS
,TYPE
,*

FROM
            DepT
    ),
    /* Grand total move-in costs (all prorate) */
    TotalMoveIn AS (
        SELECT
            2 AS
,TYPE
,Section = 'Total'
,rn = ROW_NUMBER() OVER (
,PARTITION BY
,TenantId
,ORDER BY
,SUM(Amt) DESC
,)
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
        WHERE TYPE = 0
        GROUP BY
            TenantId
        HAVING  SUM(Amt) <> 0
            AND SUM(Prorate) <> 0
    )
SELECT
    *

FROM
    NRFee;