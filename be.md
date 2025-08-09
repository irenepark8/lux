# Dictionary API Backend

영어 단어 검색 및 뜻 제공 API 서버

## 개요

이 프로젝트는 앱에서 사용할 영어 단어 검색 기능을 제공하는 백엔드 API입니다. 사용자가 단어를 검색하면 최대 3개의 단어 뜻과 품사를 반환합니다.

## 기능

- 영어 단어 검색
- 최대 3개의 단어 뜻 반환
- 품사 정보 제공 (명사, 동사, 형용사 등)
- CORS 지원으로 웹/앱에서 사용 가능

## API 사용법

### 엔드포인트

```
GET /dictionary-search?word={단어}
```

### 요청 예시

```bash
curl "http://localhost:3002/dictionary-search?word=hello"
```

### 응답 형식

#### 성공 시 (200 OK)
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

#### 단어를 찾을 수 없는 경우 (404 Not Found)
```json
{
  "error": "Word not found",
  "word": "xyzabc123",
  "results": []
}
```

#### 파라미터 누락 시 (400 Bad Request)
```json
{
  "error": "Word parameter is required",
  "usage": "/dictionary-search?word=hello"
}
```

## 프로젝트 구조

```
BE/
├── dict.md                              # 프로젝트 요구사항 문서
├── supabase/
│   ├── config.toml                      # Supabase 설정
│   ├── functions/
│   │   └── dictionary-search/
│   │       └── index.ts                 # Edge Function 구현
│   └── migrations/                      # 데이터베이스 마이그레이션
├── test-server.js                       # 로컬 테스트 서버 (Node.js)
└── README.md                            # 이 문서
```

## 로컬 개발 환경 설정

### 1. 테스트 서버 실행 (Node.js)

```bash
cd BE
node test-server.js
```

서버가 http://localhost:3002 에서 실행됩니다.

### 2. API 테스트

```bash
# 기본 테스트
curl "http://localhost:3002/dictionary-search?word=hello"

# 다른 단어 테스트  
curl "http://localhost:3002/dictionary-search?word=computer"

# 존재하지 않는 단어 테스트
curl "http://localhost:3002/dictionary-search?word=nonexistentword"
```

### 3. Supabase Edge Function 배포 (추후)

Docker Desktop이 설치되어 있고 Supabase 프로젝트가 설정된 경우:

```bash
# Supabase 로컬 개발 환경 시작
npx supabase start

# Edge Function 배포
npx supabase functions deploy dictionary-search

# 프로덕션 배포
npx supabase functions deploy dictionary-search --project-ref YOUR_PROJECT_REF
```

## 기술 스택

- **백엔드**: Supabase Edge Functions (Deno/TypeScript)
- **사전 API**: [Free Dictionary API](https://dictionaryapi.dev/)
- **테스트**: Node.js (로컬 개발용)
- **브라우저 자동화**: Playwright (MCP 연동)

## 특징

1. **무료 사전 API 사용**: OED의 paywall 문제를 해결하기 위해 무료 Dictionary API 사용
2. **최대 3개 결과**: 요구사항에 따라 단어당 최대 3개의 뜻만 반환
3. **품사 정보 포함**: 명사, 동사, 형용사 등 품사 정보 제공
4. **CORS 지원**: 웹과 모바일 앱에서 직접 호출 가능
5. **에러 처리**: 적절한 HTTP 상태 코드와 에러 메시지 제공

## API 제공업체

이 프로젝트는 [Free Dictionary API](https://dictionaryapi.dev/)를 사용합니다.
- 무료로 사용 가능
- 속도 제한 없음
- 신뢰할 수 있는 영어 사전 데이터 제공