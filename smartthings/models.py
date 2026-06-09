from enum import Enum
from typing import Any
from pydantic import BaseModel, Field

class OvenMode(Enum):
    AIR_FRYER="AirFryer"
    CONVECTION="Convection"
    HOT_BLAST="HotBlast"
    BAKE="Bake"
    GRILL="Grill"
    MICROWAVE="MicroWave"
    AUTO_COOK="Autocook"
    AUTO_COOK_CUSTOM="AutocookCustom"
    FERMENTATION="Fermentation"
    DRYING="Drying"
    DEODORIZATION="Deodorization"
    NO_OPERATION="NoOperation"

class CookRecipePayload(BaseModel):
    ovenMode: OvenMode = Field(..., description="Oven Mode")
    ovenSetpoint: int = Field(..., ge=40, le=200, description="Oven Setpoint")
    cookTime: int = Field(..., ge=1, le=7200, description="Cook Time")


class DeviceCommandPayload(BaseModel):
    component: str = Field(..., description="Component")
    capability: str = Field(..., description="Capability")
    command: str = Field(..., description="Command")
    arguments: list[Any] = Field(..., description="Arguments")


def minutes_to_seconds(minutes: int) -> int:
    return minutes * 60
