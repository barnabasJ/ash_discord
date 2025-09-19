# Pull Request

## Summary

Brief description of what this PR accomplishes.

## Changes Made

- [ ] Added new feature: _describe feature_
- [ ] Fixed bug: _describe bug_
- [ ] Updated documentation: _what was updated_
- [ ] Refactored code: _what was refactored_
- [ ] Performance improvement: _describe improvement_
- [ ] Other: _describe other changes_

## Type of Change

- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📚 Documentation only changes
- [ ] 🔧 Refactoring (no functional changes, no api changes)
- [ ] ⚡ Performance improvements
- [ ] 🧪 Test improvements

## Testing

### Test Coverage
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] I have added tests for edge cases and error conditions  
- [ ] New and existing unit tests pass locally with my changes
- [ ] I have checked that code coverage is maintained or improved

### Manual Testing
- [ ] I have manually tested the changes in a development environment
- [ ] I have tested with a real Discord bot application
- [ ] I have verified backward compatibility (if applicable)

### Test Details
Describe the testing performed:

```elixir
# Example test cases added
test "new feature works as expected" do
  # test implementation
end
```

## Code Quality

### Code Standards
- [ ] My code follows the style guidelines of this project
- [ ] I have run `mix format` and the code is properly formatted
- [ ] I have run `mix credo` and addressed any issues
- [ ] I have run `mix dialyzer` and resolved any type errors

### Documentation
- [ ] I have updated the documentation to reflect my changes
- [ ] I have added or updated function documentation (`@doc`, `@spec`)
- [ ] I have updated the CHANGELOG.md file
- [ ] I have added examples in documentation if applicable

## Discord Integration

### Discord API Changes
- [ ] My changes are compatible with the current Discord API version
- [ ] I have tested command registration with Discord
- [ ] I have verified interaction handling works correctly
- [ ] I have checked rate limiting considerations (if applicable)

### Consumer Impact
- [ ] Changes maintain backward compatibility with existing consumers
- [ ] New callback requirements are clearly documented
- [ ] Performance impact is minimal or positive
- [ ] Breaking changes are justified and documented

## Dependencies

### Dependency Changes
- [ ] No new dependencies added
- [ ] New dependencies are justified and lightweight
- [ ] Dependencies are properly versioned in mix.exs
- [ ] All dependencies are compatible with supported Elixir/OTP versions

### Version Compatibility
- [ ] Changes work with minimum supported Ash version (3.0)
- [ ] Changes work with minimum supported Elixir version (1.15)
- [ ] Changes work with minimum supported OTP version (25)

## Breaking Changes

If this PR includes breaking changes, please describe:

### What breaks:
- List specific APIs, functions, or behaviors that change

### Migration path:
- Provide clear upgrade instructions for users
- Include code examples showing before/after

### Justification:
- Explain why the breaking change is necessary

## Related Issues

- Closes #(issue number)
- Related to #(issue number)
- Addresses #(issue number)

## Additional Context

### Performance Impact
- [ ] No performance impact
- [ ] Performance improvement: _describe improvement_
- [ ] Potential performance impact: _describe and justify_

### Security Considerations
- [ ] No security implications
- [ ] Security improvement: _describe improvement_
- [ ] Requires security review: _explain why_

## Checklist for Maintainers

*This section is for maintainer use - contributors don't need to complete*

- [ ] Code review completed
- [ ] All CI checks pass
- [ ] Documentation review completed  
- [ ] Breaking change impact assessed
- [ ] Release notes prepared (if needed)
- [ ] Migration guide updated (if needed)

## Screenshots/Examples

If applicable, add screenshots or code examples demonstrating the changes:

```elixir
# Before
old_implementation()

# After  
new_implementation()
```

---

**By submitting this pull request, I confirm:**

- [ ] I have read and agree to the project's [Code of Conduct](CODE_OF_CONDUCT.md)
- [ ] I have read the [Contributing Guidelines](CONTRIBUTING.md)
- [ ] This PR is ready for review (not a draft)
- [ ] I am willing to address feedback and make necessary changes