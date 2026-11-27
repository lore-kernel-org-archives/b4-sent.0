MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-pillow-sg-v1-1-cbcff72e5e81@certik.com>
References: <20261128-pillow-sg-v1-0-cbcff72e5e81@certik.com>
In-Reply-To: <20261128-pillow-sg-v1-0-cbcff72e5e81@certik.com>
From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 10:05:10 +0000
Subject: [meta-python][scarthgap][PATCH 1/4] python3-pillow: patch
 CVE-2026-112398 and CVE-2026-112403
To: openembedded-devel@lists.openembedded.org
Cc: Anuj Mittal <anuj.mittal@oss.qualcomm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795830619; l=3396;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=fSK/UbSd/igxvmXLDrbSB6iHAn64lqj+LFzXum8JMyo=;
 b=aAf/AJrlIJrgHcJNHcwE/8U0pZm1DUFoh3CmKePXz3q91ypgUaNnjLpUqW4pOU76DbRvekhS1
 4vtlNMfpsL+BEspgpZobRt+orkwMwEc66YRC/FgijA5PaZg1mtqQpV8
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reject JPEG streams whose scanlines are wider or have more components
(#10131).

Upstream commit:
https://github.com/python-pillow/Pillow/commit/242a059aedc1935097d9aa1dc3f099750467ba75

AI-Generated: OpenAI Codex, gpt-6.2-sol
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
 .../CVE-2026-112398_CVE-2026-112403.patch     | 37 +++++++++++++++++++
 .../python/python3-pillow_10.3.0.bb           |  1 +
 2 files changed, 38 insertions(+)
 create mode 100644 meta-python/recipes-devtools/python/python3-pillow/CVE-2026-112398_CVE-2026-112403.patch

diff --git a/meta-python/recipes-devtools/python/python3-pillow/CVE-2026-112398_CVE-2026-112403.patch b/meta-python/recipes-devtools/python/python3-pillow/CVE-2026-112398_CVE-2026-112403.patch
new file mode 100644
index 000000000..eb5d8cf99
--- /dev/null
+++ b/meta-python/recipes-devtools/python/python3-pillow/CVE-2026-112398_CVE-2026-112403.patch
@@ -0,0 +1,37 @@
+From 242a059aedc1935097d9aa1dc3f099750467ba75 Mon Sep 17 00:00:00 2001
+From: Andrew Murray <3112309+radarhere@users.noreply.github.com>
+Date: Tue, 6 Oct 2026 16:25:03 +1100
+Subject: [PATCH] Reject JPEG streams whose scanlines are wider or have more
+ components (#10131)
+
+Co-authored-by: Andrew Murray <radarhere@users.noreply.github.com>
+Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
+Co-authored-by: Jeffrey 'Alex' Clark <aclark@aclark.net>
+
+CVE: CVE-2026-112398 CVE-2026-112403
+Upstream-Status: Backport [https://github.com/python-pillow/Pillow/commit/242a059aedc1935097d9aa1dc3f099750467ba75]
+Backport note: Omit upstream test changes in Tests/test_file_jpeg.py.
+Signed-off-by: Dickson Wu <dickson.wu@certik.com>
+---
+diff --git a/src/libImaging/JpegDecode.c b/src/libImaging/JpegDecode.c
+index 116ffd8df49..476197370e9 100644
+--- a/src/libImaging/JpegDecode.c
++++ b/src/libImaging/JpegDecode.c
+@@ -241,6 +241,17 @@ ImagingJpegDecode(Imaging im, ImagingCodecState state, UINT8 *buf, Py_ssize_t by
+                 break;
+             }
+ 
++            /* The scanline buffer was sized from the tile extents and the
++               unpacker, not from the JPEG header, so make sure the lines
++               libjpeg is about to produce actually fit in it. */
++            if (context->cinfo.output_width > (JDIMENSION)state->xsize ||
++                (size_t)context->cinfo.output_components * context->cinfo.output_width >
++                    (size_t)state->bytes) {
++                jpeg_destroy_decompress(&context->cinfo);
++                state->errcode = IMAGING_CODEC_BROKEN;
++                return -1;
++            }
++
+             state->state++;
+             /* fall through */
+ 
diff --git a/meta-python/recipes-devtools/python/python3-pillow_10.3.0.bb b/meta-python/recipes-devtools/python/python3-pillow_10.3.0.bb
index 240fec967..844892f0c 100644
--- a/meta-python/recipes-devtools/python/python3-pillow_10.3.0.bb
+++ b/meta-python/recipes-devtools/python/python3-pillow_10.3.0.bb
@@ -14,6 +14,7 @@ SRC_URI = "git://github.com/python-pillow/Pillow.git;branch=main;protocol=https
            file://CVE-2026-59198.patch \
            file://CVE-2026-59204.patch \
            file://CVE-2026-112393.patch \
+           file://CVE-2026-112398_CVE-2026-112403.patch \
            "
 SRCREV = "5c89d88eee199ba53f64581ea39b6a1bc52feb1a"
 
