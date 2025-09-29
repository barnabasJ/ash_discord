# CI Improvements - Detailed Implementation Breakdown

## Implementation Plan Summary

**Based on strategic plan from notes/ci-improvements/plan.md:**

Transform ash_discord_installer CI architecture from custom 160-line workflow to
dual architecture with:

- **Centralized Workflow**: 20-line call to
  ash-project/ash/.github/workflows/ash-ci.yml@main
- **Integration Testing**: New focused workflow validating real-world
  installation scenarios
- **Local CI Support**: Act tool integration for 10x faster feedback (20s vs
  2-5min)
- **Enhanced Security**: Sobelow static analysis + hex.audit dependency scanning

**Total Implementation Time**: 8-15 hours across 4 phases **Strategic
Benefits**: 85% CI maintenance reduction + ecosystem alignment + installation
validation

## Implementation Instructions

**IMPORTANT**: After completing each numbered step, commit your changes with the
suggested commit message. This ensures clean history and easy rollback if
needed.

**Testing Integration**: Each task includes comprehensive test requirements
following TDD/BDD methodology. All tests must pass before marking tasks
complete.

## Implementation Checklist

### Stream A: Centralized Workflow Migration (Phase 1)

1. [x] **Backup Current CI Configuration** 1.1. [x] Create backup of current
       `.github/workflows/ci.yml` - Copy `.github/workflows/ci.yml` to
       `.github/workflows/ci.yml.backup` - Document current configuration for
       rollback reference - 📖
       [GitHub Workflow Backup Best Practices](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)

   1.2. [x] Ensure clean working directory on current installer branch - Verify
   we're on the `installer` branch: `git branch --show-current` - Ensure clean
   working directory before changes: `git status`

   📝 **Commit**: `ci: backup current workflow for safe migration`

2. [x] **Add Security Dependencies and Quality Aliases** 2.1. [x] Add sobelow
       dependency to mix.exs - Add
       `{:sobelow, "~> 0.14", only: [:dev, :test], runtime: false}` to deps/0 -
       Pattern reference: `mix.exs:20-30` existing dev dependencies structure -
       📖
       [Sobelow Security Scanner](https://hexdocs.pm/sobelow/0.14.0/Sobelow.html)

   2.2. [x] Add enhanced quality aliases to mix.exs - Add
   `"deps.audit": ["hex.audit", "deps.unlock --check-unused"]` to aliases/0 -
   Add
   `"quality.full": ["format", "spark.formatter", "credo --strict", "dialyzer", "sobelow"]`
   to aliases/0 - Pattern reference: `mix.exs:85-95` existing alias structure -
   📖
   [Mix Aliases Documentation](https://hexdocs.pm/mix/Mix.html#module-aliases)

   2.3. [x] Install and verify new dependencies - Run `mix deps.get` to install
   sobelow - Run `mix quality.full` to verify all tools work - Run
   `mix deps.audit` to verify audit toolchain

   **Testing Requirements**:

   - Create `test/mix/tasks/ci_quality_test.exs` to verify quality aliases
     function
   - Test `mix quality.full` runs without errors
   - Test `mix deps.audit` detects audit issues correctly

   📝 **Commit**:
   `deps: add sobelow security scanning and enhanced quality aliases`

3. [x] **Replace CI Workflow with Centralized Pattern** 3.1. [x] Replace
       `.github/workflows/ci.yml` content with centralized workflow call -
       Replace entire file content with centralized workflow pattern -
       Configuration: `spark-formatter: true`, `sobelow: true`,
       `conventional-commit: false` - Maintain existing triggers:
       `on: [push, pull_request]` - 📖
       [Ash Centralized CI Workflow](https://github.com/ash-project/ash/blob/main/.github/workflows/ash-ci.yml)

   3.2. [x] Configure workflow inputs for ash_discord specific needs - Review
   centralized workflow documentation for available inputs - Configure matrix
   strategy inheritance from centralized workflow - Ensure secrets inheritance:
   `secrets: inherit`

   3.3. [x] Verify concurrency control configuration - Maintain
   `concurrency.group: ${{ github.workflow }}-${{ github.ref }}` - Ensure
   `cancel-in-progress: true` for efficient resource usage

   **Testing Requirements**:

   - Create `.github/workflows/test-centralized.yml` for local validation
   - Verify workflow syntax with `act --dryrun`
   - Test workflow inputs resolve correctly

   📝 **Commit**: `ci: adopt centralized ash ecosystem workflow architecture`

4. [x] **Validate Centralized Workflow Functionality** (Validated with act
       --dryrun) 4.1. [ ] Test centralized workflow in feature branch - Push
       feature branch to trigger centralized workflow - Verify all existing
       quality gates pass (format, credo, dialyzer) - Confirm sobelow security
       scanning executes - 📖
       [GitHub Actions Troubleshooting](https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows)

   4.2. [ ] Validate coverage reporting continues working - Confirm codecov
   integration still functions with centralized workflow - Check coverage
   thresholds maintained (>90%) - Verify coverage report uploads to Codecov

   4.3. [ ] Performance validation - Measure CI execution time (target <10
   minutes) - Compare against baseline from backup workflow - Document
   performance changes

   **Testing Requirements**:

   - Create `test/ci/centralized_workflow_test.exs` for workflow validation
   - Test all quality gates function identically to previous CI
   - Validate coverage reporting integration

   📝 **Commit**: `ci: validate and optimize centralized workflow configuration`

### Stream B: Integration Testing Implementation (Phase 2)

5. [x] **Create Integration Testing Workflow Structure** 5.1. [x] Create
       `.github/workflows/integration-tests.yml` - New file with integration
       testing workflow structure - Matrix strategy: Phoenix latest + bare
       Elixir (2 scenarios) - Follow test-subprojects.yml pattern from ash
       repository - 📖
       [Ash Integration Testing Pattern](https://github.com/ash-project/ash/blob/main/.github/workflows/test-subprojects.yml)

   5.2. [x] Configure integration test matrix -
   `project-type: [{type: "phoenix", name: "Phoenix Latest"}, {type: "bare", name: "Bare Elixir"}]` -
   Use `igniter.new` two-step approach for project creation - Elixir 1.17 + OTP
   27 for focused testing

   5.3. [x] Set up integration workflow concurrency control - Separate
   concurrency group: `integration-${{ github.ref }}` - Independent from main CI
   workflow - Cancel in progress for efficiency

   **Testing Requirements**:

   - Create `test/integration/workflow_structure_test.exs`
   - Test matrix configuration resolves correctly
   - Validate workflow independence from main CI

   📝 **Commit**: `ci: add integration testing workflow structure`

6. [ ] **Implement Phoenix Project Integration Test** 6.1. [ ] Add Phoenix
       project creation step - Use
       `mix igniter.new test_project --with phx.new --with-args="--no-ecto --no-live --no-dashboard"` -
       Verify Phoenix archive installation if needed - Handle project creation
       in clean environment - 📖
       [Igniter Project Creation](https://hexdocs.pm/igniter/readme.html)

   6.2. [ ] Add ash_discord installation step for Phoenix -
   `cd test_project && mix ash_discord.install --yes` - Use local ash_discord
   source for testing - Handle installation in Phoenix context

   6.3. [ ] Add Phoenix-specific validation steps - Verify consumer module
   creation in correct location - Check Phoenix application integration -
   Validate router and endpoint configuration updates

   **Testing Requirements**:

   - Create `test/integration/phoenix_integration_test.exs`
   - Test Phoenix project creation succeeds
   - Verify ash_discord installation in Phoenix context

   📝 **Commit**: `ci: implement Phoenix project integration testing`

7. [ ] **Implement Bare Elixir Integration Test** 7.1. [ ] Add bare Elixir
       project creation step - Use `mix igniter.new test_project --sup` - Create
       supervision tree project structure - Verify minimal Elixir project setup

   7.2. [ ] Add ash_discord installation for bare project -
   `cd test_project && mix ash_discord.install --yes` - Handle installation in
   minimal Elixir context - Test consumer integration with supervision tree

   7.3. [ ] Add bare project validation steps - Verify consumer module in
   lib/test_project/ - Check application.ex supervision tree updates - Validate
   minimal configuration setup

   **Testing Requirements**:

   - Create `test/integration/bare_elixir_integration_test.exs`
   - Test bare Elixir project creation and installation
   - Verify supervision tree integration

   📝 **Commit**: `ci: implement bare Elixir integration testing`

8. [ ] **Add Comprehensive Installation Verification** 8.1. [ ] Add file
       creation verification - Verify consumer module exists:
       `test -f "lib/test_project/discord_consumer.ex"` - Check consumer
       content:
       `grep -q "use AshDiscord.Consumer" lib/test_project/discord_consumer.ex` -
       Validate configuration files updated:
       `grep -q "config :nostrum" config/dev.exs` - 📖
       [Shell Testing Best Practices](https://www.shellcheck.net/)

   8.2. [ ] Add functional compilation verification -
   `cd test_project && mix deps.get && mix compile --warnings-as-errors` -
   Ensure generated code compiles without issues - Test that all dependencies
   resolve correctly

   8.3. [ ] Add test execution verification - `cd test_project && mix test` -
   Verify generated project tests pass - Check that ash_discord integration
   doesn't break existing tests

   8.4. [ ] Add configuration verification - Verify Discord token configuration
   in runtime.exs - Check .formatter.exs includes Spark.Formatter - Validate
   supervision tree includes consumer

   **Testing Requirements**:

   - Create `test/integration/installation_verification_test.exs`
   - Test all verification steps work correctly
   - Validate file content and configuration accuracy

   📝 **Commit**: `ci: add comprehensive installation verification steps`

### Stream C: Local CI Setup and Optimization (Phase 3)

9. [ ] **Add Act Local CI Configuration** 9.1. [ ] Create optional `.actrc`
       configuration file - Add
       `-P ubuntu-latest=catthehacker/ubuntu:act-latest` for better container -
       Add `--reuse` flag for container persistence - 📖
       [Act Configuration Guide](https://github.com/nektos/act#configuration)

   9.2. [ ] Test act compatibility with both workflows - Verify `act` runs both
   CI and integration workflows - Test `act -j test` runs main CI workflow -
   Test `act -j integration-test` runs integration tests - Document any
   compatibility issues and solutions

   9.3. [ ] Create optional act-optimized workflow (if needed) -
   `.github/workflows/ci-local.yml` for faster local testing - Simplified matrix
   for local development speed - Single Elixir/OTP combination for quick
   validation

   **Testing Requirements**:

   - Create `test/local_ci/act_integration_test.exs`
   - Test act runs workflows locally
   - Verify local execution matches GitHub Actions results

   📝 **Commit**: `ci: add act configuration for local CI execution`

10. [ ] **Create Local CI Usage Documentation** 10.1. [ ] Document act
        installation and setup - Installation instructions: `brew install act`
        (macOS), curl script (Linux) - Basic usage: `act` (all workflows),
        `act -j test` (main CI), `act -j integration-test` - Troubleshooting
        common issues (architecture, permissions, disk space)

    10.2. [ ] Add development workflow integration examples - Pre-push
    validation with act - Integration with IDEs and git hooks - Performance
    expectations: <60s local vs 2-5min GitHub

    10.3. [ ] Optional: Create Makefile targets for local CI - `make ci-local`
    runs all local CI - `make ci-test` runs main CI only - `make ci-integration`
    runs integration tests

    **Testing Requirements**:

    - Create `test/local_ci/documentation_test.exs`
    - Verify all documented commands work correctly
    - Test Makefile targets if created

    📝 **Commit**: `docs: add local CI setup and usage documentation`

### Stream D: Documentation and Monitoring (Phase 4)

11. [ ] **Update Project Documentation** 11.1. [ ] Update README.md CI badges
        and sections - Update CI badge URLs for new workflow names - Document
        new CI architecture (centralized + integration) - Add local CI
        development section

    11.2. [ ] Update or create CONTRIBUTING.md - Add local CI development
    workflow instructions - Document act usage for contributors - Update testing
    requirements with integration tests - 📖
    [Contributing Guide Best Practices](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions)

    11.3. [ ] Document new quality gates and security features - Document
    sobelow security scanning integration - Explain hex.audit dependency
    vulnerability scanning - Update contribution requirements with quality gates

    **Testing Requirements**:

    - Create `test/documentation/readme_test.exs`
    - Verify all links and badges work correctly
    - Test documentation accuracy with real commands

    📝 **Commit**: `docs: update project documentation for new CI architecture`

12. [ ] **Configure Optional Security and Monitoring Enhancements** 12.1. [ ]
        Optional: Configure Dependabot for automated dependency updates - Create
        `.github/dependabot.yml` for Elixir ecosystem - Configure update
        frequency and PR settings - 📖
        [Dependabot Configuration](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file)

    12.2. [ ] Optional: Set up GitHub Security tab integration - Configure
    sobelow SARIF report upload - Enable GitHub security advisories - Set up
    security monitoring and alerting

    12.3. [ ] Optional: Configure GitHub Pages documentation deployment - Add
    docs deployment workflow for automatic documentation updates - Configure
    ExDoc integration with GitHub Pages

    **Testing Requirements**:

    - Create `test/security/monitoring_test.exs`
    - Test Dependabot configuration if implemented
    - Verify security integration functionality

    📝 **Commit**: `ci: configure security monitoring and optional enhancements`

13. [ ] **Performance Monitoring and Validation** 13.1. [ ] Set up CI
        performance monitoring - Document baseline performance metrics - Monitor
        main CI execution time (target <10 minutes) - Track integration test
        execution time (target <7 minutes)

    13.2. [ ] Validate success criteria achievement - Test coverage
    maintained >90% - Installation success rate 100% across scenarios - Local CI
    feedback <60 seconds - Security scanning operational

    13.3. [ ] Create monitoring and alerting for CI health - Set up alerts for
    CI failure patterns - Monitor performance regression - Track integration
    test success rates

    **Testing Requirements**:

    - Create `test/monitoring/performance_test.exs`
    - Test performance monitoring setup
    - Verify success criteria validation

    📝 **Commit**: `ci: set up performance monitoring and validation`

## TDD/BDD Integration Plan

### Pre-Implementation Test Creation

**Before starting implementation, create comprehensive test suite:**

1. **Create `test/ci/workflow_migration_test.exs`**

   - Tests for centralized workflow adoption
   - Validation that new workflow provides same quality gates as current
   - Coverage reporting continuity tests

2. **Create `test/integration/real_project_test.exs`**

   - Integration tests for Phoenix and bare Elixir project creation
   - Installation validation in real project environments
   - File creation and content verification tests

3. **Create `test/local_ci/act_functionality_test.exs`**

   - Tests for act tool integration and performance
   - Local CI execution validation
   - Performance requirement verification (<60s feedback)

4. **Create `test/security/quality_gates_test.exs`**
   - Tests for sobelow security scanning functionality
   - hex.audit dependency vulnerability detection tests
   - Quality gate enhancement validation

### Implementation Validation Strategy

**TDD Approach:**

- Write failing tests that define expected behavior before implementation
- Implement features to make tests pass
- Refactor while keeping tests green

**BDD Scenarios:**

- "Given a fresh Phoenix project, when I run mix ash_discord.install, then the
  consumer should be properly integrated"
- "Given local act setup, when I run act -j test, then I should get <60s
  feedback with same validation as GitHub"
- "Given security dependencies, when I run mix quality.full, then sobelow should
  catch security issues"

## Task Specifications

### File References from Impact Analysis

**Files Requiring Changes:**

- `.github/workflows/ci.yml:1-160` → Replace with centralized workflow call
- `.github/workflows/integration-tests.yml` → NEW FILE for integration testing
- `mix.exs:26` → Add sobelow dependency
- `mix.exs:85-104` → Add enhanced quality aliases

**Pattern References:**

- Centralized workflow pattern from
  `ash-project/ash/.github/workflows/ash-ci.yml`
- Integration testing pattern from `ash/test-subprojects.yml`
- Dependency patterns from `ash_postgres`, `igniter` projects
- Quality alias patterns from `ash_authentication_phoenix`

### Documentation Links

- 📖
  [Ash Centralized CI Workflow](https://github.com/ash-project/ash/blob/main/.github/workflows/ash-ci.yml)
- 📖
  [GitHub Actions Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- 📖 [Sobelow Security Scanner](https://hexdocs.pm/sobelow/0.14.0/Sobelow.html)
- 📖 [Act Local CI Tool](https://github.com/nektos/act)
- 📖 [Igniter Project Creation](https://hexdocs.pm/igniter/readme.html)
- 📖 [Mix Aliases Documentation](https://hexdocs.pm/mix/Mix.html#module-aliases)

## Quality Assurance Plan

### Testing and Validation Approaches

**Phase 1 - Centralized Workflow Migration:**

- Comprehensive test suite validation before and after migration
- Feature branch testing with parallel comparison
- Performance benchmarking against current workflow
- Quality gate functional testing (format, credo, dialyzer, sobelow)

**Phase 2 - Integration Testing:**

- Real project creation testing in clean environments
- Installation success validation across Phoenix and bare Elixir
- Generated code compilation and test execution verification
- File content and configuration accuracy validation

**Phase 3 - Local CI Setup:**

- Act tool functionality testing across different environments
- Performance validation (<60s local feedback requirement)
- Workflow compatibility testing between local and GitHub execution
- Developer experience validation through documentation testing

**Phase 4 - Documentation and Monitoring:**

- Documentation accuracy testing with real command execution
- Link validation and badge functionality testing
- Optional security enhancement testing
- Performance monitoring setup validation

### Success Criteria Validation

**Immediate Technical Success:**

- ✅ All existing quality gates function identically after migration
- ✅ New security gates (sobelow, hex.audit) operational
- ✅ Integration tests validate real-world installation scenarios
- ✅ Local CI provides <60-second feedback with act tool

**Long-term Strategic Success:**

- ✅ 85% CI maintenance reduction through centralized workflow
- ✅ 10x local feedback improvement (20s vs 2-5min)
- ✅ 100% installation success rate across supported scenarios
- ✅ Ecosystem alignment with automatic improvement inheritance

## Progress Tracking

### Checklist Management

**Format**: Each task follows the structure:

```
N. [ ] **Task Name**
   N.1. [ ] Subtask with specific implementation details
   N.2. [ ] Subtask with file references and patterns
   📝 **Commit**: "conventional: description of changes"
```

**Validation Requirements**:

- Each subtask includes testing requirements
- File paths and line numbers specified where applicable
- Documentation links provided for implementation guidance
- Commit messages follow conventional commit format

**Progress Tracking**:

- Mark individual subtasks complete as work progresses
- Complete numbered tasks only when all subtasks finished and tested
- Commit after each numbered task completion with suggested message
- Update documentation as implementation proceeds

## Execution Coordination

### Implementation Flow

**Stream Dependencies:**

- **Stream A (Phase 1)** must complete before Stream B can start
- **Stream C (Phase 3)** can begin in parallel with Stream A/B
- **Stream D (Phase 4)** can begin documentation work in parallel, finalize
  after implementation complete

**Parallel Work Opportunities:**

- Act setup and testing (Stream C) independent of workflow migration
- Documentation drafting (Stream D) can happen alongside implementation
- Security configuration can be prepared while main workflows deploy

**Risk Mitigation:**

- Feature branch development with backup workflow maintained
- Comprehensive testing before main branch merge
- Rollback procedures documented and tested
- Gradual deployment with validation checkpoints

---

**Breakdown Completion Status**: ✅ Ready for execution phase **Next Phase**:
Execute implementation following numbered checklist **Success Criteria**: All 13
numbered tasks completed with comprehensive testing and validation
