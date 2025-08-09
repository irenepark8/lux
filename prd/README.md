# Backend API Services

영어 단어 검색 및 일정 관리 API 서버 (Supabase Edge Functions)

## 🎯 개요

이 프로젝트는 앱에서 사용할 영어 단어 검색 기능과 음성 인식 기반 일정 관리 기능을 제공하는 백엔드 API입니다.

## ✨ 기능

### Dictionary API
- 영어 단어 검색
- 최대 3개의 단어 뜻 반환
- 품사 정보 제공 (명사, 동사, 형용사 등)

### Schedule API  
- 음성 인식 기반 일정 추가
- 일정 조회/수정/삭제
- 날짜별 필터링
- 사용자별 데이터 분리 (RLS)

### 공통
- CORS 지원으로 웹/앱에서 사용 가능
- Supabase Edge Functions로 배포 완료

## 🚀 API 엔드포인트 상세 가이드

### 📚 Dictionary API

#### 단어 검색
**엔드포인트:**
```
GET https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/dictionary-search
```

**쿼리 파라미터:**
- `word` (필수): 검색할 영어 단어

**헤더:**
- `Authorization: Bearer {ANON_KEY}` (필수)

**요청 예시:**
```bash
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZyYXRiemhzZ2lpeWdnZnJkcXBrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIyMTQ1MTgsImV4cCI6MjA2Nzc5MDUxOH0.FsRC0wTUVrA7JgSk1S25NnCshVFoGRaCgJQNKwE97RI" \
  "https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/dictionary-search?word=hello"
```

**성공 응답 (200):**
```json
{
  "word": "hello",
  "results": [
    {
      "word": "hello",
      "partOfSpeech": "noun",
      "definition": "\"Hello!\" or an equivalent greeting."
    },
    {
      "word": "hello", 
      "partOfSpeech": "verb",
      "definition": "To greet with \"hello\"."
    },
    {
      "word": "hello",
      "partOfSpeech": "interjection", 
      "definition": "A greeting (salutation) said when meeting someone or acknowledging someone's arrival or presence."
    }
  ]
}
```

**에러 응답:**
- **400 Bad Request**: `word` 파라미터 누락
- **404 Not Found**: 단어를 찾을 수 없음
- **500 Internal Server Error**: 서버 오류

---

### 📅 Schedule API

#### 1. 일정 추가
**엔드포인트:**
```
POST https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/add-schedule
```

**헤더:**
- `Authorization: Bearer {USER_JWT_TOKEN}` (필수) - 인증된 사용자 토큰
- `Content-Type: application/json` (필수)

**요청 바디 (JSON):**
```json
{
  "title": "과외",           // 필수: 일정 제목
  "date": "2025-01-03",     // 필수: YYYY-MM-DD 형식
  "time": "14:00",          // 필수: HH:MM 형식 (24시간)
  "category": "교육",       // 필수: 카테고리
  "description": "수학 과외 수업"  // 선택: 상세 설명
}
```

**성공 응답 (201):**
```json
{
  "success": true,
  "schedule": {
    "id": "uuid-string",
    "user_id": "user-uuid",
    "title": "과외",
    "date": "2025-01-03",
    "time": "14:00:00",
    "category": "교육",
    "description": "수학 과외 수업",
    "created_at": "2025-08-02T08:47:21.527289+00:00",
    "updated_at": "2025-08-02T08:47:21.527289+00:00"
  }
}
```

#### 2. 일정 조회
**엔드포인트:**
```
GET https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/add-schedule
```

**헤더:**
- `Authorization: Bearer {USER_JWT_TOKEN}` (필수)

**쿼리 파라미터 (선택):**
- `date`: 특정 날짜 필터링 (YYYY-MM-DD)
- `limit`: 조회 개수 (기본값: 50)
- `offset`: 페이지네이션 오프셋 (기본값: 0)

**요청 예시:**
```bash
# 전체 일정 조회
curl -H "Authorization: Bearer {USER_TOKEN}" \
  "https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/add-schedule"

# 특정 날짜 일정 조회
curl -H "Authorization: Bearer {USER_TOKEN}" \
  "https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/add-schedule?date=2025-01-03"

# 페이지네이션
curl -H "Authorization: Bearer {USER_TOKEN}" \
  "https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/add-schedule?limit=10&offset=20"
```

#### 3. 특정 일정 조회
**엔드포인트:**
```
GET https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/manage-schedule?id={schedule_id}
```

**헤더:**
- `Authorization: Bearer {USER_JWT_TOKEN}` (필수)

**쿼리 파라미터:**
- `id` (필수): 조회할 일정의 UUID

#### 4. 일정 수정 (권장 - 새로운 API)
**엔드포인트:**
```
PUT https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/edit-schedule
```

**헤더:**
- `Authorization: Bearer {USER_JWT_TOKEN}` (필수)
- `Content-Type: application/json` (필수)

**요청 바디 (JSON):**
```json
{
  "id": "3d81d062-b9c1-473d-b75b-cd7fd395f5f7",  // 필수: 수정할 일정 ID
  "title": "수정된 제목",      // 선택
  "date": "2025-01-04",       // 선택: YYYY-MM-DD 형식
  "time": "15:30",            // 선택: HH:MM 형식
  "category": "개인",         // 선택
  "description": "수정된 설명" // 선택
}
```

**요청 예시:**
```bash
curl -X PUT \
  -H "Authorization: Bearer {USER_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "3d81d062-b9c1-473d-b75b-cd7fd395f5f7",
    "title": "수정된 과외",
    "time": "15:00"
  }' \
  "https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/edit-schedule"
```

**성공 응답 (200):**
```json
{
  "success": true,
  "message": "Schedule updated successfully",
  "schedule": {
    "id": "3d81d062-b9c1-473d-b75b-cd7fd395f5f7",
    "user_id": "user-uuid",
    "title": "수정된 과외",
    "date": "2025-01-03",
    "time": "15:00:00",
    "category": "교육",
    "description": "수학 과외 수업",
    "created_at": "2025-08-02T08:47:21.527289+00:00",
    "updated_at": "2025-08-02T09:15:30.123456+00:00"
  },
  "updatedFields": ["title", "time"]
}
```

#### 5. 일정 수정 (기존 방식)
**엔드포인트:**
```
PUT https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/manage-schedule?id={schedule_id}
```

#### 6. 일정 삭제 (권장 - 새로운 API)
**엔드포인트:**
```
DELETE https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/delete-schedule
```

**헤더:**
- `Authorization: Bearer {USER_JWT_TOKEN}` (필수)
- `Content-Type: application/json` (필수)

**요청 바디 (JSON):**
```json
{
  "id": "3d81d062-b9c1-473d-b75b-cd7fd395f5f7"  // 필수: 삭제할 일정 ID
}
```

**요청 예시:**
```bash
curl -X DELETE \
  -H "Authorization: Bearer {USER_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"id": "3d81d062-b9c1-473d-b75b-cd7fd395f5f7"}' \
  "https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/delete-schedule"
```

**성공 응답 (200):**
```json
{
  "success": true,
  "message": "Schedule deleted successfully",
  "deletedSchedule": {
    "id": "3d81d062-b9c1-473d-b75b-cd7fd395f5f7",
    "title": "과외",
    "date": "2025-01-03",
    "time": "14:00:00"
  }
}
```

#### 7. 일정 삭제 (기존 방식)
**엔드포인트:**
```
DELETE https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/manage-schedule?id={schedule_id}
```

**헤더:**
- `Authorization: Bearer {USER_JWT_TOKEN}` (필수)

**쿼리 파라미터:**
- `id` (필수): 삭제할 일정의 UUID

---

### 🧪 테스트용 Schedule API

#### 테스트용 일정 추가/조회
**엔드포인트:**
```
POST/GET https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/test-schedule
```

**특징:**
- 고정된 테스트 사용자 ID 사용 (`00000000-0000-0000-0000-000000000000`)
- 인증 필요하지만 실제 사용자 계정 불필요
- RLS 우회하여 테스트 가능

**테스트 일정 추가:**
```bash
curl -X POST \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZyYXRiemhzZ2lpeWdnZnJkcXBrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIyMTQ1MTgsImV4cCI6MjA2Nzc5MDUxOH0.FsRC0wTUVrA7JgSk1S25NnCshVFoGRaCgJQNKwE97RI" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "과외",
    "date": "2025-01-03",
    "time": "14:00",
    "category": "교육",
    "description": "수학 과외 수업"
  }' \
  "https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/test-schedule"
```

---

### 🚨 공통 에러 응답

**401 Unauthorized:**
```json
{
  "error": "Unauthorized"
}
```

**400 Bad Request:**
```json
{
  "error": "Missing required fields",
  "required": ["title", "date", "time", "category"]
}
```

**404 Not Found:**
```json
{
  "error": "Schedule not found"
}
```

**500 Internal Server Error:**
```json
{
  "error": "Internal server error",
  "message": "상세 오류 메시지"
}
```

## 📁 프로젝트 구조

```
BE/
├── dict.md                              # 프로젝트 요구사항 문서
├── supabase/
│   ├── config.toml                      # Supabase 설정
│   ├── functions/
│   │   ├── dictionary-search/           # 영어 사전 검색 API ✅
│   │   ├── add-schedule/                # 일정 추가 API ✅
│   │   ├── edit-schedule/               # 일정 수정 API ✅
│   │   ├── delete-schedule/             # 일정 삭제 API ✅ NEW!
│   │   ├── manage-schedule/             # 일정 관리 API ✅
│   │   └── test-schedule/               # 테스트용 API ✅
│   └── migrations/
│       ├── drop_not_null_from_todos_status.sql
│       └── create_schedules_table.sql   # 스케줄 테이블 ✅
├── test-server.js                       # 로컬 테스트 서버 (Node.js)
└── README.md                            # 이 문서
```

## 📊 배포 상태

### Dictionary API
- ✅ **Function ID**: 2bfdb6a6-26fb-4382-a2f9-d2be227dd27d
- ✅ **Status**: ACTIVE
- ✅ **테스트 통과** (hello, computer 등)

### Schedule API
- ✅ **add-schedule Function ID**: 1bc87eff-01e1-47f0-bd9f-3ae078b229e1
- ✅ **edit-schedule Function ID**: 4007a978-8fd6-46d5-af6c-481b9df443b8
- ✅ **delete-schedule Function ID**: 7a5854e6-8a1e-47fe-bbe5-88bde8e5571d 🆕
- ✅ **manage-schedule Function ID**: 25885d4a-f456-4d4a-92d8-bbc97d4ff45d
- ✅ **test-schedule Function ID**: 7491a3c1-decb-4cf9-8e6f-4ac1a67b3c41
- ✅ **데이터베이스 테이블**: schedules 테이블 생성 완료
- ✅ **테스트 통과** (일정 추가/조회/수정/삭제/필터링)

### Supabase 프로젝트 정보:
- **Project URL**: https://fratbzhsgiiyggfrdqpk.supabase.co
- **Database**: PostgreSQL with RLS
- **Authentication**: Anonymous Key 기반

## 🔧 기술 스택

- **백엔드**: Supabase Edge Functions (Deno/TypeScript)
- **데이터베이스**: PostgreSQL (Supabase)
- **사전 API**: [Free Dictionary API](https://dictionaryapi.dev/)
- **테스트**: Node.js (로컬 개발용)
- **인증**: Supabase Anonymous Key + RLS
- **배포**: Supabase Cloud Platform

## 💡 특징

### Dictionary API
1. **무료 사전 API 사용**: OED의 paywall 문제를 해결하기 위해 무료 Dictionary API 사용
2. **최대 3개 결과**: 요구사항에 따라 단어당 최대 3개의 뜻만 반환
3. **품사 정보 포함**: 명사, 동사, 형용사 등 품사 정보 제공

### Schedule API
1. **음성 인식 지원**: 클라이언트의 `ScheduleData` 모델과 호환
2. **데이터 검증**: 날짜(YYYY-MM-DD), 시간(HH:MM) 형식 검증
3. **RLS 보안**: 사용자별 데이터 분리 및 보안
4. **날짜 필터링**: 특정 날짜 일정 조회 가능
5. **CRUD 완전 지원**: 생성/조회/수정/삭제 모든 기능
6. **🆕 개선된 Edit/Delete API**: 사용하기 쉬운 전용 수정/삭제 엔드포인트

### 공통
1. **CORS 지원**: 웹과 모바일 앱에서 직접 호출 가능
2. **에러 처리**: 적절한 HTTP 상태 코드와 에러 메시지 제공
3. **Serverless**: Supabase Edge Functions로 자동 스케일링

## 🌐 앱에서 사용하기

### Dictionary API 사용 예시:
```javascript
const searchWord = async (word) => {
  const response = await fetch(
    `https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/dictionary-search?word=${word}`,
    {
      headers: {
        'Authorization': 'Bearer {YOUR_ANON_KEY}'
      }
    }
  );
  return await response.json();
};
```

### Schedule API 사용 예시:
```javascript
// 일정 추가 (클라이언트 ScheduleData 모델과 호환)
const addSchedule = async (scheduleData) => {
  const response = await fetch(
    'https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/add-schedule',
    {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer {YOUR_USER_TOKEN}',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(scheduleData)
    }
  );
  return await response.json();
};

// 일정 수정 (새로운 API 사용)
const editSchedule = async (scheduleId, updates) => {
  const response = await fetch(
    'https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/edit-schedule',
    {
      method: 'PUT',
      headers: {
        'Authorization': 'Bearer {YOUR_USER_TOKEN}',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        id: scheduleId,
        ...updates
      })
    }
  );
  return await response.json();
};

// 일정 삭제 (새로운 API 사용)
const deleteSchedule = async (scheduleId) => {
  const response = await fetch(
    'https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/delete-schedule',
    {
      method: 'DELETE',
      headers: {
        'Authorization': 'Bearer {YOUR_USER_TOKEN}',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        id: scheduleId
      })
    }
  );
  return await response.json();
};

// 일정 조회
const getSchedules = async (date = null) => {
  const url = date 
    ? `https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/add-schedule?date=${date}`
    : 'https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/add-schedule';
    
  const response = await fetch(url, {
    headers: {
      'Authorization': 'Bearer {YOUR_USER_TOKEN}'
    }
  });
  return await response.json();
};
```

## 📝 API 제공업체

- **Dictionary API**: [Free Dictionary API](https://dictionaryapi.dev/) - 무료, 속도 제한 없음
- **Database**: Supabase PostgreSQL - 실시간 기능, RLS 보안
- **Hosting**: Supabase Edge Functions - 글로벌 CDN, 자동 스케일링

## 🆕 최신 업데이트

### v1.2 - Schedule Delete API 추가
- **새로운 엔드포인트**: `/delete-schedule` 추가
- **개선된 사용성**: ID를 body에 포함하는 방식으로 변경
- **안전한 삭제**: 사용자 권한 확인 및 존재 여부 검증
- **상세한 응답**: 삭제된 일정 정보 포함

### v1.1 - Schedule Edit API 추가
- **새로운 엔드포인트**: `/edit-schedule` 추가
- **개선된 사용성**: ID를 body에 포함하는 방식으로 변경
- **상세한 응답**: 수정된 필드 목록 포함
- **에러 처리 강화**: 더 자세한 에러 메시지와 사용법 안내