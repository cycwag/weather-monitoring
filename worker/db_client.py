import os
import psycopg2
 
def get_connection():
    return psycopg2.connect(
        host=os.environ.get("DB_HOST", "postgres"),
        port=os.environ.get("DB_PORT", 5432),
        user=os.environ.get("DB_USER", "weather_user"),
        password=os.environ.get("DB_PASSWORD", "weather_pass"),
        database=os.environ.get("DB_NAME", "weather_db"),
    )
 
 
def insert_weather(city, temperature, humidity, description):
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO weather_history (city, temperature, humidity, description)
                VALUES (%s, %s, %s, %s)
                """,
                (city, temperature, humidity, description),
            )
        conn.commit()
    finally:
        conn.close()
