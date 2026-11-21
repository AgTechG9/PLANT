from fastapi import APIRouter
from typing import List
from pydantic import BaseModel

router = APIRouter()

class CountyWeather(BaseModel):
    county: str
    temperature_c: int
    condition: str
    rainfall_risk: str
    advisory: str
    humidity: int

@router.get("/weather", response_model=List[CountyWeather])
def get_county_weather():
    return [
        CountyWeather(
            county="Bong",
            temperature_c=27,
            condition="Scattered Showers",
            rainfall_risk="Moderate",
            advisory="Good for cassava stem planting. Ensure ridges have drainage furrow.",
            humidity=84
        ),
        CountyWeather(
            county="Nimba",
            temperature_c=25,
            condition="Cloudy / Overcast",
            rainfall_risk="Low",
            advisory="Ideal conditions for pepper transplanting and foliar neem spraying.",
            humidity=78
        ),
        CountyWeather(
            county="Lofa",
            temperature_c=28,
            condition="Sunny Intervals",
            rainfall_risk="Low",
            advisory="Weeding recommended. Avoid chemical sprays during midday heat.",
            humidity=72
        )
    ]
