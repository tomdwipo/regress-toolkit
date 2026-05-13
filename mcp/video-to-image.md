# video-to-image MCP

Extract frames from Jira video attachments — useful when a bug report includes a screen recording and Claude needs to "see" specific moments.

## Setup

```bash
git clone https://github.com/tomdwipo/video-to-image-mcp.git ~/mcp-servers/video-to-image
cd ~/mcp-servers/video-to-image
uv sync
```

**ffmpeg is required**:
- macOS: `brew install ffmpeg`
- Linux: `apt-get install -y ffmpeg`

## `.mcp.json` stanza

```json
"video-to-image": {
  "command": "{{UV_BIN}}",
  "args": [
    "run", "--directory", "{{MCP_DIR}}/video-to-image",
    "python", "mcp_server.py"
  ]
}
```

No auth — all local.

## Tools

| Tool                            | What it does                                      |
|---------------------------------|---------------------------------------------------|
| `video_info`                    | Duration, fps, codec, resolution                  |
| `extract_frame_at_timestamp`    | Single frame at `HH:MM:SS.mmm`                    |
| `extract_frames_by_count`       | N evenly-spaced frames                            |
| `extract_frames_by_interval`    | One frame every N seconds                         |

## Workflow with `jira-attachment`

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ list_attachments│ →  │ download_all_    │ →  │ video_info →    │
│ (find videos)   │    │ videos           │    │ extract_frames_ │
└─────────────────┘    └──────────────────┘    │ by_interval     │
                                               └────────┬────────┘
                                                        ▼
                                              ┌─────────────────┐
                                              │ Claude reads    │
                                              │ frames as       │
                                              │ images          │
                                              └─────────────────┘
```

## Common gotchas

- **Don't pull every frame.** A 30-second recording at 30 fps = 900 frames. Default to `extract_frames_by_count` with N=6 (or `extract_frames_by_interval` with 5s).
- **Output path.** Frames default to a temp dir; pass an explicit `output_dir` to keep them next to the source video.
- **Large videos hang.** ffmpeg streams the file; if Jira returns a 100 MB recording, `video_info` itself may take >30s. Wrap calls with a timeout.
