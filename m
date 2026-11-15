From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sun, 15 Nov 2026 08:21:28 +0000
Subject: [PATCH 1/2] media: rkvdec: Stop the VDPU381 core on timeout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-rkvdec-wdt-stop-v1-1-59e687c6cc63@gmail.com>
References: <20261115-rkvdec-wdt-stop-v1-0-59e687c6cc63@gmail.com>
In-Reply-To: <20261115-rkvdec-wdt-stop-v1-0-59e687c6cc63@gmail.com>
To: Detlev Casanova <detlev.casanova@collabora.com>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Alex Kazinsky <a.kazinsky@ideco.ru>, stable@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794730887; l=6869;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=L/ZVI8Exe59G7uEuqh1qHfrONjucBNmbBZOMQ/y3hf8=;
 b=HW1zDX/AQ/P2BPCCM5lbu9Oq0SQoERVPUY7+uECcih2+7wLgaVBIDWQcI9C4newUPBc91Mh9S
 LBnSiGvM4DjBO/s6XKM1s72rRVd96U45suz86+hul4DXcIEguGLSs5X
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On a timeout, rkvdec_watchdog_func() writes RKVDEC_IRQ_DIS to
RKVDEC_REG_INTERRUPT, an RK3399 register. On VDPU381 that offset is
another register, so the core keeps running after the job completes
and its IOMMU and power domain are suspended. On RK3588:

  Kernel panic - not syncing: stack-protector: Kernel stack is corrupted in: cpu_suspend+0x380/0x3d0

Add a ->stop() variant op, called with the IRQ disabled. VDPU381 soft
resets the core as the Rockchip BSP does, with the reset lines as a
fallback, and reprograms the IOMMU, which the reset leaves in bypass.
VDPU383 is fixed separately.

Fixes: e5aa698ea659 ("media: rkvdec: Add H264 support for the VDPU381 variant")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 .../platform/rockchip/rkvdec/rkvdec-vdpu381-regs.h |  4 ++
 drivers/media/platform/rockchip/rkvdec/rkvdec.c    | 64 +++++++++++++++++++++-
 drivers/media/platform/rockchip/rkvdec/rkvdec.h    |  3 +
 3 files changed, 70 insertions(+), 1 deletion(-)

diff --git a/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu381-regs.h b/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu381-regs.h
index 6da36031df2d..57ab23d76d73 100644
--- a/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu381-regs.h
+++ b/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu381-regs.h
@@ -34,6 +34,7 @@
 
 #define VDPU381_REG_IMPORTANT_EN	0x02c
 #define VDPU381_DEC_IRQ_DISABLE	BIT(4)
+#define VDPU381_SOFT_RESET_EN		BIT(20)
 
 #define VDPU381_REG_STA_INT		0x380
 #define VDPU381_STA_INT_DEC_RDY_STA	BIT(2)
@@ -41,6 +42,9 @@
 #define VDPU381_STA_INT_TIMEOUT		BIT(5)
 #define VDPU381_STA_INT_SOFTRESET_RDY	BIT(9)
 
+#define VDPU381_REG_DEBUG_INT		0x440
+#define VDPU381_DEBUG_INT_BUS_IDLE	BIT(0)
+
 /* base: OFFSET_COMMON_REGS */
 struct rkvdec_vdpu381_regs_common {
 	struct {
diff --git a/drivers/media/platform/rockchip/rkvdec/rkvdec.c b/drivers/media/platform/rockchip/rkvdec/rkvdec.c
index 4e3a706f74f6..a8fdad2850fb 100644
--- a/drivers/media/platform/rockchip/rkvdec/rkvdec.c
+++ b/drivers/media/platform/rockchip/rkvdec/rkvdec.c
@@ -14,12 +14,14 @@
 #include <linux/genalloc.h>
 #include <linux/interrupt.h>
 #include <linux/iommu.h>
+#include <linux/iopoll.h>
 #include <linux/module.h>
 #include <linux/of.h>
 #include <linux/of_device.h>
 #include <linux/platform_device.h>
 #include <linux/pm.h>
 #include <linux/pm_runtime.h>
+#include <linux/reset.h>
 #include <linux/slab.h>
 #include <linux/videodev2.h>
 #include <linux/workqueue.h>
@@ -1592,6 +1594,56 @@ static void vdpu383_flatten_matrices(u8 *output, const u8 *input, int matrices,
 	}
 }
 
+static int rkvdec_pulse_resets(struct rkvdec_dev *rkvdec)
+{
+	int ret;
+
+	if (!rkvdec->resets)
+		return -ENODEV;
+
+	ret = reset_control_assert(rkvdec->resets);
+	if (ret)
+		return ret;
+	udelay(5);
+	return reset_control_deassert(rkvdec->resets);
+}
+
+static void rk3399_stop(struct rkvdec_dev *rkvdec)
+{
+	writel(RKVDEC_IRQ_DIS, rkvdec->regs + RKVDEC_REG_INTERRUPT);
+}
+
+static void vdpu381_stop(struct rkvdec_dev *rkvdec)
+{
+	void __iomem *regs = rkvdec->regs;
+	u32 status;
+	int ret;
+
+	/* Soft reset needs an idle bus: let a busy core finish first. */
+	readl_poll_timeout(regs + VDPU381_REG_STA_INT, status, status,
+			   100, 100 * USEC_PER_MSEC);
+
+	writel(VDPU381_DEC_IRQ_DISABLE | VDPU381_SOFT_RESET_EN,
+	       regs + VDPU381_REG_IMPORTANT_EN);
+	ret = readl_poll_timeout_atomic(regs + VDPU381_REG_STA_INT, status,
+					status & VDPU381_STA_INT_SOFTRESET_RDY,
+					1, 100);
+	writel(0, regs + VDPU381_REG_STA_INT);
+	if (!ret)
+		ret = readl_poll_timeout(regs + VDPU381_REG_DEBUG_INT, status,
+					 status & VDPU381_DEBUG_INT_BUS_IDLE, 1, 1000);
+
+	if (ret) {
+		dev_warn(rkvdec->dev, "soft reset failed\n");
+		if (rkvdec_pulse_resets(rkvdec)) {
+			dev_err(rkvdec->dev, "cannot reset the core\n");
+			return;
+		}
+	}
+
+	rkvdec_iommu_restore(rkvdec);
+}
+
 static void rkvdec_watchdog_func(struct work_struct *work)
 {
 	struct rkvdec_dev *rkvdec;
@@ -1602,7 +1654,9 @@ static void rkvdec_watchdog_func(struct work_struct *work)
 	ctx = v4l2_m2m_get_curr_priv(rkvdec->m2m_dev);
 	if (ctx) {
 		dev_err(rkvdec->dev, "Frame processing timed out!\n");
-		writel(RKVDEC_IRQ_DIS, rkvdec->regs + RKVDEC_REG_INTERRUPT);
+		disable_irq(rkvdec->irq);
+		rkvdec->variant->ops->stop(rkvdec);
+		enable_irq(rkvdec->irq);
 		rkvdec_job_finish(rkvdec, VB2_BUF_STATE_ERROR);
 	}
 }
@@ -1652,6 +1706,7 @@ static int rkvdec_disable_multicore(struct rkvdec_dev *rkvdec)
 
 static const struct rkvdec_variant_ops rk3399_variant_ops = {
 	.irq_handler = rk3399_irq_handler,
+	.stop = rk3399_stop,
 	.colmv_size = rkvdec_colmv_size,
 	.flatten_matrices = transpose_and_flatten_matrices,
 };
@@ -1696,6 +1751,7 @@ static const struct rcb_size_info vdpu381_rcb_sizes[] = {
 
 static const struct rkvdec_variant_ops vdpu381_variant_ops = {
 	.irq_handler = vdpu381_irq_handler,
+	.stop = vdpu381_stop,
 	.colmv_size = rkvdec_colmv_size,
 	.flatten_matrices = transpose_and_flatten_matrices,
 };
@@ -1723,6 +1779,7 @@ static const struct rcb_size_info vdpu383_rcb_sizes[] = {
 
 static const struct rkvdec_variant_ops vdpu383_variant_ops = {
 	.irq_handler = vdpu383_irq_handler,
+	.stop = rk3399_stop,
 	.colmv_size = vdpu383_colmv_size,
 	.flatten_matrices = vdpu383_flatten_matrices,
 };
@@ -1813,9 +1870,14 @@ static int rkvdec_probe(struct platform_device *pdev)
 
 	vb2_dma_contig_set_max_seg_size(&pdev->dev, DMA_BIT_MASK(32));
 
+	rkvdec->resets = devm_reset_control_array_get_optional_exclusive(&pdev->dev);
+	if (IS_ERR(rkvdec->resets))
+		return PTR_ERR(rkvdec->resets);
+
 	irq = platform_get_irq(pdev, 0);
 	if (irq < 0)
 		return irq;
+	rkvdec->irq = irq;
 
 	ret = devm_request_threaded_irq(&pdev->dev, irq, NULL,
 					rkvdec_irq_handler, IRQF_ONESHOT,
diff --git a/drivers/media/platform/rockchip/rkvdec/rkvdec.h b/drivers/media/platform/rockchip/rkvdec/rkvdec.h
index 894c18eeb795..d9acf85e5acc 100644
--- a/drivers/media/platform/rockchip/rkvdec/rkvdec.h
+++ b/drivers/media/platform/rockchip/rkvdec/rkvdec.h
@@ -74,6 +74,7 @@ vb2_to_rkvdec_decoded_buf(struct vb2_buffer *buf)
 
 struct rkvdec_variant_ops {
 	irqreturn_t (*irq_handler)(struct rkvdec_dev *rkvdec);
+	void (*stop)(struct rkvdec_dev *rkvdec);
 	u32 (*colmv_size)(u16 width, u16 height);
 	void (*flatten_matrices)(u8 *output, const u8 *input, int matrices, int row_length);
 };
@@ -139,6 +140,8 @@ struct rkvdec_dev {
 	void __iomem *link;
 	struct mutex vdev_lock; /* serializes ioctls */
 	struct delayed_work watchdog_work;
+	struct reset_control *resets;
+	int irq;
 	struct gen_pool *sram_pool;
 	struct iommu_domain *iommu_domain;
 	struct iommu_domain *empty_domain;

-- 
2.55.0

