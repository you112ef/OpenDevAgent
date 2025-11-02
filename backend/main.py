from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uuid
import os
from typing import Dict, Optional
from agent_logic.software_engineer_crew import SoftwareEngineerCrew
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="OpenDevAgent - AI Software Engineer",
    description="Kilo-Inspired Plan-Act-Observe-Fix Loop for AI-driven development",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

task_status: Dict[str, dict] = {}

class TaskSubmission(BaseModel):
    task_description: str
    target_language: str = "python"
    target_framework: Optional[str] = None
    openrouter_api_key: str

class TaskResponse(BaseModel):
    task_id: str
    status: str
    message: str

class TaskStatusResponse(BaseModel):
    task_id: str
    status: str
    phase: str
    progress: int
    logs: list
    result: Optional[dict] = None
    error: Optional[str] = None

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "OpenDevAgent Backend"}

@app.post("/api/submit_task", response_model=TaskResponse)
async def submit_task(submission: TaskSubmission, background_tasks: BackgroundTasks):
    task_id = str(uuid.uuid4())
    
    task_status[task_id] = {
        "status": "pending",
        "phase": "planning",
        "progress": 0,
        "logs": ["Task queued for processing"],
        "result": None,
        "error": None
    }
    
    background_tasks.add_task(
        execute_task,
        task_id=task_id,
        task_description=submission.task_description,
        target_language=submission.target_language,
        target_framework=submission.target_framework,
        openrouter_api_key=submission.openrouter_api_key
    )
    
    return TaskResponse(
        task_id=task_id,
        status="accepted",
        message="Task submitted for processing"
    )

async def execute_task(
    task_id: str,
    task_description: str,
    target_language: str,
    target_framework: Optional[str],
    openrouter_api_key: str
):
    try:
        logger.info(f"[{task_id}] Starting task execution")
        task_status[task_id]["status"] = "running"
        
        crew = SoftwareEngineerCrew(openrouter_api_key=openrouter_api_key)
        
        result = crew.execute_plan_act_observe_fix(
            task_id=task_id,
            task_description=task_description,
            target_language=target_language,
            target_framework=target_framework,
            task_status=task_status
        )
        
        task_status[task_id]["status"] = "completed"
        task_status[task_id]["phase"] = "complete"
        task_status[task_id]["progress"] = 100
        task_status[task_id]["result"] = result
        
    except Exception as e:
        logger.error(f"[{task_id}] Task execution failed: {str(e)}")
        task_status[task_id]["status"] = "failed"
        task_status[task_id]["error"] = str(e)
        task_status[task_id]["logs"].append(f"ERROR: {str(e)}")

@app.get("/api/task_status/{task_id}", response_model=TaskStatusResponse)
async def get_task_status(task_id: str):
    if task_id not in task_status:
        raise HTTPException(status_code=404, detail="Task not found")
    
    status = task_status[task_id]
    return TaskStatusResponse(**status)

@app.get("/api/tasks")
async def list_tasks():
    return {
        "total": len(task_status),
        "tasks": list(task_status.keys()),
        "status_summary": {
            "pending": sum(1 for s in task_status.values() if s["status"] == "pending"),
            "running": sum(1 for s in task_status.values() if s["status"] == "running"),
            "completed": sum(1 for s in task_status.values() if s["status"] == "completed"),
            "failed": sum(1 for s in task_status.values() if s["status"] == "failed"),
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
