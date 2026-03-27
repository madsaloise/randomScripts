
--  SQL Server Database Load Monitor

-- 1. ACTIVE QUERIES 
SELECT
    '🔵 ACTIVE QUERIES'                             AS section,
    r.session_id,
    s.login_name                                    AS [user],
    s.host_name,
    s.program_name                                  AS app,
    r.status,
    r.command,
    r.wait_type,
    r.wait_time / 1000                              AS wait_secs,
    r.total_elapsed_time / 1000                     AS elapsed_secs,
    r.cpu_time / 1000                               AS cpu_secs,
    r.logical_reads,
    r.writes,
    r.row_count,
    DB_NAME(r.database_id)                          AS database_name,
    LEFT(st.text, 200)                              AS query_snippet
FROM sys.dm_exec_requests r
JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) st
WHERE r.session_id <> @@SPID
  AND s.is_user_process = 1
ORDER BY r.total_elapsed_time DESC;


-- 2. LONG-RUNNING QUERIES 
SELECT
    '⚠️  LONG-RUNNING QUERIES (>30s)'               AS section,
    r.session_id,
    s.login_name                                    AS [user],
    r.status,
    r.wait_type,
    r.total_elapsed_time / 1000                     AS elapsed_secs,
    r.cpu_time / 1000                               AS cpu_secs,
    r.logical_reads,
    DB_NAME(r.database_id)                          AS database_name,
    LEFT(st.text, 300)                              AS query_snippet
FROM sys.dm_exec_requests r
JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) st
WHERE r.session_id <> @@SPID
  AND s.is_user_process = 1
  AND r.total_elapsed_time > 30000 
ORDER BY r.total_elapsed_time DESC;


-- 3. BLOCKED QUERIES 
SELECT
    '🔒 BLOCKING CHAINS'                            AS section,
    blocked.session_id                              AS blocked_spid,
    blocked_s.login_name                            AS blocked_user,
    blocked_s.host_name                             AS blocked_host,
    blocked.wait_time / 1000                        AS blocked_for_secs,
    blocked.wait_type,
    blocking.session_id                             AS blocking_spid,
    blocking_s.login_name                           AS blocking_user,
    blocking_s.host_name                            AS blocking_host,
    LEFT(blocked_text.text,  150)                   AS blocked_query,
    LEFT(blocking_text.text, 150)                   AS blocking_query
FROM sys.dm_exec_requests blocked
JOIN sys.dm_exec_sessions blocked_s  ON blocked.session_id   = blocked_s.session_id
JOIN sys.dm_exec_sessions blocking_s ON blocked.blocking_session_id = blocking_s.session_id
CROSS APPLY sys.dm_exec_sql_text(blocked.sql_handle)  blocked_text
JOIN sys.dm_exec_requests blocking   ON blocked.blocking_session_id = blocking.session_id
CROSS APPLY sys.dm_exec_sql_text(blocking.sql_handle) blocking_text
WHERE blocked.blocking_session_id <> 0
ORDER BY blocked.wait_time DESC;


-- 4. CONNECTION SUMMARY 
SELECT
    '📊 CONNECTION SUMMARY'                         AS section,
    DB_NAME(database_id)                            AS database_name,
    status,
    COUNT(*)                                        AS session_count,
    COUNT(DISTINCT login_name)                      AS distinct_users
FROM sys.dm_exec_sessions
WHERE is_user_process = 1
GROUP BY database_id, status
ORDER BY session_count DESC;



-- 5. WAIT STATISTICS 
SELECT TOP 15
    '⏳ TOP WAIT TYPES'                             AS section,
    wait_type,
    waiting_tasks_count,
    wait_time_ms / 1000                             AS total_wait_secs,
    max_wait_time_ms / 1000                         AS max_wait_secs,
    ROUND(100.0 * wait_time_ms / SUM(wait_time_ms) OVER (), 2) AS pct_of_total
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN (  -- tror det er alle background tasks
    'SLEEP_TASK','BROKER_TO_FLUSH','BROKER_EVENTHANDLER',
    'REQUEST_FOR_DEADLOCK_SEARCH','LOGMGR_QUEUE','CHECKPOINT_QUEUE',
    'CLR_AUTO_EVENT','DISPATCHER_QUEUE_SEMAPHORE','FT_IFTS_SCHEDULER_IDLE_WAIT',
    'HADR_FILESTREAM_IOMGR_IOCOMPLETION','HADR_WORK_QUEUE','HADR_CLUSAPI_CALL',
    'HADR_TIMER_TASK','HADR_TRANSPORT_DBRLIST','SQLTRACE_BUFFER_FLUSH',
    'SQLTRACE_INCREMENTAL_FLUSH_SLEEP','WAITFOR','XE_TIMER_EVENT',
    'XE_DISPATCHER_WAIT','ONDEMAND_TASK_MANAGER','SERVER_IDLE_CHECK',
    'SLEEP_DBSTARTUP','SLEEP_DCOMSTARTUP','SLEEP_MASTERDBREADY',
    'SLEEP_MASTERMDREADY','SLEEP_MASTERUPGRADED','SLEEP_MSDBSTARTUP',
    'SLEEP_TEMPDBSTARTUP','SNI_HTTP_ACCEPT','SP_SERVER_DIAGNOSTICS_SLEEP',
    'WAIT_XTP_OFFLINE_CKPT_NEW_LOG','DIRTY_PAGE_POLL'
)
  AND wait_time_ms > 0
ORDER BY wait_time_ms DESC;

-- 6. TOP QUERIES BY CPU 
SELECT TOP 15
    '🔥 TOP QUERIES BY CPU'                         AS section,
    qs.execution_count,
    qs.total_worker_time / 1000                     AS total_cpu_ms,
    qs.total_worker_time / qs.execution_count / 1000 AS avg_cpu_ms,
    qs.total_elapsed_time / 1000                    AS total_elapsed_ms,
    qs.total_logical_reads,
    qs.total_logical_reads / qs.execution_count     AS avg_logical_reads,
   -- qs.total_writes,
    LEFT(st.text, 200)                              AS query_snippet,
    DB_NAME(st.dbid)                                AS database_name
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY qs.total_worker_time DESC;


-- 7. TOP QUERIES BY LOGICAL READS
SELECT TOP 15
    '📖 TOP QUERIES BY LOGICAL READS'               AS section,
    qs.execution_count,
    qs.total_logical_reads,
    qs.total_logical_reads / qs.execution_count     AS avg_logical_reads,
    qs.total_worker_time / 1000                     AS total_cpu_ms,
    qs.total_elapsed_time / 1000                    AS total_elapsed_ms,
    LEFT(st.text, 200)                              AS query_snippet,
    DB_NAME(st.dbid)                                AS database_name
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY qs.total_logical_reads DESC;


-- 8. TRANSACTION LOG USAGE 
SELECT
    '📝 TRANSACTION LOG USAGE'                      AS section,
    instance_name,
    log_size_mb             = ROUND(cntr_value / 1024.0, 1),
    NULL                    AS log_used_mb,
    NULL                    AS log_used_pct
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Log File(s) Size (KB)'
  AND instance_name <> '_Total'

UNION ALL

SELECT
    '📝 TRANSACTION LOG USAGE',
    instance_name,
    NULL,
    ROUND(cntr_value / 1024.0, 1),
    NULL
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Log File(s) Used Size (KB)'
  AND instance_name <> '_Total'
ORDER BY instance_name;


-- 9. MEMORY USAGE
SELECT
    '💾 MEMORY SNAPSHOT'                            AS section,
    physical_memory_in_use_kb / 1024               AS mem_used_mb,
    page_fault_count,
    memory_utilization_percentage
FROM sys.dm_os_process_memory;

SELECT
    '💾 PLAN CACHE USAGE'                           AS section,
    objtype                                         AS cache_type,
    COUNT(*)                                        AS plan_count,
    SUM(size_in_bytes) / 1024 / 1024               AS cache_size_mb,
    AVG(usecounts)                                  AS avg_use_count
FROM sys.dm_exec_cached_plans
GROUP BY objtype
ORDER BY cache_size_mb DESC;



-- 10. OPEN TRANSACTIONS — sessions with uncommitted work

SELECT
    '🔓 OPEN TRANSACTIONS'                          AS section,
    s.session_id,
    s.login_name                                    AS [user],
    s.host_name,
    s.open_transaction_count,
    s.transaction_isolation_level,
    CASE s.transaction_isolation_level
        WHEN 0 THEN 'Unspecified'
        WHEN 1 THEN 'Read Uncommitted'
        WHEN 2 THEN 'Read Committed'
        WHEN 3 THEN 'Repeatable Read'
        WHEN 4 THEN 'Serializable'
        WHEN 5 THEN 'Snapshot'
    END                                             AS isolation_level_desc,
    s.last_request_start_time,
    DATEDIFF(SECOND, s.last_request_start_time, GETDATE()) AS idle_secs,
    *
FROM sys.dm_exec_sessions s
WHERE s.open_transaction_count > 0
  AND s.is_user_process = 1
  AND s.session_id <> @@SPID
ORDER BY s.open_transaction_count DESC, idle_secs DESC;


-- 11. INDEX USAGE STATS 
SELECT TOP 10
    '🗂️  MISSING INDEXES'                           AS section,
    DB_NAME(mid.database_id)                        AS database_name,
    OBJECT_NAME(mid.object_id, mid.database_id)     AS table_name,
    migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans)
                                                    AS improvement_score,
    migs.user_seeks,
    migs.user_scans,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns
FROM sys.dm_db_missing_index_group_stats migs
JOIN sys.dm_db_missing_index_groups mig  ON migs.group_handle = mig.index_group_handle
JOIN sys.dm_db_missing_index_details mid ON mig.index_handle  = mid.index_handle
ORDER BY improvement_score DESC;