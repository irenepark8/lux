# 할 일 수정 (PATCH)

아래의 `curl` 명령어를 터미널에서 실행하여 특정 할 일의 내용을 수정할 수 있습니다.

### ID가 1인 할 일의 제목과 마감일 수정

```bash
curl -X PATCH 'https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/edit_todo' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZyYXRiemhzZ2lpeWdnZnJkcXBrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIyMTQ1MTgsImV4cCI6MjA2Nzc5MDUxOH0.FsRC0wTUVrA7JgSk1S25NnCshVFoGRaCgJQNKwE97RI' \
  -H 'Content-Type: application/json' \
  -d '{
    "id": 1,
    "title": "새로운 할 일 제목",
    "due_date": "2025-07-13"
  }'
```
