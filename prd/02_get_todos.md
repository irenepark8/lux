## 할 일 목록 조회 (GET)

아래의 `curl` 명령어를 터미널에서 실행하여 특정 날짜의 할 일 목록을 조회할 수 있습니다.

### 오늘(2025-07-11) 할 일 조회

```bash
curl -X GET 'https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/get_todo?date=2025-07-11' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZyYXRiemhzZ2lpeWdnZnJkcXBrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIyMTQ1MTgsImV4cCI6MjA2Nzc5MDUxOH0.FsRC0wTUVrA7JgSk1S25NnCshVFoGRaCgJQNKwE97RI'
```

### 내일(2025-07-12) 할 일 조회

아래 명령어를 실행하면 "내일 할 일"로 추가했던 1개의 항목이 조회됩니다.

```bash
curl -X GET 'https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/get_todo?date=2025-07-12' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZyYXRiemhzZ2lpeWdnZnJkcXBrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIyMTQ1MTgsImV4cCI6MjA2Nzc5MDUxOH0.FsRC0wTUVrA7JgSk1S25NnCshVFoGRaCgJQNKwE97RI'
```

### 오늘 할 일 추가 2

```bash
curl -X POST 'https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/add_todo' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZyYXRiemhzZ2lpeWdnZnJkcXBrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIyMTQ1MTgsImV4cCI6MjA2Nzc5MDUxOH0.FsRC0wTUVrA7JgSk1S25NnCshVFoGRaCgJQNKwE97RI' \
  -H 'Content-Type: application/json' \
  -d '{
    "title": "Read Chapter 5 of Physics",
    "due_date": "2025-07-11"
  }'
```
