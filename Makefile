# AshDiscord Installer - Development Makefile

.PHONY: help ci-local ci-test ci-integration ci-all quality deps test clean

# Display available targets
help:
	@echo "Available targets:"
	@echo "  ci-local      - Run optimized local CI checks (fast)"
	@echo "  ci-test       - Run main CI workflow locally"
	@echo "  ci-integration - Run integration tests locally"
	@echo "  ci-all        - Run all CI workflows locally"
	@echo "  quality       - Run quality checks (format, credo, sobelow)"
	@echo "  deps          - Get and audit dependencies"
	@echo "  test          - Run tests with coverage"
	@echo "  clean         - Clean build artifacts and Docker containers"

# Local CI workflows using act
ci-local:
	@echo "🚀 Running optimized local CI..."
	act -W .github/workflows/ci-local.yml

ci-test:
	@echo "🚀 Running main CI workflow..."
	act -W .github/workflows/ci.yml

ci-integration:
	@echo "🚀 Running integration tests..."
	act -W .github/workflows/integration-tests.yml

ci-all: ci-local ci-test ci-integration

# Local Elixir tasks (without act)
quality:
	@echo "📋 Running quality checks..."
	mix format --check-formatted
	mix credo --strict
	mix sobelow --config

deps:
	@echo "📦 Getting and auditing dependencies..."
	mix deps.get
	mix deps.audit

test:
	@echo "🧪 Running tests with coverage..."
	mix test --warnings-as-errors
	mix coveralls.html

# Cleanup
clean:
	@echo "🧹 Cleaning up..."
	mix clean
	rm -rf _build deps cover doc
	docker system prune -f