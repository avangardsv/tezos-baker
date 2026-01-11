# Contributing to Tezos Baker Study Mode

Thank you for your interest in contributing! This is an educational project designed to help people learn Tezos baking fundamentals.

## How to Contribute

### Reporting Issues
- Use GitHub Issues to report bugs or suggest improvements
- Include your system info (OS, Docker version)
- Provide error logs and steps to reproduce

### Suggesting Enhancements
- Educational improvements (better explanations, diagrams)
- Script improvements (better error handling, logging)
- Documentation clarifications
- Additional troubleshooting guides

### Pull Requests
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Test your changes on Ghostnet testnet
4. Commit with clear messages
5. Push to your fork
6. Open a Pull Request with detailed description

## What We Accept
✅ Educational improvements
✅ Better documentation
✅ Bug fixes for testnet functionality
✅ Additional npm scripts for common tasks
✅ Improved monitoring/logging
✅ Better error messages

## What We Don't Accept
❌ Production/mainnet features (out of scope)
❌ Complex dependencies (keep it simple)
❌ Breaking changes to core workflow
❌ Features requiring paid services

## Code Style
- Use clear, descriptive variable names
- Add comments explaining non-obvious logic
- Follow existing bash script patterns
- Test on both x86_64 and arm64 if possible

## Testing
- Test all changes on Ghostnet testnet
- Verify scripts work from fresh clone
- Check that monitoring stack still works
- Ensure .env.example is updated if adding new variables

## Questions?
Open a GitHub Discussion or Issue - we're here to help learners!
