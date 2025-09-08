# Demo Project

## Overview

Development workspace with reusable components and AI workflow management system.

## Project Structure

```
demo/
├── README.md                   # This file
├── scripts/                    # Automation scripts
│   ├── create-repo.sh          # General repository creation
│   └── create-cli-repo.sh      # CLI project creation with infrastructure
├── lib/                        # Shared libraries
│   └── log.sh                 # Logging utilities
└── .agents/                    # AI Workflow Management System (separate project)
    └── (see .agents/README.md for details)
```

## Available Scripts

### Repository Creation
- `scripts/create-repo.sh` - Create GitHub repositories with customizable options
- `scripts/create-cli-repo.sh` - Create CLI applications with full infrastructure

## Usage

### Usage

```bash
# General repository
./scripts/create-repo.sh --name=my-project --private --clone

# CLI application with infrastructure
./scripts/create-cli-repo.sh --name=my-cli-tool --private
```

## AI Workflow Management

This repository includes a separate `.agents/` project for AI workflow management. See `.agents/README.md` for complete documentation on:

- AI behavior rules and preferences
- Logging and tracking systems  
- Validation tools
- Cross-project reusability

The agents system is designed as a standalone project that can be copied to any repository for consistent AI-assisted development workflows.