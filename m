From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 08:52:44 +0000
Message-Id: <20261127-yoc1s-ffmpeg-v1-0-f01fec79468b@certik.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANxECWsC/yWMSw4CIRBErzLptSRAdD5exbgApvkYBUKj0Uzm7
 oIu61XV24CwBCQ4DxsUfAUKKbYgDgMYr6JDFtaWQXI5CiEn9klGELP2kdExsZzmcTrOC+cK2iU
 XtOH9012AjCrVO5Xh+q/oqW9oatf1sVaETBcVje+IMK41pTvrHPb9C7oZCvubAAAA
X-Change-ID: 20261127-yoc1s-ffmpeg-19586748900a
Subject: [scarthgap][PATCH 0/7] ffmpeg: backport seven security fixes
To: openembedded-core@lists.openembedded.org
Cc: Yoann Congal <yoann.congal@smile.fr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795769564; l=1956;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=+GiepgD4KymWaju/DEF38E1uqESug8md6EBjxCGlDwk=;
 b=SQhEgVkysTAgEhXzlhcHZe4QqVZMu0AeJPY5kU944iupyayOJ6Pye/1Soa9gGfZfmT5TnjSak
 EDLCswIiZ2xAcd7tWkIncHdNP8ffXkv0bP7XRfyNzf0rsu4VOz11Iov
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Backport seven upstream FFmpeg fixes to Scarthgap's FFmpeg 6.1.4.

Tested: git am on current OE-Core Scarthgap and zero-fuzz SRC_URI
application. Reused Pilot-YOC1 sandbox results for the same FFmpeg
recipe and patch stack: baseline and patched BitBake builds, patched
do_patch, and 1,520 passing patched FATE tests with FATE_SAMPLES empty.

The backports and test runs were prepared with AI coding tools (OpenAI
Codex agents, with review by Claude). I went over the result before
signing off.

Dickson Wu (7):
  ffmpeg: fix CVE-2026-135736
  ffmpeg: fix CVE-2026-135743
  ffmpeg: fix CVE-2026-135722
  ffmpeg: fix CVE-2026-135725
  ffmpeg: fix CVE-2026-135734
  ffmpeg: fix CVE-2026-135738
  ffmpeg: fix CVE-2026-135740

 .../ffmpeg/ffmpeg/CVE-2026-135722.patch       | 36 +++++++++++++
 .../ffmpeg/ffmpeg/CVE-2026-135725.patch       | 34 ++++++++++++
 .../ffmpeg/ffmpeg/CVE-2026-135734.patch       | 36 +++++++++++++
 .../ffmpeg/ffmpeg/CVE-2026-135736.patch       | 45 ++++++++++++++++
 .../ffmpeg/ffmpeg/CVE-2026-135738.patch       | 52 +++++++++++++++++++
 .../ffmpeg/ffmpeg/CVE-2026-135740.patch       | 35 +++++++++++++
 .../ffmpeg/ffmpeg/CVE-2026-135743.patch       | 49 +++++++++++++++++
 .../recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb |  7 +++
 8 files changed, 294 insertions(+)
 create mode 100644 meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135722.patch
 create mode 100644 meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135725.patch
 create mode 100644 meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135734.patch
 create mode 100644 meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135736.patch
 create mode 100644 meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135738.patch
 create mode 100644 meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135740.patch
 create mode 100644 meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135743.patch


base-commit: d521a7d8364fe038ce5205003170e80de218a83a
-- 
2.43.0

