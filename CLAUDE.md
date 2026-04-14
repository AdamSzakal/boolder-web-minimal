# CLAUDE.md

## Build

After any changes to files under `scripts/static/` (templates, assets, lib), always run:

```
ruby scripts/static/build.rb
```

Output goes to `dist/`. Changes are not visible until build runs.
