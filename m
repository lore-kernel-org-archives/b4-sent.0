MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-yoc1s-ffmpeg-v1-6-f01fec79468b@certik.com>
References: <20261127-yoc1s-ffmpeg-v1-0-f01fec79468b@certik.com>
In-Reply-To: <20261127-yoc1s-ffmpeg-v1-0-f01fec79468b@certik.com>
From: Dickson Wu <dickson.wu@certik.com>
Date: Thu, 26 Nov 2026 23:02:05 +0000
Subject: [scarthgap][PATCH 6/7] ffmpeg: fix CVE-2026-135738
To: openembedded-core@lists.openembedded.org
Cc: Yoann Congal <yoann.congal@smile.fr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795769565; l=3924;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=uvqx9OEiKnuHymVoNT1op4kL9F/mtTaEnrhCOi2ujoI=;
 b=rGcmMUFYAqty6J4JiPTaVhGHgptgSia4gDuAJh285ahzqO1xnTPzLCewP9Pk9ozcSUPNB/Pi1
 oG7SvHwGiS1ArslO6LdMkIVhjzHNVK5HYuhPTTwSLV+WKXuzpBH5GbJ
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The signalstats histograms did not cover the full 16-bit sample range,
allowing out-of-bounds writes and an invalid float-to-integer
conversion. Backport the upstream fix.

https://github.com/FFmpeg/FFmpeg/commit/04955e8b148f

AI-Generated: OpenAI Codex, gpt-6.2-sol
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
 .../ffmpeg/ffmpeg/CVE-2026-135738.patch       | 52 +++++++++++++++++++
 .../recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb |  1 +
 2 files changed, 53 insertions(+)
 create mode 100644 meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135738.patch

diff --git a/meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135738.patch b/meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135738.patch
new file mode 100644
index 00000000..e01db76d
--- /dev/null
+++ b/meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135738.patch
@@ -0,0 +1,52 @@
+From 04955e8b148fa3e7ab022cbb9f5e35c49165ae21 Mon Sep 17 00:00:00 2001
+From: Michael Niedermayer <michael@niedermayer.cc>
+Date: Sat, 14 Nov 2026 01:58:22 +0100
+Subject: [PATCH] avfilter/vf_signalstats: allocate the histograms for all 16
+ bit sample values
+
+Fixes: out of array write
+Fixes: 91956.4 is outside the range of representable values of type 'unsigned short'
+Fixes: 3DKcZFM0ZaFw
+Fixes: AISLE-2026-0166-00233
+
+Found-by: Joshua Rogers (AISLE)
+
+Out of array write Replicated through UnModified FFmpeg with ASAN
+Float to integer overflow Replicated through UnModified FFmpeg with UBSAN
+
+CVE: CVE-2026-135738
+Upstream-Status: Backport [https://github.com/FFmpeg/FFmpeg/commit/04955e8b148fa3e7ab022cbb9f5e35c49165ae21]
+
+Signed-off-by: Dickson Wu <dickson.wu@certik.com>
+---
+ libavfilter/vf_signalstats.c | 10 +++++-----
+ 1 file changed, 5 insertions(+), 5 deletions(-)
+
+diff --git a/libavfilter/vf_signalstats.c b/libavfilter/vf_signalstats.c
+index 5859b46478c16..a69773c20831b 100644
+--- a/libavfilter/vf_signalstats.c
++++ b/libavfilter/vf_signalstats.c
+@@ -161,10 +161,10 @@ static int config_output(AVFilterLink *outlink)
+     s->vsub = desc->log2_chroma_h;
+     s->depth = desc->comp[0].depth;
+     s->maxsize = 1 << s->depth;
+-    s->histy = av_malloc_array(s->maxsize, sizeof(*s->histy));
+-    s->histu = av_malloc_array(s->maxsize, sizeof(*s->histu));
+-    s->histv = av_malloc_array(s->maxsize, sizeof(*s->histv));
+-    s->histsat = av_malloc_array(s->maxsize, sizeof(*s->histsat));
++    s->histy = av_calloc(1 << (s->depth > 8 ? 16 : 8), sizeof(*s->histy));
++    s->histu = av_calloc(1 << (s->depth > 8 ? 16 : 8), sizeof(*s->histu));
++    s->histv = av_calloc(1 << (s->depth > 8 ? 16 : 8), sizeof(*s->histv));
++    s->histsat = av_calloc(1 << (s->depth > 8 ? 16 : 8), sizeof(*s->histsat));
+ 
+     if (!s->histy || !s->histu || !s->histv || !s->histsat)
+         return AVERROR(ENOMEM);
+@@ -520,7 +520,7 @@ static int compute_sat_hue_metrics16(AVFilterContext *ctx, void *arg, int jobnr,
+         for (i = 0; i < s->chromaw; i++) {
+             const int yuvu = p_u[i];
+             const int yuvv = p_v[i];
+-            p_sat[i] = hypotf(yuvu - mid, yuvv - mid); // int or round?
++            p_sat[i] = (int)hypotf(yuvu - mid, yuvv - mid); // int or round?
+             ((int16_t*)p_hue)[i] = fmodf(floorf((180.f / M_PI) * atan2f(yuvu-mid, yuvv-mid) + 180.f), 360.f);
+         }
+         p_u   += lsz_u;
diff --git a/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb b/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb
index 4f2a1ec1..2c06762b 100644
--- a/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb
+++ b/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb
@@ -37,6 +37,7 @@ SRC_URI = " \
     file://CVE-2026-135722.patch \
     file://CVE-2026-135725.patch \
     file://CVE-2026-135734.patch \
+    file://CVE-2026-135738.patch \
 "
 
 SRC_URI[sha256sum] = "a231e3d5742c44b1cdaebfb98ad7b6200d12763e0b6db9e1e2c5891f2c083a18"
-- 
2.43.0

