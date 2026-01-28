# Contributing to Golf Genius Ruby

Thank you for your interest in contributing to the Golf Genius Ruby gem!

## Development Setup

1. Fork and clone the repository
2. Install dependencies:
   ```bash
   bundle install
   ```
3. Run the test suite to verify everything works:
   ```bash
   bundle exec rake test
   ```

## Making Changes

1. Create a new branch for your feature or fix:
   ```bash
   git checkout -b feature/my-new-feature
   ```

2. Make your changes, following the code style (enforced by RuboCop)

3. Add tests for your changes

4. Run the full CI suite locally:
   ```bash
   bin/ci
   ```

5. Update documentation if needed (README, YARD docs, CHANGELOG)

## Code Style

This project uses RuboCop for code style enforcement. Run it with:

```bash
bundle exec rubocop
```

To auto-fix issues:

```bash
bundle exec rubocop -a
```

## Testing

Tests use Minitest with WebMock for HTTP stubbing. No API key is required.

```bash
# Run all tests
bundle exec rake test

# Run a specific test file
bundle exec ruby -Itest test/golf_genius/resources/event_test.rb
```

## Adding New Resources

To add a new API resource:

1. Create the resource file in `lib/golf_genius/resources/`:
   ```ruby
   # lib/golf_genius/resources/player.rb
   module GolfGenius
     class Player < Resource
       RESOURCE_PATH = "/players"

       extend APIOperations::List
       extend APIOperations::Fetch
     end
   end
   ```

2. Add the require to `lib/golf_genius.rb`

3. Add to the Client class if needed

4. Add tests in `test/golf_genius/resources/`

5. Add fixtures in `test/fixtures/api_responses.rb`

6. Update documentation

## Commit Messages

Use clear, descriptive commit messages:

- `feat: Add Player resource`
- `fix: Handle nil response in roster endpoint`
- `docs: Update README with pagination examples`
- `test: Add tests for error handling`

## Pull Requests

1. Ensure all CI checks pass
2. Update CHANGELOG.md for user-facing changes
3. Fill out the pull request template
4. Request review from maintainers

## Releasing (Maintainers)

1. Update version in `lib/golf_genius/version.rb`
2. Update CHANGELOG.md with release notes
3. Commit: `git commit -am "Release v0.2.0"`
4. Tag: `git tag v0.2.0`
5. Push: `git push origin main --tags`
6. GitHub Actions will automatically build and publish to RubyGems

## Questions?

Open an issue or reach out to the maintainers.
