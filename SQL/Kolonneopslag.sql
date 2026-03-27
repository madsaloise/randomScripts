declare @column as varchar(50)
--Kolonne, der søges efter
set @column = 'Journal'

USE <Database>
--Where does column appear in tables
SELECT TABLE_CATALOG,TABLE_SCHEMA,Table_Name, Column_Name 
FROM INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME LIKE '%' + @column + '%'
order by TABLE_SCHEMA,TABLE_NAME,COLUMN_NAME

--Where is it mentioned in scripts
SELECT [Scehma] = schema_name(o.schema_id), o.Name, o.type, s2.rn as Række,s2.line as LinjeTekst
FROM sys.sql_modules m
INNER JOIN sys.objects o ON o.object_id = m.object_id
CROSS APPLY (SELECT *, ROW_NUMBER() OVER(ORDER BY 1/0) 
             FROM STRING_SPLIT(m.definition, CHAR(10))) s2(line, rn)
WHERE replace(s2.line, ' ','') like '%' + @column + '%'