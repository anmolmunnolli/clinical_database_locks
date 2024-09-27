import psycopg2
import pandas as pd
from dotenv import load_dotenv
import os

load_dotenv()

db_host = os.getenv("DB_HOST")
db_name = os.getenv("DB_NAME")
db_user = os.getenv("DB_USER")
db_password = os.getenv("DB_PASSWORD")
db_port = os.getenv("DB_PORT")

conn = psycopg2.connect(
    host=db_host,
    database=db_name,
    user=db_user,
    password=db_password,
    port=db_port
)

cur = conn.cursor()

csv_file_path = "C:/Users/anmol/clinical_database_locks/clinical_trials_mock_data.csv"
df = pd.read_csv(csv_file_path)
df = df.drop_duplicates(subset=['trial_id', 'patient_id'])

df['lock_timestamp'] = pd.to_datetime(df['lock_timestamp'], errors='coerce')

for index, row in df.iterrows():
    lock_timestamp = row['lock_timestamp'] if pd.notna(row['lock_timestamp']) else None
    
    cur.execute("""
        INSERT INTO clinical_trials (trial_id, trial_name, status, patient_id, visit_date, treatment, outcome, lock_timestamp)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """,
        (row['trial_id'], row['trial_name'], row['status'], row['patient_id'], row['visit_date'], row['treatment'], row['outcome'], lock_timestamp)
    )

conn.commit()
cur.close()
conn.close()

print("Data successfully inserted!")
