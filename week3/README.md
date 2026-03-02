# 3주차 - Kubernetes Service로 Pod 연결하기

## 학습 내용

- Service의 역할과 동작 원리 이해 (ClusterIP 고정 엔드포인트)
- ClusterIP / NodePort / LoadBalancer 타입별 차이
- Label Selector로 Service-Pod 연결 메커니즘
- CoreDNS를 통한 서비스 이름 기반 내부 DNS 통신

**상세 내용 정리** - [notion-link](https://www.notion.so/Docker-Compose-30718afea17280a08d10ee98ac878126?source=copy_link)

## 테스트 환경

- OS: Rocky Linux 9 (VM)
- Kubernetes: v1.x

## 파일 설명

| 파일                 | 설명                                                  |
| -------------------- | ----------------------------------------------------- |
| `web-deploy.yaml`    | nginx Deployment (replicas: 2, label: app=web)        |
| `clusterip-svc.yaml` | ClusterIP Service - 클러스터 내부 통신용              |
| `nodeport-svc.yaml`  | NodePort Service - 외부 접근용 (30080)                |
| `client.yaml`        | curl 테스트용 Pod (kubectl exec으로 내부 접근 테스트) |

## 실험 결과

### 1. Pod 직접 IP 통신 vs Service 통신

```bash
kubectl apply -f web-deploy.yaml
kubectl apply -f client.yaml

kubectl get pods -o wide        # web Pod IP 확인
# client Pod에서 web Pod IP로 직접 접근
kubectl exec -it client -- curl http://<web-pod-IP>
```

- Pod IP로 직접 접근 성공 확인
- 단, Pod 재시작 시 IP 변경 → IP 직접 지정 방식은 운영 환경 부적합

### 2. ClusterIP Service - 서비스 이름 DNS 통신

```bash
kubectl apply -f clusterip-svc.yaml
kubectl get svc web-clusterip
kubectl describe svc web-clusterip     # Endpoints: Pod IP 자동 반영 확인
```

| 항목      | 값               |
| --------- | ---------------- |
| Type      | ClusterIP        |
| ClusterIP | 10.x.x.x (고정)  |
| Endpoints | Pod IP 자동 반영 |

```bash
kubectl exec -it client -- curl http://web-clusterip
```

- Service 이름(`web-clusterip`)으로 DNS 해석 성공
- Pod IP가 바뀌어도 Service 이름으로 통신 안정적

### 3. NodePort - 외부 접근

```bash
kubectl apply -f nodeport-svc.yaml
kubectl get svc web-nodeport
# TYPE: NodePort, PORT: 80:30080/TCP
```

| 항목 | 값           |
| ---- | ------------ |
| Type | NodePort     |
| Port | 80:30080/TCP |

```bash
hostname -I                            # VM IP 확인
curl http://<Rocky-VM-IP>:30080
```

- VM 외부(Windows PC 브라우저)에서도 접근 확인

### 4. Label Selector 동작 확인

```bash
kubectl describe svc web-clusterip | grep -A5 Selector
kubectl get pods --show-labels

kubectl label pod <pod-name> app-          # 라벨 제거
kubectl get endpoints web-clusterip        # Endpoints 비어있음 확인

kubectl label pod <pod-name> app=web       # 라벨 복구
kubectl get endpoints web-clusterip        # Pod 재등록 확인
```

| 시나리오     | Endpoints 상태  |
| ------------ | --------------- |
| 정상 상태    | Pod IP 포함     |
| 라벨 제거 후 | 비어있음 (none) |
| 라벨 복구 후 | Pod IP 재등록   |

## 핵심 개념

- Pod는 재시작 시 IP가 바뀌므로 직접 IP 통신은 운영 환경 부적합
- Service(ClusterIP)는 고정 가상 IP를 제공 → Pod IP 변경과 무관하게 통신 가능
- CoreDNS가 Service 이름을 `<svc-name>.<namespace>.svc.cluster.local`로 자동 등록 → 같은 namespace에서는 이름만으로 통신 가능
- Label Selector로 Service가 트래픽을 보낼 Pod를 동적으로 결정 → 라벨 불일치 시 Endpoints 비어 트래픽 불가
- NodePort는 VM 실제 NIC에 포트를 열어 클러스터 외부 접근 가능 (ClusterIP는 외부 라우팅 테이블에 없어 불가)

## 주요 명령어

```bash
# Service 조회
kubectl get svc
kubectl describe svc <service-name>
kubectl get endpoints <service-name>

# Label 조작
kubectl get pods --show-labels
kubectl label pod <pod-name> <key>=<value>    # 라벨 추가/수정
kubectl label pod <pod-name> <key>-           # 라벨 삭제

# Pod 내부에서 서비스 접근
kubectl exec -it client -- curl http://web-clusterip

# 외부 접근 (NodePort)
hostname -I                                   # VM IP 확인
curl http://<VM-IP>:30080
```
