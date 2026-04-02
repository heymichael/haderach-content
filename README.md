# Haderach Content

Static content pages served via Firebase Hosting. Files in `public/` are
copied to the hosting root at deploy time.

## Structure

```
public/
  overview.html    # Platform overview and release notes
```

## Workflow

1. Edit files, push a branch, open a PR
2. PR checks pass in seconds (no build step)
3. Merge to main
4. Trigger `deploy-content` in `haderach-platform` to push to Firebase Hosting

## Deploying

Content is deployed via the `deploy-content` workflow in the
[haderach-platform](https://github.com/heymichael/haderach-platform) repo.
It checks out this repo at HEAD, restores all other app artifacts, and
deploys the assembled directory to Firebase Hosting.
