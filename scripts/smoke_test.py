import os
import httpx
import asyncio
from dotenv import load_dotenv

load_dotenv()

SMARTTHINGS_PAT = os.getenv('SMARTTHINGS_PAT')
if not SMARTTHINGS_PAT:
    print("SMARTTHINGS_PAT is not set")

SMARTTHINGS_DEVICE_ID = os.getenv('SMARTTHINGS_DEVICE_ID')
if not SMARTTHINGS_DEVICE_ID:
    print("SMARTTHINGS_DEVICE_ID is not set")

SMARTTHINGS_BASE_URL = os.getenv('SMARTTHINGS_BASE_URL')
if not SMARTTHINGS_BASE_URL:
    print("SMARTTHINGS_BASE_URL is not set")

async def smoke_test():
    async with httpx.AsyncClient() as client:
        headers = {'Authorization': f'Bearer {SMARTTHINGS_PAT}'}
        response = await client.get(f'{SMARTTHINGS_BASE_URL}/devices/{SMARTTHINGS_DEVICE_ID}', headers=headers)
        if response.status_code != 200:
            print(f"Error: {response.status_code}")
            print(response.text)
            return
        print(response.json())
        device_id = response.json().get('deviceId')
        print("================================================")
        print(f"Device ID: {device_id}")
        print("================================================")
    async with httpx.AsyncClient() as client:
        headers = {'Authorization': f'Bearer {SMARTTHINGS_PAT}'}
        response = await client.get(f'{SMARTTHINGS_BASE_URL}/devices/{device_id}/status', headers=headers)
        if response.status_code != 200:
            print(f"Error: {response.status_code}")
            if 'capabilities' in response.json():
                for capability in response.json().get('capabilities'):
                    print(f"Capability: {capability}")
            return
        print(response.json())
asyncio.run(smoke_test())