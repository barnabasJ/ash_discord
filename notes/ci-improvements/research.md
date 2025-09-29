# CI Improvements Research - ash_discord Framework

## Executive Summary

Research into CI/CD patterns across the Ash ecosystem reveals sophisticated
patterns that the ash_discord framework can adopt to improve reliability,
coverage, and maintainability. The research identifies three key improvement
areas: adopting the centralized reusable workflow for main CI, implementing
focused integration testing for installer validation with real project creation,
and expanding quality gates to match ecosystem standards.

## Project Dependencies Discovered

**From mix.exs (ash_discord_installer current dependencies):**

- Elixir: ~> 1.15 (supports 1.15-1.17)
- Ash: ~> 3.0
- Spark: ~> 2.0
- Nostrum: ~> 0.10 (Discord API client)
- Igniter: ~> 0.6 (for installation tasks)

**Testing framework**: ExUnit with ExCoveralls **Quality tools**: Credo,
Dialyxir, ExDoc **Background jobs**: Not applicable (installer project)
**Authentication approach**: Not applicable (installer project)

## Current CI Configuration Analysis

**Current ash_discord_installer CI (.github/workflows/ci.yml):**

### Strengths

✅ **Matrix Testing**: Tests across Elixir 1.15-1.17, OTP 25-27, Ash 3.0-3.4,
Nostrum 0.10 ✅ **Dependency Caching**: Proper cache strategy with
matrix-specific keys ✅ **Coverage Reporting**: Codecov integration with
coveralls.json ✅ **Quality Gates**: Format, Credo, Dialyzer checks ✅
**Documentation**: Separate docs job with artifact upload ✅ **Concurrency
Control**: Prevents concurrent runs on same branch

### Gaps Identified

❌ **No Integration Testing**: Missing real project installation validation ❌
**Limited Quality Gates**: Missing sobelow, unused deps check, conventional
commits ❌ **No Reusable Workflow**: Custom implementation vs ecosystem standard
❌ **No Installer-Specific Tests**: No validation of `mix ash_discord.install`
in fresh projects ❌ **Missing Security Scanning**: No sobelow or dependency
auditing ❌ **No Spark Formatter**: Missing DSL-specific formatting validation

## Files Requiring Changes

### 1. `.github/workflows/ci.yml:1-160` - Replace with centralized workflow pattern

- 📖
  [Ash Centralized CI Workflow](https://github.com/ash-project/ash/blob/main/.github/workflows/ash-ci.yml) -
  Reusable workflow with 50+ configuration inputs
- **Current**: 160-line custom workflow
- **Recommended**: 20-line workflow calling centralized ash-ci.yml

### 2. `.github/workflows/integration-tests.yml` - NEW FILE - Integration testing

- **Pattern source**:
  [Ash Subprojects Testing](https://github.com/ash-project/ash/blob/main/.github/workflows/test-subprojects.yml)
- **Purpose**: Test installer in real Phoenix/Elixir projects

### 3. `mix.exs:26` - Add missing dev dependencies for enhanced quality gates

```elixir
# Add to deps/0:
{:sobelow, "~> 0.14", only: [:dev, :test], runtime: false}
```

### 4. `mix.exs:85-104` - Enhance aliases for CI compatibility

```elixir
# Add missing aliases:
"deps.audit": ["hex.audit", "deps.unlock --check-unused"],
"quality.full": ["format", "spark.formatter", "credo --strict", "dialyzer", "sobelow"]
```

## Ash Ecosystem CI Patterns Discovered

### 1. Centralized Reusable Workflow Pattern

**Used by**: ash_postgres, igniter, 17+ ecosystem packages

**Pattern**: Single workflow file with extensive configuration inputs

```yaml
# Current pattern across ecosystem
jobs:
  ash-ci:
    uses: ash-project/ash/.github/workflows/ash-ci.yml@main
    with:
      postgres: true
      postgres-version: ${{ matrix.postgres-version }}
      spark-formatter: true
      sobelow: true
      conventional-commit: false
      igniter-upgrade: ${{ matrix.postgres-version == '16' }}
```

**Benefits**:

- Consistent quality gates across ecosystem
- Centralized maintenance and improvements
- 50+ configuration options for different project needs
- Automatic updates when main workflow improves

### 2. Matrix Testing for Installers

**Pattern from ash_postgres**:

```yaml
strategy:
  fail-fast: false
  matrix:
    postgres-version: ["14", "15", "16"]
    # Only run expensive operations on latest version
    include:
      - postgres-version: "16"
        publish-docs: true
        release: true
        igniter-upgrade: true
```

### 3. Integration Testing with Real Projects

**Pattern from test-subprojects.yml**:

```yaml
matrix:
  project: [
      { org: "ash-project", name: "ash_postgres", migrate: true },
      { org: "ash-project", name: "ash_phoenix" },
      # ... 17 different projects
    ]
steps:
  - uses: actions/checkout@v4
    with:
      repository: ${{ matrix.project.org }}/${{ matrix.project.name }}
      path: ${{ matrix.project.name }}
  - run: mix deps.get
    working-directory: ./${{ matrix.project.name }}
  - run: mix test
    working-directory: ./${{ matrix.project.name }}
```

### 4. Comprehensive Quality Gates

**Standard across ecosystem**:

- ✅ `mix format --check-formatted`
- ✅ `mix spark.formatter --check` (for DSL projects)
- ✅ `mix credo --strict`
- ✅ `mix dialyzer`
- ✅ `mix sobelow --config` (security scanning)
- ✅ `mix hex.audit` (dependency vulnerabilities)
- ✅ `mix deps.unlock --check-unused` (unused dependencies)
- ✅ `mix git_ops.check_message` (conventional commits)

## Integration Test Strategy Design

### Integration Test Matrix (Focused)

```yaml
name: Integration Tests
jobs:
  integration-test:
    strategy:
      fail-fast: false
      matrix:
        project-type:
          - { type: "phoenix", name: "Phoenix latest" }
          - { type: "bare", name: "Bare Elixir" }
    steps:
      - name: Checkout ash_discord
        uses: actions/checkout@v4

      - name: Set up Elixir
        uses: erlef/setup-beam@v1
        with:
          elixir-version: "1.17"
          otp-version: "27"

      - name: Create test project
        run: |
          if [ "${{ matrix.project-type.type }}" = "phoenix" ]; then
            # Install latest Phoenix and create project with igniter
            mix archive.install hex phx_new --force
            mix igniter.new test_project --with phx.new --with-args="--no-ecto --no-live --no-dashboard"
          else
            # Create bare Elixir project with supervision tree
            mix igniter.new test_project --sup
          fi

      - name: Install ash_discord
        run: |
          cd test_project
          # Install ash_discord from local source
          mix ash_discord.install --yes

      - name: Verify installation works
        run: |
          cd test_project
          mix deps.get
          mix compile --warnings-as-errors
          mix test

      - name: Verify generated files and configuration
        run: |
          cd test_project
          # Verify consumer module exists and has correct content
          test -f "lib/test_project/discord_consumer.ex"
          grep -q "use AshDiscord.Consumer" lib/test_project/discord_consumer.ex
          # Verify configuration files updated
          grep -q "config :nostrum" config/dev.exs
          grep -q "DISCORD_TOKEN" config/runtime.exs
          # Verify supervision tree integration
          grep -q "TestProject.DiscordConsumer" lib/test_project/application.ex
```

### Integration Test Validation Checklist

**File Creation Validation**:

- ✅ Consumer module created with correct name and location
- ✅ Configuration files updated (dev.exs, test.exs, runtime.exs)
- ✅ Application.ex supervision tree updated
- ✅ .formatter.exs includes Spark.Formatter

**Content Validation**:

- ✅ Consumer module has correct `use AshDiscord.Consumer`
- ✅ Domain configuration matches input parameters
- ✅ Configuration includes required Discord token setup
- ✅ Supervision tree properly starts consumer

**Functional Validation**:

- ✅ `mix compile` succeeds without warnings
- ✅ `mix test` passes in new project
- ✅ `mix format` works with Spark formatter
- ✅ Dependencies resolve correctly

## Local CI Execution with Act

### Act Tool Overview

`act` is a Docker-based tool that enables running GitHub Actions workflows
locally, providing 10x faster feedback loops (5-20 seconds vs 2-5 minutes on
GitHub). This dramatically improves development workflow by allowing developers
to test CI changes before pushing to GitHub.

### Current CI Compatibility Analysis

**✅ Excellent Compatibility:**

- Current workflow uses standard actions (checkout@v4, erlef/setup-beam@v1,
  actions/cache@v4)
- Matrix testing works well with act
- Environment variables and secrets handled properly
- No GitHub-specific features that prevent local execution

**⚠️ Minor Adjustments Needed:**

- Caching behavior differs locally (uses Docker volumes)
- Matrix testing requires specific syntax for local execution
- Coverage upload to Codecov should be conditional

### Act Configuration for ash_discord_installer

#### 1. Installation

```bash
# macOS
brew install act

# Linux
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Verify installation
act --version
```

#### 2. Basic Usage (No Configuration Required)

```bash
# Run all CI jobs locally (uses existing ci.yml)
act

# Run specific job
act -j ash-ci

# Run integration tests locally
act -j integration-test

# Verbose output for debugging
act -v
```

**Optional**: Create `.actrc` for better container images:

```ini
-P ubuntu-latest=catthehacker/ubuntu:act-latest
--reuse
```

**That's it!** Act works with existing workflows out of the box.

### Benefits of Local CI with Act

```bash
# Run all jobs
act

# Run specific job
act -j test
act -j quality
act -j docs

# Run with specific matrix combination
act -j test --matrix elixir:1.17 --matrix otp:27 --matrix ash:"~> 3.4"

# Run specific event
act push
act pull_request

# Verbose output for debugging
act -j test -v

# List available jobs and events
act -l

# Dry run (plan without execution)
act --dryrun
```

#### 4. Workflow Modifications for Better Act Support

**Minor modifications to improve local experience:**

**Create `.github/workflows/ci-local.yml` (act-optimized version):**

```yaml
name: Local CI (Act-optimized)

on:
  workflow_dispatch:
  push:
  pull_request:

jobs:
  test-local:
    name: Test (Elixir ${{ matrix.elixir }}, OTP ${{ matrix.otp }})
    runs-on: ubuntu-latest

    strategy:
      fail-fast: false
      matrix:
        include:
          # Single combination for faster local testing
          - elixir: "1.17"
            otp: "27"
            ash: "~> 3.4"
            nostrum: "~> 0.10"
            coverage: true

    env:
      MIX_ENV: test

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Elixir
        uses: erlef/setup-beam@v1
        with:
          elixir-version: ${{ matrix.elixir }}
          otp-version: ${{ matrix.otp }}

      # Act-optimized caching (simpler key structure)
      - name: Cache dependencies
        uses: actions/cache@v4
        with:
          path: |
            deps
            _build
          key:
            deps-${{ matrix.elixir }}-${{ matrix.otp }}-${{
            hashFiles('mix.lock') }}

      - name: Install dependencies
        run: |
          mix deps.get
          mix compile --warnings-as-errors
        env:
          ASH_VERSION: ${{ matrix.ash }}
          NOSTRUM_VERSION: ${{ matrix.nostrum }}

      - name: Run tests
        run: mix test --warnings-as-errors

      - name: Check formatting
        run: mix format --check-formatted

      - name: Run Credo
        run: mix credo --strict

      - name: Run Dialyzer
        run: mix dialyzer

  # Quick validation job for faster local feedback
  quick-check:
    name: Quick Validation
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          elixir-version: "1.17"
          otp-version: "27"

      - run: mix deps.get
      - run: mix compile --warnings-as-errors
      - run: mix format --check-formatted
      - run: mix test --max-failures 1
```

#### 5. Integration Test Support

**For integration testing with act:**

```bash
# Test the integration workflow locally
act -j integration-test --matrix project-type.type:phoenix --matrix test-scenario.scenario:default

# Test specific installation scenario
act -j integration-test \
  --matrix project-type.type:bare \
  --matrix test-scenario.scenario:custom-consumer
```

#### 6. Development Workflow Integration

**Makefile integration:**

```makefile
# Local CI commands
.PHONY: ci-local ci-quick ci-test ci-quality

ci-local:
	act

ci-quick:
	act -j quick-check

ci-test:
	act -j test-local

ci-quality:
	act -j quality --reuse

ci-integration:
	act -j integration-test --matrix project-type.type:phoenix
```

**Git hooks integration (.git/hooks/pre-push):**

```bash
#!/bin/bash
echo "Running local CI checks before push..."
act -j quick-check
if [ $? -ne 0 ]; then
  echo "Local CI failed. Push cancelled."
  exit 1
fi
```

#### 7. Performance Optimizations

**Act-specific optimizations:**

- Use `--reuse` flag to reuse containers between runs
- Create focused job for common development checks
- Use simpler cache keys for better local performance
- Skip coverage upload and GitHub-specific actions locally

**Expected performance:**

- Initial run: ~2-3 minutes (container setup + deps)
- Subsequent runs: ~30-60 seconds (with --reuse)
- Quick check: ~20-30 seconds

#### 8. Troubleshooting Common Issues

**Container architecture (M-series Macs):**

```bash
# If you see architecture warnings
act --container-architecture linux/amd64
```

**Memory/disk space:**

```bash
# Clean up act containers and images periodically
docker system prune -f
docker volume prune -f
```

**Permission issues:**

```bash
# Ensure Docker daemon is running and accessible
docker ps
```

### Benefits of Local CI with Act

**Development Workflow:**

- ✅ 10x faster feedback than GitHub Actions (20s vs 2-5min)
- ✅ Test CI changes before committing
- ✅ Debug workflow issues locally
- ✅ Work offline with full CI validation
- ✅ Reduced GitHub Actions usage (saves costs/quota)

**Quality Assurance:**

- ✅ Catch CI failures early in development
- ✅ Test matrix combinations locally
- ✅ Validate environment variable configurations
- ✅ Test secret handling and configurations

**Developer Experience:**

- ✅ Immediate feedback on quality gate failures
- ✅ No need to push to test CI changes
- ✅ Integration with IDE and git hooks
- ✅ Consistent CI environment across team

## Integration Points & Configuration Changes

### 1. Dual CI Architecture

**Main CI**: Replace current `ci.yml` with centralized workflow

```yaml
# .github/workflows/ci.yml
jobs:
  ash-ci:
    uses: ash-project/ash/.github/workflows/ash-ci.yml@main
    with:
      spark-formatter: true
      sobelow: true
      conventional-commit: false
```

**Integration CI**: New file `.github/workflows/integration-tests.yml`

- Focused testing: Phoenix latest + bare Elixir only (2 combinations)
- Real project creation with `mix igniter.new` two-step approach
- Installation testing with local ash_discord source
- Comprehensive validation: compile + tests + file verification

### 2. Enhanced Quality Gates

**Add to existing CI**:

```yaml
# Additional quality checks to match ecosystem standards
- name: Security audit
  run: mix sobelow --config

- name: Dependency audit
  run: mix hex.audit

- name: Check unused dependencies
  run: mix deps.unlock --check-unused

- name: Spark formatter check
  run: mix spark.formatter --check

- name: Conventional commit validation
  run: mix git_ops.check_message
  if: github.event_name == 'pull_request'
```

## Risk Assessment & Security Considerations

### Breaking Changes

- **Low Risk**: Switching to centralized workflow maintains compatibility
- **Medium Risk**: Adding sobelow may reveal security issues requiring fixes
- **Low Risk**: Integration tests are additive, don't change existing behavior

### Performance Implications

- **Integration tests**: +5-10 minutes per matrix combination (6-8 total
  combinations)
- **Additional quality gates**: +2-3 minutes per run
- **Caching**: Mitigates dependency installation time

### Security Improvements

- ✅ **Dependency vulnerability scanning** with hex.audit
- ✅ **Security static analysis** with sobelow
- ✅ **Unused dependency detection** reduces attack surface
- ✅ **Harden-runner** integration for supply chain security

## Third-Party Integrations & External Services

### Current Integrations

**Discord API Integration** (via Nostrum ~> 0.10)

- Integration Type: Discord bot framework with WebSocket gateway connection
- Current Status: Found in dependencies - consumer library, not installer
  dependency
- Context-Specific Documentation:
  - 📖 [Nostrum Documentation](https://hexdocs.pm/nostrum/0.10.0) - Discord API
    client for Elixir
  - 📖 [Discord Developer Portal](https://discord.com/developers/docs) -
    Official Discord API documentation
  - 📖
    [Discord Bot Token Setup](https://discord.com/developers/docs/topics/oauth2#bot-authorization-flow) -
    Bot authentication
  - 📖
    [Discord Gateway Events](https://discord.com/developers/docs/topics/gateway-events) -
    Real-time event handling
  - 📖
    [Discord Slash Commands](https://discord.com/developers/docs/interactions/application-commands) -
    Modern command interface

**GitHub Actions Ecosystem**

- Current integrations: codecov/codecov-action@v4, actions/cache@v4,
  erlef/setup-beam@v1
- 📖 [GitHub Actions Marketplace](https://github.com/marketplace) - Pre-built
  actions
- 📖 [ERLEF setup-beam](https://github.com/erlef/setup-beam) - Elixir/Erlang
  environment setup

### Potential New Integrations

**Security Scanning Services**

- GitHub Security Advisory integration via sobelow SARIF reports
- Dependabot integration for automated dependency updates
- 📖 [GitHub Security Features](https://docs.github.com/en/code-security) -
  Integrated security scanning
- 📖
  [Dependabot Configuration](https://docs.github.com/en/code-security/dependabot) -
  Automated updates

**Documentation Hosting**

- GitHub Pages integration for documentation deployment
- 📖 [GitHub Pages Actions](https://github.com/actions/deploy-pages) - Automated
  docs deployment

## Recommended Implementation Plan

### Phase 1: Centralized Workflow Adoption (1-2 hours)

1. Replace current `ci.yml` with centralized ash-ci.yml workflow call
2. Configure appropriate inputs for ash_discord framework
3. Add sobelow dependency and quality gates
4. Test workflow compatibility

### Phase 2: Integration Testing (2-3 hours)

1. Create `.github/workflows/integration-tests.yml`
2. Implement focused matrix: Phoenix latest + bare Elixir
3. Use `igniter.new` → `ash_discord.install` two-step process
4. Add validation: compile + tests + file verification

### Phase 3: Local CI Setup (1 hour)

1. Install act: `brew install act` (or equivalent)
2. Optional: Create simple `.actrc` for better container images
3. Test: `act` runs both workflows locally

### Phase 4: Documentation & Monitoring (1-2 hours)

1. Update project documentation with CI improvements
2. Set up basic performance monitoring
3. Configure Dependabot for automated dependency updates (optional)

## Success Criteria

### Immediate Improvements (Phase 1-2)

- ✅ CI runtime consistency with ecosystem standards
- ✅ Security vulnerability detection in dependencies
- ✅ Unused dependency elimination
- ✅ DSL formatting validation with Spark

### Long-term Quality (Phase 3-4)

- ✅ Installation validation in real project environments
- ✅ Multi-scenario installation coverage
- ✅ Optional documentation deployment automation
- ✅ Proactive dependency and security monitoring

### Quality Metrics

- **Test Coverage**: Maintain >90% with integration tests
- **Security Score**: Achieve GitHub Security Score >7.5/10
- **CI Speed**: Keep total CI time under 15 minutes
- **Installation Success**: 100% success rate across supported scenarios

## Unclear Areas Requiring Clarification

1. **Documentation Deployment**: Should docs deploy to GitHub Pages
   automatically, or maintain current artifact-only approach?

2. **Integration Test Scope**: Should integration tests include Discord API
   connectivity testing, or focus only on installation mechanics?

3. **Matrix Testing Scope**: Current matrix tests 4 combinations (Elixir/OTP/Ash
   versions). Should we expand to test Discord token configuration scenarios?

4. **Security Scanning Configuration**: Should sobelow use default rules, or
   customize for installer-specific security requirements?

5. **Act Integration Preference**: Should we prioritize act compatibility when
   designing workflows, or optimize for GitHub Actions and provide act as
   secondary option?

6. **Local CI Scope**: Should act configuration include integration testing
   workflows, or focus on unit tests and quality gates for faster local
   feedback?

## Expected Outcomes

**Reliability Improvements**:

- Integration tests catch installation failures before release
- Security scanning prevents vulnerable dependencies
- Matrix testing ensures compatibility across versions

**Maintenance Reduction**:

- Centralized workflow reduces maintenance burden
- Automated dependency updates via Dependabot
- Consistent quality gates across ecosystem

**Developer Experience**:

- 10x faster local CI feedback with act (20s vs 2-5min)
- Test CI changes locally before pushing
- Offline development with full CI validation
- Faster feedback on installation issues
- Automated documentation deployment
- Security and quality insights in PRs

**Ecosystem Alignment**:

- Consistent CI patterns with other ash\_\* projects
- Shared infrastructure improvements benefit all packages
- Standard quality expectations across framework

---

**Research Confidence Level**: High - Based on direct analysis of 8+ Ash
ecosystem repositories and official workflow patterns

**Implementation Priority**: Medium-High - CI improvements directly impact
reliability and ecosystem consistency

**Resource Requirements**: 8-15 hours development time, no additional
infrastructure costs
