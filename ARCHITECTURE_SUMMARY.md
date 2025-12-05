# Core Gateway - Architecture Summary

## 📋 Overview

This document provides a comprehensive overview of the Core Gateway microservices architecture, complementing the sequence diagrams in `core-gateway-architecture.drawio`.

## 🏗️ System Architecture

### Infrastructure Stack

```
Internet
    ↓
Nginx (Reverse Proxy) :80, :443
    ↓
Kong API Gateway :8000 (Proxy), :8001 (Admin)
    ↓
┌─────────────────┬─────────────────┬─────────────────┐
│  Backend-MD     │  Backend-RYO    │  Service-Meta   │
│  (NestJS)       │  (Django)       │  (NestJS)       │
│  :9001          │  :9002          │  :9003          │
└─────────────────┴─────────────────┴─────────────────┘
         ↓                ↓                  ↓
┌─────────────────┬─────────────────┬─────────────────┐
│  PostgreSQL     │  Redis          │  Oracle DB      │
│  :5432          │  :6379          │  :1521          │
└─────────────────┴─────────────────┴─────────────────┘
```

### Supporting Services
- **Prometheus** (:9090) - Metrics collection
- **Grafana** (:3000) - Metrics visualization
- **AWS S3** - File storage (images, documents)

---

## 🔐 1. Authentication Flow

### Supported Services
- **Backend-MD**: JWT-based authentication with PostgreSQL
- **Backend-RYO**: JWT-based authentication with Django
- **Service-Meta**: JWT-based authentication with PostgreSQL

### Flow Summary
```
Client → Nginx → Kong → Backend Service
                  ↓
            Rate Limiting (60/min)
            CORS
            Request Size Limit (128MB)
                  ↓
            Backend validates credentials
                  ↓
            Generate JWT Token
                  ↓
            Return Token + User Data
```

### JWT Payload (Backend-MD)
```json
{
  "id": "user_id",
  "username": "username",
  "email": "user@example.com",
  "user_role_id": 1,
  "area": "area_code",
  "region": "region_code",
  "iat": 1234567890,
  "exp": 1234567890
}
```

---

## 📱 2. Activity Submission Flow (Backend-MD)

### Key Features
- **Async Processing**: Uses BullMQ with Redis
- **Multiple Activity Types**: SIO, SOG, Branch, Program
- **File Upload**: AWS S3 integration
- **Real-time Notifications**: WebSocket support
- **Retry Mechanism**: 5 attempts with exponential backoff

### Flow Summary
```
1. Client submits activity + files
2. Kong validates JWT and applies plugins
3. Backend uploads files to S3
4. Add job to BullMQ queue (stored in Redis)
5. Return 202 Accepted with Job ID
6. [Async] Queue Processor polls job from Redis
7. Process activity data
8. Save to PostgreSQL
9. Create notification
10. Broadcast via WebSocket
11. Update job status in Redis
```

### Activity Types & Queues
- `activityQueue` - General activities
- `activitySioQueue` - Sell In Order activities
- `activitySogQueue` - Sell Out Good activities
- `activityBranchQueue` - Branch-specific activities
- `activityProgramQueue` - Program-related activities

### Queue Configuration
```typescript
{
  attempts: 5,
  backoff: {
    type: 'exponential',
    delay: 5000 // 5 seconds initial delay
  },
  removeOnComplete: true,
  removeOnFail: false
}
```

---

## 🎫 3. Voucher Redemption Flow (Backend-RYO)

### Business Process
1. **Retailer Registration** → Photo verification by Office
2. **Office Approval** → Voucher generation
3. **Wholesaler Redemption** → Validate voucher
4. **Transaction Submission** → Record sales
5. **Reimbursement Request** → Office approval

### Flow Summary

#### Phase 1: Voucher Redemption
```
1. Wholesaler submits voucher code + ws_id
2. Validate:
   - Voucher not already redeemed
   - Voucher not expired
   - Retailer photos verified
   - Wholesaler ID matches retailer's wholesaler
3. Create VoucherRedeem record
4. Mark voucher as redeemed
5. Return 201 Created
```

#### Phase 2: Transaction Submission
```
1. Wholesaler submits transaction details:
   - voucher_code
   - items (array)
   - total_price
   - total_price_after_discount
   - transaction image
2. Create WholesaleTransaction
3. Create WholesaleTransactionDetail for each item
4. Return 200 OK
```

#### Phase 3: Reimbursement
```
1. Wholesaler submits voucher codes for reimbursement
2. Validate vouchers are redeemed
3. Create Reimburse records
4. Office reviews and approves/rejects
5. Update reimbursement status
```

### Validation Rules
- ✅ Voucher must not be redeemed
- ✅ Voucher must not be expired
- ✅ Retailer photos must be verified and approved
- ✅ Wholesaler ID must match retailer's assigned wholesaler

---

## 📊 4. Master Data Flow (Service-Meta)

### Data Sources
Oracle Database Views (38+ entities):
- **Customers**: `APPS.XTD_AR_CUSTOMERS_V`
- **Branches**: `APPS.XTD_INV_BRANCHES_V`
- **Regions**: `APPS.XTD_INV_REGION_V`
- **Employees**: `APPS.XTD_HR_EMPLOYEES_V`
- **GeoTree**: `APPS.XTD_INV_GEOTREE_V`
- **Warehouses**: `APPS.XTD_INV_WAREHOUSES_V`
- **Items, Sales Orders, AR/AP, Pricing, and more...**

### Flow Summary
```
1. Client requests master data
2. Kong routes to service-meta
3. Check Redis cache
4. [Cache Hit] → Return cached data
5. [Cache Miss] → Query Oracle view
6. Store result in Redis with TTL
7. Return data to client
```

### Caching Strategy
- **Cache Layer**: Redis
- **TTL**: Configurable per entity
- **Auto-refresh**: On cache miss
- **Supports**: Pagination, date filters, search

### API Pattern
```
GET /api/v1/{entity}                 - Get all with pagination
GET /api/v1/{entity}/by-date         - Filter by date
GET /api/v1/{entity}/{id}            - Get by ID/code
```

---

## 🔌 API Gateway (Kong) Configuration

### Routes
- `/md-backend-api` → `http://backend-md:9001`
- `/ryo-api` → `http://backend-ryo:9002`
- `/service-meta` → `http://service-meta:9003`

### Applied Plugins (All Services)
```yaml
plugins:
  - prometheus          # Metrics export
  - rate-limiting:
      minute: 60        # 60 requests per minute
  - cors               # Cross-origin support
  - request-size-limiting:
      allowed_payload_size: 128  # 128MB max
```

### Features
- ✅ Declarative configuration (`kong.yml`)
- ✅ DB-less mode (faster, simpler)
- ✅ Health checks
- ✅ Auto-reconnection
- ✅ Prometheus metrics export

---

## 📈 Monitoring & Observability

### Prometheus Scrape Targets
```yaml
scrape_configs:
  - job_name: 'kong'
    targets: ['kong:8001']
  - job_name: 'backend-md'
    targets: ['backend-md:9001']
  - job_name: 'backend-ryo'
    targets: ['backend-ryo:9002']
  - job_name: 'service-meta'
    targets: ['service-meta:9003']
```

### Grafana Dashboards
- **Kong Gateway Metrics**: Request rate, latency, errors
- **Backend Performance**: Response times, throughput
- **Database Metrics**: Connection pools, query performance
- **Queue Metrics**: Job processing, failure rates

### Access Points
- **Prometheus**: `http://api.kcsi.id:9090`
- **Grafana**: `http://api.kcsi.id/grafana/`
- **Kong Admin**: `http://api.kcsi.id/kong-4dm1n/` (restricted)

---

## 🗂️ Backend Services Deep Dive

### Backend-MD (NestJS) - Port 9001

**Purpose**: Sales force automation and field operations

**Key Modules**:
- **Activity**: Field activities (SIO, SOG, Branch, Program)
- **Call Plan**: Visit scheduling and planning
- **Outlet**: Outlet/customer management
- **Survey**: Field surveys
- **Batch**: Batch operations and targets
- **Dashboard**: Analytics and reports
- **Absensi**: Attendance tracking
- **Reimburse BBM**: Fuel reimbursement
- **User/Auth**: User management and authentication
- **Notifications**: Push notifications via WebSocket

**Tech Stack**:
- NestJS v10
- Drizzle ORM (PostgreSQL)
- BullMQ (Redis queues)
- Socket.IO (WebSocket)
- AWS S3 (file storage)
- JWT authentication

**Database**: PostgreSQL with 51+ migrations

---

### Backend-RYO (Django) - Port 9002

**Purpose**: Marketing campaign and voucher management

**Key Apps**:
- **API**: REST API endpoints
- **Office**: Admin operations and verification
- **Retailer**: Retailer registration and management
- **Wholesales**: Wholesaler operations and voucher redemption

**Key Features**:
- Retailer registration with photo verification
- Voucher generation and redemption
- Transaction recording
- Reimbursement workflow
- Geographic data (provinsi, kota, kecamatan, kelurahan)
- WhatsApp notifications (Twilio integration)

**Tech Stack**:
- Django + DRF
- PostgreSQL
- JWT authentication
- drf-yasg (Swagger)
- Twilio (WhatsApp API)

**Models**:
- User, Retailer, RetailerPhoto, Voucher
- Wholesale, VoucherRedeem, WholesaleTransaction
- Item, Reimburse, Kodepos
- VoucherLimit, VoucherProject, VoucherRetailerDiscount

---

### Service-Meta (NestJS) - Port 9003

**Purpose**: Master data provider from Oracle EBS

**Key Modules**:
- Customer, Branch, Region, Employee
- GeoTree, Warehouse, Organization, Position
- Item List, Sales Item, Salesman
- Province, City, District, Sub-district
- AR/AP Terms, Invoice Types, Tax
- Price List, Payment/Receipt Methods
- Currency, Transaction Types
- COA Expense, Sales Activities
- Purchase Orders, Sales Order Stock
- FPPR (various types), Summary FPPR
- MTL Transaction Lists

**Tech Stack**:
- NestJS v10
- TypeORM + Prisma
- Oracle Database (11g+)
- Oracle Instant Client
- Redis caching
- RabbitMQ (message queue)
- JWT authentication
- Swagger documentation

**Features**:
- Connection pooling
- Auto-reconnection
- Redis caching with TTL
- Pagination support
- Date-based filtering
- Comprehensive error handling

---

## 🔄 Data Flow Patterns

### 1. Synchronous Request-Response
```
Client → Nginx → Kong → Backend → Database → Response
```
**Use Cases**: Authentication, data retrieval, simple operations

### 2. Asynchronous Queue Processing
```
Client → Backend → Queue (Redis) → [Async] Processor → Database
                 ↓
            202 Accepted (Job ID)
```
**Use Cases**: File uploads, heavy processing, batch operations

### 3. Real-time Notifications
```
Event → Backend → WebSocket Gateway → Connected Clients
```
**Use Cases**: Activity updates, notifications, live updates

### 4. Cached Data Retrieval
```
Client → Backend → Redis Cache → [Hit] Return
                              ↓ [Miss]
                         Oracle DB → Cache → Return
```
**Use Cases**: Master data, frequently accessed data

---

## 🛡️ Security Measures

### Network Security
- **Nginx**: SSL/TLS termination, IP filtering
- **Kong Admin API**: Restricted to private networks only
- **Firewall Rules**: VPC, private networks only

### Application Security
- **JWT Authentication**: All protected endpoints
- **Rate Limiting**: 60 requests/minute per service
- **Request Size Limits**: 128MB max payload
- **CORS**: Configured per service
- **Password Hashing**: bcrypt
- **SQL Injection Protection**: ORM usage (Drizzle, TypeORM, Django ORM)

### File Security
- **AWS S3**: Private buckets with IAM policies
- **File Validation**: Type and size checks
- **Secure URLs**: Pre-signed URLs for downloads

---

## 🚀 Deployment

### Docker Compose Services
```yaml
services:
  - kong-database      # PostgreSQL for Kong
  - kong-migrations    # Kong schema setup
  - kong               # API Gateway
  - backend-md         # NestJS backend
  - backend-ryo        # Django backend
  - service-meta       # Meta service
  - prometheus         # Metrics
  - grafana            # Visualization
```

### Environment Variables
Each service requires:
- Database connection strings
- Redis connection (for backends using cache/queue)
- JWT secrets
- AWS credentials (for S3)
- Oracle connection (for service-meta)

### Healthchecks
```bash
# Kong
curl http://localhost:8001/status

# Backend-MD
curl http://localhost:9001/health

# Backend-RYO
curl http://localhost:9002/metrics

# Service-Meta
curl http://localhost:9003/api/health
```

---

## 📝 API Documentation

### Swagger/OpenAPI
- **Backend-RYO**: `http://api.kcsi.id/ryo-api/docs/`
- **Service-Meta**: `http://localhost:9003/docs`

### Interactive Testing
All Swagger UIs support:
- Bearer token authentication
- Try-it-out functionality
- Request/response examples
- Schema documentation

---

## 🔧 Development Workflow

### Local Development
```bash
# Backend-MD
cd backend-md
yarn install
yarn dev

# Backend-RYO
cd backend-ryo
pip install -r requirements.txt
python manage.py runserver

# Service-Meta
cd service-meta
yarn install
yarn dev
```

### Database Migrations
```bash
# Backend-MD (Drizzle)
npx drizzle-kit generate
yarn migrate

# Backend-RYO (Django)
python manage.py makemigrations
python manage.py migrate

# Service-Meta (TypeORM)
yarn typeorm migration:generate
yarn typeorm migration:run
```

---

## 📊 Diagram Reference

The `core-gateway-architecture.drawio` file contains 5 detailed diagrams:

1. **Authentication Flow** - JWT-based login process
2. **Activity Submission Flow** - Queue-based async processing
3. **Voucher Redemption Flow** - Complete voucher lifecycle
4. **Master Data Flow** - Cached Oracle data retrieval
5. **System Architecture Overview** - Complete infrastructure view

---

## 🤝 Integration Points

### Backend-MD ↔ Service-Meta
Backend-MD can call Service-Meta for master data (customers, branches, regions, employees)

### Backend-RYO ↔ External Services
- **Twilio**: WhatsApp notifications for voucher delivery
- **AWS S3**: Photo storage for retailer verification

### All Services ↔ Kong
All external API calls route through Kong Gateway for:
- Unified entry point
- Rate limiting
- Metrics collection
- CORS handling

---

## 📞 Support & Resources

### Key Technologies Documentation
- [NestJS](https://docs.nestjs.com/)
- [Django](https://docs.djangoproject.com/)
- [Kong Gateway](https://docs.konghq.com/)
- [PostgreSQL](https://www.postgresql.org/docs/)
- [Redis](https://redis.io/documentation)
- [Oracle Database](https://docs.oracle.com/database/)
- [BullMQ](https://docs.bullmq.io/)

### Production URLs
- Main API: `https://api.kcsi.id`
- Grafana: `https://api.kcsi.id/grafana/`
- Prometheus: `https://api.kcsi.id:9090`

---

**Generated**: October 2025  
**Version**: 1.0  
**Author**: AI Architecture Analysis

