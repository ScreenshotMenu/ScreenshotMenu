#!/bin/sh
# Deploy web/ to screenshotmenu.nestimer.com.
#
#   scripts/deploy-site.sh          rebuild, back up the live site, upload, smoke-test
#   scripts/deploy-site.sh -n       dry run: show what would change, upload nothing
#
# Files only on the server (the Google verification file, anything added by
# hand) are left alone: nothing is ever deleted remotely. Each deploy first
# tars the live site to /root/screenshotmenu-backup-<time>.tgz; the newest
# ten are kept. Restore with:
#   ssh root@134.209.8.62 'tar xzf /root/screenshotmenu-backup-<time>.tgz -C /var/www'
set -eu

HOST=root@134.209.8.62
ROOT=/var/www/screenshotmenu
SITE=https://screenshotmenu.nestimer.com

cd "$(dirname "$0")/.."

python3 scripts/build-site.py

# Deploy only what is committed, so the live site can always be traced to a commit.
if [ -n "$(git status --porcelain -- web scripts/build-site.py)" ]; then
    echo "web/ has uncommitted changes (maybe from the build above); commit them first:" >&2
    git status --short -- web scripts/build-site.py >&2
    exit 1
fi

if [ "${1:-}" = "-n" ]; then
    rsync -rlcn --itemize-changes --exclude .DS_Store web/ "$HOST:$ROOT/" | grep -v '^\.' || echo "nothing to upload"
    exit 0
fi

stamp=$(date +%Y%m%d-%H%M%S)
ssh "$HOST" "tar czf /root/screenshotmenu-backup-$stamp.tgz -C /var/www screenshotmenu \
    && ls -1t /root/screenshotmenu-backup-*.tgz | tail -n +11 | xargs -r rm --"
echo "backup: /root/screenshotmenu-backup-$stamp.tgz"

# macOS ships openrsync, which has no --chown and a stricter --chmod,
# so ownership and modes are fixed on the server afterwards.
rsync -rlc --itemize-changes --exclude .DS_Store web/ "$HOST:$ROOT/" | grep -v '^\.' || true
ssh "$HOST" "chown -R www-data:www-data $ROOT \
    && find $ROOT -type d -exec chmod 755 {} + \
    && find $ROOT -type f -exec chmod 644 {} +"

# Every page in the sitemap, plus the files crawlers and browsers fetch.
failed=0
for url in $(sed -n 's:.*<loc>\(.*\)</loc>.*:\1:p' web/sitemap.xml) \
           "$SITE/robots.txt" "$SITE/llms.txt" "$SITE/sitemap.xml" "$SITE/assets/site.css"; do
    code=$(curl -s -o /dev/null -w '%{http_code}' "$url")
    [ "$code" = 200 ] || { echo "FAIL $code $url" >&2; failed=1; }
done
[ "$failed" = 0 ] || exit 1
echo "deployed $(git rev-parse --short HEAD) to $SITE"
