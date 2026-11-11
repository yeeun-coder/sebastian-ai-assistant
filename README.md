# 나의 세바스찬 - 개발계획서

## 1. 프로젝트 개요

| 항목 | 내용 |
|------|------|
| 프로젝트명 | 나의 세바스찬 (My Sebastian) |
| 서비스 설명 | 사용자의 일상, 건강, 일정 등을 관리해주는 맞춤형 AI 비서 앱 |
| 타겟 사용자 | 대학생, 사회 초년생, 건강 관리가 필요한 사용자, 생산성 앱 사용자 |
| 사용 환경 | Android / iOS (Flutter 크로스 플랫폼) |
| Backend | Node.js + TypeORM + SQLite + Swagger |
| Frontend (App) | Flutter |
| 아키텍처 | REST API 기반 Client-Server 구조 |

### 1.1 기획 배경
- 캘린더, To-Do, 루틴 등 어플이 다양하게 분산되어 있음
- 혼자의 의지로만 꾸준하게 계획을 관리하기 어려움
- 일정이나 습관들의 수동 입력 피로도 해소 필요

### 1.2 기대 효과
- 사용자 삶을 통합 관리할 수 있는 AI 비서
- 비서 컨셉 선택지를 통해 재미 요소 확보
- 데이터 기반 개인화를 통한 사용자 정보 학습
- 대화식 일정 입력으로 수동 입력 스트레스 해소

---

## 2. 기술 스택

### 2.1 Backend
| 기술 | 용도 | 버전 (권장) |
|------|------|------------|
| Node.js | 서버 런타임 | v20 LTS |
| Express.js | HTTP 서버 프레임워크 | v4.x |
| TypeORM | ORM (데이터베이스 매핑) | v0.3.x |
| SQLite | 경량 데이터베이스 | better-sqlite3 |
| Swagger (swagger-jsdoc + swagger-ui-express) | API 문서 자동화 | - |
| JWT (jsonwebtoken) | 인증 토큰 관리 | - |
| bcrypt | 비밀번호 해싱 | - |
| TypeScript | 타입 안전성 | v5.x |
| node-cron | 알림 스케줄링 | - |

### 2.2 Frontend (App)
| 기술 | 용도 | 버전 (권장) |
|------|------|------------|
| Flutter | 크로스 플랫폼 앱 프레임워크 | v3.x |
| Dart | 프로그래밍 언어 | v3.x |
| dio | HTTP 클라이언트 | - |
| provider / riverpod | 상태 관리 | - |
| flutter_local_notifications | 로컬 푸시 알림 | - |
| table_calendar | 캘린더 UI | - |
| flutter_secure_storage | 토큰 안전 저장 | - |
| go_router | 라우팅 관리 | - |

### 2.3 AI 연동
| 기술 | 용도 |
|------|------|
| Claude API / OpenAI API | 자연어 처리 기반 일정/할일 파싱, AI 비서 대화 |

---

## 3. 시스템 아키텍처

```
+-------------------+         +-----------------------------------+
|  Flutter App      |  HTTP   |  Node.js Backend                  |
|  (Android/iOS)    |<------->|  Express + TypeORM + SQLite       |
|                   |  REST   |                                   |
|  - UI/UX          |  API    |  - Auth (JWT)                     |
|  - State Mgmt     |         |  - Schedule/Todo CRUD             |
|  - Local Push     |         |  - AI Chat Proxy                  |
|  - Calendar       |         |  - Notification                   |
+-------------------+         |  - Swagger Docs                   |
                              +----------------+------------------+
                                               |
                                               v
                              +----------------------------+
                              |  AI API                    |
                              |  (Claude / OpenAI)         |
                              |  - Natural Language Parse  |
                              |  - Schedule/Todo Extract   |
                              |  - Butler Mode Response    |
                              +----------------------------+
```

---

## 4. 데이터베이스 설계 (ERD)

### 4.1 테이블 정의

#### users (사용자)
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | INTEGER (PK, AUTO) | 사용자 고유 ID |
| email | VARCHAR(255), UNIQUE | 이메일 |
| password | VARCHAR(255) | 해싱된 비밀번호 |
| nickname | VARCHAR(50) | 닉네임 |
| age | INTEGER | 나이 |
| gender | VARCHAR(10) | 성별 (male/female) |
| profile_image | VARCHAR(500) | 프로필 이미지 경로 |
| ai_mode | VARCHAR(50) | AI 모드 (비서/엄마/신하/교관 등) |
| ai_name | VARCHAR(50) | AI 비서 이름 (기본: 세바스찬) |
| created_at | DATETIME | 생성일 |
| updated_at | DATETIME | 수정일 |

#### schedules (일정)
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | INTEGER (PK, AUTO) | 일정 고유 ID |
| user_id | INTEGER (FK → users) | 사용자 ID |
| title | VARCHAR(255) | 일정 제목 |
| description | TEXT | 일정 설명 |
| date | DATE | 일정 날짜 |
| start_time | TIME | 시작 시간 |
| end_time | TIME | 종료 시간 |
| is_recurring | BOOLEAN | 반복 여부 |
| recurrence_rule | VARCHAR(100) | 반복 규칙 (daily/weekly/monthly + 세부) |
| source | VARCHAR(20) | 등록 출처 (ai_chat / manual) |
| created_at | DATETIME | 생성일 |
| updated_at | DATETIME | 수정일 |

#### todos (할 일)
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | INTEGER (PK, AUTO) | To-Do 고유 ID |
| user_id | INTEGER (FK → users) | 사용자 ID |
| title | VARCHAR(255) | 할 일 제목 |
| deadline | DATETIME | 마감일 |
| status | VARCHAR(20) | 상태 (pending/imminent/urgent/completed) |
| is_recurring | BOOLEAN | 반복 여부 |
| recurrence_rule | VARCHAR(100) | 반복 규칙 |
| source | VARCHAR(20) | 등록 출처 (ai_chat / manual) |
| completed_at | DATETIME | 완료일 |
| created_at | DATETIME | 생성일 |
| updated_at | DATETIME | 수정일 |

#### notifications (알림)
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | INTEGER (PK, AUTO) | 알림 고유 ID |
| user_id | INTEGER (FK → users) | 사용자 ID |
| schedule_id | INTEGER (FK → schedules, nullable) | 연결 일정 |
| todo_id | INTEGER (FK → todos, nullable) | 연결 To-Do |
| title | VARCHAR(255) | 알림 제목 |
| message | TEXT | 알림 내용 |
| notify_at | DATETIME | 알림 시각 |
| is_enabled | BOOLEAN | 활성화 여부 |
| is_recurring | BOOLEAN | 반복 여부 |
| recurrence_rule | VARCHAR(100) | 반복 규칙 |
| created_at | DATETIME | 생성일 |
| updated_at | DATETIME | 수정일 |

#### chat_messages (채팅 메시지)
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | INTEGER (PK, AUTO) | 메시지 고유 ID |
| user_id | INTEGER (FK → users) | 사용자 ID |
| role | VARCHAR(20) | 발신자 (user / assistant) |
| content | TEXT | 메시지 내용 |
| created_at | DATETIME | 생성일 |

#### user_tags (사용자 특성 태그)
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | INTEGER (PK, AUTO) | 태그 고유 ID |
| user_id | INTEGER (FK → users) | 사용자 ID |
| tag | VARCHAR(100) | AI 분석 태그 내용 |
| created_at | DATETIME | 생성일 |

---

## 5. API 설계 (REST API)

### 5.1 인증 (Auth)
| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/api/auth/register` | 회원가입 |
| POST | `/api/auth/login` | 로그인 (JWT 발급) |
| POST | `/api/auth/logout` | 로그아웃 |
| DELETE | `/api/auth/withdraw` | 회원탈퇴 |

### 5.2 사용자 (Users)
| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/api/users/me` | 내 프로필 조회 |
| PUT | `/api/users/me` | 프로필 수정 (닉네임, 나이, 성별, 프로필 이미지) |
| PUT | `/api/users/me/password` | 비밀번호 변경 |
| GET | `/api/users/me/tags` | AI 분석 태그 조회 |

### 5.3 AI 비서 설정
| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/api/ai-settings` | AI 비서 설정 조회 (모드, 이름) |
| PUT | `/api/ai-settings` | AI 비서 설정 변경 |

### 5.4 채팅 (Chat)
| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/api/chat/send` | 메시지 전송 → AI 응답 + 일정/할일 자동 파싱 |
| GET | `/api/chat/history` | 채팅 기록 조회 (페이지네이션) |

### 5.5 일정 (Schedules)
| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/api/schedules` | 일정 목록 조회 (query: date, month) |
| GET | `/api/schedules/:id` | 일정 상세 조회 |
| POST | `/api/schedules` | 일정 수동 등록 |
| PUT | `/api/schedules/:id` | 일정 수정 |
| DELETE | `/api/schedules/:id` | 일정 삭제 |
| GET | `/api/schedules/today` | 오늘 일정 브리핑 |

### 5.6 할 일 (Todos)
| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/api/todos` | To-Do 목록 조회 (query: date, status) |
| GET | `/api/todos/:id` | To-Do 상세 조회 |
| POST | `/api/todos` | To-Do 수동 등록 |
| PUT | `/api/todos/:id` | To-Do 수정 |
| PATCH | `/api/todos/:id/status` | To-Do 상태 변경 (완료 토글) |
| DELETE | `/api/todos/:id` | To-Do 삭제 |

### 5.7 알림 (Notifications)
| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/api/notifications` | 알림 목록 조회 |
| PUT | `/api/notifications/:id` | 알림 수정 (시간 변경, 반복 변경) |
| PATCH | `/api/notifications/:id/toggle` | 알림 ON/OFF 토글 |

### 5.8 브리핑
| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/api/briefing/today` | 오늘 일정 + To-Do + 날씨 통합 브리핑 |

---

## 6. 화면별 상세 설계

### 6.1 스플래시 화면
- **목적**: 브랜드 아이덴티티 전달, 첫 인상 형성
- **UI**: 중앙 로고 + 서비스명, 하단 슬로건, 흰색 배경
- **로직**:
  1. 앱 실행 후 3초간 스플래시 유지
  2. flutter_secure_storage에서 JWT 토큰 확인
  3. 유효한 토큰 → 홈(AI 채팅) 이동 / 없음 → 로그인 화면 이동

### 6.2 로그인 / 회원가입
- **목적**: 개인화 데이터와 서비스 이용 권한 관리
- **필요 기능**:
  - 이메일 중복 검사, 이메일 형식 검증, 비밀번호 복잡도 확인
- **화면 구성**:
  - 로그인: 이메일 + 비밀번호 입력 → 로그인 버튼
  - 회원가입: 이메일 + 비밀번호 + 비밀번호 확인 + 대슬 + 생년월일 + 성별 → 가입 버튼
  - 화면 전환 링크로 로그인↔회원가입 연결
- **로직**:
  1. 클라이언트 유효성 검사
  2. 서버 API 호출 (register / login)
  3. 성공 시 JWT 저장 → 일정 브리핑 화면 이동

### 6.3 앱 접속 - 일정 브리핑
- **목적**: 오늘 일정을 한눈에 파악
- **표시 조건**: 앱 첫 접속 시 1회
- **화면 구성**:
  - 상단: 로고 + "오늘 일정 브리핑" 타이틀
  - 날짜 카드: 날짜, 날씨 안내
  - 타임라인: 오늘의 일정 + To-Do 시간순 나열
- **로직**:
  1. `GET /api/briefing/today` 호출
  2. 일정 + To-Do 시간순 정렬 표시
  3. 하단 확인 버튼 → AI 채팅 홈 이동

### 6.4 AI 채팅 & 홈 (메인 화면)
- **목적**: AI 비서를 활용한 대화형 일정/할일 관리
- **화면 구성**:
  - 상단 AppBar: 알림 아이콘, 어플명 "나의 세바스찬", 세바스찬 아이콘
  - 하단 네비게이션 바: 홈 / 달력 / 루틴 / 사용자 설정
  - 중앙: 채팅 메시지 영역
  - 하단: 텍스트 입력창 + 전송 버튼
- **핵심 로직 (AI 채팅 파싱)**:
  1. 사용자 메시지 → `POST /api/chat/send`
  2. Backend에서 AI API 호출 → 자연어 분석
  3. 분석 결과에 따라:
     - **일정** → 날짜/시간 추출 → schedules 테이블 저장 → 알림 자동 생성 (30분 전)
     - **할 일** → 마감일 기준 등록 → todos 테이블 저장 → D-3부터 알림
     - **일반 대화** → AI 응답만 반환
  4. 응답을 채팅 UI에 표시 (일정 생성 시 카드 형태)
- **알림 자동 생성 규칙**:
  - 일정 → 30분 전 알림
  - 반복 일정 → 동일 주기/시간 반복 알림
  - 마감형 To-Do → D-3부터 표시, 마감 임박 시 강조
- **알림 관리**:
  - 알림 아이콘 클릭 → 알림 리스트 조회
  - ON/OFF 토글, 시간 수정, 반복 여부 변경 → 즉시 반영
- **세바스찬 프로필**: 아이콘 클릭 → 설정된 이름 2초 표시

### 6.5 달력
- **목적**: 일정/할일을 날짜 중심으로 관리
- **화면 구성**:
  - 상단: AppBar (알림, 어플명, 세바스찬 아이콘)
  - 중앙: 월간 캘린더 (오늘 날짜 강조, 일정 있는 날 도트 표시)
  - 하단(접힘): 선택 날짜의 일정 시간순 나열 + 수동 추가 (+) 버튼
  - 하단(펼침): To-Do 리스트 (드래그로 전체 보기)
- **일정 관리**:
  - AI 채팅 등록 일정 자동 반영
  - 수동 입력: + 버튼 → 제목, 날짜, 시간, 알림 입력 → 저장
  - 일정 클릭 → 수정/삭제
- **To-Do 관리**:
  - AI 자동 분류 + 수동 입력 지원
  - 체크 시 줄 긋기 + 텍스트 색상 회색(#D9D9D9)
  - 상태별 색상:
    | 상태 | 색상 |
    |------|------|
    | 기본 (D-3 이상) | 검정 |
    | 임박 (D-2 ~ D-1) | (경고색) |
    | 마감 당일 (D-day) | 빨강 |
    | 완료 | 회색 |
  - 하단 To-Do 영역 드래그 → 전체 To-Do 펼침/요약 전환

### 6.6 사용자 설정
- **목적**: AI 비서 개인화 + 계정 관리
- **화면 구성**:
  - 프로필: 이미지, 닉네임, 나이, 성별
  - AI 한 마디: AI가 분석한 사용자 특징 태그 5개
  - AI 모드 설정: 비서 / 엄마 / 신하 / 교관 등 선택
  - AI 이름 변경
  - 계정 관리: 프로필 수정, 비밀번호 변경, 로그아웃, 탈퇴
- **특수 로직**: 나이 60세 이상 → 신사봇(간단 조작, 큰 글씨) 기본 설정

---

## 7. 프로젝트 디렉토리 구조

### 7.1 Backend
```
backend/
├── src/
│   ├── app.ts                    # Express 앱 설정
│   ├── server.ts                 # 서버 시작점
│   ├── data-source.ts            # TypeORM 데이터소스 설정
│   ├── entity/                   # TypeORM 엔티티
│   │   ├── User.ts
│   │   ├── Schedule.ts
│   │   ├── Todo.ts
│   │   ├── Notification.ts
│   │   ├── ChatMessage.ts
│   │   └── UserTag.ts
│   ├── routes/                   # 라우터
│   │   ├── auth.routes.ts
│   │   ├── user.routes.ts
│   │   ├── chat.routes.ts
│   │   ├── schedule.routes.ts
│   │   ├── todo.routes.ts
│   │   ├── notification.routes.ts
│   │   └── briefing.routes.ts
│   ├── controllers/              # 컨트롤러
│   │   ├── auth.controller.ts
│   │   ├── user.controller.ts
│   │   ├── chat.controller.ts
│   │   ├── schedule.controller.ts
│   │   ├── todo.controller.ts
│   │   ├── notification.controller.ts
│   │   └── briefing.controller.ts
│   ├── services/                 # 비즈니스 로직
│   │   ├── auth.service.ts
│   │   ├── user.service.ts
│   │   ├── ai.service.ts         # AI API 연동 + 자연어 파싱
│   │   ├── chat.service.ts
│   │   ├── schedule.service.ts
│   │   ├── todo.service.ts
│   │   ├── notification.service.ts
│   │   └── briefing.service.ts
│   ├── middleware/
│   │   ├── auth.middleware.ts     # JWT 인증 미들웨어
│   │   └── validation.middleware.ts
│   ├── utils/
│   │   ├── date.util.ts          # 날짜/시간 파싱 유틸
│   │   └── notification.util.ts  # 알림 규칙 계산
│   └── swagger/
│       └── swagger.config.ts     # Swagger 설정
├── database.sqlite               # SQLite DB 파일
├── package.json
├── tsconfig.json
└── .env
```

### 7.2 Flutter App
```
app/
├── lib/
│   ├── main.dart
│   ├── app.dart                  # 앱 설정, 라우터, 테마
│   ├── config/
│   │   ├── api_config.dart       # API Base URL 등
│   │   └── theme.dart            # 앱 테마 (색상, 폰트)
│   ├── models/                   # 데이터 모델
│   │   ├── user.dart
│   │   ├── schedule.dart
│   │   ├── todo.dart
│   │   ├── notification.dart
│   │   ├── chat_message.dart
│   │   └── briefing.dart
│   ├── services/                 # API 호출 서비스
│   │   ├── api_client.dart       # Dio 기반 HTTP 클라이언트
│   │   ├── auth_service.dart
│   │   ├── chat_service.dart
│   │   ├── schedule_service.dart
│   │   ├── todo_service.dart
│   │   ├── notification_service.dart
│   │   └── briefing_service.dart
│   ├── providers/                # 상태 관리
│   │   ├── auth_provider.dart
│   │   ├── chat_provider.dart
│   │   ├── schedule_provider.dart
│   │   ├── todo_provider.dart
│   │   └── notification_provider.dart
│   ├── screens/                  # 화면
│   │   ├── splash/
│   │   │   └── splash_screen.dart
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── briefing/
│   │   │   └── briefing_screen.dart
│   │   ├── home/
│   │   │   └── home_screen.dart  # AI 채팅 & 홈
│   │   ├── calendar/
│   │   │   └── calendar_screen.dart
│   │   ├── notifications/
│   │   │   └── notification_screen.dart
│   │   └── settings/
│   │       ├── settings_screen.dart
│   │       ├── profile_edit_screen.dart
│   │       └── ai_mode_screen.dart
│   └── widgets/                  # 공용 위젯
│       ├── chat_bubble.dart
│       ├── schedule_card.dart
│       ├── todo_item.dart
│       ├── bottom_nav_bar.dart
│       └── app_bar_widget.dart
├── pubspec.yaml
└── .env
```

---

## 8. 핵심 로직 상세

### 8.1 AI 채팅 파싱 흐름

```
사용자 입력: "27일 오후4시 영화관 일정인데 시작 1시간 전에 출발 알림 설정해줘"
         │
         ▼
   Backend (chat.service)
         │
         ├── AI API 호출 (프롬프트에 파싱 규칙 포함)
         │
         ▼
   AI 응답 (구조화된 JSON)
   {
     "type": "schedule",
     "title": "영화관",
     "date": "2026-03-27",
     "start_time": "16:00",
     "notifications": [
       { "time": "15:00", "message": "영화관으로 출발할 시간입니다" }
     ],
     "reply": "27일 오후 4시 영화관 일정을 등록했어요. 3시에 출발 알림을 설정해드렸습니다."
   }
         │
         ▼
   DB 저장 (schedules + notifications)
         │
         ▼
   Flutter 앱에 응답 반환 → 채팅 UI + 일정 카드 표시
```

### 8.2 알림 자동 생성 규칙

| 유형 | 규칙 |
|------|------|
| 일반 일정 | 시작 30분 전 알림 |
| 반복 일정 | 동일 주기/시간에 반복 알림 생성 |
| 마감형 To-Do | D-3부터 매일 알림, D-day에 강조 알림 |
| 사용자 커스텀 | 사용자가 명시한 시간에 알림 (AI 파싱) |

### 8.3 To-Do 상태 자동 계산

```typescript
function getTodoStatus(deadline: Date): string {
  const daysLeft = diffDays(deadline, today);
  if (completed) return 'completed';   // 회색
  if (daysLeft === 0) return 'urgent'; // 빨강 (D-day)
  if (daysLeft <= 2) return 'imminent'; // 경고색 (D-2 ~ D-1)
  return 'pending';                     // 기본 (검정)
}
```

---

## 9. AI 비서 모드 설계

| 모드 | 말투/성격 | 특징 |
|------|---------|------|
| 비서 (기본) | 정중하고 격식있는 말투 | "일정을 등록해드렸습니다, 주인님" |
| 엄마 | 따뜻하고 잔소리 스타일 | "밥은 먹었니? 약 먹을 시간이야~" |
| 신하 | 충성스럽고 과장된 존경 | "전하, 오늘의 일정을 보고드리옵니다" |
| 교관 | 엄격하고 단호한 명령조 | "기상! 오늘 할 일이 3개 남았다!" |
| 신사봇 (60세 이상 기본) | 간결하고 큰 글씨 | 조작 간소화, 핵심 정보만 표시 |

AI API 호출 시 system prompt에 모드별 페르소나를 주입하여 응답 톤 제어.

---

## 10. 개발 단계별 계획

### Phase 1: 기반 구축
- [ ] Backend 프로젝트 초기화 (Express + TypeScript + TypeORM + SQLite)
- [ ] Swagger 설정
- [ ] DB 엔티티 및 마이그레이션 생성
- [ ] Flutter 프로젝트 초기화 + 기본 라우팅 설정
- [ ] 공통 테마, 위젯 정의

### Phase 2: 인증 시스템
- [ ] 회원가입 API (이메일 중복 검사, 비밀번호 해싱)
- [ ] 로그인 API (JWT 발급)
- [ ] 인증 미들웨어 (JWT 검증)
- [ ] Flutter 로그인/회원가입 화면
- [ ] 토큰 저장 및 자동 로그인 (스플래시)

### Phase 3: AI 채팅 & 일정 관리
- [ ] AI API 연동 서비스 (자연어 → 일정/할일 파싱)
- [ ] 채팅 API (메시지 전송, 기록 조회)
- [ ] 일정 CRUD API
- [ ] To-Do CRUD API
- [ ] Flutter AI 채팅 화면 (메시지 UI, 일정 카드)
- [ ] Flutter 달력 화면 (table_calendar + 일정/To-Do 연동)

### Phase 4: 알림 시스템
- [ ] 알림 자동 생성 로직 (일정 등록 시 연동)
- [ ] 알림 관리 API (조회, 수정, ON/OFF)
- [ ] Flutter 로컬 푸시 알림 연동
- [ ] 알림 관리 화면

### Phase 5: 사용자 설정 & 개인화
- [ ] 프로필 관리 API
- [ ] AI 모드/이름 설정 API
- [ ] AI 사용자 분석 태그 생성
- [ ] Flutter 설정 화면 (프로필, AI 모드, 계정 관리)
- [ ] 일정 브리핑 화면

### Phase 6: 마무리 & 테스트
- [ ] 전체 API 테스트
- [ ] Flutter UI/UX 다듬기
- [ ] 60세 이상 신사봇 모드 자동 설정
- [ ] 에러 핸들링 및 예외처리
- [ ] 빌드 및 배포 준비 (Android APK / iOS)

---

## 11. 주요 패키지 의존성

### Backend (package.json)
```json
{
  "dependencies": {
    "express": "^4.18.x",
    "typeorm": "^0.3.x",
    "better-sqlite3": "^11.x",
    "jsonwebtoken": "^9.x",
    "bcrypt": "^5.x",
    "swagger-jsdoc": "^6.x",
    "swagger-ui-express": "^5.x",
    "cors": "^2.x",
    "dotenv": "^16.x",
    "class-validator": "^0.14.x",
    "node-cron": "^3.x"
  },
  "devDependencies": {
    "typescript": "^5.x",
    "ts-node": "^10.x",
    "nodemon": "^3.x",
    "@types/express": "^4.x",
    "@types/jsonwebtoken": "^9.x",
    "@types/bcrypt": "^5.x"
  }
}
```

### Flutter (pubspec.yaml 주요 패키지)
```yaml
dependencies:
  dio: ^5.x
  provider: ^6.x          # 또는 flutter_riverpod
  go_router: ^14.x
  flutter_secure_storage: ^9.x
  flutter_local_notifications: ^17.x
  table_calendar: ^3.x
  intl: ^0.19.x
  cached_network_image: ^3.x
```

---

## 12. 환경 변수 (.env)

### Backend
```env
PORT=3000
JWT_SECRET=your_jwt_secret_key
JWT_EXPIRES_IN=7d
AI_API_KEY=your_ai_api_key
AI_API_URL=https://api.anthropic.com/v1/messages
DB_PATH=./database.sqlite
```

### Flutter
```env
API_BASE_URL=http://localhost:3000/api
```

---

## 13. Swagger API 문서

- 접속 경로: `http://localhost:3000/api-docs`
- 모든 API 엔드포인트 자동 문서화
- 요청/응답 스키마 정의
- JWT 인증 헤더 테스트 지원

---

## 14. 관리자 웹 (`web/`) + 서버 동시 실행

Vite가 `/admin`을 Nest(기본 `http://localhost:3000`)로 프록시하므로, **서버가 먼저 떠 있어야** 로그인·API 호출이 됩니다.

저장소 루트에서:

```bash
npm install
npm run dev
```

`sebastian_server`와 `web`이 함께 실행됩니다. 환경 변수·엔드포인트는 `web/README.md`를 참고하세요.

---
