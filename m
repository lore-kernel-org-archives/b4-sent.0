MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-yoc1s-ffmpeg-v1-2-f01fec79468b@certik.com>
References: <20261127-yoc1s-ffmpeg-v1-0-f01fec79468b@certik.com>
In-Reply-To: <20261127-yoc1s-ffmpeg-v1-0-f01fec79468b@certik.com>
From: Dickson Wu <dickson.wu@certik.com>
Date: Thu, 26 Nov 2026 23:02:05 +0000
Subject: [scarthgap][PATCH 2/7] ffmpeg: fix CVE-2026-135743
To: openembedded-core@lists.openembedded.org
Cc: Yoann Congal <yoann.congal@smile.fr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795769564; l=3448;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=Yvwta390KcGjewvsNg2wwIiE2FTnqbt31WzPyeMoquE=;
 b=MfmRBOmarNIxsgcW1CNr/MlTDW+VGMnk01nFQcyaCr9jIGlJNhrK/w7SSaarMCoNzyktkxDv/
 F/0NPDo33MmBvW2fhaRbEMyqAo+2886MMFnJEiK2uiw9UdmBIXoewqZ
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The dynamic audio normalizer could resize gain-history buffers
incorrectly when its filter size changed, causing invalid memmove sizes
and out-of-bounds access. Backport the upstream fix.

https://github.com/FFmpeg/FFmpeg/commit/3dd257f99b5c

AI-Generated: OpenAI Codex, gpt-6.2-sol
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
 .../ffmpeg/ffmpeg/CVE-2026-135743.patch       | 49 +++++++++++++++++++
 .../recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb |  1 +
 2 files changed, 50 insertions(+)
 create mode 100644 meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135743.patch

diff --git a/meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135743.patch b/meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135743.patch
new file mode 100644
index 00000000..46d6284a
--- /dev/null
+++ b/meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135743.patch
@@ -0,0 +1,49 @@
+From 3dd257f99b5cdc1bf38e1cadff1e34ec559c7b7c Mon Sep 17 00:00:00 2001
+From: Michael Niedermayer <michael@niedermayer.cc>
+Date: Sat, 14 Nov 2026 05:14:09 +0100
+Subject: [PATCH] avfilter/af_dynaudnorm: resize the gain histories by the
+ change of the filter size
+
+Fixes: out of array access (memmove with negative size)
+Fixes: out of array write
+Fixes: ArUvqAYbevNM
+Fixes: AISLE-2026-0166-00680
+
+Found-by: Joshua Rogers (AISLE)
+The out of array write was found during triage of the security report
+
+Out of array access Replicated through UnModified FFmpeg with ASAN
+Out of array write Replicated through UnModified FFmpeg with ASAN
+no further issues found with 3000 iterations of a random gausssize command sequence generator
+
+CVE: CVE-2026-135743
+Upstream-Status: Backport [https://github.com/FFmpeg/FFmpeg/commit/3dd257f99b5cdc1bf38e1cadff1e34ec559c7b7c]
+
+Signed-off-by: Dickson Wu <dickson.wu@certik.com>
+---
+ libavfilter/af_dynaudnorm.c | 8 ++++----
+ 1 file changed, 4 insertions(+), 4 deletions(-)
+
+diff --git a/libavfilter/af_dynaudnorm.c b/libavfilter/af_dynaudnorm.c
+index 1af6a3ed9f04f..e00405995c17b 100644
+--- a/libavfilter/af_dynaudnorm.c
++++ b/libavfilter/af_dynaudnorm.c
+@@ -261,14 +261,14 @@ static void cqueue_resize(cqueue *q, int new_size)
+     av_assert2(q->max_size >= new_size);
+     av_assert2(MIN_FILTER_SIZE <= new_size);
+ 
+-    if (new_size > q->nb_elements) {
+-        const int side = (new_size - q->nb_elements) / 2;
++    if (!cqueue_empty(q) && new_size > q->size) {
++        const int side = (new_size - q->size) / 2;
+ 
+         memmove(q->elements + side, q->elements, sizeof(double) * q->nb_elements);
+         for (int i = 0; i < side; i++)
+             q->elements[i] = q->elements[side];
+-        q->nb_elements = new_size - 1 - side;
+-    } else {
++        q->nb_elements += side;
++    } else if (!cqueue_empty(q)) {
+         int count = (q->size - new_size + 1) / 2;
+ 
+         while (count-- > 0)
diff --git a/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb b/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb
index a44b407b..9d92115b 100644
--- a/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb
+++ b/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb
@@ -33,6 +33,7 @@ SRC_URI = " \
     file://CVE-2025-25473.patch \
     file://CVE-2025-22921.patch \
     file://CVE-2026-135736.patch \
+    file://CVE-2026-135743.patch \
 "
 
 SRC_URI[sha256sum] = "a231e3d5742c44b1cdaebfb98ad7b6200d12763e0b6db9e1e2c5891f2c083a18"
-- 
2.43.0

