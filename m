From: Valerii Bokov <vlry.bkv@gmail.com>
Date: Wed, 28 Oct 2026 12:27:00 +0100
Subject: [PATCH] media: rkvdec: vdpu383: configure the reference read cache
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-rkvdec-vdpu383-cache-v1-1-d3548d3b3586@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqAIBBA0avErBtIB0K6SrQwHWsIKpQkEO+et
 HyL/wskjsIJpq5A5CxJrrNB9R243Z4bo/hm0IMe1aANxiN7dpj9/ZAhdNbtjCasazCkyFuClt6
 Rg7z/dl5q/QD4PiVxZgAAAA==
X-Change-ID: 20261028-rkvdec-vdpu383-cache-8fbbf8313da3
To: Detlev Casanova <detlev.casanova@collabora.com>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Valerii Bokov <vlry.bkv@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793186830; l=7332;
 i=vlry.bkv@gmail.com; s=20261028; h=from:subject:message-id;
 bh=YrZCEEl+iz1Vm2vKE98hmEVblDsYTlb5LJykT0gy+hU=;
 b=j1Tr4qKXzrF23H++aNUmp8sTwItKHnW6PjU85/kuAMTyUxSLxzxUpzC/jTojEiGmCjY4yiwr/
 0qAIcK/pTnYCpo+U98LEJ4xjPfhCX9TnvtFsxlBmRUx53VuXMNa15xe
X-Developer-Key: i=vlry.bkv@gmail.com; a=ed25519;
 pk=u/rk2lx5DMp734XMF4ThLZD2H0AqvfYuikR7wu2iyNA=
X-Endpoint-Received: by B4 Relay for vlry.bkv@gmail.com/20261028 with auth_id=1342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The VDPU383 has a reference read cache with its own register region,
"cache" in the device tree, which the driver does not map. Its
configuration and read limit are therefore left at their power-on
values, and those differ between power-ups. On RK3576 this makes H.264
decoding of a 2688x1520 stream take either 22.5 ms or 65.4 ms per
frame, depending on the power-up, while the values the vendor driver
programs bring it to 3.6 ms per frame.

Map the "cache" region and, as the vendor driver does before every
frame, enable cacheable read-allocate accesses with 64-byte lines,
clear the cache and set the read limit (MAX_READS in the vendor
driver) to 0x1c. The cache is cleared on every run because reference
buffers are rewritten between frames.

Decode time per frame for a 2688x1520 H.264 stream on RK3576, within
one decoder power-up, with the registers set between runs:

  MAX_READS  CACHE0_CFG  ms/frame
  0x0        power-on        65.4  (slow power-up)
  0x2        power-on        22.5  (fast power-up)
  0x1c       power-on         7.2
  0x2        0x13             8.6
  0x1c       0x13             3.6

The decoded output was bit-identical in all five cases. These numbers
were taken by setting the registers from user space through /dev/mem.

With this patch applied, a 2688x1520 recording from the same camera
decodes at 3.55-3.60 ms per frame on every decoder power-up (8 of 8
runs), and the decoded output is bit-identical to FFmpeg's software
decoder (751 frames).

The registers were identified with the help of an AI coding assistant
(Claude), by diffing register dumps of fast and slow power-ups and
comparing them with the vendor driver (rkvdec_vdpu38x_run() in
mpp_rkvdec2.c); the assistant also drafted this patch.

Link: https://lists.infradead.org/pipermail/linux-rockchip/2026-June/072308.html
Signed-off-by: Valerii Bokov <vlry.bkv@gmail.com>
---
 .../platform/rockchip/rkvdec/rkvdec-vdpu383-h264.c    |  2 ++
 .../platform/rockchip/rkvdec/rkvdec-vdpu383-hevc.c    |  2 ++
 .../platform/rockchip/rkvdec/rkvdec-vdpu383-regs.h    |  8 ++++++++
 drivers/media/platform/rockchip/rkvdec/rkvdec.c       | 19 +++++++++++++++++++
 drivers/media/platform/rockchip/rkvdec/rkvdec.h       |  2 ++
 5 files changed, 33 insertions(+)

diff --git a/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu383-h264.c b/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu383-h264.c
index 5ec755733..572ff404d 100644
--- a/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu383-h264.c
+++ b/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu383-h264.c
@@ -441,6 +441,8 @@ static int rkvdec_h264_run(struct rkvdec_ctx *ctx)
 	timeout_threshold = h264_ctx->regs.common.reg013_core_timeout_threshold;
 	rkvdec_schedule_watchdog(rkvdec, timeout_threshold);
 
+	rkvdec_vdpu383_setup_cache(rkvdec);
+
 	/* Start decoding! */
 	writel(timeout_threshold, rkvdec->link + VDPU383_LINK_TIMEOUT_THRESHOLD);
 	writel(0, rkvdec->link + VDPU383_LINK_IP_ENABLE);
diff --git a/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu383-hevc.c b/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu383-hevc.c
index 3462d995d..f2f811b0f 100644
--- a/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu383-hevc.c
+++ b/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu383-hevc.c
@@ -568,6 +568,8 @@ static int rkvdec_hevc_run(struct rkvdec_ctx *ctx)
 	timeout_threshold = hevc_ctx->regs.common.reg013_core_timeout_threshold;
 	rkvdec_schedule_watchdog(rkvdec, timeout_threshold);
 
+	rkvdec_vdpu383_setup_cache(rkvdec);
+
 	/* Start decoding! */
 	writel(timeout_threshold, rkvdec->link + VDPU383_LINK_TIMEOUT_THRESHOLD);
 	writel(VDPU383_IP_CRU_MODE, rkvdec->link + VDPU383_LINK_IP_ENABLE);
diff --git a/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu383-regs.h b/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu383-regs.h
index 04eb23297..e04b5ce1c 100644
--- a/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu383-regs.h
+++ b/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu383-regs.h
@@ -42,6 +42,14 @@
 #define VDPU383_STA_INT_SOFTRESET_RDY	(BIT(10) | BIT(11))
 #define VDPU383_STA_INT_ALL		0x3ff
 
+/* Reference read cache, in the "cache" register region */
+#define VDPU383_CACHE_CLR_CACHE0	0x10
+#define VDPU383_CACHE_MAX_READS		0x18
+#define VDPU383_CACHE_CACHE0_CFG	0x1c
+#define VDPU383_CACHE_CFG_CACHEABLE	BIT(0)
+#define VDPU383_CACHE_CFG_READ_ALLOCATE	BIT(1)
+#define VDPU383_CACHE_CFG_LINE_64B	BIT(4)
+
 struct vdpu383_regs_common {
 	u32 reg008_dec_mode;
 
diff --git a/drivers/media/platform/rockchip/rkvdec/rkvdec.c b/drivers/media/platform/rockchip/rkvdec/rkvdec.c
index fbcd0f175..c609e8c69 100644
--- a/drivers/media/platform/rockchip/rkvdec/rkvdec.c
+++ b/drivers/media/platform/rockchip/rkvdec/rkvdec.c
@@ -1158,6 +1158,21 @@ void rkvdec_schedule_watchdog(struct rkvdec_dev *rkvdec, u32 timeout_threshold)
 	schedule_delayed_work(&rkvdec->watchdog_work, msecs_to_jiffies(watchdog_time));
 }
 
+/*
+ * The reference read cache and the read limit are left at their power-on
+ * values otherwise, which vary between power-ups and make decoding several
+ * times slower. Program them as the vendor driver does, before every frame:
+ * the cache is cleared each time because reference buffers are rewritten
+ * between frames.
+ */
+void rkvdec_vdpu383_setup_cache(struct rkvdec_dev *rkvdec)
+{
+	writel(VDPU383_CACHE_CFG_CACHEABLE | VDPU383_CACHE_CFG_READ_ALLOCATE |
+	       VDPU383_CACHE_CFG_LINE_64B, rkvdec->cache + VDPU383_CACHE_CACHE0_CFG);
+	writel(1, rkvdec->cache + VDPU383_CACHE_CLR_CACHE0);
+	writel(0x1c, rkvdec->cache + VDPU383_CACHE_MAX_READS);
+}
+
 static void rkvdec_device_run(void *priv)
 {
 	struct rkvdec_ctx *ctx = priv;
@@ -1807,6 +1822,10 @@ static int rkvdec_probe(struct platform_device *pdev)
 		rkvdec->link = devm_platform_ioremap_resource_byname(pdev, "link");
 		if (IS_ERR(rkvdec->link))
 			return PTR_ERR(rkvdec->link);
+
+		rkvdec->cache = devm_platform_ioremap_resource_byname(pdev, "cache");
+		if (IS_ERR(rkvdec->cache))
+			return PTR_ERR(rkvdec->cache);
 	}
 
 	ret = dma_set_coherent_mask(&pdev->dev, DMA_BIT_MASK(32));
diff --git a/drivers/media/platform/rockchip/rkvdec/rkvdec.h b/drivers/media/platform/rockchip/rkvdec/rkvdec.h
index a24be6638..f97eaef3a 100644
--- a/drivers/media/platform/rockchip/rkvdec/rkvdec.h
+++ b/drivers/media/platform/rockchip/rkvdec/rkvdec.h
@@ -136,6 +136,7 @@ struct rkvdec_dev {
 	struct clk *axi_clk;
 	void __iomem *regs;
 	void __iomem *link;
+	void __iomem *cache;
 	struct mutex vdev_lock; /* serializes ioctls */
 	struct delayed_work watchdog_work;
 	struct gen_pool *sram_pool;
@@ -180,6 +181,7 @@ void rkvdec_run_preamble(struct rkvdec_ctx *ctx, struct rkvdec_run *run);
 void rkvdec_run_postamble(struct rkvdec_ctx *ctx, struct rkvdec_run *run);
 void rkvdec_memcpy_toio(void __iomem *dst, void *src, size_t len);
 void rkvdec_schedule_watchdog(struct rkvdec_dev *rkvdec, u32 timeout_threshold);
+void rkvdec_vdpu383_setup_cache(struct rkvdec_dev *rkvdec);
 
 void rkvdec_quirks_disable_qos(struct rkvdec_ctx *ctx);
 

---
base-commit: 65ba8f34ec886ec72b2c07ddc8cf3d815c32869d
change-id: 20261028-rkvdec-vdpu383-cache-8fbbf8313da3

Best regards,
-- 
Valerii Bokov <vlry.bkv@gmail.com>

