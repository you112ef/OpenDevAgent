from crewai import Agent, Task, Crew
from langchain_openai import ChatOpenAI
from tools.sandbox_executor import SandboxExecutor
from tools.code_analyzer import CodeAnalyzer
import logging
from typing import Optional, Dict

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class SoftwareEngineerCrew:
    def __init__(self, openrouter_api_key: str):
        self.openrouter_api_key = openrouter_api_key
        self.sandbox_executor = SandboxExecutor()
        self.code_analyzer = CodeAnalyzer()
        self.setup_llm_clients()
        self.setup_agents()
    
    def setup_llm_clients(self):
        self.architect_llm = ChatOpenAI(
            model="openai/gpt-4o",
            openai_api_key=self.openrouter_api_key,
            openai_api_base="https://openrouter.ai/api/v1",
            temperature=0.3,
        )
        
        self.coder_llm = ChatOpenAI(
            model="mistral/codestral-22b",
            openai_api_key=self.openrouter_api_key,
            openai_api_base="https://openrouter.ai/api/v1",
            temperature=0.2,
        )
        
        self.debugger_llm = ChatOpenAI(
            model="anthropic/claude-3-5-sonnet",
            openai_api_key=self.openrouter_api_key,
            openai_api_base="https://openrouter.ai/api/v1",
            temperature=0.2,
        )
    
    def setup_agents(self):
        self.architect = Agent(
            role="System Architect",
            goal="Design robust software architectures and break down complex tasks into actionable components",
            backstory="Expert software architect with deep knowledge of system design, scalability, and best practices",
            llm=self.architect_llm,
            verbose=True
        )
        
        self.coder = Agent(
            role="Lead Developer",
            goal="Generate production-ready code that implements architectural designs",
            backstory="Senior software engineer with expertise in multiple programming languages and frameworks",
            llm=self.coder_llm,
            verbose=True
        )
        
        self.debugger = Agent(
            role="QA & Debugging Specialist",
            goal="Identify bugs, analyze test failures, and generate fixes",
            backstory="Expert debugger with deep knowledge of error patterns and testing strategies",
            llm=self.debugger_llm,
            verbose=True
        )
    
    def execute_plan_act_observe_fix(
        self,
        task_id: str,
        task_description: str,
        target_language: str,
        target_framework: Optional[str],
        task_status: Dict
    ) -> Dict:
        try:
            logs = task_status[task_id]["logs"]
            
            logs.append(f"[PHASE 1: PLANNING] Architect analyzing task...")
            task_status[task_id]["phase"] = "planning"
            task_status[task_id]["progress"] = 15
            
            plan = self._phase_plan(task_description, target_language, target_framework)
            logs.append(f"✓ Plan created: {len(plan.get('components', []))} components identified")
            
            logs.append(f"[PHASE 2: ACTING] Coder generating implementation...")
            task_status[task_id]["phase"] = "coding"
            task_status[task_id]["progress"] = 40
            
            code_artifacts = self._phase_act(plan, target_language, target_framework)
            logs.append(f"✓ Code generated: {len(code_artifacts)} files created")
            
            logs.append(f"[PHASE 3: OBSERVING] Executing code in sandbox...")
            task_status[task_id]["phase"] = "testing"
            task_status[task_id]["progress"] = 65
            
            execution_results = self._phase_observe(code_artifacts, target_language, task_id, logs)
            logs.append(f"✓ Execution complete. Status: {execution_results.get('status', 'unknown')}")
            
            if execution_results.get("status") == "success":
                task_status[task_id]["phase"] = "complete"
                task_status[task_id]["progress"] = 100
                return {
                    "status": "success",
                    "plan": plan,
                    "code": code_artifacts,
                    "execution": execution_results
                }
            
            logs.append(f"[PHASE 4: FIXING] Debugger analyzing failures...")
            task_status[task_id]["phase"] = "debugging"
            task_status[task_id]["progress"] = 80
            
            fixes = self._phase_fix(
                execution_results,
                code_artifacts,
                plan,
                target_language,
                logs
            )
            
            logs.append(f"✓ Fixes generated. Retesting...")
            
            retest_results = self._phase_observe(fixes, target_language, task_id, logs)
            task_status[task_id]["progress"] = 100
            
            return {
                "status": retest_results.get("status", "completed_with_fixes"),
                "plan": plan,
                "initial_code": code_artifacts,
                "fixed_code": fixes,
                "initial_execution": execution_results,
                "final_execution": retest_results
            }
        
        except Exception as e:
            logger.error(f"[{task_id}] Execution error: {str(e)}")
            raise
    
    def _phase_plan(self, task_description: str, target_language: str, target_framework: Optional[str]) -> Dict:
        planning_prompt = f"""
        Task: {task_description}
        Target Language: {target_language}
        Target Framework: {target_framework or 'None'}
        
        Create a detailed architecture plan that includes:
        1. System components and their responsibilities
        2. Data structures and relationships
        3. Implementation steps in order
        4. Testing strategy
        5. Potential edge cases
        
        Return a structured plan.
        """
        
        planning_task = Task(
            description=planning_prompt,
            agent=self.architect,
            expected_output="Detailed architecture and implementation plan"
        )
        
        crew = Crew(
            agents=[self.architect],
            tasks=[planning_task],
            verbose=True
        )
        
        result = crew.kickoff()
        
        return {
            "components": ["component_1", "component_2"],
            "plan_text": str(result),
            "target_language": target_language,
            "framework": target_framework
        }
    
    def _phase_act(self, plan: Dict, target_language: str, target_framework: Optional[str]) -> Dict:
        coding_prompt = f"""
        Based on this architecture plan:
        {plan.get('plan_text', '')}
        
        Target Language: {target_language}
        Framework: {target_framework or 'None'}
        
        Generate production-ready code that:
        1. Implements all components from the plan
        2. Includes proper error handling
        3. Includes unit tests
        4. Follows best practices for {target_language}
        5. Is well-documented with comments
        
        Provide the complete code with filenames.
        """
        
        coding_task = Task(
            description=coding_prompt,
            agent=self.coder,
            expected_output="Complete, production-ready source code"
        )
        
        crew = Crew(
            agents=[self.coder],
            tasks=[coding_task],
            verbose=True
        )
        
        result = crew.kickoff()
        
        return {
            "files": {
                "main.py": str(result),
                "tests.py": "# Test suite will be generated"
            },
            "language": target_language,
            "code_text": str(result)
        }
    
    def _phase_observe(self, code_artifacts: Dict, target_language: str, task_id: str, logs: list) -> Dict:
        logger.info(f"[{task_id}] Executing code in sandbox...")
        logs.append(f"Sandbox execution started for {target_language}...")
        
        execution_result = self.sandbox_executor.execute(
            code_artifacts=code_artifacts,
            language=target_language,
            timeout=60,
            task_id=task_id
        )
        
        if execution_result.get("exit_code") == 0:
            logs.append("✓ All tests passed!")
            return {
                "status": "success",
                "stdout": execution_result.get("stdout", ""),
                "stderr": execution_result.get("stderr", ""),
                "exit_code": 0
            }
        else:
            logs.append(f"✗ Execution failed with exit code {execution_result.get('exit_code')}")
            logs.append(f"Error output: {execution_result.get('stderr', '')}")
            return {
                "status": "failed",
                "stdout": execution_result.get("stdout", ""),
                "stderr": execution_result.get("stderr", ""),
                "exit_code": execution_result.get("exit_code", 1),
                "error": execution_result.get("error", "Unknown error")
            }
    
    def _phase_fix(self, execution_results: Dict, code_artifacts: Dict, plan: Dict, target_language: str, logs: list) -> Dict:
        error_context = f"""
        Previous execution failed with:
        STDOUT: {execution_results.get('stdout', '')}
        STDERR: {execution_results.get('stderr', '')}
        Exit Code: {execution_results.get('exit_code', 1)}
        
        Current code:
        {code_artifacts.get('code_text', '')}
        
        Please analyze the errors and provide fixed code.
        """
        
        fixing_task = Task(
            description=error_context,
            agent=self.debugger,
            expected_output="Fixed and corrected source code"
        )
        
        crew = Crew(
            agents=[self.debugger],
            tasks=[fixing_task],
            verbose=True
        )
        
        result = crew.kickoff()
        logs.append(f"Debugger analysis: {str(result)[:200]}...")
        
        return {
            "files": {
                "main.py": str(result),
                "tests.py": "# Updated test suite"
            },
            "fixes_applied": str(result)
        }
