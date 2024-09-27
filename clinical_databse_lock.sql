
-- Create clinical_trials table
CREATE TABLE clinical_trials (
    trial_id INT,
    trial_name VARCHAR(255),
    status VARCHAR(50),
    patient_id INT,
    visit_date DATE,
    treatment VARCHAR(255),
    outcome VARCHAR(255),
    lock_timestamp TIMESTAMP,
    PRIMARY KEY (trial_id, patient_id)
);

BEGIN;


LOCK TABLE clinical_trials IN ACCESS EXCLUSIVE MODE;

COMMIT
-- Example command that causes an error
INSERT INTO clinical_trials (trial_id, trial_name, status, patient_id, visit_date, treatment, outcome, lock_timestamp)
VALUES (4, 'Trial 1', 'ongoing', 1, '2024-09-30', 'Drug A', 'not evaluated', NULL);

SELECT 
    blocked_locks.pid AS blocked_pid,
    blocked_activity.usename AS blocked_user,
    blocking_locks.pid AS blocking_pid,
    blocking_activity.usename AS blocking_user,
    blocked_activity.query AS blocked_query,
    blocking_activity.query AS blocking_query
FROM 
    pg_catalog.pg_locks blocked_locks
JOIN 
    pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN 
    pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.database = blocked_locks.database
    AND blocking_locks.relation = blocked_locks.relation
    AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
    AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
    AND blocking_locks.virtualtransaction <> blocked_locks.virtualtransaction
    AND blocked_locks.granted = false
JOIN 
    pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid;


--Check trials that are currently locked
SELECT trial_name, lock_timestamp
FROM clinical_trials
WHERE status = 'locked';

--Fetch all data for a specific trial before it was locked
SELECT *
FROM clinical_trials
WHERE trial_name = 'COVID-19 Vaccine Study' 
  AND (lock_timestamp IS NULL OR visit_date < lock_timestamp);

--Attempting to update data for a locked trial (This should fail if lock is enforced via triggers or constraints)
UPDATE clinical_trials
SET outcome = 'improved'
WHERE trial_name = 'Cancer Therapy Study'
  AND status = 'locked';

--List trials that have been locked within the last 30 days
SELECT trial_name, lock_timestamp
FROM clinical_trials
WHERE status = 'locked'
  AND lock_timestamp > NOW() - INTERVAL '30 days';

--Count the number of locked vs ongoing trials
SELECT status, COUNT(*)
FROM clinical_trials
GROUP BY status;

--Fetch patient data that is under review or whose outcome has not been finalized, for ongoing trials only
SELECT patient_id, treatment, outcome
FROM clinical_trials
WHERE status = 'ongoing' 
  AND outcome = 'under review';

-- Lock Impact on Trial Completion Rates
SELECT status, COUNT(*) AS trials_count
FROM clinical_trials
GROUP BY status
HAVING SUM(CASE WHEN lock_timestamp IS NOT NULL THEN 1 ELSE 0 END) > 0;

--average lock duration
SELECT trial_id, AVG(EXTRACT(EPOCH FROM (NOW() - lock_timestamp))) AS avg_lock_duration
FROM clinical_trials
WHERE lock_timestamp IS NOT NULL
GROUP BY trial_id;