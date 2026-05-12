import time
import uuid
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from database import get_all_rules, upsert_rule, delete_rule
from rule_engine import execute_actions

router = APIRouter()


class RuleIn(BaseModel):
    name: str
    enabled: bool = True
    trigger: dict      # {"type": "time", "cron": "0 22 * * *"} or {"type": "device_state", "device_id": "x"}
    condition: dict = {}
    actions: list      # [{"type": "mqtt", "device_id": "x", "payload": {"state": "OFF"}}]


@router.get("/")
async def list_rules():
    return await get_all_rules()


@router.post("/")
async def create_rule(r: RuleIn):
    rule = {**r.model_dump(), "id": str(uuid.uuid4())}
    await upsert_rule(rule)
    return rule


@router.put("/{rule_id}")
async def update_rule(rule_id: str, r: RuleIn):
    rule = {**r.model_dump(), "id": rule_id}
    await upsert_rule(rule)
    return rule


@router.delete("/{rule_id}")
async def remove_rule(rule_id: str):
    await delete_rule(rule_id)
    return {"ok": True}


@router.post("/{rule_id}/run")
async def run_rule(rule_id: str):
    rules = await get_all_rules()
    rule = next((r for r in rules if r["id"] == rule_id), None)
    if not rule:
        raise HTTPException(404, "Rule not found")
    await execute_actions(rule["actions"])
    return {"ok": True}
