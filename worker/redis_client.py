import os
import json
import redis
 
_client = redis.Redis(
    host=os.environ.get("REDIS_HOST", "redis"),
    port=int(os.environ.get("REDIS_PORT", 6379)),
    decode_responses=True,
)
 
 
def cache_weather(city, data, expire_seconds=1800):
    key = f"weather:{city.lower()}"
    _client.set(key, json.dumps(data), ex=expire_seconds)