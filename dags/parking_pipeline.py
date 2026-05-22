from airflow.decorators import dag, task
from datetime import datetime

@dag(start_date=datetime(2024, 1, 1), schedule=None, catchup=False)
def parking_pipeline():

    @task
    def hello():
        print("Airflow is working")

    hello()

parking_pipeline()