#!/usr/bin/env python3
"""IndexNow: tell search engines (Bing, Yandex, Seznam, ...) which pages of
screenshotmenu.nestimer.com changed. Bing feeds ChatGPT and Copilot search,
so new pages show up there within hours rather than weeks. Google does not
support IndexNow; sitemap.xml covers it.

deploy-site.sh calls this twice:

    python3 scripts/indexnow.py changed LIST   # before upload: what will change
    python3 scripts/indexnow.py submit LIST    # after the smoke test: send it

and `python3 scripts/indexnow.py all LIST` lists every page, for a full resubmit.

The key is published as web/<KEY>.txt, which is how IndexNow checks the
domain is ours.
"""
import hashlib
import json
import subprocess
import sys
import urllib.request
from pathlib import Path

WEB = Path(__file__).resolve().parent.parent / "web"
HOST = "root@134.209.8.62"
ROOT = "/var/www/screenshotmenu"
DOMAIN = "screenshotmenu.nestimer.com"
KEY = "159cacfdf80784289b47b0f46e3bd566"
ENDPOINT = "https://api.indexnow.org/indexnow"


def page_url(relative):
    return f"https://{DOMAIN}/{relative.removesuffix('index.html')}"


def pages():
    return sorted(str(p.relative_to(WEB)) for p in WEB.rglob("*.html"))


def remote_sums():
    """md5 of the pages currently live; empty on a first deploy."""
    command = f"cd {ROOT} 2>/dev/null && find . -name '*.html' -exec md5sum {{}} + || true"
    output = subprocess.run(["ssh", HOST, command], capture_output=True, text=True, check=True).stdout
    sums = {}
    for line in output.splitlines():
        digest, path = line.split(maxsplit=1)
        sums[path.removeprefix("./")] = digest
    return sums


def write(list_path, urls):
    Path(list_path).write_text("".join(f"{u}\n" for u in urls), encoding="utf-8")
    print(f"indexnow: {len(urls)} pages listed")


def changed(list_path):
    remote = remote_sums()
    write(list_path, [
        page_url(rel) for rel in pages()
        if remote.get(rel) != hashlib.md5((WEB / rel).read_bytes()).hexdigest()
    ])


def all_pages(list_path):
    write(list_path, [page_url(rel) for rel in pages()])


def submit(list_path):
    urls = Path(list_path).read_text(encoding="utf-8").split()
    if not urls:
        print("indexnow: nothing to submit")
        return
    body = json.dumps({
        "host": DOMAIN,
        "key": KEY,
        "keyLocation": f"https://{DOMAIN}/{KEY}.txt",
        "urlList": urls,
    }).encode()
    request = urllib.request.Request(ENDPOINT, data=body, headers={"Content-Type": "application/json; charset=utf-8"})
    # 200 and 202 both mean accepted. A failure here doesn't fail the deploy:
    # the site is already live.
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            print(f"indexnow: {response.status}, {len(urls)} urls")
    except Exception as error:
        print(f"indexnow: failed, {error}", file=sys.stderr)


def main():
    commands = {"changed": changed, "all": all_pages, "submit": submit}
    if len(sys.argv) != 3 or sys.argv[1] not in commands:
        raise SystemExit("usage: indexnow.py changed|all|submit LIST")
    commands[sys.argv[1]](sys.argv[2])


if __name__ == "__main__":
    main()
