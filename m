MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-yoc1s-ffmpeg-v1-7-f01fec79468b@certik.com>
References: <20261127-yoc1s-ffmpeg-v1-0-f01fec79468b@certik.com>
In-Reply-To: <20261127-yoc1s-ffmpeg-v1-0-f01fec79468b@certik.com>
From: Dickson Wu <dickson.wu@certik.com>
Date: Thu, 26 Nov 2026 23:02:05 +0000
Subject: [scarthgap][PATCH 7/7] ffmpeg: fix CVE-2026-135740
To: openembedded-core@lists.openembedded.org
Cc: Yoann Congal <yoann.congal@smile.fr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795769565; l=2695;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=zdkqaBc9YVASTYHuvTkigBjoFyQo3qq7mR75JEq5aMo=;
 b=KS0YTqgSro11Cup1gsmQVjh4GZWh6stJOpe3Lv3AbMAAhyJBArLgd5PUqfoWnj2ffaaGb2t/I
 whSCuFXH+xsBNkFSZcmYmtWUzJGnH8zEMdweIS6v0p0iyi32egJ/D+c
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The readeia608 filter could index its histogram with high-bit-depth
samples outside its bounds. Backport the upstream fix.

https://github.com/FFmpeg/FFmpeg/commit/df1ddf75db9a

AI-Generated: OpenAI Codex, gpt-6.2-sol
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
 .../ffmpeg/ffmpeg/CVE-2026-135740.patch       | 35 +++++++++++++++++++
 .../recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb |  1 +
 2 files changed, 36 insertions(+)
 create mode 100644 meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135740.patch

diff --git a/meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135740.patch b/meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135740.patch
new file mode 100644
index 00000000..ef18e212
--- /dev/null
+++ b/meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135740.patch
@@ -0,0 +1,35 @@
+From df1ddf75db9a1ff36a35019511e17f795cf20c55 Mon Sep 17 00:00:00 2001
+From: Michael Niedermayer <michael@niedermayer.cc>
+Date: Sat, 14 Nov 2026 00:36:46 +0100
+Subject: [PATCH] avfilter/vf_readeia608: clip high bit depth samples to the
+ histogram
+
+Fixes: out of array write
+Fixes: 1gH0Fg8kXAvn
+Fixes: AISLE-2026-0166-00264
+
+Found-by: Joshua Rogers (AISLE)
+
+Out of array write Replicated through UnModified FFmpeg with ASAN
+
+CVE: CVE-2026-135740
+Upstream-Status: Backport [https://github.com/FFmpeg/FFmpeg/commit/df1ddf75db9a1ff36a35019511e17f795cf20c55]
+
+Signed-off-by: Dickson Wu <dickson.wu@certik.com>
+---
+ libavfilter/vf_readeia608.c | 2 +-
+ 1 file changed, 1 insertion(+), 1 deletion(-)
+
+diff --git a/libavfilter/vf_readeia608.c b/libavfilter/vf_readeia608.c
+index 86e9019356aa8..2d23afdf196f9 100644
+--- a/libavfilter/vf_readeia608.c
++++ b/libavfilter/vf_readeia608.c
+@@ -173,7 +173,7 @@ static void build_histogram(ReadEIA608Context *s, ScanItem *scan, const LineItem
+     memset(scan->histogram, 0, (s->max + 1) * sizeof(*scan->histogram));
+ 
+     for (int i = LAG; i < len + LAG; i++)
+-        scan->histogram[line[i].input]++;
++        scan->histogram[FFMIN(line[i].input, s->max)]++;
+ }
+ 
+ static void find_black_and_white(ReadEIA608Context *s, ScanItem *scan)
diff --git a/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb b/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb
index 2c06762b..99585cd5 100644
--- a/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb
+++ b/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb
@@ -38,6 +38,7 @@ SRC_URI = " \
     file://CVE-2026-135725.patch \
     file://CVE-2026-135734.patch \
     file://CVE-2026-135738.patch \
+    file://CVE-2026-135740.patch \
 "
 
 SRC_URI[sha256sum] = "a231e3d5742c44b1cdaebfb98ad7b6200d12763e0b6db9e1e2c5891f2c083a18"
-- 
2.43.0

