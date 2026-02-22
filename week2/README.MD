# 2주차 - docker-compose로 멀티 컨테이너 앱 구성

## 학습 내용
- docker-compose 구조 및 핵심 문법 이해
- 멀티 컨테이너 간 네트워크 통신 원리
- 볼륨을 이용한 데이터 영속성 확보
- healthcheck + depends_on 조합으로 안정적인 기동 순서 제어

**상세 내용 정리** - [notion-link](https://www.notion.so/Docker-30718afea172800c92b6e409a1ce1158?source=copy_link)

## 테스트 환경
- OS: Ubuntu 22.04 (VM)
- Docker: 27.x
- docker compose: v2 (플러그인 방식, `docker compose` 명령어 사용)
- 앱 컨테이너: `nginx:alpine` (Spring Boot 없이 구조 파악 목적)
- DB 컨테이너: `postgis/postgis:15-3.3` (PostGIS 포함)

## 파일 설명
| 파일 | 설명 |
|------|------|
| `docker-compose.yml` | 메인 compose 파일 - app + db 서비스 정의 |
| `init.sql` | DB 초기화 SQL - 컨테이너 최초 기동 시 자동 실행 |

## 실험 결과

### 1. 컨테이너 기동 확인
```bash
docker compose ps
```
| 서비스 | 상태 | 포트 |
|--------|------|------|
| app | running | 0.0.0.0:8080→80/tcp |
| db | running (healthy) | 5432/tcp |

### 2. 컨테이너 간 통신 확인
```bash
# app 컨테이너에서 db 서비스 이름으로 DNS 해석
docker compose exec app sh -c "nslookup db"
```
- `db` → `172.18.0.x` 자동 해석됨
- 같은 `app-network` 브리지 네트워크 내에서 **서비스 이름 = DNS 호스트명**

### 3. 볼륨 영속성 확인
| 시나리오 | 결과 |
|----------|------|
| `docker compose down` 후 재기동 | 데이터 유지 ✅ |
| `docker compose down -v` 후 재기동 | init.sql로 재생성 ✅ |

### 4. healthcheck 동작 확인
- `depends_on` 단독 사용: DB 컨테이너 **시작** 시점만 보장, 준비 완료 보장 안 됨
- `condition: service_healthy` 추가: pg_isready 통과 후에만 app 기동 → 실무 표준

## 핵심 개념
- 같은 네트워크의 컨테이너끼리는 **서비스 이름으로 통신** (IP 불필요)
- `volumes: 이름:/경로` → Docker 관리 볼륨, 컨테이너 삭제해도 데이터 유지
- healthcheck + condition 조합으로 기동 순서 안정화
- Spring Boot 적용 시 `SPRING_DATASOURCE_URL=jdbc:postgresql://db:5432/myapp` 그대로 사용 가능

## 주요 명령어
```bash
# 실행 / 중지
docker compose up -d           # 백그라운드 실행
docker compose down            # 중지 + 컨테이너 삭제 (볼륨 유지)
docker compose down -v         # 볼륨까지 삭제

# 확인
docker compose ps              # 서비스 상태 확인
docker compose logs -f app     # 실시간 로그
docker compose logs db         # DB 로그

# 접속
docker compose exec db psql -U myuser -d myapp   # DB 접속
docker compose exec app sh                        # app 컨테이너 셸

# 재시작
docker compose restart app     # 특정 서비스만 재시작
docker compose build           # 이미지 빌드만 (up 없이)
```

## DB 데이터 확인
```bash
docker compose exec db psql -U myuser -d myapp -c "SELECT * FROM users;"
```
```
 id |     name      |         created_at
----+---------------+----------------------------
  1 | DevOps Student | 2025-xx-xx xx:xx:xx
  2 | K8s Learner    | 2025-xx-xx xx:xx:xx
(2 rows)
```

## 다음 주차 예고
- 3주차: 실제 Spring Boot 앱 Dockerize + docker-compose로 배포
- 멀티스테이지 빌드 실전 적용 (1주차 이론 → 실제 jar 빌드)
- `.env` 파일로 환경변수 분리 관리
