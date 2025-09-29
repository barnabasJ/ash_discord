# CI Improvements - Strategic Implementation Plan

## ash_discord_installer CI Enhancement

## Impact Analysis Summary

**Based on comprehensive research of notes/ci-improvements/research.md:**

### Codebase Changes Required

- **`.github/workflows/ci.yml:1-160`** - Replace 160-line custom workflow with
  20-line centralized call
- **`.github/workflows/integration-tests.yml`** - NEW FILE - Focused integration
  testing workflow
- **`mix.exs`** - Add sobelow dependency for security scanning
- **`mix.exs`** - Enhance aliases for comprehensive quality gates

### Existing Patterns Discovered

- **Matrix Testing Pattern**: Current 4-combination matrix (Elixir 1.15-1.17,
  OTP 25-27, Ash 3.0-3.4)
- **Caching Strategy**: Matrix-specific cache keys with proper dependency
  management
- **Quality Gates**: Format, Credo, Dialyzer foundation with coverage reporting
- **Concurrency Control**: Branch-specific concurrency prevention

### Third-Party Integrations Identified

- **Ash Centralized Workflow**:
  `ash-project/ash/.github/workflows/ash-ci.yml@main` with 50+ inputs
- **GitHub Actions Ecosystem**: codecov/codecov-action@v4, erlef/setup-beam@v1,
  actions/cache@v4
- **Act Tool Integration**: Docker-based local CI execution for 10x faster
  feedback
- **Security Services**: Sobelow 0.14+ for static security analysis, hex.audit
  for dependency vulnerabilities

## Feature Specification

### User Stories & Acceptance Criteria

**As a Framework Maintainer:**

- **Story**: Consistent CI quality gates across ash ecosystem packages
- **Criteria**: Main CI uses centralized ash-ci.yml workflow with
  ecosystem-standard quality checks

**As an Installer Developer:**

- **Story**: Real-world installation validation before release
- **Criteria**: Integration tests validate ash_discord.install in actual Phoenix
  and bare Elixir projects

**As a Contributor:**

- **Story**: Fast local CI feedback during development
- **Criteria**: Act tool enables full CI validation in 20 seconds vs 2-5 minutes
  on GitHub

**As a Security-Conscious Developer:**

- **Story**: Proactive vulnerability detection in dependencies and code
- **Criteria**: Automated sobelow security scanning and hex.audit dependency
  vulnerability detection

### API Contracts & Data Flow

#### Centralized Workflow Integration

```yaml
# Main CI workflow call pattern
jobs:
  test:
    uses: ash-project/ash/.github/workflows/ash-ci.yml@main
    with:
      spark-formatter: true # DSL formatting validation
      sobelow: true # Security static analysis
      conventional-commit: false # Current project standard
```

#### Integration Testing Workflow

```yaml
# Integration test matrix configuration
strategy:
  fail-fast: false
  matrix:
    project-type:
      - { type: "phoenix", name: "Phoenix Latest" }
      - { type: "bare", name: "Bare Elixir" }

# Test execution flow
steps:
  - Create test project (igniter.new --with phx.new --with-args="--no-ecto
    --no-live --no-dashboard" OR igniter.new --sup)
  - Install ash_discord from local source
  - Validate installation: compile + test + file verification
```

### State Management Requirements

#### Workflow State Coordination

- **Parallel Execution**: Main CI and integration tests run independently on
  same triggers
- **Status Reporting**: Both workflows report as required status checks for PR
  merging
- **Cache Management**: Shared cache strategy across workflows with consistent
  keys

#### Local Development State

- **Act Integration**: Workflows compatible with local execution via act tool
- **Container Reuse**: `--reuse` flag enables container persistence between runs
- **Development Cache**: Simplified cache keys for optimal local performance

### Integration Points with Existing Systems

#### Ash Ecosystem Integration

- **Centralized Workflow**: Inherits 50+ configuration options from
  ash-project/ash
- **Quality Standards**: Aligns with ecosystem security and formatting standards
- **Automatic Updates**: Benefits from centralized workflow improvements
  automatically

#### GitHub Actions Ecosystem

- **Action Compatibility**: Uses standard actions (checkout@v4,
  erlef/setup-beam@v1)
- **Secret Management**: Compatible with existing GITHUB_TOKEN and CODECOV_TOKEN
- **Matrix Execution**: Leverages GitHub's matrix strategy for parallel
  execution

## Technical Design Using Existing Patterns

### Data Model Changes - mix.exs Enhancement

```elixir
# Following existing dependency pattern from ash_postgres, igniter projects
def deps do
  [
    # ... existing deps ...
    {:sobelow, "~> 0.14", only: [:dev, :test], runtime: false}
  ]
end

# Following existing alias pattern from ash_authentication_phoenix
def aliases do
  [
    # ... existing aliases ...
    "deps.audit": ["hex.audit", "deps.unlock --check-unused"],
    "quality.full": ["format", "spark.formatter", "credo --strict", "dialyzer", "sobelow"]
  ]
end
```

### Workflow Architecture Following Discovered Patterns

#### Main CI - Centralized Pattern (ash_postgres style)

```yaml
# .github/workflows/ci.yml - Following ash_postgres:6-20
name: ash_discord_installer CI
on: [push, pull_request]

jobs:
  test:
    uses: ash-project/ash/.github/workflows/ash-ci.yml@main
    with:
      spark-formatter: true
      sobelow: true
      conventional-commit: false
    secrets: inherit
```

#### Integration Testing - Subproject Pattern (ash/test-subprojects.yml style)

```yaml
# .github/workflows/integration-tests.yml - Following ash test-subprojects pattern
name: ash_discord_installer Integration Tests
on: [push, pull_request]

jobs:
  integration-test:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        project-type:
          - {
              type: "phoenix",
              name: "Phoenix Latest",
              create:
                'mix igniter.new test_project --with phx.new
                --with-args="--no-ecto --no-live --no-dashboard"',
            }
          - {
              type: "bare",
              name: "Bare Elixir",
              create: "mix igniter.new test_project --sup",
            }

    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          elixir-version: "1.17"
          otp-version: "27"

      - name: Create test project
        run: ${{ matrix.project-type.create }}

      - name: Install ash_discord
        run: |
          cd test_project
          mix ash_discord.install --yes

      - name: Verify installation
        run: |
          cd test_project
          mix deps.get
          mix compile --warnings-as-errors
          mix test
```

### Configuration Management Following Project Conventions

#### Act Configuration - Minimal Setup (following act documentation)

```ini
# .actrc - Optional for better local performance
-P ubuntu-latest=catthehacker/ubuntu:act-latest
--reuse
```

#### Cache Strategy - Following Current Matrix Pattern

```yaml
# Main CI Cache Strategy (extending current pattern from ci.yml:45-52)
- name: Cache dependencies
  uses: actions/cache@v4
  with:
    path: |
      deps
      _build
    key:
      deps-${{ matrix.elixir }}-${{ matrix.otp }}-${{ matrix.ash }}-${{
      hashFiles('mix.lock') }}

# Integration Tests Cache Strategy
- name: Cache dependencies
  uses: actions/cache@v4
  with:
    path: |
      deps
      _build
    key:
      integration-${{ matrix.project-type.type }}-${{ hashFiles('mix.lock') }}
```

## Third-Party Integrations

### Ash Centralized Workflow Integration

- **API**: `ash-project/ash/.github/workflows/ash-ci.yml@main`
- **Configuration Inputs**: 50+ available options for customization
- **Specific Usage**:
  - `spark-formatter: true` - DSL formatting validation
  - `sobelow: true` - Security static analysis
  - `conventional-commit: false` - Following project standards
- **Authentication**: Uses GitHub's built-in GITHUB_TOKEN and secrets
  inheritance

### Security Scanning Integration

- **Sobelow**: Static security analysis for Elixir applications
- **Version**: ~> 0.14 (latest with improved Phoenix support)
- **Integration**: Via centralized workflow's sobelow: true option
- **Output**: SARIF format compatible with GitHub Security tab
- **Additional Security**: hex.audit and deps.unlock --check-unused available
  via mix quality.full alias

### Local CI Tool Integration

- **Act Tool**: Docker-based GitHub Actions local execution
- **Installation**: `brew install act` (macOS), curl script (Linux)
- **Usage**: `act` runs all workflows locally, `act -j test` runs main CI job,
  `act -j integration-test` runs integration tests
- **Performance**: 20 seconds vs 2-5 minutes on GitHub (10x improvement)

## Implementation Strategy

### Primary Approach: Dual Architecture with Strategic Optimizations

**Architecture Rationale** (from architecture-agent consultation):

- **Separation of Concerns**: Centralized workflow handles standard quality
  gates, custom workflow handles installer-specific validation
- **Parallel Execution**: Workflows run independently for faster overall CI time
  (main CI ~8-10 min, integration tests ~5-7 min, total ~10-12 min vs 20-25 min
  sequential)
- **Local Development First**: Act compatibility built into workflow design from
  start

**Strategic Approach** (from senior-engineer-reviewer consultation):

- **Hybrid Implementation**: Balance ecosystem consistency with
  installer-specific needs
- **85% Maintenance Reduction**: 20 lines vs 160 lines of CI YAML through
  centralization
- **Security-First Quality Gates**: Align with ecosystem standards while
  maintaining development velocity

### Agent Consultations Completed

#### Architecture Agent - CI Architecture Planning

**Guidance Received:**

- Recommended parallel execution model over dependent jobs for better resource
  utilization
- Confirmed dual workflow approach with clear separation of concerns
- Provided caching strategy differentiation between workflows
- Validated Act integration as first-class citizen rather than afterthought

#### Senior Engineer Reviewer - Strategic Validation

**Assessment:**

- **Strategic Value**: High - Ecosystem alignment with automatic improvement
  propagation
- **Risk Level**: Medium (manageable with proper migration approach)
- **Maintenance Impact**: 85% reduction in CI maintenance burden
- **Recommendation**: Adopt hybrid architecture with strategic optimizations

## Implementation Phases

### Phase 1: Centralized Workflow Adoption (1-2 hours)

**Objective**: Replace custom CI with ecosystem-standard centralized workflow

**Tasks:**

1. **Replace ci.yml with centralized call**
   - Backup current `.github/workflows/ci.yml`
   - Replace with 20-line centralized workflow call
   - Configure inputs: `spark-formatter: true`, `sobelow: true`

2. **Add sobelow dependency**
   - Add `{:sobelow, "~> 0.14", only: [:dev, :test], runtime: false}` to mix.exs
   - Add quality aliases: `"deps.audit"`, `"quality.full"`

3. **Validate workflow compatibility**
   - Test centralized workflow in feature branch
   - Verify all existing quality gates still function
   - Confirm coverage reporting continues working

**Success Criteria:**

- ✅ CI passes with centralized workflow
- ✅ All existing quality gates functional (format, credo, dialyzer)
- ✅ New security gates active (sobelow via centralized workflow, hex.audit via
  quality.full alias)
- ✅ Coverage reporting maintains current thresholds

### Phase 2: Integration Testing Implementation (2-3 hours)

**Objective**: Add real-world installation validation through focused
integration testing

**Tasks:**

1. **Create integration testing workflow**
   - New file: `.github/workflows/integration-tests.yml`
   - Implement 2-scenario matrix: Phoenix latest + bare Elixir
   - Use igniter.new two-step approach for project creation

2. **Implement installation validation**
   - Test `mix ash_discord.install --yes` in fresh projects
   - Verify file creation: consumer module, configuration updates
   - Validate functional installation: compile + test execution

3. **Add comprehensive verification**
   - Consumer module content validation (use AshDiscord.Consumer)
   - Configuration file verification (Discord token setup)
   - Supervision tree integration confirmation

**Success Criteria:**

- ✅ Integration tests create fresh projects successfully
- ✅ ash_discord.install completes without errors in both scenarios
- ✅ Generated code compiles and tests pass
- ✅ All expected files created with correct content

### Phase 3: Local CI Setup & Optimization (1 hour)

**Objective**: Enable 10x faster local CI feedback through act integration

**Tasks:**

1. **Install and configure act tool**
   - Document installation: `brew install act` or equivalent
   - Create optional `.actrc` for container optimization
   - Test workflow execution: `act` runs all workflows, `act -j test` and
     `act -j integration-test` run individual workflows

2. **Optimize for local development**
   - Verify workflows work with act out-of-the-box
   - Optional: Create `.github/workflows/ci-local.yml` for faster local testing
   - Document local CI usage patterns

3. **Integration with development workflow**
   - Document act usage: `act -j test` (main CI), `act -j integration-test`
     (integration tests), `act` (all workflows)
   - Optional: Makefile targets for common act commands
   - Optional: Git hooks integration for pre-push validation

**Success Criteria:**

- ✅ Act tool installed and functional
- ✅ Both CI workflows run locally in <60 seconds
- ✅ Local CI provides same validation as GitHub Actions
- ✅ Documentation enables contributor adoption

### Phase 4: Documentation & Monitoring (1-2 hours)

**Objective**: Complete implementation with proper documentation and optional
enhancements

**Tasks:**

1. **Update project documentation**
   - README CI badge updates for new workflows
   - CONTRIBUTING.md local CI development instructions
   - Document new quality gates and security scanning

2. **Optional enhancements**
   - Configure Dependabot for automated dependency updates
   - Set up GitHub Security tab integration for sobelow reports
   - Optional: GitHub Pages documentation deployment

3. **Performance monitoring setup**
   - Monitor CI execution times (target: main CI <10 min, integration <7 min,
     parallel total ~10-12 min)
   - Track integration test success rates (target 100%)
   - Optional: GitHub Security score monitoring (target >7.5/10)

**Success Criteria:**

- ✅ Documentation updated for new CI architecture
- ✅ Contributors can use local CI for development
- ✅ Optional security enhancements configured
- ✅ Performance monitoring provides visibility

## Quality and Testing Strategy

### Testing Approach Using Discovered Patterns

#### Main CI Testing - Following Ash Ecosystem Pattern

- **Matrix Testing**: Maintain current 4-combination matrix (Elixir/OTP/Ash
  versions)
- **Quality Gates**: Format, spark.formatter, credo --strict, dialyzer, sobelow
- **Coverage**: Maintain >90% coverage through existing ExCoveralls integration
- **Security**: sobelow (via centralized workflow), hex.audit and deps.unlock
  --check-unused (via quality.full alias)

#### Integration Testing - Following Subproject Pattern

- **Real Project Creation**: Use igniter.new for authentic project structure
- **Installation Testing**: Validate mix ash_discord.install in fresh
  environments
- **Functional Validation**: Compile + test execution in generated projects
- **Content Verification**: Consumer module, configuration, supervision tree
  integration

#### Local Testing - Following Act Best Practices

- **Fast Feedback**: 20-second validation vs 2-5 minute GitHub Actions
- **Full Coverage**: Same quality gates as GitHub Actions, locally executable
- **Development Integration**: Pre-push validation, contributor onboarding
- **Container Optimization**: --reuse flag for persistent containers

### Success Criteria & Metrics

#### Immediate Quality Improvements

- ✅ **Security Posture**: Sobelow and hex.audit active for vulnerability
  detection
- ✅ **Code Quality**: Spark formatter ensures DSL formatting consistency
- ✅ **Dependency Health**: Unused dependency detection reduces maintenance
  burden
- ✅ **Installation Validation**: Real-world testing prevents deployment issues

#### Long-term Quality Metrics

- ✅ **Test Coverage**: Maintain >90% with comprehensive integration testing
- ✅ **CI Performance**: Main CI <10 minutes, integration tests <7 minutes,
  total parallel time ~10-12 minutes
- ✅ **Installation Success**: 100% success rate across supported scenarios
- ✅ **Security Score**: GitHub Security Score >7.5/10 through automated
  scanning

#### Developer Experience Metrics

- ✅ **Local CI Adoption**: Contributors use act for pre-push validation
- ✅ **Feedback Speed**: 10x improvement (20s vs 2-5min) for common checks
- ✅ **Onboarding**: New contributors can validate changes locally
- ✅ **Maintenance Reduction**: 85% reduction in CI YAML maintenance

## Risk Assessment & Mitigation Strategies

### Implementation Risks

#### Migration Risk: Medium

- **Risk**: Breaking existing CI during transition to centralized workflow
- **Impact**: Contributors unable to validate changes, deployment blocked
- **Mitigation**:
  - Implement in feature branch with parallel testing period
  - Maintain custom workflow backup during transition
  - Test centralized workflow thoroughly before main branch merge
  - Gradual rollout with ability to revert quickly

#### Integration Testing Complexity: Medium

- **Risk**: Integration tests add CI time and complexity
- **Impact**: Slower feedback, increased maintenance overhead
- **Mitigation**:
  - Focus on 2 strategic scenarios (Phoenix + bare) vs expanded matrix
  - Optimize with proper caching strategy
  - Run in parallel with main CI for faster overall time
  - Clear separation from main CI for independent maintenance

#### Act Adoption Friction: Low

- **Risk**: Contributors may not adopt local CI tooling
- **Impact**: Continued reliance on slow GitHub Actions feedback
- **Mitigation**:
  - Make act integration optional with clear benefits documentation
  - Provide simple setup instructions (`brew install act`)
  - Document 10x speed improvement to drive organic adoption
  - Ensure workflows work without act for non-adopters

### Strategic Risks & Long-term Considerations

#### Ecosystem Dependency: Low-Medium

- **Risk**: Centralized workflow changes could break CI
- **Impact**: All dependent projects affected by upstream changes
- **Mitigation**:
  - Ash ecosystem maintains backward compatibility standards
  - Version pinning available (@main vs @v1.2.3 tags)
  - Custom workflow backup available if needed
  - Strong testing in ash project before changes propagate

#### Maintenance Coordination: Low

- **Risk**: Integration testing workflow requires ongoing maintenance
- **Impact**: Custom code maintenance burden remains
- **Mitigation**:
  - Simple 2-scenario matrix reduces complexity
  - Clear documentation for maintenance procedures
  - Integration tests focused on stable installation patterns
  - Architecture allows independent evolution of integration tests

## Implementation Success Validation

### Phase Completion Criteria

#### Phase 1 Complete When:

- ✅ Centralized workflow successfully replaces custom CI
- ✅ All existing quality gates function correctly
- ✅ New security gates (sobelow, hex.audit) operational
- ✅ Main CI time remains reasonable (<10 minutes)
- ✅ Integration tests complete efficiently (<7 minutes)

#### Phase 2 Complete When:

- ✅ Integration tests validate Phoenix and bare Elixir installation
- ✅ All installation scenarios create correct files and configuration
- ✅ Generated projects compile and test successfully
- ✅ Integration workflow runs independently and reports status

#### Phase 3 Complete When:

- ✅ Act tool enables local execution of both workflows
- ✅ Local CI provides <60-second feedback for common scenarios
- ✅ Documentation enables contributor adoption
- ✅ Optional optimizations enhance developer experience

#### Phase 4 Complete When:

- ✅ Project documentation reflects new CI architecture
- ✅ Contributors understand and can use local CI workflow
- ✅ Optional security enhancements provide additional value
- ✅ Performance monitoring provides operational visibility

### Overall Success Indicators

#### Technical Success:

- ✅ **85% CI maintenance reduction** through centralized workflow adoption
- ✅ **10x local feedback improvement** through act integration
- ✅ **Real-world validation** through comprehensive integration testing
- ✅ **Security alignment** with ash ecosystem standards

#### Strategic Success:

- ✅ **Ecosystem consistency** with automatic improvement inheritance
- ✅ **Contributor experience** enhanced through faster local validation
- ✅ **Installation reliability** improved through real-world testing
- ✅ **Future scalability** positioned for ecosystem growth

The implementation is considered complete when all phase criteria are met and
the project demonstrates successful ecosystem alignment while maintaining
installer-specific functionality validation through the dual CI architecture.

---

**Implementation Priority**: High - Strategic benefits significantly outweigh
transition costs **Resource Requirements**: 8-15 hours development time, no
additional infrastructure costs **Strategic Value**: High - Positions project
for ecosystem evolution with reduced maintenance burden
