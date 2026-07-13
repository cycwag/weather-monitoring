CREATE TABLE IF NOT EXISTS weather_history (
    id SERIAL PRIMARY KEY,
    city VARCHAR(100) NOT NULL,
    temperature FLOAT NOT NULL,
    humidity INT NOT NULL,
    description VARCHAR(255),
    recorded_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_weather_city_time
    ON weather_history (city, recorded_at DESC);