MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-yoc1s-ffmpeg-v1-1-f01fec79468b@certik.com>
References: <20261127-yoc1s-ffmpeg-v1-0-f01fec79468b@certik.com>
In-Reply-To: <20261127-yoc1s-ffmpeg-v1-0-f01fec79468b@certik.com>
From: Dickson Wu <dickson.wu@certik.com>
Date: Thu, 26 Nov 2026 23:02:05 +0000
Subject: [scarthgap][PATCH 1/7] ffmpeg: fix CVE-2026-135736
To: openembedded-core@lists.openembedded.org
Cc: Yoann Congal <yoann.congal@smile.fr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795769564; l=2986;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=GuxqvwhgVspx+ChWbJMq5zFQuumStwuxwgjYy0uKo0M=;
 b=Vnm50eIBmXI/K4HU+lRY3Qts8bT2U2tUsOuP6B9zieKkAqDEhJMrzdCgPlxo9FZyPLDUS2Qlz
 xyqETFIbPd6BpjVAAWLUdf+cE+w1UmqM1BuMZtjF6cvDAj25k9trQQG
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The deband filter allowed the runtime coupling option for subsampled
pixel formats, which could access outside chroma planes. Backport the
upstream fix.

https://github.com/FFmpeg/FFmpeg/commit/24ad423d908c

AI-Generated: OpenAI Codex, gpt-6.2-sol
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
 .../ffmpeg/ffmpeg/CVE-2026-135736.patch       | 45 +++++++++++++++++++
 .../recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb |  1 +
 2 files changed, 46 insertions(+)
 create mode 100644 meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135736.patch

diff --git a/meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135736.patch b/meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135736.patch
new file mode 100644
index 00000000..6abf259f
--- /dev/null
+++ b/meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135736.patch
@@ -0,0 +1,45 @@
+From 24ad423d908cd595c983b6c503ddb0ee94901ba2 Mon Sep 17 00:00:00 2001
+From: Michael Niedermayer <michael@niedermayer.cc>
+Date: Sat, 14 Nov 2026 05:23:08 +0100
+Subject: [PATCH] avfilter/vf_deband: reject the coupling command for
+ subsampled formats
+
+Fixes: out of array access
+Fixes: QJKTLuAvDBVR
+Fixes: AISLE-2026-0166-00123
+
+Found-by: Joshua Rogers (AISLE)
+
+Out of array read and write Replicated through UnModified FFmpeg with ASAN
+
+CVE: CVE-2026-135736
+Upstream-Status: Backport [https://github.com/FFmpeg/FFmpeg/commit/24ad423d908cd595c983b6c503ddb0ee94901ba2]
+
+Signed-off-by: Dickson Wu <dickson.wu@certik.com>
+---
+ libavfilter/vf_deband.c | 7 +++++++
+ 1 file changed, 7 insertions(+)
+
+diff --git a/libavfilter/vf_deband.c b/libavfilter/vf_deband.c
+index 2ff4fca6fa4de..6dd08dd10f80e 100644
+--- a/libavfilter/vf_deband.c
++++ b/libavfilter/vf_deband.c
+@@ -438,11 +438,18 @@ static int filter_frame(AVFilterLink *inlink, AVFrame *in)
+ static int process_command(AVFilterContext *ctx, const char *cmd, const char *args,
+                            char *res, int res_len, int flags)
+ {
++    DebandContext *s = ctx->priv;
+     int ret = ff_filter_process_command(ctx, cmd, args, res, res_len, flags);
+ 
+     if (ret < 0)
+         return ret;
+ 
++    if (s->coupling && (s->shift[0] || s->shift[1])) {
++        av_log(ctx, AV_LOG_ERROR, "coupling needs a pixel format without chroma subsampling\n");
++        s->coupling = 0;
++        return AVERROR(EINVAL);
++    }
++
+     return config_input(ctx->inputs[0]);
+ }
+ 
diff --git a/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb b/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb
index 849835c8..a44b407b 100644
--- a/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb
+++ b/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb
@@ -32,6 +32,7 @@ SRC_URI = " \
     file://CVE-2024-35369.patch \
     file://CVE-2025-25473.patch \
     file://CVE-2025-22921.patch \
+    file://CVE-2026-135736.patch \
 "
 
 SRC_URI[sha256sum] = "a231e3d5742c44b1cdaebfb98ad7b6200d12763e0b6db9e1e2c5891f2c083a18"
-- 
2.43.0

