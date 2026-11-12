# execution-service

Microsserviço de **execução** da Oficina Mecânica (Tech Challenge FIAP, Fase 4).
Extraído do monolito [`api`](https://github.com/FIAP-15SOAT-GabrielHelton/api) conforme a RFC-005.

## Responsabilidade

- Coloca a OS na fila ao receber o evento `work_order.approved`.
- Expõe a fila e o andamento da execução para os funcionários (`/api/v1/executions`).
- Publica `execution.started` e `execution.completed` para os outros serviços.

Banco próprio em **MongoDB**: um documento por OS, com os serviços embutidos.
A comunicação com os outros serviços é só por eventos no RabbitMQ (exchange de tópico `oficina.events`).

## Endpoints

| Método | Caminho | O que faz |
| :--- | :--- | :--- |
| GET | `/api/v1/executions?status=queued` | Fila de execução, mais antigas primeiro |
| GET | `/api/v1/executions/:work_order_id` | Detalhe de uma execução |
| PATCH | `/api/v1/executions/:work_order_id/start` | Inicia a execução |
| PATCH | `/api/v1/executions/:work_order_id/items/:line_item_id/start` | Inicia um serviço |
| PATCH | `/api/v1/executions/:work_order_id/items/:line_item_id/finish` | Finaliza um serviço |
| PATCH | `/api/v1/executions/:work_order_id/complete` | Conclui (todos os serviços finalizados) |

## Executar localmente

```bash
cp .env.example .env
docker compose up          # API em http://localhost:3002, RabbitMQ em http://localhost:15674
```

O serviço `consumer` do compose (`bin/consumer`) é o processo que escuta os eventos.

## Testes

```bash
docker compose run --rm -e RAILS_ENV=test -e COVERAGE=1 \
  -e MONGODB_URI=mongodb://mongo:27017/execution_service_test web bundle exec rspec
```

## Pendências

- Manifestos `k8s/`, `infra/` e os workflows de deploy ainda são cópias do `api` e precisam ser adaptados.
- `spec/swagger_helper.rb` ainda descreve recursos do monolito; o Swagger precisa ser refeito.
