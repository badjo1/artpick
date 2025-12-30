# The Continuum - Documentation

## Testing Setup

### Current Status

Rails 8.1.1 heeft een bekend compatibility issue met Minitest 6.0.0 dat test discovery blokkeert.

**Symptoom:** `bin/rails test` geeft `0 runs, 0 assertions`

### Workaround

Tot Rails dit fix, gebruik de infrastructure test script:

```bash
# Test dat alle admin controllers, views en routes bestaan
ruby test_admin_pages.rb
```

Dit script controleert:
- ✓ Alle controllers en hun actions bestaan
- ✓ Alle views bestaan
- ✓ Alle routes zijn geconfigureerd

### Testing Guide

Zie [TESTING_BEST_PRACTICES.md](./TESTING_BEST_PRACTICES.md) voor:
- TDD workflow
- Test patterns
- Code coverage met SimpleCov
- RuboCop linting

### Shared Documentation

Testing docs worden gedeeld via `~/Projects/shared-docs/`:

```
~/Projects/shared-docs/
├── README.md
└── TESTING_BEST_PRACTICES.md  ← Shared tussen alle projecten
```

Beide artpick en fundtogether linken naar deze shared docs via symlinks.

**Voordeel:** Update de docs op één plek, beschikbaar in alle projecten.

## Test Infrastructure Checklist

- [x] test_helper.rb met SessionTestHelper
- [x] test/test_helpers/session_test_helper.rb
- [x] test/integration/admin_pages_test.rb
- [x] test/fixtures/users.yml met roles
- [x] test_admin_pages.rb infrastructure check
- [ ] Rails/Minitest compatibility fix (wachten op Rails update)

## Running Tests (When Fixed)

```bash
# All tests
bin/rails test

# Specific file
bin/rails test test/integration/admin_pages_test.rb

# With verbosity
bin/rails test -v

# With coverage
COVERAGE=true bin/rails test
```

## Adding SimpleCov (Future)

```ruby
# test/test_helper.rb (when tests work)
require 'simplecov'
SimpleCov.start 'rails' do
  add_filter '/test/'
  add_filter '/config/'

  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
end
```

## Resources

- [Rails Testing Guide](https://guides.rubyonrails.org/testing.html)
- [Minitest Documentation](https://github.com/minitest/minitest)
- [Testing Best Practices](./TESTING_BEST_PRACTICES.md)
