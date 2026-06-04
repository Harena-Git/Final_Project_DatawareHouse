FROM apache/airflow:2.9.2

USER root
RUN apt-get update && apt-get install -y git && apt-get clean

USER airflow
RUN pip install --no-cache-dir \
    pandas==2.2.3 \
    psycopg2-binary==2.9.9 \
    requests==2.32.3 \
    python-dotenv==1.0.1 \
    "dbt-core==1.8.7" \
    "dbt-postgres==1.8.2"
