From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 16:40:38 +0000
Subject: [PATCH v3 07/12] media: verisilicon: Reinitialize the IOMMU after
 resetting an encoder core
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-hantro-robust-v3-7-82383c722ad2@gmail.com>
References: <20261113-hantro-robust-v3-0-82383c722ad2@gmail.com>
In-Reply-To: <20261113-hantro-robust-v3-0-82383c722ad2@gmail.com>
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Nicolas Frattaroli <frattaroli.nicolas@gmail.com>, 
 Andrzej Pietrasiewicz <andrzej.p@collabora.com>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>
Cc: linux-media@vger.kernel.org, iommu@lists.linux.dev, 
 linux-rockchip@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Sergei Khomenkov <shomenkow@gmail.com>, 
 Tharit Tangkijwanichakul <tharitt97@gmail.com>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794588032; l=6191;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=jnOaMXXkqIdF/W+aQDFv26f6KiRw45A2/C/Mdhu62GA=;
 b=E4l1drfEiAJSnLdl7T1rjptWqXeyJxfVf8LWkzKBpQsl0eMJm3v7Ft2xmP0KSV33xJ3HB+flB
 wrhXSrVghzjB5HwZj+B+UJIj5sxF23fny1XAmR69NlLHTdNujLTd272
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A Rockchip encoder core that faulted on an unmapped IOVA leaves its
IOMMU with the fault pending, and the reset pulse of the previous patch
can reset the IOMMU behind its driver. The IOMMU is only reprogrammed
on runtime resume, which doesn't happen between back-to-back jobs.

Do like rkvdec: allocate an empty paging domain at probe and, after the
reset pulse, attach and detach it. The IOMMU driver reprograms the
IOMMU on each domain change, and the default domain keeps its mappings.

Only do this for a device with reset lines whose domain is a DMA
domain. If the attach fails, the IOMMU may be left without translation
(rockchip-iommu falls back to its identity domain), so refuse all
further jobs.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro.h        |  5 ++
 drivers/media/platform/verisilicon/hantro_drv.c    | 62 ++++++++++++++++++++++
 drivers/media/platform/verisilicon/hantro_hw.h     |  1 +
 .../media/platform/verisilicon/rockchip_vpu_hw.c   |  6 ++-
 4 files changed, 73 insertions(+), 1 deletion(-)

diff --git a/drivers/media/platform/verisilicon/hantro.h b/drivers/media/platform/verisilicon/hantro.h
index 0353de154a1e..e3881ca21c56 100644
--- a/drivers/media/platform/verisilicon/hantro.h
+++ b/drivers/media/platform/verisilicon/hantro.h
@@ -193,6 +193,9 @@ hantro_vdev_to_func(struct video_device *vdev)
  *			shared with interrupt handlers.
  * @variant:		Hardware variant-specific parameters.
  * @watchdog_work:	Delayed work for hardware timeout handling.
+ * @empty_domain:	Empty IOMMU domain, used to reinitialize the IOMMU after
+ *			a reset of the core. NULL if not needed.
+ * @iommu_lost:		The IOMMU couldn't be reinitialized, no job can run.
  */
 struct hantro_dev {
 	struct v4l2_device v4l2_dev;
@@ -213,6 +216,8 @@ struct hantro_dev {
 	spinlock_t irqlock;
 	const struct hantro_variant *variant;
 	struct delayed_work watchdog_work;
+	struct iommu_domain *empty_domain;
+	bool iommu_lost;
 };
 
 /**
diff --git a/drivers/media/platform/verisilicon/hantro_drv.c b/drivers/media/platform/verisilicon/hantro_drv.c
index daec9f1ea968..9bb4d1582622 100644
--- a/drivers/media/platform/verisilicon/hantro_drv.c
+++ b/drivers/media/platform/verisilicon/hantro_drv.c
@@ -11,6 +11,7 @@
  */
 
 #include <linux/clk.h>
+#include <linux/iommu.h>
 #include <linux/module.h>
 #include <linux/of.h>
 #include <linux/of_platform.h>
@@ -113,6 +114,30 @@ void hantro_irq_done(struct hantro_dev *vpu,
 	}
 }
 
+/*
+ * Pulsing the reset lines of a core can reset its IOMMU behind the IOMMU
+ * driver. Attaching and detaching the empty domain makes the driver reprogram
+ * it; the default domain keeps its mappings. A failed attach may leave the
+ * IOMMU without translation, so no further job may run.
+ */
+void hantro_iommu_restore(struct hantro_dev *vpu)
+{
+	int ret;
+
+	if (!vpu->empty_domain)
+		return;
+
+	ret = iommu_attach_device(vpu->empty_domain, vpu->dev);
+	if (ret) {
+		dev_err(vpu->dev, "Failed to reinitialize the IOMMU (%d), refusing further jobs\n",
+			ret);
+		vpu->iommu_lost = true;
+		return;
+	}
+
+	iommu_detach_device(vpu->empty_domain, vpu->dev);
+}
+
 void hantro_watchdog(struct work_struct *work)
 {
 	struct hantro_dev *vpu;
@@ -175,6 +200,9 @@ static void device_run(void *priv)
 	src = hantro_get_src_buf(ctx);
 	dst = hantro_get_dst_buf(ctx);
 
+	if (unlikely(vpu->iommu_lost))
+		goto err_cancel_job;
+
 	ret = pm_runtime_resume_and_get(vpu->dev);
 	if (ret < 0)
 		goto err_cancel_job;
@@ -1074,6 +1102,36 @@ static struct v4l2_m2m_dev *hantro_get_v4l2_m2m_dev(struct hantro_dev *vpu)
 	return v4l2_m2m_init(&vpu_m2m_ops);
 }
 
+static void hantro_free_empty_domain(void *data)
+{
+	iommu_domain_free(data);
+}
+
+static int hantro_alloc_empty_domain(struct hantro_dev *vpu)
+{
+	struct iommu_domain *domain;
+
+	/*
+	 * Only needed if the core can be reset, and only possible with a DMA
+	 * domain to return to.
+	 */
+	if (!vpu->resets)
+		return 0;
+
+	domain = iommu_get_domain_for_dev(vpu->dev);
+	if (!domain || !iommu_is_dma_domain(domain))
+		return 0;
+
+	domain = iommu_paging_domain_alloc(vpu->dev);
+	if (IS_ERR(domain))
+		return PTR_ERR(domain);
+
+	vpu->empty_domain = domain;
+
+	return devm_add_action_or_reset(vpu->dev, hantro_free_empty_domain,
+					domain);
+}
+
 static int hantro_probe(struct platform_device *pdev)
 {
 	struct hantro_dev *vpu;
@@ -1134,6 +1192,10 @@ static int hantro_probe(struct platform_device *pdev)
 	if (IS_ERR(vpu->resets))
 		return PTR_ERR(vpu->resets);
 
+	ret = hantro_alloc_empty_domain(vpu);
+	if (ret)
+		return ret;
+
 	num_bases = vpu->variant->num_regs ?: 1;
 	vpu->reg_bases = devm_kcalloc(&pdev->dev, num_bases,
 				      sizeof(*vpu->reg_bases), GFP_KERNEL);
diff --git a/drivers/media/platform/verisilicon/hantro_hw.h b/drivers/media/platform/verisilicon/hantro_hw.h
index 13e573f1f19d..aa610dd5beef 100644
--- a/drivers/media/platform/verisilicon/hantro_hw.h
+++ b/drivers/media/platform/verisilicon/hantro_hw.h
@@ -427,6 +427,7 @@ extern const struct hantro_postproc_ops rockchip_vpu981_postproc_ops;
 extern const u32 hantro_vp8_dec_mc_filter[8][6];
 
 void hantro_watchdog(struct work_struct *work);
+void hantro_iommu_restore(struct hantro_dev *vpu);
 void hantro_irq_done(struct hantro_dev *vpu,
 		     enum vb2_buffer_state result);
 void hantro_start_prepare_run(struct hantro_ctx *ctx);
diff --git a/drivers/media/platform/verisilicon/rockchip_vpu_hw.c b/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
index 1467ae2bed1a..113b6977031d 100644
--- a/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
+++ b/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
@@ -490,8 +490,12 @@ static void rockchip_vpu_enc_hw_reset(struct hantro_dev *vpu)
 	udelay(5);
 
 	ret = reset_control_deassert(vpu->resets);
-	if (ret)
+	if (ret) {
 		dev_err(vpu->dev, "Failed to deassert resets: %d\n", ret);
+		return;
+	}
+
+	hantro_iommu_restore(vpu);
 }
 
 static void rockchip_vpu1_enc_reset(struct hantro_ctx *ctx)

-- 
2.55.0

