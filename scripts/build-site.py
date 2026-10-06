#!/usr/bin/env python3
"""Build the static pages of the ScreenshotMenu website.

web/index.html is written by hand; this script only refreshes the blocks
between <!-- NAV --> / <!-- /NAV --> and <!-- FOOTER --> / <!-- /FOOTER -->
in it, so the shared chrome stays identical everywhere. The use-case pages,
their index and sitemap.xml are generated from USE_CASES below.

    python3 scripts/build-site.py
"""

import datetime
import html
import json
import re
import subprocess
from pathlib import Path

SITE = "https://screenshotmenu.nestimer.com"
WEB = Path(__file__).resolve().parent.parent / "web"
DMG = "https://github.com/ScreenshotMenu/ScreenshotMenu/releases/latest/download/ScreenshotMenu.dmg"
REPO = "https://github.com/ScreenshotMenu/ScreenshotMenu"
COMPANY = "Global Tech Distribution s.r.o."
COMPANY_URL = "https://gt-d.cz"
OG_ALT = "ScreenshotMenu open in the macOS menu bar, showing its nine capture modes"
TODAY = datetime.date.today().isoformat()


def mi(name):
    """A menu item name, styled like the app's menu."""
    return f'<span class="mi">{name}</span>'


USE_CASES = [
    {
        "slug": "screenshot-to-clipboard",
        "who": "Bug reports & chats",
        "title": "Screenshot to clipboard on Mac, in one click",
        "meta_title": "Screenshot to Clipboard on Mac in One Click — ScreenshotMenu",
        "description": "Copy a screenshot of an area, window or the whole screen straight to the Mac clipboard from the menu bar, then paste it into Slack, Jira, GitHub or email. No file left behind.",
        "card": "Grab an area straight to the clipboard and paste it into Slack, Jira or a GitHub issue. No file to find and delete later.",
        "lead": "Most screenshots are never meant to be kept. They go into a chat, a ticket or an email and are forgotten. ScreenshotMenu sends them to the clipboard, so nothing piles up on your Desktop.",
        "body": f"""
<h2>The problem with screenshots as files</h2>
<p>By default macOS saves every screenshot as a PNG on the Desktop. When you are reporting a bug or answering a colleague, that means taking the shot, finding the file, dragging it into the conversation and deleting it afterwards. Or you don't delete it, and the Desktop fills up.</p>
<p>macOS can copy to the clipboard instead, but only if you remember to hold <kbd>Control</kbd> on top of <kbd>⌘</kbd> <kbd>⇧</kbd> <kbd>4</kbd>. Few people do.</p>

<h2>How to do it with ScreenshotMenu</h2>
<ol>
<li>Click the camera icon in the menu bar.</li>
<li>Choose {mi("Area to Clipboard")}, {mi("Window to Clipboard")} or {mi("Fullscreen to Clipboard")}.</li>
<li>Drag over the area, or click the window you want.</li>
<li>Press <kbd>⌘</kbd> <kbd>V</kbd> in Slack, Teams, Jira, Linear, a GitHub issue, Mail, Notion or anywhere else that accepts images.</li>
</ol>
<div class="callout">Nothing is written to disk. The image only lives on the clipboard until you copy something else.</div>

<h2>Want to mark it up first?</h2>
<p>Turn on {mi("Open in Preview")} in the menu. Clipboard captures then also open in Preview as an untitled document, so you can add an arrow or a box, copy the result and paste it. See <a href="/use-cases/annotate-screenshots/">screenshot and annotate in Preview</a>.</p>

<h2>Who uses it this way</h2>
<ul>
<li><strong>Developers and QA</strong> attaching the broken state of a UI to an issue.</li>
<li><strong>Support teams</strong> showing a customer exactly where a setting lives.</li>
<li><strong>Anyone in a chat</strong> who needs to answer “what do you see?” quickly.</li>
</ul>
""",
        "faq": [
            ("Where does a clipboard screenshot go on Mac?",
             "Nowhere on disk. It is held on the system clipboard until you paste it or copy something else. To keep one, paste it into Preview (File › New from Clipboard) and save it."),
            ("What is the keyboard shortcut to screenshot to clipboard on Mac?",
             "Control + Command + Shift + 4 for an area, then Space for a window, or Control + Command + Shift + 3 for the full screen. ScreenshotMenu puts the same three captures in the menu bar so you don't have to remember them."),
            ("Can I paste a clipboard screenshot into Slack or Jira?",
             "Yes. Any app that accepts pasted images works, including Slack, Microsoft Teams, Jira, Linear, GitHub, Notion, Mail and Messages."),
        ],
        "related": ["annotate-screenshots", "timed-screenshot", "screenshot-without-keyboard"],
    },
    {
        "slug": "timed-screenshot",
        "who": "Docs & tutorials",
        "title": "Timed screenshots on Mac: capture menus, tooltips and hover states",
        "meta_title": "Timed Screenshot on Mac (5-Second Delay) — ScreenshotMenu",
        "description": "Take a screenshot on Mac with a 5-second delay to capture open menus, tooltips, dropdowns and hover states. Fullscreen, window or area, from the menu bar.",
        "card": "A 5-second delay gives you time to open the menu, hover the button or show the tooltip before the shutter fires.",
        "lead": "Open menus and tooltips disappear the moment you press a shortcut. A five-second timer lets you set the scene first and keep your hands free when the capture fires.",
        "body": f"""
<h2>Why menus and tooltips are hard to capture</h2>
<p>A tooltip appears while the pointer rests on a button. A menu stays open while you hold it. Press a screenshot shortcut and the app loses focus, and the thing you wanted to show closes before the shot is taken.</p>

<h2>How to do it with ScreenshotMenu</h2>
<ol>
<li>Click the camera icon and choose {mi("Timed Fullscreen (5s)")}, {mi("Timed Window (5s)")} or {mi("Timed Area (5s)")}.</li>
<li>Open the menu, hover the control, or bring up the tooltip, and keep it there. For window and area modes, pick the window or drag the area when macOS asks.</li>
<li>After five seconds the shutter fires, and a save dialog asks where to put the PNG. It appears after the capture, so it never ends up in the shot.</li>
</ol>
<div class="callout">Timed captures always go to a file, because they are usually for documentation that you want to keep.</div>

<h2>Good for</h2>
<ul>
<li><strong>Help-centre articles and user guides</strong> that show where a setting lives.</li>
<li><strong>Release notes and changelogs</strong> showing a new menu item.</li>
<li><strong>Bug reports</strong> about a hover state or dropdown that renders wrong.</li>
<li><strong>Training material</strong> where the menu needs to be open in the picture.</li>
</ul>

<h2>The built-in way</h2>
<p>macOS has a timer too: press <kbd>⌘</kbd> <kbd>⇧</kbd> <kbd>5</kbd>, open <em>Options</em>, choose 5 or 10 seconds and click Capture. It works, but the timer is a setting that stays on for later captures until you turn it off. In ScreenshotMenu a timed capture is just a different menu item.</p>
""",
        "faq": [
            ("How do I take a screenshot with a delay on Mac?",
             "Press Command + Shift + 5, choose a 5- or 10-second timer under Options, then Capture. Or use ScreenshotMenu's Timed Fullscreen, Timed Window or Timed Area items, which fire after 5 seconds."),
            ("How do I screenshot an open menu on Mac?",
             "Start a timed capture, then open the menu and keep it open. The screenshot is taken while the menu is visible."),
            ("Can I change the delay from 5 seconds?",
             "Not in ScreenshotMenu; the delay is fixed at 5 seconds to keep the menu short. The built-in Command + Shift + 5 toolbar also offers 10 seconds."),
        ],
        "related": ["window-screenshot", "annotate-screenshots", "screenshot-to-clipboard"],
    },
    {
        "slug": "silent-screenshot",
        "who": "Calls & screen sharing",
        "title": "Take a screenshot on Mac without the shutter sound",
        "meta_title": "Screenshot on Mac Without Sound (Silent Mode) — ScreenshotMenu",
        "description": "Turn off the camera shutter sound for Mac screenshots without muting your whole Mac. Silent Mode in ScreenshotMenu is useful during calls, meetings and recordings.",
        "card": "Turn off the shutter sound for screenshots only, without muting the call you are in.",
        "lead": "The camera click is loud on a call, in a quiet office or during a recording. Silent Mode turns it off for screenshots only, and leaves the rest of your Mac's sound alone.",
        "body": f"""
<h2>Why the built-in options are awkward</h2>
<p>macOS has no switch for the screenshot sound alone. The usual advice is to mute the Mac or turn off interface sound effects system-wide. On a call that means muting the people you are talking to, or losing every other system sound.</p>

<h2>How to do it with ScreenshotMenu</h2>
<ol>
<li>Click the camera icon in the menu bar.</li>
<li>Tick {mi("Silent Mode")}.</li>
</ol>
<p>Every capture from the menu, whether to a file, to the clipboard or timed, is now silent. The setting is remembered. Untick it to bring the sound back.</p>
<div class="callout">Under the hood this passes <code>-x</code> to macOS's own <code>screencapture</code> tool, the documented flag for “do not play sounds”. Nothing else about the capture changes.</div>

<h2>Good for</h2>
<ul>
<li><strong>Video calls</strong> in Zoom, Meet or Teams, where the click goes out to everyone.</li>
<li><strong>Screen recordings and live streams</strong> where a shutter sound would end up in the audio.</li>
<li><strong>Libraries, open-plan offices and late nights.</strong></li>
</ul>
""",
        "faq": [
            ("How do I turn off the screenshot sound on Mac?",
             "macOS has no dedicated switch: you either mute the Mac or turn off user-interface sound effects in System Settings › Sound. ScreenshotMenu's Silent Mode mutes only its own screenshots."),
            ("Does Silent Mode affect screenshots taken with keyboard shortcuts?",
             "No. It applies to captures started from the ScreenshotMenu menu. Shortcuts like Command + Shift + 4 are handled by macOS and keep their usual sound."),
        ],
        "related": ["screenshot-to-clipboard", "screenshot-without-keyboard", "private-screenshot-app"],
    },
    {
        "slug": "screenshot-without-keyboard",
        "who": "New Mac users",
        "title": "How to take a screenshot on Mac without keyboard shortcuts",
        "meta_title": "Screenshot on Mac Without Keyboard Shortcuts — ScreenshotMenu",
        "description": "Take screenshots on a Mac with the mouse or trackpad only: a menu bar app with every capture mode one click away. Free, for macOS 13 and later.",
        "card": "Every capture mode in one menu, for anyone who can never remember ⌘⇧3, ⌘⇧4 and ⌘⇧5, or would rather use the trackpad.",
        "lead": "macOS has nine screenshot variations spread over three shortcuts and two modifier keys. ScreenshotMenu puts all of them in one menu that you click.",
        "body": f"""
<h2>Nine captures, three shortcuts, two modifiers</h2>
<p>Screenshots on a Mac are powerful but hidden. Here is what you need to remember to do it from the keyboard:</p>
<div class="table-wrap"><table>
<tr><th>You want</th><th>Keyboard</th><th>ScreenshotMenu</th></tr>
<tr><td>Whole screen to a file</td><td><kbd>⌘</kbd> <kbd>⇧</kbd> <kbd>3</kbd></td><td>{mi("Fullscreen to File")}</td></tr>
<tr><td>Area to a file</td><td><kbd>⌘</kbd> <kbd>⇧</kbd> <kbd>4</kbd>, drag</td><td>{mi("Area to File")}</td></tr>
<tr><td>Window to a file</td><td><kbd>⌘</kbd> <kbd>⇧</kbd> <kbd>4</kbd>, <kbd>Space</kbd>, click</td><td>{mi("Window to File")}</td></tr>
<tr><td>Any of these to the clipboard</td><td>add <kbd>Control</kbd></td><td>{mi("… to Clipboard")}</td></tr>
<tr><td>With a timer</td><td><kbd>⌘</kbd> <kbd>⇧</kbd> <kbd>5</kbd> › Options › 5 s</td><td>{mi("Timed … (5s)")}</td></tr>
</table></div>

<h2>How to do it with ScreenshotMenu</h2>
<ol>
<li><a href="{DMG}">Download the DMG</a>, drag ScreenshotMenu to Applications and open it.</li>
<li>A camera icon appears in the menu bar. Allow <em>Screen Recording</em> when macOS asks; every screenshot app needs it.</li>
<li>From now on, click the icon and pick a capture.</li>
</ol>
<p>Tick {mi("Autolaunch")} so the icon is there after every restart.</p>

<h2>Good for</h2>
<ul>
<li><strong>People who are new to the Mac</strong> or switching from Windows' Snipping Tool.</li>
<li><strong>Trackpad and mouse-first users</strong>, and anyone who finds four-key chords uncomfortable.</li>
<li><strong>Parents, teachers and IT helpdesks</strong> setting up a Mac for someone else. “Click the camera” is easier to explain than a shortcut.</li>
</ul>
""",
        "faq": [
            ("How do I take a screenshot on a Mac with just the mouse?",
             "Install a menu bar screenshot app like ScreenshotMenu and click its icon; every capture mode is in the menu. Without an app, you can open the Screenshot app from Applications › Utilities."),
            ("Is there a Snipping Tool for Mac?",
             "macOS has the Screenshot toolbar (Command + Shift + 5). ScreenshotMenu is a lighter alternative that lives in the menu bar, with area, window and full-screen captures one click away."),
            ("Why does a screenshot app need Screen Recording permission?",
             "macOS requires it for any app that captures the screen, including Apple's own. ScreenshotMenu never records video or audio; the permission prompt simply covers both."),
        ],
        "related": ["screenshot-to-clipboard", "timed-screenshot", "private-screenshot-app"],
    },
    {
        "slug": "window-screenshot",
        "who": "Designers & writers",
        "title": "Screenshot a single window on Mac and save it as PNG",
        "meta_title": "Screenshot a Window on Mac and Save as PNG — ScreenshotMenu",
        "description": "Capture one app window on Mac, without the rest of the screen, and save it as a PNG with a dated name and a save dialog. For docs, decks, portfolios and design reviews.",
        "card": "Capture one app window, with no desktop clutter around it, and choose where the PNG is saved.",
        "lead": "A window capture is the cleanest screenshot there is: no desktop, no other apps, no stray notifications. ScreenshotMenu makes it a single menu item and asks where to save the result.",
        "body": f"""
<h2>How to do it with ScreenshotMenu</h2>
<ol>
<li>Click the camera icon and choose {mi("Window to File")}.</li>
<li>Move the pointer over the window you want. It is highlighted. Click it.</li>
<li>A save dialog opens with a name such as <code>Screenshot 2026-10-06 at 14.32.10.png</code>. Rename it, choose a folder and save.</li>
</ol>
<p>The window is captured with the soft macOS drop shadow, just like the system's own window screenshots, on a transparent background, so it sits nicely on slides and in documents.</p>

<h2>Save where you want, not on the Desktop</h2>
<p>Because every file capture goes through a save dialog, screenshots land straight in the project folder, the docs repo or the shared drive, and the Desktop stays clear. After saving:</p>
<ul>
<li>{mi("Show in Finder")} reveals the new file, ready to drag into Figma, Keynote or an email.</li>
<li>{mi("Open in Preview")} opens it for cropping or annotation.</li>
<li>{mi("Open Last Screenshot")} reopens the last file you saved, at any time.</li>
</ul>

<h2>Good for</h2>
<ul>
<li><strong>Documentation and blog posts</strong> about a specific app.</li>
<li><strong>Design reviews and portfolios</strong> showing a single screen.</li>
<li><strong>Presentations</strong>, where a window on a transparent background looks clean.</li>
</ul>
""",
        "faq": [
            ("How do I screenshot just one window on Mac?",
             "Press Command + Shift + 4, then Space, then click the window. Or choose Window to File (or Window to Clipboard) in ScreenshotMenu and click the window."),
            ("Can I choose where Mac screenshots are saved?",
             "With ScreenshotMenu, every file capture opens a save dialog, so you pick the folder each time. The built-in tool saves to one fixed location that you change under Command + Shift + 5 › Options."),
            ("What format are the screenshots?",
             "PNG, the same lossless format macOS uses for its own screenshots."),
        ],
        "related": ["timed-screenshot", "annotate-screenshots", "screenshot-to-clipboard"],
    },
    {
        "slug": "annotate-screenshots",
        "who": "Feedback & reviews",
        "title": "Take a screenshot and mark it up in Preview",
        "meta_title": "Screenshot and Annotate in Preview on Mac — ScreenshotMenu",
        "description": "Capture a screenshot on Mac and open it straight in Preview to add arrows, boxes and text, with no extra annotation app. Free menu bar tool for macOS.",
        "card": "Send every capture straight to Preview to add arrows, boxes and text with the markup tools already on your Mac.",
        "lead": "You probably don't need a separate annotation app. Preview, which ships with every Mac, has arrows, shapes, text and highlights. ScreenshotMenu hands each capture to it.",
        "body": f"""
<h2>How to do it with ScreenshotMenu</h2>
<ol>
<li>Click the camera icon and tick {mi("Open in Preview")}.</li>
<li>Take any capture.
  <ul>
  <li><strong>File captures</strong> open in Preview after you save them.</li>
  <li><strong>Clipboard captures</strong> open in Preview as an untitled document. Nothing is saved unless you choose to.</li>
  </ul>
</li>
<li>In Preview, click the markup button (the pen-tip icon) and add arrows, rectangles, text or highlights.</li>
<li>Save, or select all and copy to paste the annotated image anywhere.</li>
</ol>
<div class="callout">ScreenshotMenu does this without the Accessibility permission that many screenshot tools request. It asks macOS's own <code>screencapture</code> to hand the image to Preview with its <code>-P</code> flag, so the app never needs to control other apps.</div>

<h2>When you need more than Preview</h2>
<p>If you want blur and pixelate tools, numbered steps, scrolling capture, OCR or a capture history, a full screenshot suite such as <a href="https://shottr.cc">Shottr</a> or CleanShot X is the better choice. ScreenshotMenu deliberately stays small.</p>
""",
        "faq": [
            ("How do I annotate a screenshot on Mac without extra apps?",
             "Open it in Preview and click the markup (pen-tip) button for arrows, shapes, text and highlights. ScreenshotMenu can open every capture in Preview automatically."),
            ("Can I annotate a clipboard screenshot?",
             "Yes. With Open in Preview on, clipboard captures also open in Preview as an untitled document that you can mark up, copy, and close without saving."),
        ],
        "related": ["screenshot-to-clipboard", "window-screenshot", "private-screenshot-app"],
    },
    {
        "slug": "private-screenshot-app",
        "who": "Privacy-minded & IT",
        "title": "A private screenshot app for Mac: no network, no tracking",
        "meta_title": "Private, Open-Source Screenshot App for Mac — ScreenshotMenu",
        "description": "ScreenshotMenu is an open-source Mac screenshot app with no network code, no analytics and no Accessibility permission. Under 300 lines of Swift you can audit. Signed and notarised.",
        "card": "No network code, no analytics, no Accessibility permission. Under 300 lines of open-source Swift that you can read in minutes.",
        "lead": "Screenshots often contain the most sensitive things on your screen: passwords, customer data, private messages. The tool that takes them should be easy to trust. ScreenshotMenu is small enough to check yourself.",
        "body": f"""
<h2>What the app does not do</h2>
<ul>
<li><strong>No network access.</strong> There is no networking code at all: no analytics, no update check, no crash reporting, no cloud upload.</li>
<li><strong>No Accessibility permission.</strong> Many menu bar screenshot tools ask for it so they can drive other apps. ScreenshotMenu doesn't need it, so it cannot control your computer.</li>
<li><strong>No account, no licence key, no ads.</strong></li>
<li><strong>No background capture.</strong> Nothing is taken unless you click a menu item.</li>
</ul>

<h2>What it asks for</h2>
<p>Only <strong>Screen Recording</strong>, which macOS requires for any app that captures the screen, including Apple's own. The prompt mentions “screen and system audio” because one permission covers both. The app never records video or audio and has no code that could.</p>

<h2>How you can verify it</h2>
<ul>
<li>The <a href="{REPO}">source code is on GitHub</a> under the MIT licence. The whole app is one file, <a href="{REPO}/blob/main/Sources/ScreenshotMenu/AppDelegate.swift"><code>AppDelegate.swift</code></a>, under 300 lines.</li>
<li>Every capture runs <code>/usr/sbin/screencapture</code>, the screenshot tool that ships with macOS, with the right flags. Images come from Apple's own code path.</li>
<li>Releases are signed with a Developer ID and notarised by Apple. You can also <a href="{REPO}#building">build it yourself</a> with <code>make install</code>.</li>
</ul>

<h2>Good for</h2>
<ul>
<li><strong>Companies with strict software policies</strong> that need a tool IT can review quickly.</li>
<li><strong>People handling customer or health data</strong> who can't risk a tool phoning home.</li>
<li><strong>Anyone</strong> who prefers fewer permissions on their Mac.</li>
</ul>
""",
        "faq": [
            ("Does ScreenshotMenu upload my screenshots?",
             "No. The app contains no network code. Captures go only to the file you choose or to the clipboard."),
            ("Why doesn't ScreenshotMenu need Accessibility access?",
             "It lets macOS's own screencapture tool do the work, including handing images to Preview, so it never has to control other apps."),
            ("Is ScreenshotMenu open source?",
             "Yes, under the MIT licence. The full source is on GitHub and the whole app is a single Swift file under 300 lines."),
        ],
        "related": ["silent-screenshot", "screenshot-without-keyboard", "annotate-screenshots"],
    },
]

BY_SLUG = {u["slug"]: u for u in USE_CASES}

NAV = """<!-- NAV -->
<nav>
  <div class="wrap">
    <a class="brand" href="/"><img src="/assets/icon.png" alt="" width="30" height="30" /> ScreenshotMenu</a>
    <div class="nav-links">
      <a href="/#features">Features</a>
      <a href="/use-cases/">Use cases</a>
      <a href="/#privacy">Privacy</a>
      <a href="/#faq">FAQ</a>
    </div>
    <a class="nav-cta" href="/#download">Download</a>
  </div>
</nav>
<!-- /NAV -->"""

FOOTER = f"""<!-- FOOTER -->
<footer>
  <div class="wrap">
    <div class="foot-grid">
      <div>
        <div class="brand"><img src="/assets/icon.png" alt="" width="26" height="26" /> ScreenshotMenu</div>
        <p>A free, open-source screenshot menu for the macOS menu bar. Built on Apple's own <code>screencapture</code>.</p>
      </div>
      <div>
        <h4>Product</h4>
        <ul>
          <li><a href="/#features">Features</a></li>
          <li><a href="/#modes">All capture modes</a></li>
          <li><a href="/#privacy">Privacy</a></li>
          <li><a href="/#faq">FAQ</a></li>
          <li><a href="{DMG}">Download</a></li>
        </ul>
      </div>
      <div>
        <h4>Use cases</h4>
        <ul>
{chr(10).join(f'          <li><a href="/use-cases/{u["slug"]}/">{html.escape(u["who"])}</a></li>' for u in USE_CASES)}
        </ul>
      </div>
      <div>
        <h4>Open source</h4>
        <ul>
          <li><a href="{REPO}">Source on GitHub</a></li>
          <li><a href="{REPO}/releases">Releases</a></li>
          <li><a href="{REPO}/issues">Report an issue</a></li>
          <li><a href="{REPO}/blob/main/LICENSE">MIT licence</a></li>
        </ul>
      </div>
    </div>
    <div class="foot-bottom">
      <span>© 2026 <a href="{COMPANY_URL}">{COMPANY}</a></span>
      <span>Made for macOS 13 Ventura and later · Apple Silicon &amp; Intel</span>
    </div>
  </div>
</footer>
<!-- /FOOTER -->"""

DOWNLOAD_ICON = '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3v12m0 0l-4-4m4 4l4-4M5 21h14"/></svg>'

DOWNLOAD_BOX = f"""<section id="download">
  <div class="wrap">
    <div class="download">
      <h2>Get ScreenshotMenu</h2>
      <p>Free and open source. Download the signed, notarised DMG, drag it to Applications, and the camera icon appears in your menu bar.</p>
      <a class="btn-primary" href="{DMG}">{DOWNLOAD_ICON} Download .dmg</a>
      <div class="sub">macOS 13 Ventura or later · Apple Silicon &amp; Intel · MIT licence</div>
    </div>
  </div>
</section>"""


def head(title, description, path, extra_ld):
    url = SITE + path
    ld = "\n".join(
        f'<script type="application/ld+json">\n{json.dumps(obj, indent=2, ensure_ascii=False)}\n</script>'
        for obj in extra_ld
    )
    t, d = html.escape(title), html.escape(description)
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>{t}</title>
<meta name="description" content="{d}" />
<meta name="theme-color" content="#2f6bff" />
<link rel="canonical" href="{url}" />
<link rel="icon" type="image/png" href="/assets/icon.png" />
<link rel="apple-touch-icon" href="/assets/icon.png" />
<link rel="stylesheet" href="/assets/site.css" />
<meta property="og:type" content="article" />
<meta property="og:url" content="{url}" />
<meta property="og:title" content="{t}" />
<meta property="og:description" content="{d}" />
<meta property="og:image" content="{SITE}/assets/social-card.png" />
<meta property="og:image:width" content="1270" />
<meta property="og:image:height" content="760" />
<meta property="og:image:alt" content="{OG_ALT}" />
<meta property="og:site_name" content="ScreenshotMenu" />
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:title" content="{t}" />
<meta name="twitter:description" content="{d}" />
<meta name="twitter:image" content="{SITE}/assets/social-card.png" />
<meta name="twitter:image:alt" content="{OG_ALT}" />
{ld}
</head>
<body>
"""


def breadcrumbs_ld(items):
    return {
        "@context": "https://schema.org",
        "@type": "BreadcrumbList",
        "itemListElement": [
            {"@type": "ListItem", "position": i + 1, "name": name, "item": SITE + path}
            for i, (name, path) in enumerate(items)
        ],
    }


def strip_tags(s):
    return re.sub(r"<[^>]+>", "", s)


def card(u):
    return f"""      <a class="uc-card" href="/use-cases/{u['slug']}/">
        <span class="who">{html.escape(u['who'])}</span>
        <h3>{html.escape(u['title'])}</h3>
        <p>{html.escape(u['card'])}</p>
        <span class="more">Read more →</span>
      </a>"""


def use_case_page(u):
    """The page, with @DATE@ where its modification date goes."""
    path = f"/use-cases/{u['slug']}/"
    faq_ld = {
        "@context": "https://schema.org",
        "@type": "FAQPage",
        "mainEntity": [
            {"@type": "Question", "name": q, "acceptedAnswer": {"@type": "Answer", "text": a}}
            for q, a in u["faq"]
        ],
    }
    article_ld = {
        "@context": "https://schema.org",
        "@type": "TechArticle",
        "headline": u["title"],
        "description": u["description"],
        "url": SITE + path,
        "dateModified": "@DATE@",
        "about": {"@type": "SoftwareApplication", "name": "ScreenshotMenu", "url": SITE + "/"},
        "publisher": {"@type": "Organization", "name": COMPANY, "url": COMPANY_URL},
    }
    crumbs = breadcrumbs_ld([("ScreenshotMenu", "/"), ("Use cases", "/use-cases/"), (u["who"], path)])
    faq_html = "\n".join(
        f"      <details{' open' if i == 0 else ''}>\n        <summary>{html.escape(q)}</summary>\n        <p>{html.escape(a)}</p>\n      </details>"
        for i, (q, a) in enumerate(u["faq"])
    )
    related = "\n".join(card(BY_SLUG[s]) for s in u["related"])
    return head(u["meta_title"], u["description"], path, [article_ld, faq_ld, crumbs]) + f"""
{NAV}

<main>
<div class="wrap">
  <div class="crumbs"><a href="/">ScreenshotMenu</a><span>›</span><a href="/use-cases/">Use cases</a><span>›</span>{html.escape(u['who'])}</div>
</div>

<header class="article-hero">
  <div class="wrap">
    <div class="eyebrow">{html.escape(u['who'])}</div>
    <h1>{html.escape(u['title'])}</h1>
    <p class="lead">{html.escape(u['lead'])}</p>
    <div class="cta-row">
      <a class="btn-primary" href="{DMG}">{DOWNLOAD_ICON} Download for macOS</a>
      <a class="btn-ghost" href="/#modes">See all capture modes</a>
    </div>
  </div>
</header>

<section class="article">
  <div class="wrap">
    <div class="prose">
{u['body'].strip()}

<h2>Questions</h2>
    </div>
    <div class="faq-list">
{faq_html}
    </div>
  </div>
</section>

<section class="related">
  <div class="wrap">
    <h2>Other ways to use ScreenshotMenu</h2>
    <div class="uc-grid">
{related}
    </div>
  </div>
</section>

{DOWNLOAD_BOX}
</main>

{FOOTER}

</body>
</html>
"""


def use_case_index():
    path = "/use-cases/"
    title = "Mac Screenshot Use Cases: Clipboard, Timed, Silent, Window — ScreenshotMenu"
    description = "How people use ScreenshotMenu on Mac: screenshots to the clipboard for bug reports, timed captures of menus, silent screenshots on calls, window captures for docs, and more."
    item_list = {
        "@context": "https://schema.org",
        "@type": "ItemList",
        "itemListElement": [
            {"@type": "ListItem", "position": i + 1, "url": f"{SITE}/use-cases/{u['slug']}/", "name": u["title"]}
            for i, u in enumerate(USE_CASES)
        ],
    }
    crumbs = breadcrumbs_ld([("ScreenshotMenu", "/"), ("Use cases", path)])
    cards = "\n".join(card(u) for u in USE_CASES)
    return head(title, description, path, [item_list, crumbs]) + f"""
{NAV}

<main>
<div class="wrap">
  <div class="crumbs"><a href="/">ScreenshotMenu</a><span>›</span>Use cases</div>
</div>

<header class="article-hero">
  <div class="wrap">
    <div class="eyebrow">Use cases</div>
    <h1>One menu, many kinds of screenshot</h1>
    <p class="lead">ScreenshotMenu has nine capture modes and four settings. Here is how people use them day to day, with the exact menu items to click.</p>
  </div>
</header>

<section class="article">
  <div class="wrap">
    <div class="uc-grid">
{cards}
    </div>
  </div>
</section>

{DOWNLOAD_BOX}
</main>

{FOOTER}

</body>
</html>
"""


def replace_block(text, name, block):
    pattern = re.compile(rf"<!-- {name} -->.*?<!-- /{name} -->", re.S)
    if not pattern.search(text):
        raise SystemExit(f"index.html is missing the <!-- {name} --> block")
    return pattern.sub(lambda _: block, text)


def committed(rel):
    """The file as it is in git HEAD, or None if it is new."""
    r = subprocess.run(["git", "show", f"HEAD:web/{rel}"], cwd=WEB.parent, capture_output=True, text=True)
    return r.stdout if r.returncode == 0 else None


def committed_lastmods():
    old = committed("sitemap.xml") or ""
    return {
        loc[len(SITE):]: date
        for loc, date in re.findall(r"<loc>(.*?)</loc>\s*<lastmod>(.*?)</lastmod>", old)
    }


def dated(rel, text, old_date):
    """Fill in @DATE@: the page keeps its committed date unless its content changed.

    Using today's date unconditionally would make every build a change and
    tell search engines that untouched pages were updated.
    """
    prev = committed(rel)
    if old_date and prev is not None and prev == text.replace("@DATE@", old_date):
        return text.replace("@DATE@", old_date), old_date
    return text.replace("@DATE@", TODAY), TODAY


def sitemap(lastmods):
    urls = "\n".join(
        f"  <url>\n    <loc>{SITE}{p}</loc>\n    <lastmod>{d}</lastmod>\n  </url>" for p, d in lastmods.items()
    )
    return f'<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n{urls}\n</urlset>\n'


def main():
    old = committed_lastmods()
    lastmods = {}

    index = WEB / "index.html"
    text = index.read_text()
    text = replace_block(text, "NAV", NAV)
    text = replace_block(text, "FOOTER", FOOTER)
    text = replace_block(text, "USE-CASES", "<!-- USE-CASES -->\n" + "\n".join(card(u) for u in USE_CASES[:6]) + "\n<!-- /USE-CASES -->")
    index.write_text(text)
    _, lastmods["/"] = dated("index.html", text, old.get("/"))

    pages = [("/use-cases/", "use-cases/index.html", use_case_index())]
    pages += [(f"/use-cases/{u['slug']}/", f"use-cases/{u['slug']}/index.html", use_case_page(u)) for u in USE_CASES]
    for path, rel, page in pages:
        page, lastmods[path] = dated(rel, page, old.get(path))
        out = WEB / rel
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(page)

    (WEB / "sitemap.xml").write_text(sitemap(lastmods))
    print(f"built {len(USE_CASES)} use-case pages, index, nav/footer and sitemap")


if __name__ == "__main__":
    main()
