#!/usr/bin/env python3
"""
DialogChain Project Generator - Core Module
Simplified version focused on essential project creation
"""

import os
import sys
import json
import yaml
from pathlib import Path
from typing import Dict, List, Any
from dataclasses import dataclass
from datetime import datetime

@dataclass
class ProjectTemplate:
    """Project template configuration"""
    name: str
    description: str
    triggers: List[Dict[str, Any]]
    processors: List[Dict[str, Any]]
    outputs: List[Dict[str, Any]]
    dependencies: Dict[str, List[str]]
    docker_services: List[str]
    environment_vars: Dict[str, str]

class DialogChainProjectGenerator:
    """Main project generator class"""

    def __init__(self, project_name: str, template_name: str = "basic"):
        self.project_name = project_name
        self.template_name = template_name
        self.project_path = Path.cwd() / project_name
        self.templates = self._load_templates()

    def _load_templates(self) -> Dict[str, ProjectTemplate]:
        """Load predefined project templates"""
        return {
            "basic": ProjectTemplate(
                name="basic",
                description="Simple HTTP to file pipeline",
                triggers=[
                    {
                        "id": "http_input",
                        "type": "http",
                        "port": 8080,
                        "path": "/webhook",
                        "enabled": True
                    }
                ],
                processors=[
                    {
                        "id": "main_processor",
                        "type": "python",
                        "script": "processors/main.py",
                        "parallel": True,
                        "timeout": 5000,
                        "retry": 2,
                        "dependencies": []
                    }
                ],
                outputs=[
                    {
                        "id": "file_output",
                        "type": "file",
                        "path": "logs/output.log",
                        "format": "json"
                    }
                ],
                dependencies={
                    "python": ["pyyaml", "requests", "fastapi", "uvicorn"],
                    "system": ["curl", "git"]
                },
                docker_services=["app"],
                environment_vars={
                    "LOG_LEVEL": "INFO",
                    "ENVIRONMENT": "development"
                }
            ),

            "security": ProjectTemplate(
                name="security",
                description="AI-powered security monitoring system",
                triggers=[
                    {
                        "id": "camera_feed",
                        "type": "http",
                        "port": 8080,
                        "path": "/camera/frame",
                        "enabled": True
                    },
                    {
                        "id": "motion_sensor",
                        "type": "mqtt",
                        "broker": "mqtt://localhost:1883",
                        "topic": "sensors/motion",
                        "enabled": True
                    }
                ],
                processors=[
                    {
                        "id": "object_detection",
                        "type": "python",
                        "script": "processors/yolo_detect.py",
                        "parallel": True,
                        "timeout": 5000,
                        "retry": 2,
                        "dependencies": [],
                        "environment": {
                            "MODEL_PATH": "/models/yolov8n.pt",
                            "CONFIDENCE_THRESHOLD": "0.6"
                        }
                    },
                    {
                        "id": "threat_analysis",
                        "type": "go",
                        "binary": "./processors/threat-analyzer",
                        "args": ["--confidence=0.7"],
                        "parallel": False,
                        "timeout": 2000,
                        "retry": 1,
                        "dependencies": ["object_detection"]
                    }
                ],
                outputs=[
                    {
                        "id": "security_alert",
                        "type": "email",
                        "smtp": "smtp://localhost:587",
                        "to": ["security@company.com"],
                        "condition": "threat_level > 0.8"
                    },
                    {
                        "id": "dashboard_update",
                        "type": "websocket",
                        "url": "ws://dashboard:3000/alerts",
                        "batch_size": 10
                    }
                ],
                dependencies={
                    "python": ["ultralytics", "opencv-python", "numpy", "torch"],
                    "go": ["github.com/gorilla/websocket"],
                    "system": ["curl", "git", "docker"]
                },
                docker_services=["app", "mqtt", "redis"],
                environment_vars={
                    "MODEL_PATH": "/models/yolov8n.pt",
                    "MQTT_BROKER": "mqtt://mqtt:1883",
                    "REDIS_URL": "redis://redis:6379"
                }
            ),

            "iot": ProjectTemplate(
                name="iot",
                description="High-throughput IoT data processing pipeline",
                triggers=[
                    {
                        "id": "sensor_data",
                        "type": "mqtt",
                        "broker": "mqtt://iot-broker:1883",
                        "topic": "sensors/+/data",
                        "enabled": True
                    }
                ],
                processors=[
                    {
                        "id": "data_validation",
                        "type": "rust_wasm",
                        "wasm": "processors/validator.wasm",
                        "parallel": True,
                        "timeout": 1000,
                        "retry": 0,
                        "dependencies": []
                    },
                    {
                        "id": "anomaly_detection",
                        "type": "python",
                        "script": "processors/anomaly_detector.py",
                        "parallel": True,
                        "timeout": 3000,
                        "retry": 1,
                        "dependencies": ["data_validation"]
                    }
                ],
                outputs=[
                    {
                        "id": "database_storage",
                        "type": "database",
                        "connection": "postgresql://user:pass@postgres:5432/iot",
                        "table": "sensor_readings",
                        "batch_size": 1000
                    }
                ],
                dependencies={
                    "python": ["scikit-learn", "pandas", "numpy"],
                    "rust": ["serde", "wasm-bindgen"],
                    "system": ["docker", "postgresql-client"]
                },
                docker_services=["app", "postgres", "mqtt"],
                environment_vars={
                    "DATABASE_URL": "postgresql://iot:password@postgres:5432/iot",
                    "MQTT_BROKER": "mqtt://mqtt:1883"
                }
            )
        }

    def generate_project(self) -> None:
        """Generate complete project structure"""
        print(f"🚀 Generating DialogChain project: {self.project_name}")

        if self.template_name not in self.templates:
            raise ValueError(f"Template '{self.template_name}' not found")

        template = self.templates[self.template_name]

        # Create project directory
        self.project_path.mkdir(parents=True, exist_ok=True)

        # Generate all components
        self._create_directory_structure()
        self._generate_pipeline_config(template)
        self._generate_processors(template)
        self._generate_docker_files(template)
        self._generate_scripts(template)
        self._generate_requirements(template)
        self._create_gitignore()
        self._create_readme(template)

        print(f"✅ Project '{self.project_name}' generated successfully!")
        self._show_next_steps()

    def _create_directory_structure(self) -> None:
        """Create directory structure"""
        directories = [
            "processors", "scripts", "configs", "logs", "cache",
            "models", "data", "tests", "docs"
        ]

        for directory in directories:
            (self.project_path / directory).mkdir(parents=True, exist_ok=True)

        print("📁 Directory structure created")

    def _generate_pipeline_config(self, template: ProjectTemplate) -> None:
        """Generate main pipeline configuration"""
        config = {
            "name": self.project_name,
            "version": "1.0.0",
            "description": template.description,
            "triggers": template.triggers,
            "processors": template.processors,
            "outputs": template.outputs,
            "settings": {
                "performance": {
                    "max_concurrent": 10,
                    "buffer_size": 1000
                },
                "monitoring": {
                    "enabled": True,
                    "log_level": "INFO"
                },
                "security": {
                    "require_auth": False,
                    "rate_limit": 1000
                }
            }
        }

        with open(self.project_path / "pipeline.yaml", "w") as f:
            yaml.dump(config, f, default_flow_style=False, indent=2)

        print("⚙️  Pipeline configuration generated")

    def _generate_processors(self, template: ProjectTemplate) -> None:
        """Generate processor implementations"""
        for processor in template.processors:
            processor_type = processor.get("type", "python")
            processor_id = processor["id"]

            if processor_type == "python":
                self._create_python_processor(processor_id)
            elif processor_type == "go":
                self._create_go_processor(processor_id)
            elif processor_type == "rust_wasm":
                self._create_rust_processor(processor_id)

        print("🔧 Processors generated")

    def _create_python_processor(self, processor_id: str) -> None:
        """Create Python processor"""
        content = f'''#!/usr/bin/env python3
"""
{processor_id.replace("_", " ").title()} Processor
"""

import json
import sys
import logging
from datetime import datetime
from typing import Dict, Any

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def process_data(data: Dict[str, Any]) -> Dict[str, Any]:
    """Main processing function"""
    try:
        # Add metadata
        data["processed_at"] = datetime.utcnow().isoformat()
        data["processor"] = "{processor_id}"
        
        # TODO: Implement your processing logic here
        if "message" in data:
            data["message"] = data["message"].upper()
            logger.info(f"Processed message: {{data['message']}}")
        
        return data
        
    except Exception as e:
        logger.error(f"Processing failed: {{str(e)}}")
        return {{
            "error": str(e),
            "processor": "{processor_id}",
            "original_data": data
        }}

def main():
    try:
        input_data = json.load(sys.stdin)
        result = process_data(input_data)
        json.dump(result, sys.stdout, indent=2)
    except Exception as e:
        json.dump({{"error": str(e)}}, sys.stdout)
        sys.exit(1)

if __name__ == "__main__":
    main()
'''

        script_path = self.project_path / "processors" / f"{processor_id}.py"
        with open(script_path, "w") as f:
            f.write(content)

        os.chmod(script_path, 0o755)

    def _create_go_processor(self, processor_id: str) -> None:
        """Create Go processor"""
        content = f'''package main

import (
    "encoding/json"
    "fmt"
    "os"
    "time"
)

type ProcessorData struct {{
    ProcessedAt string                 `json:"processed_at"`
    Processor   string                 `json:"processor"`
    Data        map[string]interface{{}} `json:",inline"`
}}

func main() {{
    var input map[string]interface{{}}
    
    if err := json.NewDecoder(os.Stdin).Decode(&input); err != nil {{
        fmt.Fprintf(os.Stderr, "Error reading input: %v\\n", err)
        os.Exit(1)
    }}
    
    result := ProcessorData{{
        ProcessedAt: time.Now().UTC().Format(time.RFC3339),
        Processor:   "{processor_id}",
        Data:        input,
    }}
    
    // TODO: Implement your processing logic here
    if msg, ok := input["message"].(string); ok {{
        result.Data["message"] = fmt.Sprintf("Processed by Go: %s", msg)
    }}
    
    if err := json.NewEncoder(os.Stdout).Encode(result); err != nil {{
        fmt.Fprintf(os.Stderr, "Error encoding output: %v\\n", err)
        os.Exit(1)
    }}
}}
'''

        processor_dir = self.project_path / "processors" / processor_id
        processor_dir.mkdir(exist_ok=True)

        with open(processor_dir / "main.go", "w") as f:
            f.write(content)

        # Create go.mod
        go_mod = f'''module {self.project_name}/processors/{processor_id}

go 1.21
'''

        with open(processor_dir / "go.mod", "w") as f:
            f.write(go_mod)

    def _create_rust_processor(self, processor_id: str) -> None:
        """Create Rust WASM processor stub"""
        processor_dir = self.project_path / "processors" / f"{processor_id}_wasm"
        processor_dir.mkdir(exist_ok=True)

        # Create placeholder files
        with open(processor_dir / "README.md", "w") as f:
            f.write(f"# {processor_id} Rust WASM Processor\\n\\nTo be implemented...")

    def _generate_docker_files(self, template: ProjectTemplate) -> None:
        """Generate Docker configuration"""
        dockerfile = f'''FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \\
    curl build-essential && \\
    rm -rf /var/lib/apt/lists/*

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Make scripts executable
RUN find processors -name "*.py" -exec chmod +x {{}} \\;

EXPOSE 8080
CMD ["python", "-m", "dialogchain.runner", "pipeline.yaml"]
'''

        with open(self.project_path / "Dockerfile", "w") as f:
            f.write(dockerfile)

        # Docker Compose
        compose = f'''version: '3.8'

services:
  {self.project_name}:
    build: .
    ports:
      - "8080:8080"
    environment:
      - ENVIRONMENT=development
    volumes:
      - ./logs:/app/logs
      - ./data:/app/data
    depends_on:
      - redis

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
'''

        with open(self.project_path / "docker-compose.yml", "w") as f:
            f.write(compose)

        print("🐳 Docker configuration generated")

    def _generate_scripts(self, template: ProjectTemplate) -> None:
        """Generate development scripts"""
        dev_script = f'''#!/bin/bash
set -e

PROJECT_NAME="{self.project_name}"

case "${{1:-help}}" in
    "setup")
        echo "Setting up development environment..."
        python3 -m venv venv
        source venv/bin/activate
        pip install -r requirements.txt
        echo "Setup complete!"
        ;;
    "start")
        echo "Starting development environment..."
        docker-compose up -d
        echo "Services started. Access at http://localhost:8080"
        ;;
    "stop")
        echo "Stopping services..."
        docker-compose down
        ;;
    "logs")
        docker-compose logs -f
        ;;
    "test")
        echo "Running tests..."
        python -m pytest tests/ || echo "No tests found"
        ;;
    *)
        echo "Usage: $0 {{setup|start|stop|logs|test}}"
        ;;
esac
'''

        scripts_dir = self.project_path / "scripts"
        script_path = scripts_dir / "dev.sh"
        with open(script_path, "w") as f:
            f.write(dev_script)

        os.chmod(script_path, 0o755)
        print("📜 Development scripts generated")

    def _generate_requirements(self, template: ProjectTemplate) -> None:
        """Generate requirements.txt"""
        requirements = ["pyyaml>=6.0", "requests>=2.31.0"]
        requirements.extend(template.dependencies.get("python", []))

        with open(self.project_path / "requirements.txt", "w") as f:
            f.write("\\n".join(requirements))

        print("📦 Requirements file generated")

    def _create_gitignore(self) -> None:
        """Create .gitignore file"""
        gitignore_content = '''# DialogChain
logs/
cache/
*.log

# Python
__pycache__/
*.py[cod]
venv/
.env

# Go
*.exe
*.dll
*.so
*.dylib

# Node.js
node_modules/

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
'''

        with open(self.project_path / ".gitignore", "w") as f:
            f.write(gitignore_content)

    def _create_readme(self, template: ProjectTemplate) -> None:
        """Create README.md"""
        readme_content = f'''# {self.project_name.replace("_", " ").title()}

{template.description}

## Quick Start

1. **Setup:**
   ```bash
   ./scripts/dev.sh setup
   ```

2. **Start development:**
   ```bash
   ./scripts/dev.sh start
   ```

3. **Test the pipeline:**
   ```bash
   curl -X POST http://localhost:8080/webhook \\
     -H "Content-Type: application/json" \\
     -d '{{"message": "Hello DialogChain!"}}'
   ```

## Project Structure

```
{self.project_name}/
├── pipeline.yaml          # Main configuration
├── processors/            # Data processors
├── scripts/               # Development tools
├── configs/               # Environment configs
├── logs/                  # Application logs
└── tests/                 # Test suites
```

## Development

- `./scripts/dev.sh setup` - Initial setup
- `./scripts/dev.sh start` - Start services
- `./scripts/dev.sh stop` - Stop services
- `./scripts/dev.sh logs` - View logs

## Configuration

Edit `pipeline.yaml` to customize your pipeline behavior.

For more information, visit: https://dialogchain.io/docs
'''

        with open(self.project_path / "README.md", "w") as f:
            f.write(readme_content)

    def _show_next_steps(self) -> None:
        """Show next steps to user"""
        print("\\n📋 Next steps:")
        print(f"  1. cd {self.project_path}")
        print("  2. ./scripts/dev.sh setup")
        print("  3. ./scripts/dev.sh start")
        print("  4. Test: curl -X POST http://localhost:8080/webhook -d '{\"message\":\"test\"}'")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python project_generator.py <project_name> [template_name]")
        sys.exit(1)

    project_name = sys.argv[1]
    template_name = sys.argv[2] if len(sys.argv) > 2 else "basic"

    generator = DialogChainProjectGenerator(project_name, template_name)
    generator.generate_project()