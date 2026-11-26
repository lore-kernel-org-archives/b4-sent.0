MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-yoc1s-ffmpeg-v1-5-f01fec79468b@certik.com>
References: <20261127-yoc1s-ffmpeg-v1-0-f01fec79468b@certik.com>
In-Reply-To: <20261127-yoc1s-ffmpeg-v1-0-f01fec79468b@certik.com>
From: Dickson Wu <dickson.wu@certik.com>
Date: Thu, 26 Nov 2026 23:02:05 +0000
Subject: [scarthgap][PATCH 5/7] ffmpeg: fix CVE-2026-135734
To: openembedded-core@lists.openembedded.org
Cc: Yoann Congal <yoann.congal@smile.fr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795769565; l=2657;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=pwCQ7RZf8N/57MZhqhKvdJggxKSOYWfC6RzFI8SPz0U=;
 b=j4z3XSU6lPR/d+XSuX6EJj63jT+vQKtAtm83XK5FHK6oL40fAVjlLkjk+jucEH9s71IrpmXm1
 MYaj1AXR4oJD7fPceCUwkRw2Ige8GaQes3GpqtTVEM5nxrfDZM1xMs2
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The deflicker histogram was too small for all 16-bit sample values,
allowing an out-of-bounds write. Backport the upstream fix.

https://github.com/FFmpeg/FFmpeg/commit/fa10042f748f

AI-Generated: OpenAI Codex, gpt-6.2-sol
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
 .../ffmpeg/ffmpeg/CVE-2026-135734.patch       | 36 +++++++++++++++++++
 .../recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb |  1 +
 2 files changed, 37 insertions(+)
 create mode 100644 meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135734.patch

diff --git a/meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135734.patch b/meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135734.patch
new file mode 100644
index 00000000..0d722501
--- /dev/null
+++ b/meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135734.patch
@@ -0,0 +1,36 @@
+From fa10042f748f20fad0cc0ee8fdcebe96b76603af Mon Sep 17 00:00:00 2001
+From: Michael Niedermayer <michael@niedermayer.cc>
+Date: Sat, 14 Nov 2026 01:57:50 +0100
+Subject: [PATCH] avfilter/vf_deflicker: allocate the histogram for all 16 bit
+ sample values
+
+Fixes: out of array write
+Fixes: QvFnGUZttUck
+Fixes: AISLE-2026-0166-00061
+
+Found-by: berrob14 (#24121)
+Found-by: Joshua Rogers (AISLE)
+
+Out of array write Replicated through UnModified FFmpeg with ASAN
+
+CVE: CVE-2026-135734
+Upstream-Status: Backport [https://github.com/FFmpeg/FFmpeg/commit/fa10042f748f20fad0cc0ee8fdcebe96b76603af]
+
+Signed-off-by: Dickson Wu <dickson.wu@certik.com>
+---
+ libavfilter/vf_deflicker.c | 2 +-
+ 1 file changed, 1 insertion(+), 1 deletion(-)
+
+diff --git a/libavfilter/vf_deflicker.c b/libavfilter/vf_deflicker.c
+index 38f838f088ca5..8bab1211c20ea 100644
+--- a/libavfilter/vf_deflicker.c
++++ b/libavfilter/vf_deflicker.c
+@@ -333,7 +333,7 @@ static int config_input(AVFilterLink *inlink)
+         s->calc_avgy = calc_avgy16;
+     }
+ 
+-    s->histogram = av_calloc(1 << s->depth, sizeof(*s->histogram));
++    s->histogram = av_calloc(1 << (s->depth > 8 ? 16 : 8), sizeof(*s->histogram));
+     if (!s->histogram)
+         return AVERROR(ENOMEM);
+ 
diff --git a/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb b/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb
index 789beed0..4f2a1ec1 100644
--- a/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb
+++ b/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb
@@ -36,6 +36,7 @@ SRC_URI = " \
     file://CVE-2026-135743.patch \
     file://CVE-2026-135722.patch \
     file://CVE-2026-135725.patch \
+    file://CVE-2026-135734.patch \
 "
 
 SRC_URI[sha256sum] = "a231e3d5742c44b1cdaebfb98ad7b6200d12763e0b6db9e1e2c5891f2c083a18"
-- 
2.43.0

