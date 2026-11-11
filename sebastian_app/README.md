# sebastian_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# sebastian-ai-assistant
AI-powered personal assistant app for managing schedules, health, and daily routines

---

## 📌 프로젝트 소개
Sebastian은 사용자의 **일정, 건강, 루틴을 통합 관리**해주는 AI 기반 개인 비서 앱입니다.  
단순한 스케줄러를 넘어, 사용자의 상태를 분석하고 능동적으로 관리해주는 것이 목표입니다.

---

## 🎯 주요 기능

### 📅 일정 관리
- 일정 등록 / 수정 / 삭제
- 날짜 기반 캘린더 제공

### 🔁 루틴 관리
- 복용 약, 영양제, 습관 관리
- 반복 알림 기능

### 🤖 AI 비서
- 사용자와 채팅
- 일정 / 건강 기반 피드백 제공

---

## 🛠 기술 스택

### 📱 Frontend
- Flutter

### ⚙️ Backend
- NestJS

### 🗄 Database
- SQLite

---

## 🚀 개발 진행 방식

- GitHub 기반 협업
- 브랜치 전략:
  - `main` → 배포
  - `develop` → 개발 통합
  - `feature/*` → 기능 개발

---

## 📅 향후 계획

- AI 기능 고도화
- 푸시 알림 시스템
- 사용자 맞춤 추천 기능

---

## 📌 협업 규칙

- main 브랜치 직접 수정 금지
- 기능 단위 Pull Request 필수
- 작업 전 최신 코드 pull
- API → Backend → Frontend 순서 개발

---

### 📌 주요 테이블

| 테이블명 | 설명 |
|----------|------|
| users | 사용자 계정 정보 |
| user_profiles | 사용자 상세 프로필 (나이, 성별 등) |
| ai_messages | AI가 생성한 채팅 기록 |
| user_messages | 사용자가 보낸 채팅 기록 |
| schedules | 일정 관리 데이터 |
| todos | 할 일 (To-Do) 관리 |
| user_tags | AI가 분석한 사용자 성격 및 행동 태그 |

---
