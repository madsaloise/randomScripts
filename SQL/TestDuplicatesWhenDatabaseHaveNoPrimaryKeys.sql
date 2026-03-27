DECLARE @OrdinalPosition INT      = 1 --Kolonnenummer angives, 1 = Første kolonne
DECLARE @SchemaInclude SYSNAME      = 'LIS' --alle includes skal skrives præcist og kan inkludere flere muligheder ved at kommaseparere, e.g. 'PS_Soegenoegler,Kredse'
DECLARE @SchemaExclude SYSNAME     = '' --NULL eller '' for at ignorere et filter
DECLARE @TableInclude SYSNAME       = ''
DECLARE @TableExclude SYSNAME      = 'dim_TableName'

DECLARE @sqlStatus NVARCHAR(MAX);
DECLARE @sqlDuplicates NVARCHAR(MAX);
DROP TABLE IF EXISTS #TMP

;WITH FirstColumns AS (
    SELECT 
        t.TABLE_SCHEMA,
        t.TABLE_NAME,
        c.COLUMN_NAME
    FROM INFORMATION_SCHEMA.TABLES t
    JOIN INFORMATION_SCHEMA.COLUMNS c
        ON c.TABLE_SCHEMA = t.TABLE_SCHEMA
       AND c.TABLE_NAME = t.TABLE_NAME
    WHERE t.TABLE_TYPE = 'BASE TABLE'
	AND c.ORDINAL_POSITION = @OrdinalPosition
    AND (ISNULL(@SchemaInclude,'') = '' OR t.TABLE_SCHEMA IN (SELECT TRIM(value) FROM STRING_SPLIT(@SchemaInclude, ',')))
    AND (ISNULL(@SchemaExclude,'') = '' OR t.TABLE_SCHEMA NOT IN (SELECT TRIM(value) FROM STRING_SPLIT(@SchemaExclude, ',')))
    AND (ISNULL(@TableInclude,'') = '' OR t.TABLE_NAME IN (SELECT TRIM(value) FROM STRING_SPLIT(@TableInclude, ',')))
    AND (ISNULL(@TableExclude,'') = '' OR t.TABLE_NAME NOT IN (SELECT TRIM(value) FROM STRING_SPLIT(@TableExclude, ',')))

)
SELECT * INTO #TMP FROM FirstColumns;

SELECT @sqlStatus = STRING_AGG(
    CAST(
        'SELECT ''' + TABLE_NAME + ''' AS TABLE_NAME, '
        + '''' + COLUMN_NAME + ''' AS COLUMN_NAME, '
        + 'CASE WHEN COUNT(*) = COUNT(DISTINCT [' + COLUMN_NAME + ']) '
        + 'THEN ''UNIQUE'' ELSE ''NOT UNIQUE'' END AS STATUS '
        + 'FROM [' + TABLE_SCHEMA + '].[' + TABLE_NAME + ']'
        AS NVARCHAR(MAX)
    ),
    ' UNION ALL '
)
FROM #TMP

SELECT @sqlDuplicates = STRING_AGG(
    CAST(
        'SELECT ''' + TABLE_NAME + ''' AS TABLE_NAME, '
        + '''' + COLUMN_NAME + ''' AS COLUMN_NAME, '
        + 'CAST([' + COLUMN_NAME + '] as VARCHAR(MAX)) AS DUPLICATE_VALUE, '
        + 'COUNT(*) AS Antal '
        + 'FROM [' + TABLE_SCHEMA + '].[' + TABLE_NAME + '] '
        + 'GROUP BY [' + COLUMN_NAME + '] '
        + 'HAVING COUNT(*) > 1'
        AS NVARCHAR(MAX)
    ),
    ' UNION ALL '
)
FROM #TMP

EXEC sys.sp_executesql @sqlStatus

EXEC sys.sp_executesql @sqlDuplicates