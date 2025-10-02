/* exclude resident */
SELECT
    pr.hMy                      AS PayeeId,
    MAX(ISNULL(b.bInactive, 0)) AS IsInactiveBank,
    CASE WHEN MAX(ISNULL(co.iInsuranceLevel, 0)) = 1 THEN CASE WHEN MIN(ISNULL(co.iInsuranceLevel, 0)) = 1 THEN 0
            ELSE CASE WHEN ISNULL(
                    v.DDATEWCINSUR,
                    CONVERT(DATETIME, '09/30/2025', 101)
                ) >= CONVERT(DATETIME, '09/30/2025', 101) THEN 0
                ELSE - 1
            END
        END
        ELSE CASE WHEN ISNULL(
                v.DDATEWCINSUR,
                CONVERT(DATETIME, '09/30/2025', 101)
            ) >= CONVERT(DATETIME, '09/30/2025', 101) THEN 0
            ELSE - 1
        END
    END                         AS VendorWCInsur,
    CASE WHEN MAX(ISNULL(co.iInsuranceLevel, 0)) = 1 THEN CASE WHEN MIN(ISNULL(co.iInsuranceLevel, 0)) = 1 THEN NULL
            ELSE CASE WHEN ISNULL(
                    v.DDATEWCINSUR,
                    CONVERT(DATETIME, '09/30/2025', 101)
                ) >= CONVERT(DATETIME, '09/30/2025', 101) THEN NULL
                ELSE v.DDATEWCINSUR
            END
        END
        ELSE CASE WHEN ISNULL(
                v.DDATEWCINSUR,
                CONVERT(DATETIME, '09/30/2025', 101)
            ) >= CONVERT(DATETIME, '09/30/2025', 101) THEN NULL
            ELSE v.DDATEWCINSUR
        END
    END                         AS VendorWCInsurDate,
    CASE WHEN MAX(ISNULL(co.iInsuranceLevel, 0)) = 1 THEN CASE WHEN MIN(ISNULL(co.iInsuranceLevel, 0)) = 1 THEN 0
            ELSE CASE WHEN ISNULL(
                    v.DDATELIABINSUR,
                    CONVERT(DATETIME, '09/30/2025', 101)
                ) >= CONVERT(DATETIME, '09/30/2025', 101) THEN 0
                ELSE - 1
            END
        END
        ELSE CASE WHEN ISNULL(
                v.DDATELIABINSUR,
                CONVERT(DATETIME, '09/30/2025', 101)
            ) >= CONVERT(DATETIME, '09/30/2025', 101) THEN 0
            ELSE - 1
        END
    END                         AS VendorLiabInsur,
    CASE WHEN MAX(ISNULL(co.iInsuranceLevel, 0)) = 1 THEN CASE WHEN MIN(ISNULL(co.iInsuranceLevel, 0)) = 1 THEN NULL
            ELSE CASE WHEN ISNULL(
                    v.DDATELIABINSUR,
                    CONVERT(DATETIME, '09/30/2025', 101)
                ) >= CONVERT(DATETIME, '09/30/2025', 101) THEN NULL
                ELSE v.DDATELIABINSUR
            END
        END
        ELSE CASE WHEN ISNULL(
                v.DDATELIABINSUR,
                CONVERT(DATETIME, '09/30/2025', 101)
            ) >= CONVERT(DATETIME, '09/30/2025', 101) THEN NULL
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
    AND ISNULL(t.uRef, '') NOT LIKE ':CIS%'
    AND cp.hTran IN (
        SELECT
            CASE ISNULL(wf.iStatus, 1)
                WHEN 1 THEN x.hMy
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
    AND ISNULL(p.bInactive, 0) = 0
    AND (
        v.DDATEWCINSUR IS NOT NULL
        AND v.DDATEWCINSUR < CAST(GETDATE() AS DATE)
        OR v.DDATELIABINSUR IS NOT NULL
        AND v.DDATELIABINSUR < CAST(GETDATE() AS DATE)
    )
GROUP BY
    pr.hMy,
    cp.hTran,
    pr.uLastName,
    cp.sInvoiceNumber,
    t.sOtherDate1,
    a.hMy,
    a.hChart,
    a.sCode,
    b.sCode,
    b.hMy,
    t.bAch,
    t.CashReceipt,
    t.holdPayment,
    pr.ucode,
    ISNULL(ti.sGAcctAmount, 0),
    ISNULL(t.ConsolidateCheck, 0),
    t.sDiscountAmt,
    t.iSubType,
    t.adjustment,
    t.uPostDate,
    t.isubtype,
    v.dDateWcInsur,
    v.dDateLiabInsur,
    ISNULL(cmret.s2ndVendor, ISNULL(cmnoret.s2ndvendor, '')),
    ISNULL(cmret.h2ndVendor, ISNULL(cmnoret.h2ndVendor, 0))
HAVING
    MAX(ISNULL(b.bInactive, 0)) = 0