import os
import time
import requests

from db_client import insert_weather
from redis_client import cache_weather

API_KEY = os.environ.get("OPENWEATHER_API_KEY")
CITIES = os.environ.get("CITIES", "Jakarta").split(",")
FETCH_INTERVAL_MINUTES = int(os.environ.get("FETCH_INTERVAL_MINUTES", 30))

BASE_URL = "https://api.openweathermap.org/data/2.5/weather"


def fetch_weather(city):
    params = {
        "q": city,
        "appid": API_KEY,
        "units": "metric",  
    }
    response = requests.get(BASE_URL, params=params, timeout=10)
    response.raise_for_status()  
    return response.json()


def process_city(city):
    try:
        raw = fetch_weather(city)

        weather_data = {
            "city": city,
            "temperature": raw["main"]["temp"],
            "humidity": raw["main"]["humidity"],
            "description": raw["weather"][0]["description"],
        }

        cache_weather(city, weather_data)

    
        insert_weather(
            city=weather_data["city"],
            temperature=weather_data["temperature"],
            humidity=weather_data["humidity"],
            description=weather_data["description"],
        )

        print(f"[worker] {city}: {weather_data['temperature']}°C, {weather_data['description']}")

    except Exception as e:
     
        print(f"[worker] gagal fetch {city}: {e}")


def main():
    if not API_KEY:
        raise RuntimeError("OPENWEATHER_API_KEY belum diset di .env")

    print(f"[worker] mulai monitoring {len(CITIES)} kota, interval {FETCH_INTERVAL_MINUTES} menit")

    while True:
        for city in CITIES:
            process_city(city.strip())

        time.sleep(FETCH_INTERVAL_MINUTES * 60)


if __name__ == "__main__":
    main()