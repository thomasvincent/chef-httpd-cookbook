# CLAUDE.md

Chef cookbook managing Apache HTTP Server 2.4+ with SSL/TLS hardening.

## Stack
- Ruby / Chef 18.0+
- Test Kitchen + ChefSpec
- Supports Linux, BSD, and macOS

## Lint & Test
```bash
cookstyle .
bundle exec rspec
kitchen test
```

## Notes
- Let's Encrypt integration with automatic renewal via Certbot
- Modern cipher suites based on Mozilla guidelines (TLS 1.2/1.3 only)
- Custom resources: httpd_install, httpd_vhost, httpd_module, httpd_service
