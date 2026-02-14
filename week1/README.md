# 1주차 - Docker 심화



## 학습 내용
- Dockerfile 레이어 구조 이해
- 레이어 캐시 최적화
- 멀티스테이지 빌드

**상세 내용 정리** - [notion-link](https://www.notion.so/Docker-30718afea17280c49b91dfb6633b9c0b?source=copy_link)

## 테스트 환경
- OS: Ubuntu 22.04 (VM)
- Docker: 27.x
- 테스트용 더미 파일: `app/app.jar` (echo "fake springboot app" > app/app.jar)
- 실제 Spring Boot jar 아님 - 레이어/캐시 동작 원리 확인 목적
- 캐시 실험용: `dd if=/dev/urandom of=app/app.jar bs=1M count=5` (5MB 랜덤 파일)
- 이유: echo 더미는 크기 차이 없어 캐시 미감지

## 파일 설명
| 파일 | 설명 |
|------|------|
| `Dockerfile.v1` | 나쁜 예 - COPY 후 RUN (캐시 비효율) |
| `Dockerfile.v2` | 좋은 예 - RUN 후 COPY (캐시 최적화) |
| `Dockerfile.multi` | 멀티스테이지 - JDK 빌드 → JRE 실행 |

## 실험 결과

### 1. 최초 빌드 시간 비교
| 버전 | 빌드 시간 | 비고 |
|------|-----------|------|
| v1 | 307초 | apt-get install 포함 |
| v2 | 297초 | 최초 빌드라 캐시 없음 |

### 2. 캐시 효과 (재빌드)
| 시나리오 | v1 | v2 |
|----------|----|----|
| 코드 변경 없이 재빌드 | 1.3초 | 1.2초 |
| app.jar 수정 후 재빌드 | 296.9초 ← apt-get 재실행 | 1.5초 ← apt-get 캐시 유지 |

### 3. 이미지 크기
| 버전 | 크기 | 비고 |
|------|------|------|
| v1 | 103MB | 더미 jar 사용으로 차이 없음 |
| v2 | 103MB | 더미 jar 사용으로 차이 없음 |
| multi | 103MB | 실제 프로젝트 기준 JDK(500MB+) → JRE(280MB)로 절감 |

> ⚠️ 이미지 크기는 더미 jar 사용으로 차이 없음.
> 실제 Spring Boot 프로젝트 적용 시 멀티스테이지 효과 확인 예정 (3-4주차)

## 핵심 개념
- 레이어 순서가 캐시 히트율 결정
- 자주 바뀌는 COPY는 항상 마지막에
- 멀티스테이지로 빌드 환경(JDK)과 실행 환경(JRE) 분리

## 빌드 명령어
```bash
# 더미 jar 준비
mkdir -p app && echo "fake springboot app" > app/app.jar

# 빌드
docker build -f Dockerfile.v1 -t springapp:v1 .
docker build -f Dockerfile.v2 -t springapp:v2 .
docker build -f Dockerfile.multi -t springapp:multi .

# 이미지 크기 확인
docker images | grep springapp

# 레이어 확인
docker history springapp:v2
```
