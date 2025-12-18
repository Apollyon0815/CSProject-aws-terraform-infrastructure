# Cloud Security Week 3 - Terraform Configuration

이 Terraform 코드는 클라우드 시큐리티 3주차 과제의 AWS 인프라를 자동으로 구성합니다.

## 구성 요소

### 네트워크
- VPC: CSVPC-1 (10.0.0.0/16)
- Public Subnet: CSVPC-1-A (10.0.1.0/24)
- Internet Gateway
- Route Table

### 보안
- NACL (Network ACL) - Stateless
  - Inbound: HTTPS(443), 임시포트(1024-65535)
  - Outbound: HTTP(80), HTTPS(443), 임시포트(1024-65535)
- Security Group - Stateful
  - Inbound: HTTP(80), HTTPS(443)
  - Outbound: All traffic

### 컴퓨팅
- EC2 Instance: t2.micro
- AMI: ami-04fcc2023d6e37430
- Nginx 웹 서버 자동 설치

### IAM
- Role: CS-Role-EC2-SSM
- Policies:
  - AmazonSSMManagedInstanceCore
  - AmazonS3ReadOnlyAccess
  - AmazonS3FullAccess

### 스토리지
- S3 Bucket: hdy-s3-for-cs-project
- 암호화: AES256
- 버전 관리: 활성화

## 사용 방법

### 1. Terraform 초기화
```bash
terraform init
```

### 2. 실행 계획 확인
```bash
terraform plan
```

### 3. 인프라 배포
```bash
terraform apply
```

### 4. 인프라 삭제
```bash
terraform destroy
```

## 출력 정보

배포 완료 후 다음 정보가 출력됩니다:
- VPC ID
- Subnet ID
- EC2 Instance ID
- EC2 Public IP
- Security Group ID
- S3 Bucket Name
- IAM Role Name
- Web Server URL

## 파일 구조

```
.
├── main.tf           # 메인 리소스 정의
├── variables.tf      # 변수 선언
├── outputs.tf        # 출력 값 정의
├── terraform.tfvars  # 변수 값 설정
└── README.md         # 이 파일
```

## 주의사항

1. AWS CLI 설정이 완료되어 있어야 합니다
2. 적절한 IAM 권한이 필요합니다
3. S3 버킷 이름은 전역적으로 고유해야 합니다
4. 리소스 생성 시 비용이 발생할 수 있습니다

## 접속 방법

### SSM Session Manager로 EC2 접속
```bash
aws ssm start-session --target <instance-id>
```

### 웹 브라우저로 접속
```
http://<ec2-public-ip>
```

## 버전

- Terraform: >= 1.0
- AWS Provider: ~> 5.0
