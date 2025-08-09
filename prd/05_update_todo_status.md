# 할 일 상태 수정 (PATCH)

아래의 `curl` 명령어를 터미널에서 실행하여 특정 할 일의 상태를 수정할 수 있습니다.

### ID가 1인 할 일의 상태를 'o'(완료)로 변경

```bash
curl -X PATCH 'https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/update_todo_status' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZyYXRiemhzZ2lpeWdnZnJkcXBrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIyMTQ1MTgsImV4cCI6MjA2Nzc5MDUxOH0.FsRC0wTUVrA7JgSk1S25NnCshVFoGRaCgJQNKwE97RI' \
  -H 'Content-Type: application/json' \
  -d '{
    "id": 1,
    "status": "o"
  }'
```

### ID가 1인 할 일의 상태를 '~'(진행 중)으로 변경

```bash
curl -X PATCH 'https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/update_todo_status' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZyYXRiemhzZ2lpeWdnZnJkcXBrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIyMTQ1MTgsImV4cCI6MjA2Nzc5MDUxOH0.FsRC0wTUVrA7JgSk1S25NnCshVFoGRaCgJQNKwE97RI' \
  -H 'Content-Type: application/json' \
  -d '{
    "id": 1,
    "status": "~"
  }'
```

### ID가 1인 할 일의 상태를 null로 변경

```bash
curl -X PATCH 'https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1/update_todo_status' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZyYXRiemhzZ2lpeWdnZnJkcXBrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIyMTQ1MTgsImV4cCI6MjA2Nzc5MDUxOH0.FsRC0wTUVrA7JgSk1S25NnCshVFoGRaCgJQNKwE97RI' \
  -H 'Content-Type: application/json' \
  -d '{
    "id": 1,
    "status": null
  }'
```

```

```
