# 1주차 - Docker 심화

## 학습 내용
- Dockerfile 레이어 구조 이해
- 레이어 캐시 최적화
- 멀티스테이지 빌드

## 파일 설명
| 파일 | 설명 |
|------|------|
| `Dockerfile.v1` | 나쁜 예 - COPY 후 RUN (캐시 비효율) |
| `Dockerfile.v2` | 좋은 예 - RUN 후 COPY (캐시 최적화) |
| `Dockerfile.multi` | 멀티스테이지 - JDK 빌드 → JRE 실행 |

## 핵심 개념
레이어 순서가 캐시 히트율 결정.
자주 바뀌는 COPY는 항상 마지막에.
멀티스테이지로 빌드 환경과 실행 환경 분리.

## 실행
```bash
docker build -f Dockerfile.v2 -t springapp:v2 .
docker images | grep springapp
```

## 상세 학습 기록
[Notion 링크](여기에_나중에_추가)
