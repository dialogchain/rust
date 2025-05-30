# DialogChain - Complete Installer Package

Ten pakiet zawiera kompletny system instalacji i generowania projektów DialogChain, podzielony na modularne komponenty dla łatwiejszego zarządzania i rozwoju.

## 📁 Struktura Pakietu

```
dialogchain-installer/
├── install.sh                 # Główny skrypt instalacyjny
├── modules/
│   ├── system_detection.sh    # Wykrywanie systemu
│   ├── dependencies.sh        # Instalacja zależności
│   └── cli_generator.sh       # Generator CLI
├── generators/
│   └── project_generator.py   # Generator projektów Python
├── scripts/
│   ├── dev-setup.sh           # Konfiguracja środowiska dev
│   ├── validate-project.sh    # Walidator projektów
│   ├── benchmark.sh           # Testy wydajnościowe
│   └── analyze-logs.sh        # Analiza logów
└── README.md                  # Ten plik
```

## 🚀 Szybka Instalacja

### Automatyczna instalacja (zalecana):
```bash
curl -sSL https://install.dialogchain.io | bash
```

### Ręczna instalacja:
```bash
git clone https://github.com/dialogchain/installer.git
cd installer
chmod +x install.sh
./install.sh
```

## 📋 Komponenty Systemu

### 1. **Główny Installer** (`install.sh`)
- Orkiestruje cały proces instalacji
- Ładuje moduły dynamicznie
- Obsługuje różne systemy operacyjne
- Zarządza zależnościami

**Kluczowe funkcje:**
- Wykrywanie systemu operacyjnego i architektury
- Instalacja zależności systemowych
- Konfiguracja środowisk programistycznych
- Tworzenie struktury katalogów
- Walidacja instalacji

### 2. **Moduł Wykrywania Systemu** (`modules/system_detection.sh`)
```bash
# Funkcje:
detect_system()           # Wykrywa OS, architekturę, menedżer pakietów
run_doctor_check()        # Sprawdza stan systemu
get_system_info()         # Zwraca informacje o systemie
```

**Obsługiwane systemy:**
- Linux (Ubuntu, CentOS, Fedora, Arch, openSUSE)
- macOS (z Homebrew)
- Windows (WSL/Git Bash)

### 3. **Moduł Zależności** (`modules/dependencies.sh`)
```bash
# Funkcje:
install_system_dependencies()  # Pakiety systemowe
install_rust()                 # Rust toolchain
install_go()                   # Go runtime
install_python_deps()          # Środowisko Python
install_node_deps()            # Środowisko Node.js
setup_docker()                 # Konfiguracja Docker
```

**Instalowane komponenty:**
- **Rust**: Główny runtime dla DialogChain
- **Python**: ML/AI processing
- **Go**: High-performance processors
- **Node.js**: API integrations
- **Docker**: Konteneryzacja

### 4. **Generator CLI** (`modules/cli_generator.sh`)
Tworzy główne narzędzie `dialogchain` z komendami:

```bash
dialogchain create <project>        # Nowy projekt
dialogchain init                    # Inicjalizacja w bieżącym katalogu
dialogchain validate <config>       # Walidacja konfiguracji
dialogchain dev <config>            # Tryb deweloperski
dialogchain templates               # Lista szablonów
dialogchain examples                # Przykłady konfiguracji
dialogchain doctor                  # Diagnostyka systemu
```

### 5. **Generator Projektów** (`generators/project_generator.py`)
Python module generujący kompletne projekty:

**Dostępne szablony:**
- **basic**: Prosty pipeline HTTP → plik
- **security**: System monitoringu AI
- **iot**: Przetwarzanie danych IoT
- **microservices**: Hub integracji mikroserwisów

**Generowane komponenty:**
- Konfiguracja pipeline (`pipeline.yaml`)
- Procesory w różnych językach
- Pliki Docker i Docker Compose
- Skrypty deweloperskie
- Dokumentacja
- Testy

## 💻 Szczegóły Implementacji

### Architektura Multi-językowa

**Rust (Core Engine):**
```rust
// Główny silnik wykonawczy
pub struct DialogChainEngine {
    pipelines: Arc<RwLock<HashMap<String, Pipeline>>>,
    metrics: Arc<RwLock<MetricsCollector>>,
    security_manager: SecurityManager,
}
```

**Python (ML/AI Processing):**
```python
# Przykład procesora Python
def process_data(data):
    data['processed_at'] = datetime.utcnow().isoformat()
    # Logika ML/AI
    return data
```

**Go (High-Performance):**
```go
// Procesor Go dla wysokiej wydajności
func (p *Processor) Process(input map[string]interface{}) ProcessorData {
    // Szybkie przetwarzanie danych
    return result
}
```

### Konfiguracja YAML DSL

Uproszczony format konfiguracji:

```yaml
name: "my_pipeline"
triggers:
  - type: http
    port: 8080
    path: /webhook
    
processors:
  - id: main_processor
    type: python
    script: "processors/main.py"
    parallel: true
    
outputs:
  - type: file
    path: "logs/output.log"
```

### Bezpieczeństwo

- **Zero-trust model**: Każda operacja wymaga autoryzacji
- **Process isolation**: Izolacja procesorów w kontenerach
- **Rate limiting**: Ochrona przed przeciążeniem
- **Audit logging**: Pełne śledzenie operacji

## 🛠️ Skrypty Narzędziowe

### Development Setup (`dev-setup.sh`)
```bash
./dev-setup.sh setup     # Konfiguracja środowiska
./dev-setup.sh test      # Uruchomienie testów
./dev-setup.sh clean     # Czyszczenie artefaktów
```

### Project Validator (`validate-project.sh`)
```bash
./validate-project.sh    # Walidacja struktury projektu
```

### Performance Benchmark (`benchmark.sh`)
```bash
TOTAL_REQUESTS=1000 ./benchmark.sh    # Test wydajności
```

### Log Analyzer (`analyze-logs.sh`)
```bash
./analyze-logs.sh analyze    # Analiza logów
./analyze-logs.sh tail       # Podgląd na żywo
./analyze-logs.sh clean      # Czyszczenie starych logów
```

## 🔄 Workflow Deweloperski

### 1. Instalacja
```bash
curl -sSL https://install.dialogchain.io | bash
```

### 2. Tworzenie Projektu
```bash
dialogchain create my-security-system --template security
cd ~/.dialogchain/projects/my-security-system
```

### 3. Konfiguracja Środowiska
```bash
./scripts/dev.sh setup
```

### 4. Rozwój
```bash
# Start środowiska deweloperskiego
./scripts/dev.sh start

# Edycja konfiguracji
vim pipeline.yaml

# Test
curl -X POST http://localhost:8080/webhook -d '{"message":"test"}'

# Walidacja
dialogchain validate pipeline.yaml
```

### 5. Deployment
```bash
# Build produkcyjny
./scripts/deploy.sh build

# Deploy
./scripts/deploy.sh deploy
```

## 🔧 Rozszerzanie Systemu

### Dodawanie Nowych Szablonów

1. **Rozszerzenie generatora Python:**
```python
# W project_generator.py
"custom_template": ProjectTemplate(
    name="custom_template",
    description="Mój niestandardowy szablon",
    triggers=[...],
    processors=[...],
    outputs=[...],
    dependencies={...}
)
```

2. **Dodanie przykładu YAML:**
```yaml
# W templates/examples/custom.yaml
name: "custom_pipeline"
description: "Niestandardowy pipeline"
# ... konfiguracja
```

### Tworzenie Niestandardowych Procesorów

**Python Processor:**
```python
#!/usr/bin/env python3
import json
import sys
from typing import Dict, Any

def process_data(data: Dict[str, Any]) -> Dict[str, Any]:
    # Twoja logika przetwarzania
    data['custom_field'] = 'processed'
    return data

def main():
    input_data = json.load(sys.stdin)
    result = process_data(input_data)
    json.dump(result, sys.stdout, indent=2)

if __name__ == "__main__":
    main()
```

**Go Processor:**
```go
package main

import (
    "encoding/json"
    "os"
)

type CustomProcessor struct {
    ID string
}

func (p *CustomProcessor) Process(input map[string]interface{}) map[string]interface{} {
    // Twoja logika przetwarzania
    input["custom_field"] = "processed"
    return input
}

func main() {
    var input map[string]interface{}
    json.NewDecoder(os.Stdin).Decode(&input)
    
    processor := &CustomProcessor{ID: "custom"}
    result := processor.Process(input)
    
    json.NewEncoder(os.Stdout).Encode(result)
}
```

### Integracja z Zewnętrznymi Systemami

**MQTT Integration:**
```yaml
triggers:
  - type: mqtt
    broker: "mqtt://broker:1883"
    topic: "devices/+/data"
    qos: 1
```

**Database Output:**
```yaml
outputs:
  - type: database
    connection: "postgresql://user:pass@db:5432/mydb"
    table: "events"
    batch_size: 1000
```

**WebSocket Streaming:**
```yaml
outputs:
  - type: websocket
    url: "ws://dashboard:3000/stream"
    batch_size: 10
```

## 📊 Monitoring i Observability

### Metryki Prometheus
```yaml
settings:
  monitoring:
    enabled: true
    metrics_port: 9100
    metrics_path: /metrics
```

**Dostępne metryki:**
- `pipeline_executions_total` - Liczba wykonań pipeline
- `processor_duration_seconds` - Czas wykonania procesorów
- `pipeline_errors_total` - Liczba błędów
- `active_connections` - Aktywne połączenia

### Distributed Tracing
```yaml
settings:
  tracing:
    enabled: true
    jaeger_endpoint: "http://jaeger:14268/api/traces"
    service_name: "dialogchain-pipeline"
```

### Health Checks
```yaml
settings:
  health:
    enabled: true
    port: 8090
    path: /health
    checks:
      - database
      - redis
      - external_apis
```

## 🔒 Bezpieczeństwo w Produkcji

### TLS/SSL Configuration
```yaml
settings:
  security:
    tls:
      enabled: true
      cert_file: "/certs/server.crt"
      key_file: "/certs/server.key"
      ca_file: "/certs/ca.crt"
```

### Authentication & Authorization
```yaml
settings:
  security:
    auth:
      type: "jwt"
      secret: "${JWT_SECRET}"
      expiry: "24h"
    rbac:
      enabled: true
      roles:
        - name: "admin"
          permissions: ["read", "write", "deploy"]
        - name: "user"
          permissions: ["read"]
```

### Rate Limiting
```yaml
settings:
  security:
    rate_limiting:
      enabled: true
      requests_per_minute: 1000
      burst_size: 100
      whitelist:
        - "192.168.1.0/24"
        - "10.0.0.0/8"
```

## 🚀 Deployment Strategies

### Docker Swarm
```bash
# Stack deployment
docker stack deploy -c docker-compose.prod.yml dialogchain

# Scaling
docker service scale dialogchain_app=3
```

### Kubernetes
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dialogchain
spec:
  replicas: 3
  selector:
    matchLabels:
      app: dialogchain
  template:
    metadata:
      labels:
        app: dialogchain
    spec:
      containers:
      - name: dialogchain
        image: dialogchain:latest
        ports:
        - containerPort: 8080
        env:
        - name: ENVIRONMENT
          value: "production"
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
```

### CI/CD Pipeline
```yaml
# .github/workflows/deploy.yml
name: Deploy DialogChain

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Validate project
      run: ./validate-project.sh
    - name: Run tests
      run: ./dev-setup.sh test

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
    - name: Build Docker image
      run: docker build -t dialogchain:${{ github.sha }} .
    - name: Push to registry
      run: docker push registry.com/dialogchain:${{ github.sha }}

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
    - name: Deploy to production
      run: |
        IMAGE_TAG=${{ github.sha }} ./scripts/deploy.sh deploy
```

## 🔍 Troubleshooting

### Częste Problemy

**1. Port już używany:**
```bash
# Sprawdź co używa portu
lsof -i :8080

# Zmień port w konfiguracji
sed -i 's/port: 8080/port: 8081/' pipeline.yaml
```

**2. Procesor nie działa:**
```bash
# Test procesora indywidualnie
echo '{"test": "data"}' | python processors/main.py

# Sprawdź logi
./analyze-logs.sh analyze

# Sprawdź uprawnienia
chmod +x processors/*.py
```

**3. Docker problemy:**
```bash
# Reset środowiska Docker
docker-compose down -v
./dev-setup.sh clean
./dev-setup.sh setup
```

**4. Wysokie zużycie pamięci:**
```yaml
# Ogranicz równoległość
settings:
  performance:
    max_concurrent: 5
    buffer_size: 100
```

### Debug Mode
```bash
# Uruchom z debugowaniem
LOG_LEVEL=DEBUG dialogchain dev pipeline.yaml

# Włącz verbose logging
dialogchain dev --verbose pipeline.yaml
```

### Performance Tuning
```yaml
settings:
  performance:
    # Procesor-specific tuning
    worker_threads: 8
    max_concurrent: 50
    buffer_size: 10000
    
    # Memory management
    memory_limit: "2Gi"
    gc_frequency: "30s"
    
    # Network tuning
    connection_pool_size: 100
    keep_alive_timeout: "60s"
```

## 📈 Skalowanie

### Horizontal Scaling
```yaml
# docker-compose.yml
services:
  dialogchain:
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
```

### Load Balancing
```yaml
# nginx.conf
upstream dialogchain {
    least_conn;
    server dialogchain1:8080;
    server dialogchain2:8080;
    server dialogchain3:8080;
}

server {
    listen 80;
    location / {
        proxy_pass http://dialogchain;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Database Optimization
```sql
-- Indeksy dla lepszej wydajności
CREATE INDEX CONCURRENTLY idx_pipeline_executions_status 
ON pipeline_executions(status);

CREATE INDEX CONCURRENTLY idx_processor_metrics_processor_id 
ON processor_metrics(processor_id, created_at);

-- Partycjonowanie tabeli
CREATE TABLE pipeline_executions_2024 
PARTITION OF pipeline_executions 
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
```

## 🤝 Społeczność i Wsparcie

### Contributing
1. Fork repository
2. Utwórz feature branch: `git checkout -b feature/my-feature`
3. Commit changes: `git commit -am 'Add my feature'`
4. Push branch: `git push origin feature/my-feature`
5. Utwórz Pull Request

### Zgłaszanie Błędów
Użyj GitHub Issues z następującymi informacjami:
- Wersja DialogChain
- System operacyjny
- Konfiguracja pipeline
- Kroki do odtworzenia błędu
- Logi błędów

### Dokumentacja
- [Oficjalna dokumentacja](https://dialogchain.io/docs)
- [API Reference](https://dialogchain.io/api)
- [Examples Repository](https://github.com/dialogchain/examples)
- [Community Discord](https://discord.gg/dialogchain)

## 📄 Licencja

DialogChain jest dostępny na licencji MIT. Zobacz plik [LICENSE](LICENSE) dla szczegółów.

---

**DialogChain Installer Package v1.0.0**  
Kompletne rozwiązanie do instalacji i zarządzania projektami DialogChain  
© 2024 DialogChain Team