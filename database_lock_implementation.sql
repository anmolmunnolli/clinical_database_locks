-- Acquire an advisory lock
SELECT pg_advisory_lock(1);  -- Lock ID can be any integer

-- Perform your data operation (insert, update, delete)
INSERT INTO clinical_trials (trial_id, trial_name, status, patient_id, visit_date, treatment, outcome, lock_timestamp)
VALUES (1, 'Sample Trial', 'ongoing', 101, '2024-09-30', 'Drug A', 'not evaluated', NULL);

-- Release the advisory lock
SELECT pg_advisory_unlock(1);
