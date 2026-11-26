MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-yoc1s-ffmpeg-v1-3-f01fec79468b@certik.com>
References: <20261127-yoc1s-ffmpeg-v1-0-f01fec79468b@certik.com>
In-Reply-To: <20261127-yoc1s-ffmpeg-v1-0-f01fec79468b@certik.com>
From: Dickson Wu <dickson.wu@certik.com>
Date: Thu, 26 Nov 2026 23:02:05 +0000
Subject: [scarthgap][PATCH 3/7] ffmpeg: fix CVE-2026-135722
To: openembedded-core@lists.openembedded.org
Cc: Yoann Congal <yoann.congal@smile.fr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795769564; l=2853;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=L9rq1+XOH4O3jSXzFB1Vq1HtolZutvodyYP1EcWSOYg=;
 b=y0XaEm2orP4i6TbZJOCc44RRMT+01LQrD0IbkIrqWHGMUlYPBhXM3v/ieGFra5xTyEXpimBBQ
 n5Bi+1d+r6kDglUoZdQcpXBMzutvG3lZh2Mv2V+tvAxjLn7S02Xihmd
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The WAV muxer could write peak-envelope data without audio channels and
access outside its channel array. Backport the upstream fix.

https://github.com/FFmpeg/FFmpeg/commit/0b1c279b62af

AI-Generated: OpenAI Codex, gpt-6.2-sol
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
 .../ffmpeg/ffmpeg/CVE-2026-135722.patch       | 36 +++++++++++++++++++
 .../recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb |  1 +
 2 files changed, 37 insertions(+)
 create mode 100644 meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135722.patch

diff --git a/meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135722.patch b/meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135722.patch
new file mode 100644
index 00000000..6a063254
--- /dev/null
+++ b/meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135722.patch
@@ -0,0 +1,36 @@
+From 0b1c279b62af82e422e3fc21ba6cc2fc3154dc76 Mon Sep 17 00:00:00 2001
+From: Michael Niedermayer <michael@niedermayer.cc>
+Date: Tue, 6 Oct 2026 07:19:23 +0200
+Subject: [PATCH] avformat/wavenc: Reject peak envelope writing without
+ channels
+
+The fix is the one recommended in the report.
+
+Fixes: out of array write
+Fixes: LHiad3FmdAmI
+Fixes: AISLE-2026-0111-00337
+Out of array write Replicated through UnModified FFmpeg with ASAN
+Found-by: Joshua Rogers <joshua.rogers@aisle.com>
+
+CVE: CVE-2026-135722
+Upstream-Status: Backport [https://github.com/FFmpeg/FFmpeg/commit/0b1c279b62af82e422e3fc21ba6cc2fc3154dc76]
+
+Signed-off-by: Dickson Wu <dickson.wu@certik.com>
+---
+ libavformat/wavenc.c | 3 ++-
+ 1 file changed, 2 insertions(+), 1 deletion(-)
+
+diff --git a/libavformat/wavenc.c b/libavformat/wavenc.c
+index c9ced4a1bdf4f..9de3f7b7890a8 100644
+--- a/libavformat/wavenc.c
++++ b/libavformat/wavenc.c
+@@ -194,7 +194,8 @@ static av_cold int peak_init_writer(AVFormatContext *s)
+                "Writing 16 bit peak for 8 bit audio does not make sense\n");
+         return AVERROR(EINVAL);
+     }
+-    if (par->ch_layout.nb_channels > INT_MAX / (wav->peak_bps * wav->peak_ppv))
++    if (par->ch_layout.nb_channels <= 0 ||
++        par->ch_layout.nb_channels > INT_MAX / (wav->peak_bps * wav->peak_ppv))
+         return AVERROR(ERANGE);
+     wav->size_increment = par->ch_layout.nb_channels * wav->peak_bps * wav->peak_ppv;
+ 
diff --git a/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb b/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb
index 9d92115b..a9b42303 100644
--- a/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb
+++ b/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb
@@ -34,6 +34,7 @@ SRC_URI = " \
     file://CVE-2025-22921.patch \
     file://CVE-2026-135736.patch \
     file://CVE-2026-135743.patch \
+    file://CVE-2026-135722.patch \
 "
 
 SRC_URI[sha256sum] = "a231e3d5742c44b1cdaebfb98ad7b6200d12763e0b6db9e1e2c5891f2c083a18"
-- 
2.43.0

