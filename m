From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 16:08:44 +0000
Subject: [PATCH] media: cedrus: vp8: do not disable the engine when a
 context stops
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-cedrus-vp8-stop-v1-1-27d5ca038578@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ5AMBBA0avIrE2iTTTiKmJBO2UsaDqIpHF3x
 fIt/k8gFJkE2iJBpJOFtzVDlQXYeVgnQnbZoCttlFIaLbl4CJ6hQdm3gHbUzhjX1LX3kKsQyfP
 1Hbv+txzjQnZ/N3DfD3xlovtzAAAA
X-Change-ID: 20261112-cedrus-vp8-stop-cb2d66d855ff
To: Maxime Ripard <mripard@kernel.org>, 
 Paul Kocialkowski <paulk@sys-base.io>
Cc: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Chen-Yu Tsai <wens@kernel.org>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Emmanuel Gil Peyrot <linkmauve@linkmauve.fr>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Hans Verkuil <hverkuil@kernel.org>, linux-media@vger.kernel.org, 
 linux-staging@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794499723; l=4052;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=3L89yofDlUOsKK1Yjxc84OEjIl5RT9/obJriusF77mo=;
 b=t/eUw1Rec+jk03WZlHwh79vS+7qlA/LmC65+UbcfEwMKPCko1ptMNQXJgINJVUzoALqSK94pc
 XfP35IlqiL4Az8nPzDPzIA5y4y1mePUL6aGHQelAx48vM5VmzQjsyrR
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

All the contexts of the device share the one video engine, and the m2m
framework keeps running the jobs of the other contexts while one of them
stops streaming: stop_streaming() runs under the device mutex, which
device_run() does not take. Writing VE_MODE_DISABLED from the VP8 stop
callback can therefore switch the engine off under a picture that
another context is decoding, which then never completes and fails on
the watchdog.

Every job selects the engine mode it needs in its setup callback, and
runtime suspend resets the engine, so there is nothing to disable when
a context stops. Drop the call, and the helper, which has no other user.

Fixes: 3c39a16d30d8 ("media: cedrus: Add support for VP8 decoding")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Tested on an Orange Pi Zero2 (H616) with the same change on a 7.3.3
kernel that carries further, out-of-tree H616 cedrus patches (VE behind
the sun50i IOMMU). The old behaviour was brought back on the same boot
by a temporary test switch for comparison. The test is a 4K H.264 decode
through FFmpeg v4l2-request while a second process opens VP8 contexts
and starts/stops their OUTPUT queue in a loop. With the old VP8 stop the
watchdog fired 12 times ("frame processing timed out!", after two IOMMU
page faults at address 0), only 289 of 300 frames came out and the md5
changed. With this patch all 300 frames match the reference md5 and
dmesg stays clean.

On media-committers next, the base of this patch, it is build-tested
only (arm64, W=1, no warnings); it has not been run on that tree.

This patch is independent of Jernej's pending series "staging: media:
cedrus: assorted fixes and VP8 4K support" (v2) and also applies on top
of it.

This patch was developed with Claude (Anthropic) as a coding assistant,
which found the bug and wrote the code and the commit message. I
reviewed it and tested it as described above, and take responsibility
for it (Documentation/process/generated-content.rst).
---
 drivers/staging/media/sunxi/cedrus/cedrus_hw.c  | 5 -----
 drivers/staging/media/sunxi/cedrus/cedrus_hw.h  | 1 -
 drivers/staging/media/sunxi/cedrus/cedrus_vp8.c | 2 --
 3 files changed, 8 deletions(-)

diff --git a/drivers/staging/media/sunxi/cedrus/cedrus_hw.c b/drivers/staging/media/sunxi/cedrus/cedrus_hw.c
index 444fb53878d1..a22a8402fc60 100644
--- a/drivers/staging/media/sunxi/cedrus/cedrus_hw.c
+++ b/drivers/staging/media/sunxi/cedrus/cedrus_hw.c
@@ -71,11 +71,6 @@ int cedrus_engine_enable(struct cedrus_ctx *ctx)
 	return 0;
 }
 
-void cedrus_engine_disable(struct cedrus_dev *dev)
-{
-	cedrus_write(dev, VE_MODE, VE_MODE_DISABLED);
-}
-
 void cedrus_dst_format_set(struct cedrus_dev *dev,
 			   struct v4l2_pix_format *fmt)
 {
diff --git a/drivers/staging/media/sunxi/cedrus/cedrus_hw.h b/drivers/staging/media/sunxi/cedrus/cedrus_hw.h
index 6f1e701b1ea8..4edf729c556d 100644
--- a/drivers/staging/media/sunxi/cedrus/cedrus_hw.h
+++ b/drivers/staging/media/sunxi/cedrus/cedrus_hw.h
@@ -17,7 +17,6 @@
 #define _CEDRUS_HW_H_
 
 int cedrus_engine_enable(struct cedrus_ctx *ctx);
-void cedrus_engine_disable(struct cedrus_dev *dev);
 
 void cedrus_dst_format_set(struct cedrus_dev *dev,
 			   struct v4l2_pix_format *fmt);
diff --git a/drivers/staging/media/sunxi/cedrus/cedrus_vp8.c b/drivers/staging/media/sunxi/cedrus/cedrus_vp8.c
index 969677a3bbf9..4438c7e1bbda 100644
--- a/drivers/staging/media/sunxi/cedrus/cedrus_vp8.c
+++ b/drivers/staging/media/sunxi/cedrus/cedrus_vp8.c
@@ -856,8 +856,6 @@ static void cedrus_vp8_stop(struct cedrus_ctx *ctx)
 {
 	struct cedrus_dev *dev = ctx->dev;
 
-	cedrus_engine_disable(dev);
-
 	dma_free_coherent(dev->dev, CEDRUS_ENTROPY_PROBS_SIZE,
 			  ctx->codec.vp8.entropy_probs_buf,
 			  ctx->codec.vp8.entropy_probs_buf_dma);

---
base-commit: 3fc9303dba01676c2090768126e5327e341b7761
change-id: 20261112-cedrus-vp8-stop-cb2d66d855ff

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

