# Contributing to AshDiscord

Thank you for your interest in contributing to AshDiscord! We welcome
contributions from developers of all skill levels. This guide will help you get
started.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Contributing Guidelines](#contributing-guidelines)
- [Pull Request Process](#pull-request-process)
- [Code Standards](#code-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation Guidelines](#documentation-guidelines)
- [Community Support](#community-support)

## Code of Conduct

This project adheres to a [Code of Conduct](CODE_OF_CONDUCT.md). By
participating, you are expected to uphold this code. Please report unacceptable
behavior to the project maintainers.

## Getting Started

### Ways to Contribute

- 🐛 **Report bugs** using our
  [bug report template](.github/ISSUE_TEMPLATE/bug_report.yml)
- ✨ **Request features** using our
  [feature request template](.github/ISSUE_TEMPLATE/feature_request.yml)
- ❓ **Ask questions** using our
  [question template](.github/ISSUE_TEMPLATE/question.yml)
- 📖 **Improve documentation** by fixing typos, adding examples, or clarifying
  concepts
- 🧪 **Add tests** to improve code coverage or test edge cases
- ⚡ **Optimize performance** by identifying and fixing bottlenecks
- 🔧 **Submit code changes** to fix bugs or add features

### Before You Start

1. **Search existing issues** to avoid duplicates
2. **Read our documentation** at
   [hexdocs.pm/ash_discord](https://hexdocs.pm/ash_discord/)
3. **Join our community** on [Discord](https://discord.gg/ash-hq) for questions
4. **Check the roadmap** in our issues to see planned features

## Development Setup

### Prerequisites

- **Elixir**: 1.15+ (we recommend 1.17)
- **Erlang/OTP**: 25+ (we recommend 27)
- **Git**: For version control
- **Discord Application**: For testing Discord integration

### Local Development

1. **Fork and clone the repository:**

   ```bash
   git clone https://github.com/YOUR_USERNAME/ash_discord.git
   cd ash_discord
   ```

2. **Install dependencies:**

   ```bash
   mix deps.get
   ```

3. **Run tests to verify setup:**

   ```bash
   mix test
   ```

4. **Check code quality:**

   ```bash
   # Traditional approach
   mix format
   mix credo
   mix dialyzer
   mix sobelow

   # Or use ex_check (recommended - unified quality checks)
   mix check

   # Or use fast local CI (recommended for development)
   make ci-local    # ~60 seconds
   act -W .github/workflows/ci-local.yml
   ```

### Discord Bot Setup (for testing)

1. **Create a Discord Application** at
   [discord.com/developers/applications](https://discord.com/developers/applications)

2. **Set environment variables:**

   ```bash
   export DISCORD_BOT_TOKEN="your_bot_token"
   export DISCORD_APPLICATION_ID="your_application_id"
   ```

3. **Run the test application:**
   ```bash
   cd priv/test_app
   mix deps.get
   mix run --no-halt
   ```

### Local CI Development (New!)

We've implemented a modern dual CI architecture for fast local development:

#### **Local CI with Act Tool**

```bash
# Install act (macOS)
brew install act

# Fast local validation (~60 seconds)
make ci-local
act -W .github/workflows/ci-local.yml

# Run integration tests locally
make ci-integration
```

#### **Quality Commands**

```bash
# Quick security + quality check (recommended)
mix check

# Just security scanning
mix sobelow --config

# Dependency audit
mix deps.audit
```

#### **CI Architecture**

- **Centralized CI**: Uses `ash-project/ash/.github/workflows/ash-ci.yml@main`
- **Integration Tests**: Real Phoenix + Bare Elixir project testing
- **Security Scanning**: Sobelow + hex.audit for vulnerability detection
- **10x Faster**: Local feedback with act tool

See our **[Local CI Guide](LOCAL_CI.md)** for detailed setup and
troubleshooting.

## Contributing Guidelines

### Issue Guidelines

#### Bug Reports

- Use the bug report template
- Include clear reproduction steps
- Provide relevant system information
- Include error messages and stack traces
- Test with the latest version when possible

#### Feature Requests

- Use the feature request template
- Explain the problem you're solving
- Provide use cases and examples
- Consider backward compatibility
- Research existing Discord API capabilities

#### Questions

- Search documentation and existing issues first
- Use the question template
- Provide context about what you're trying to accomplish
- Include relevant code samples
- Specify your experience level

### Code Contribution Guidelines

#### Small Changes (< 20 lines)

- Documentation fixes
- Minor bug fixes
- Typo corrections
- Small refactoring

_Process_: Submit PR directly with clear description.

#### Medium Changes (20-100 lines)

- New utility functions
- Test improvements
- Documentation enhancements
- Bug fixes with moderate scope

_Process_: Create issue first to discuss approach, then submit PR.

#### Large Changes (100+ lines)

- New features
- Breaking changes
- Major refactoring
- API changes

_Process_: Create detailed issue → discuss design → get approval → implement →
submit PR.

## Pull Request Process

### Before Submitting

1. **Create a feature branch:**

   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/bug-description
   ```

2. **Make your changes following our code standards**

3. **Add or update tests:**

   ```bash
   # Run tests
   mix test

   # Check coverage
   mix test --cover
   ```

4. **Update documentation:**

   - Add `@doc` and `@spec` for new functions
   - Update relevant guides if needed
   - Add examples for new features

5. **Check code quality:**

   ```bash
   # RECOMMENDED: Fast local CI (includes security scanning)
   make ci-local    # ~60 seconds

   # Or traditional approach
   mix format
   mix credo --strict
   mix dialyzer
   mix sobelow --config

   # Or comprehensive quality check with ex_check
   mix check
   ```

6. **Update CHANGELOG.md** if your change affects users

### Submitting Your PR

1. **Push your branch:**

   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create pull request** on GitHub using our template

3. **Fill out the PR template completely**

4. **Link related issues** using keywords like "Closes #123"

### PR Review Process

1. **Automated checks** must pass (CI, formatting, tests)
2. **Code review** by maintainers
3. **Testing** in development environment
4. **Documentation review** for user-facing changes
5. **Final approval** and merge

### After Your PR is Merged

- Delete your feature branch
- Pull latest changes from main
- Your contribution will be included in the next release!

## Code Standards

### Elixir Style

We follow standard Elixir formatting and conventions:

```elixir
# Good: Clear, descriptive names
def register_discord_command(command_name, resource, action) do
  # Implementation
end

# Good: Proper module structure
defmodule AshDiscord.Consumer do
  @moduledoc """
  Provides Discord event consumption capabilities.

  ## Examples

      defmodule MyBot.Consumer do
        use AshDiscord.Consumer, domains: [MyBot.Discord]
      end
  """

  @doc """
  Handles Discord interaction events.

  ## Parameters

  - `interaction` - The Discord interaction struct

  ## Returns

  - `{:ok, response}` - Successful response
  - `{:error, reason}` - Error with reason
  """
  @spec handle_interaction(Nostrum.Struct.Interaction.t()) ::
    {:ok, term()} | {:error, term()}
  def handle_interaction(interaction) do
    # Implementation
  end
end
```

### Code Organization

```
lib/
├── ash_discord/
│   ├── consumer.ex          # Main consumer module
│   ├── dsl/                 # DSL extensions
│   ├── transformers/        # Spark transformers
│   └── utils/               # Utility modules
└── ash_discord.ex           # Main module
```

### Documentation Standards

- **All public functions** must have `@doc` and `@spec`
- **Modules** must have `@moduledoc` with description and examples
- **Complex functions** should have internal comments
- **Examples** should be tested with `doctest`

### Error Handling

```elixir
# Good: Descriptive error tuples
{:error, {:invalid_command_option, option_name, "must be integer"}}

# Good: Use of Ash.Error for domain errors
{:error, Ash.Error.Invalid.new(message: "Resource not found")}

# Avoid: Generic errors without context
{:error, :failed}
```

## Testing Guidelines

### Test Structure

```elixir
defmodule AshDiscord.ConsumerTest do
  use ExUnit.Case
  doctest AshDiscord.Consumer

  describe "handle_interaction/1" do
    test "handles slash command successfully" do
      interaction = build_interaction(:slash_command)

      assert {:ok, response} = AshDiscord.Consumer.handle_interaction(interaction)
      assert response.type == :channel_message_with_source
    end

    test "returns error for invalid command" do
      interaction = build_interaction(:invalid_command)

      assert {:error, reason} = AshDiscord.Consumer.handle_interaction(interaction)
      assert reason =~ "Unknown command"
    end
  end

  # Helper functions
  defp build_interaction(type) do
    # Build test interaction struct
  end
end
```

### Test Coverage

- **New features** must include comprehensive tests
- **Bug fixes** must include regression tests
- **Edge cases** should be tested
- **Error conditions** must be tested
- **Integration tests** for Discord API interactions

### Testing Discord Integration

We provide test helpers and mocks:

```elixir
# Use provided test helpers
use AshDiscord.Test.Helpers

# Mock Discord API calls
mock_discord_api(fn
  {:get_application_commands, _} -> {:ok, []}
  {:create_global_application_command, _, _} -> {:ok, %{id: "123"}}
end)
```

## Documentation Guidelines

### Writing Documentation

1. **Use clear, simple language**
2. **Provide practical examples**
3. **Include common use cases**
4. **Link to related concepts**
5. **Keep it up to date**

### Documentation Types

#### Module Documentation

```elixir
defmodule AshDiscord.Consumer do
  @moduledoc """
  Handles Discord events and routes them to Ash actions.

  The Consumer provides a macro-based approach to handling Discord events
  with minimal boilerplate while maintaining full extensibility.

  ## Quick Start

      defmodule MyBot.Consumer do
        use AshDiscord.Consumer, domains: [MyBot.Discord]
      end

  ## Configuration

  See `AshDiscord.Consumer.Config` for available options.
  """
end
```

#### Function Documentation

```elixir
@doc """
Registers a Discord command with the Discord API.

This function takes a command definition and registers it with Discord,
making it available as a slash command in servers where your bot is present.

## Parameters

- `command` - Command definition struct
- `opts` - Registration options (optional)

## Returns

- `{:ok, registered_command}` - Successfully registered
- `{:error, reason}` - Registration failed

## Examples

    iex> command = %AshDiscord.Command{name: "hello", description: "Say hello"}
    iex> AshDiscord.register_command(command)
    {:ok, %{id: "123456789", name: "hello", description: "Say hello"}}
"""
```

### Documentation Testing

```elixir
# Ensure examples work
doctest AshDiscord.Consumer

# Test documentation examples
test "documentation examples work" do
  # Test the examples from @doc
end
```

## Community Support

### Getting Help

- **Documentation**: [hexdocs.pm/ash_discord](https://hexdocs.pm/ash_discord/)
- **Discord Community**: [Join Ash Framework Discord](https://discord.gg/ash-hq)
- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For general questions and discussions

### Helping Others

- **Answer questions** in issues and Discord
- **Review pull requests** from other contributors
- **Improve documentation** based on common questions
- **Share your experience** with AshDiscord

### Mentorship

New contributors are welcome! We provide:

- **Beginner-friendly issues** labeled with `good first issue`
- **Mentorship** from experienced contributors
- **Code review feedback** to help you improve
- **Recognition** for all contributions

## Recognition

Contributors are recognized in several ways:

- **CHANGELOG.md** credits for significant contributions
- **GitHub Contributors** page shows all contributors
- **Discord announcements** for major contributions
- **Invitation to maintainer team** for consistent, high-quality contributions

## Questions?

If you have questions about contributing that aren't covered here:

1. **Check our [FAQ](docs/troubleshooting-guide.md#frequently-asked-questions)**
2. **Search existing
   [GitHub issues](https://github.com/ash-project/ash_discord/issues)**
3. **Ask in [Discord](https://discord.gg/ash-hq) #ash-discord channel**
4. **Create a [question issue](.github/ISSUE_TEMPLATE/question.yml)**

We're here to help and want your contribution to be successful!

---

**Thank you for contributing to AshDiscord!** 🎉

Every contribution, no matter how small, makes AshDiscord better for the entire
community.
