# Local CI Development Guide

This guide explains how to run CI workflows locally using the
[act](https://github.com/nektos/act) tool for faster development feedback.

## Installation

### macOS

```bash
brew install act
```

### Linux (Ubuntu/Debian)

```bash
curl -s https://api.github.com/repos/nektos/act/releases/latest | \
  grep "browser_download_url.*act_Linux_x86_64.tar.gz" | \
  cut -d : -f 2,3 | \
  tr -d \" | \
  wget -qi - && \
  tar xzf act_Linux_x86_64.tar.gz && \
  sudo mv act /usr/local/bin/
```

### Verify Installation

```bash
act --version
```

## Basic Usage

The project includes an `.actrc` configuration file that optimizes act for local
development.

### Run All CI Workflows

```bash
act
```

### Run Specific Workflows

```bash
# Main CI workflow (centralized ash ecosystem checks)
act -W .github/workflows/ci.yml

# Integration tests (Phoenix + Bare Elixir)
act -W .github/workflows/integration-tests.yml

# Local CI (optimized for speed)
act -W .github/workflows/ci-local.yml
```

### Run Specific Jobs

```bash
# Run just the centralized CI
act -j ci

# Run integration tests
act -j integration-test
```

## Performance Optimization

### Local CI Workflow

The `ci-local.yml` workflow is specifically optimized for local development:

- **Single Elixir/OTP version** (1.17/27) instead of matrix
- **Essential checks only**: format, credo, sobelow, test
- **No dialyzer** (slow, run this occasionally)
- **Manual trigger** (workflow_dispatch)

```bash
# Run optimized local CI
act -W .github/workflows/ci-local.yml
```

### Expected Performance

- **Local act execution**: ~60 seconds
- **GitHub Actions**: 2-5 minutes
- **Performance improvement**: ~4-8x faster feedback

## Development Workflow Integration

### Pre-push Validation

Add to your git pre-push hook:

```bash
#!/bin/sh
echo "Running local CI checks..."
act -W .github/workflows/ci-local.yml
```

### IDE Integration

Most IDEs can be configured to run act workflows:

**VS Code**: Add to `.vscode/tasks.json`

```json
{
  "label": "Local CI",
  "type": "shell",
  "command": "act",
  "args": ["-W", ".github/workflows/ci-local.yml"],
  "group": "test"
}
```

## Troubleshooting

### Common Issues

#### "Error: Cannot connect to Docker"

- Ensure Docker is running: `docker info`
- Check Docker permissions: `docker run hello-world`

#### "Pull image failed"

- Use local Docker images: `act -P ubuntu-latest=ubuntu:latest`
- Or specify in `.actrc`: `-P ubuntu-latest=ubuntu:latest`

#### "Out of disk space"

- Clean up act containers: `docker system prune`
- Use `--reuse` flag (already in `.actrc`)

#### Memory/Performance Issues

- Limit containers: `act --container-cap 1`
- Use smaller base image: `act -P ubuntu-latest=node:16-alpine`

### Debug Mode

```bash
# Verbose output
act --verbose

# Dry run (validate without execution)
act --dryrun

# List available workflows
act --list
```

## Available Workflows

| Workflow              | File                    | Purpose                           | Speed  |
| --------------------- | ----------------------- | --------------------------------- | ------ |
| **Main CI**           | `ci.yml`                | Centralized Ash ecosystem checks  | Medium |
| **Integration Tests** | `integration-tests.yml` | Real project installation testing | Slow   |
| **Local CI**          | `ci-local.yml`          | Fast local development checks     | Fast   |

## Quality Checks Included

### Main CI (Centralized)

- ✅ Format checking (mix format)
- ✅ Static analysis (credo)
- ✅ Type checking (dialyzer)
- ✅ Security scanning (sobelow)
- ✅ Spark formatter
- ✅ Dependency audit
- ✅ Tests with coverage

### Local CI (Optimized)

- ✅ Format checking (mix format)
- ✅ Static analysis (credo --strict)
- ✅ Security scanning (sobelow --config)
- ✅ Tests (warnings as errors)
- ❌ Type checking (dialyzer) - too slow
- ❌ Spark formatter - handled by main CI

### Integration Tests

- ✅ Phoenix project creation + installation
- ✅ Bare Elixir project creation + installation
- ✅ File generation verification
- ✅ Configuration validation
- ✅ Compilation without errors

## Best Practices

1. **Run local CI frequently** during development
2. **Run full CI periodically** (daily/weekly)
3. **Run integration tests** before major releases
4. **Use `--reuse`** to speed up subsequent runs
5. **Clean up containers** weekly with `docker system prune`

## Configuration

The `.actrc` file contains optimized settings:

```
# Use better Ubuntu container
-P ubuntu-latest=catthehacker/ubuntu:act-latest

# Reuse containers for speed
--reuse
```

You can override these with command-line flags:

```bash
# Use different container
act -P ubuntu-latest=ubuntu:20.04

# Don't reuse containers
act --rm
```
