# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-01-27

### Added
- Initial release
- Support for Seasons resource (list, fetch)
- Support for Categories resource (list, fetch)
- Support for Directories resource (list, fetch)
- Support for Events resource (list, fetch, roster, rounds, courses, tournaments)
- Configuration management with API key and base URL
- Comprehensive error handling with specific error classes
- Client-based and module-level API access patterns
- Automatic retry logic for transient failures
- Request/response logging support
- Nested objects automatically converted to Ruby POROs
- Rails auto-loading support
