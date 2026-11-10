From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:17:34 +0000
Subject: [PATCH 4/5] media: verisilicon: Reinitialize the IOMMU after a
 timeout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-hantro-robust-v1-4-6b6269c05bfa@gmail.com>
References: <20261110-hantro-robust-v1-0-6b6269c05bfa@gmail.com>
In-Reply-To: <20261110-hantro-robust-v1-0-6b6269c05bfa@gmail.com>
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
 Jernej Skrabec <jernej.skrabec@gmail.com>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295050; l=5083;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=1ILVc0XxI2PCAfgk0ngwYRC2RkfgL6hHoTl0K6AyZXI=;
 b=/vXdujryk4/fhNdDurtKbtU0Mls3+jpCuWaYnmlCPGnFOykuvqaa3ssG3OMSgEjBPcivukbcn
 tyZ4STiUmTKCsmAqnbu7Kpjlg08zMIgaPK+1+GlXdgPzkAcId1Vlpxy
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A job that times out can leave the IOMMU of the VPU in a bad state: a
core that faulted on an unmapped IOVA leaves the IOMMU with a page fault
pending, and resetting the core can leave the IOMMU out of sync with
what its driver expects. The IOMMU is only reinitialized when it runtime
suspends and resumes, which doesn't happen between back-to-back jobs, so
the next jobs run with a broken IOMMU and time out as well.

Do like rkvdec: allocate an empty paging domain at probe, and after a
timeout attach it and detach it again, which returns the device to its
default DMA domain. The IOMMU driver disables the IOMMU and fully
reinitializes it on each domain change (on Rockchip: stall, force reset,
program the directory table and enable paging), and the default domain
keeps all the existing mappings. This is done from the watchdog work,
in process context, after the codec reset operation stopped the core
and while the job still holds the runtime PM reference, so the IOMMU is
powered.

Devices without an IOMMU, and IOMMUs that can't allocate a paging
domain, are left alone.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro.h     |  3 ++
 drivers/media/platform/verisilicon/hantro_drv.c | 57 +++++++++++++++++++++++++
 2 files changed, 60 insertions(+)

diff --git a/drivers/media/platform/verisilicon/hantro.h b/drivers/media/platform/verisilicon/hantro.h
index 0353de154a1e..51bc40668c6f 100644
--- a/drivers/media/platform/verisilicon/hantro.h
+++ b/drivers/media/platform/verisilicon/hantro.h
@@ -193,6 +193,8 @@ hantro_vdev_to_func(struct video_device *vdev)
  *			shared with interrupt handlers.
  * @variant:		Hardware variant-specific parameters.
  * @watchdog_work:	Delayed work for hardware timeout handling.
+ * @empty_domain:	Empty IOMMU domain, used to reinitialize the IOMMU after
+ *			a timeout. NULL if the VPU isn't behind an IOMMU.
  */
 struct hantro_dev {
 	struct v4l2_device v4l2_dev;
@@ -213,6 +215,7 @@ struct hantro_dev {
 	spinlock_t irqlock;
 	const struct hantro_variant *variant;
 	struct delayed_work watchdog_work;
+	struct iommu_domain *empty_domain;
 };
 
 /**
diff --git a/drivers/media/platform/verisilicon/hantro_drv.c b/drivers/media/platform/verisilicon/hantro_drv.c
index 702d878c7b50..c85c8f07db34 100644
--- a/drivers/media/platform/verisilicon/hantro_drv.c
+++ b/drivers/media/platform/verisilicon/hantro_drv.c
@@ -11,6 +11,7 @@
  */
 
 #include <linux/clk.h>
+#include <linux/iommu.h>
 #include <linux/module.h>
 #include <linux/of.h>
 #include <linux/of_platform.h>
@@ -112,6 +113,31 @@ void hantro_irq_done(struct hantro_dev *vpu,
 	}
 }
 
+/*
+ * A job that timed out can leave the IOMMU stalled, for instance on a page
+ * fault the core never recovered from, and a hardware reset of the core can
+ * leave the IOMMU state out of sync with its driver. Attach the empty domain
+ * and detach it again to return to the default DMA domain: the IOMMU driver
+ * then disables and fully reinitializes the IOMMU, which keeps all the
+ * mappings of the default domain.
+ */
+static void hantro_iommu_restore(struct hantro_dev *vpu)
+{
+	int ret;
+
+	if (!vpu->empty_domain)
+		return;
+
+	ret = iommu_attach_device(vpu->empty_domain, vpu->dev);
+	if (ret) {
+		dev_warn(vpu->dev, "Failed to attach the empty IOMMU domain: %d\n",
+			 ret);
+		return;
+	}
+
+	iommu_detach_device(vpu->empty_domain, vpu->dev);
+}
+
 void hantro_watchdog(struct work_struct *work)
 {
 	struct hantro_dev *vpu;
@@ -124,6 +150,7 @@ void hantro_watchdog(struct work_struct *work)
 		vpu_err("frame processing timed out!\n");
 		if (ctx->codec_ops->reset)
 			ctx->codec_ops->reset(ctx);
+		hantro_iommu_restore(vpu);
 		hantro_job_finish(ctx, VB2_BUF_STATE_ERROR);
 	}
 }
@@ -1085,6 +1112,32 @@ static void hantro_reset_assert(struct hantro_dev *vpu)
 	reset_control_assert(vpu->resets);
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
+	if (!iommu_get_domain_for_dev(vpu->dev))
+		return 0;
+
+	domain = iommu_paging_domain_alloc(vpu->dev);
+	if (IS_ERR(domain)) {
+		/* Not fatal, the IOMMU just won't be restored on timeouts. */
+		dev_warn(vpu->dev, "Failed to allocate an empty IOMMU domain: %pe\n",
+			 domain);
+		return 0;
+	}
+
+	vpu->empty_domain = domain;
+
+	return devm_add_action_or_reset(vpu->dev, hantro_free_empty_domain,
+					domain);
+}
+
 static int hantro_probe(struct platform_device *pdev)
 {
 	const struct of_device_id *match;
@@ -1146,6 +1199,10 @@ static int hantro_probe(struct platform_device *pdev)
 	if (IS_ERR(vpu->resets))
 		return PTR_ERR(vpu->resets);
 
+	ret = hantro_alloc_empty_domain(vpu);
+	if (ret)
+		return ret;
+
 	num_bases = vpu->variant->num_regs ?: 1;
 	vpu->reg_bases = devm_kcalloc(&pdev->dev, num_bases,
 				      sizeof(*vpu->reg_bases), GFP_KERNEL);

-- 
2.55.0

