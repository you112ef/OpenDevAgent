import re
import logging
from typing import Dict, List

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class CodeAnalyzer:
    def __init__(self):
        self.patterns = {
            "python": {
                "imports": r"^(?:from|import)\s+(.+)$",
                "functions": r"^def\s+(\w+)\s*\(",
                "classes": r"^class\s+(\w+)(?:\(|:)",
                "errors": r"(?:Error|Exception|raise)",
            },
            "javascript": {
                "imports": r"^(?:import|require)\s+(.+)$",
                "functions": r"(?:function|const|let|var)\s+(\w+)\s*(?:\(|=\s*(?:\(|async))",
                "classes": r"class\s+(\w+)",
                "errors": r"(?:Error|throw|catch)",
            }
        }
    
    def analyze(self, code: str, language: str = "python") -> Dict:
        return {
            "language": language,
            "lines": len(code.split('\n')),
            "imports": self._extract_imports(code, language),
            "functions": self._extract_functions(code, language),
            "classes": self._extract_classes(code, language),
            "potential_issues": self._detect_issues(code, language),
        }
    
    def _extract_imports(self, code: str, language: str) -> List[str]:
        pattern = self.patterns.get(language, {}).get("imports", "")
        if not pattern:
            return []
        return re.findall(pattern, code, re.MULTILINE)
    
    def _extract_functions(self, code: str, language: str) -> List[str]:
        pattern = self.patterns.get(language, {}).get("functions", "")
        if not pattern:
            return []
        return re.findall(pattern, code, re.MULTILINE)
    
    def _extract_classes(self, code: str, language: str) -> List[str]:
        pattern = self.patterns.get(language, {}).get("classes", "")
        if not pattern:
            return []
        return re.findall(pattern, code, re.MULTILINE)
    
    def _detect_issues(self, code: str, language: str) -> List[str]:
        issues = []
        
        if not code.strip():
            issues.append("Empty code")
        
        if len(code) > 10000:
            issues.append("Large file (>10KB) - consider splitting")
        
        if language == "python":
            if "except:" in code and "except Exception" not in code:
                issues.append("Bare except clause detected - use specific exceptions")
            if "import *" in code:
                issues.append("Wildcard imports detected - use specific imports")
        
        return issues
