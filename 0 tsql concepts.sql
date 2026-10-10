

-- 1-   Dynamic SQL

DECLARE @company VARCHAR(10) = 'UAE'
DECLARE @year INT = 2026

DECLARE @sql NVARCHAR(MAX) = 
        ' SELECT *
        FROM FactSales
        WHERE 1 = 1 '   
        ;

IF @company IS NOT NULL
    SET @sql += ' AND CompanyID = @company';

IF @year IS NOT NULL
    SET @sql += ' AND FiscalYear = @year';


-- 2-   Shortcut assignment operator (+=) 

SET @sql += ' AND CompanyID = @company';
    -- is equivalent to :
SET @sql = @sql + ' AND CompanyID = @company';

-- 3-   cross join

    SELECT *
    FROM Companies a
    LEFT JOIN Years b
        ON 1 = 1

    -- is similar to : 

    SELECT *
    FROM Companies c
    CROSS JOIN Years y;
    
    /*
    Table A (Company)
    UAE
    KSA

    Table B (Years)
    2025
    2026

    Result :
    Company Years
    UAE     2025     
    UAE     2026
    KSA     2025
    KSA     2026
    */


-- 4-   In T-SQL, 1=1 is simply a condition that is always true. The optimizer ignores 1=1, so there is no meaningful performance impact. It's mostly a coding convenience.

    WHERE 1 = 1
        AND CompanyID = 'US01'
        AND FiscalYear = '2026'

-- 5-   