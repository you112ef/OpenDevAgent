import docker
import os
import json
import logging
import tempfile
import shutil
from typing import Dict, Optional
from pathlib import Path

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class SandboxExecutor:
    def __init__(self, image_name: str = "opendev-sandbox:python"):
        self.docker_client = docker.from_env()
        self.image_name = image_name
        self.work_dir = Path("/app/work_dir")
        self.work_dir.mkdir(parents=True, exist_ok=True)
    
    def execute(
        self,
        code_artifacts: Dict,
        language: str,
        timeout: int = 60,
        task_id: str = "unknown"
    ) -> Dict:
        task_dir = self.work_dir / task_id
        task_dir.mkdir(parents=True, exist_ok=True)
        
        try:
            self._write_files(task_dir, code_artifacts)
            
            result = self._run_in_container(
                task_dir=str(task_dir),
                language=language,
                timeout=timeout,
                task_id=task_id
            )
            
            return result
        
        except Exception as e:
            logger.error(f"[{task_id}] Sandbox execution error: {str(e)}")
            return {
                "status": "error",
                "exit_code": 1,
                "stdout": "",
                "stderr": str(e),
                "error": str(e)
            }
        
        finally:
            self._cleanup(task_dir)
    
    def _write_files(self, task_dir: Path, code_artifacts: Dict):
        if "files" in code_artifacts:
            for filename, content in code_artifacts["files"].items():
                file_path = task_dir / filename
                file_path.parent.mkdir(parents=True, exist_ok=True)
                file_path.write_text(content)
                logger.info(f"Created file: {filename}")
        
        if "code_text" in code_artifacts and not (task_dir / "main.py").exists():
            (task_dir / "main.py").write_text(code_artifacts["code_text"])
    
    def _run_in_container(
        self,
        task_dir: str,
        language: str,
        timeout: int,
        task_id: str
    ) -> Dict:
        try:
            volume_mount = {task_dir: {'bind': '/sandbox', 'mode': 'rw'}}
            
            if language == "python":
                command = "cd /sandbox && python -m pytest tests.py -v || python main.py"
            elif language == "javascript":
                command = "cd /sandbox && npm install && npm test"
            elif language == "typescript":
                command = "cd /sandbox && npm install && npx tsc && npm test"
            else:
                command = "cd /sandbox && ls -la"
            
            logger.info(f"[{task_id}] Running container command: {command}")
            
            container = self.docker_client.containers.run(
                self.image_name,
                command=["bash", "-c", command],
                volumes=volume_mount,
                working_dir="/sandbox",
                stdout=True,
                stderr=True,
                remove=True,
                timeout=timeout,
                mem_limit="2g",
                cpus=2,
                network_disabled=True
            )
            
            return {
                "status": "success",
                "exit_code": 0,
                "stdout": container.decode('utf-8') if isinstance(container, bytes) else str(container),
                "stderr": ""
            }
        
        except docker.errors.ContainerError as e:
            logger.error(f"[{task_id}] Container execution error: {str(e)}")
            return {
                "status": "error",
                "exit_code": e.exit_status,
                "stdout": e.stdout.decode('utf-8') if e.stdout else "",
                "stderr": e.stderr.decode('utf-8') if e.stderr else str(e),
                "error": str(e)
            }
        
        except docker.errors.APIError as e:
            logger.error(f"[{task_id}] Docker API error: {str(e)}")
            return {
                "status": "error",
                "exit_code": 1,
                "stdout": "",
                "stderr": str(e),
                "error": str(e)
            }
    
    def _cleanup(self, task_dir: Path):
        try:
            if task_dir.exists():
                shutil.rmtree(task_dir)
                logger.info(f"Cleaned up {task_dir}")
        except Exception as e:
            logger.warning(f"Cleanup error: {str(e)}")
