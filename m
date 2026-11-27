MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-pillow-sg-v1-3-cbcff72e5e81@certik.com>
References: <20261128-pillow-sg-v1-0-cbcff72e5e81@certik.com>
In-Reply-To: <20261128-pillow-sg-v1-0-cbcff72e5e81@certik.com>
From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 10:05:11 +0000
Subject: [meta-python][scarthgap][PATCH 3/4] python3-pillow: patch
 CVE-2026-112400
To: openembedded-devel@lists.openembedded.org
Cc: Anuj Mittal <anuj.mittal@oss.qualcomm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795830619; l=3088;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=a/k8HCX+ekskdG/KfwWkFfZ2YntI2rwdfV5RaeQhhqk=;
 b=yvjDAA7ZIerln8gMZ0nQ4nzLIIBhK0p6ELPQ44KsCbKW/ao5XXaRtuiY56SmL5t+oiA/Qbwqm
 2/Z9wN23CcaBpjb+OAQSZ/kEK8BvwrKrJoEngX0Xm5bDB5b+uwYkBN/
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Do not keep size from failed GIF decompression bomb check (#10116).

Upstream commit:
https://github.com/python-pillow/Pillow/commit/6faed707cfb760a4cbd726ddc8406f576cf35bf7

AI-Generated: OpenAI Codex, gpt-6.2-sol
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
 .../python3-pillow/CVE-2026-112400.patch      | 30 +++++++++++++++++++
 .../python/python3-pillow_10.3.0.bb           |  1 +
 2 files changed, 31 insertions(+)
 create mode 100644 meta-python/recipes-devtools/python/python3-pillow/CVE-2026-112400.patch

diff --git a/meta-python/recipes-devtools/python/python3-pillow/CVE-2026-112400.patch b/meta-python/recipes-devtools/python/python3-pillow/CVE-2026-112400.patch
new file mode 100644
index 000000000..9608fc18b
--- /dev/null
+++ b/meta-python/recipes-devtools/python/python3-pillow/CVE-2026-112400.patch
@@ -0,0 +1,30 @@
+From 6faed707cfb760a4cbd726ddc8406f576cf35bf7 Mon Sep 17 00:00:00 2001
+From: Andrew Murray <3112309+radarhere@users.noreply.github.com>
+Date: Sun, 4 Oct 2026 09:18:28 +1100
+Subject: [PATCH] Do not keep size from failed GIF decompression bomb check
+ (#10116)
+
+Co-authored-by: Jeffrey 'Alex' Clark <aclark@aclark.net>
+Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
+
+CVE: CVE-2026-112400
+Upstream-Status: Backport [https://github.com/python-pillow/Pillow/commit/6faed707cfb760a4cbd726ddc8406f576cf35bf7]
+Backport note: Omit upstream test changes in Tests/test_decompression_bomb.py.
+Signed-off-by: Dickson Wu <dickson.wu@certik.com>
+---
+diff --git a/src/PIL/GifImagePlugin.py b/src/PIL/GifImagePlugin.py
+index 48ba0f9deb1..c6b327ef8f5 100644
+--- a/src/PIL/GifImagePlugin.py
++++ b/src/PIL/GifImagePlugin.py
+@@ -286,8 +286,9 @@ def _seek(self, frame: int, update_image: bool = True) -> None:
+                 x0, y0 = i16(s, 0), i16(s, 2)
+                 x1, y1 = x0 + i16(s, 4), y0 + i16(s, 6)
+                 if (x1 > self.size[0] or y1 > self.size[1]) and update_image:
+-                    self._size = max(x1, self.size[0]), max(y1, self.size[1])
+-                    Image._decompression_bomb_check(self._size)
++                    size = max(x1, self.size[0]), max(y1, self.size[1])
++                    Image._decompression_bomb_check(size)
++                    self._size = size
+                 frame_dispose_extent = x0, y0, x1, y1
+                 flags = s[8]
+ 
diff --git a/meta-python/recipes-devtools/python/python3-pillow_10.3.0.bb b/meta-python/recipes-devtools/python/python3-pillow_10.3.0.bb
index 5f228b227..374984d0e 100644
--- a/meta-python/recipes-devtools/python/python3-pillow_10.3.0.bb
+++ b/meta-python/recipes-devtools/python/python3-pillow_10.3.0.bb
@@ -16,6 +16,7 @@ SRC_URI = "git://github.com/python-pillow/Pillow.git;branch=main;protocol=https
            file://CVE-2026-112393.patch \
            file://CVE-2026-112398_CVE-2026-112403.patch \
            file://CVE-2026-112900.patch \
+           file://CVE-2026-112400.patch \
            "
 SRCREV = "5c89d88eee199ba53f64581ea39b6a1bc52feb1a"
 
