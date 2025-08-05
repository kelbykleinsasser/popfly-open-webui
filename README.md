# Open WebUI Development Project

This is a development setup for Open WebUI, allowing you to modify core behaviors.

## Quick Setup

```bash
cd /Users/kelbyk/Dev/Popfly/open-webui
chmod +x setup-dev.sh
./setup-dev.sh
```

## Project Structure

```
Popfly/
├── open-webui/           # This project
│   ├── setup-dev.sh     # Setup script
│   ├── README.md        # This file
│   └── src/             # Cloned Open WebUI source (created by setup)
│       ├── backend/     # Python FastAPI backend
│       ├── src/         # Frontend Svelte application
│       ├── venv/        # Python virtual environment
│       └── start-dev.sh # Development server script
├── transformations/     # Your other projects...
├── talkjs/
└── ...
```

## Key Files for Modifications

- `src/backend/main.py` - Main FastAPI application
- `src/backend/apps/` - Core application modules
- `src/backend/models/` - Database models
- `src/src/` - Frontend Svelte components

## Starting Development

After setup:
```bash
cd src
./start-dev.sh
```

Access at: http://localhost:8081