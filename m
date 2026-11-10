From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:17:32 +0000
Subject: [PATCH 2/5] media: verisilicon: Don't hold a VPU behind an IOMMU
 in reset after remove
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-hantro-robust-v1-2-6b6269c05bfa@gmail.com>
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
 linux-kernel@vger.kernel.org, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295050; l=3316;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=qEr5569N+FtYhMibKxk7kNNyVtrp7SmuCFMePGyeKvw=;
 b=fdUwC5bYd2lXyty1r4w2ZIv3Hhp/77nCtRCIhe5M+B4/Zo/HUAmC5ceAhRfoIxSoe8W2K9Ysz
 PH/BdhEdI5sBto3K5kUPq6O1Ylip07SvmIgPxarr29aFacY6sjgrOhA
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the RK3588, the resets of the AV1 decoder include the AXI and APB
bus interface resets (SRST_A_AV1_BIU, SRST_P_AV1_BIU), which also cover
the Verisilicon IOMMU of the decoder. When the driver is unbound, the
driver core runtime resumes the device and, through the runtime PM
device link, its IOMMU. hantro_remove() then asserts the resets, and
when the IOMMU autosuspends 100 ms later, vsi_iommu_suspend() writes to
its registers while they are held in reset, which raises an SError and
panics the system:

  SError Interrupt on CPU4, code 0x00000000be000411 -- SError
  Workqueue: pm pm_runtime_work
  Call trace:
   clk_disable+0x30/0x90 (P)
   clk_bulk_disable+0x44/0x90
   vsi_iommu_suspend+0x4c/0xc8 [vsi_iommu]
   pm_generic_runtime_suspend+0x38/0x80
   genpd_runtime_suspend+0xc4/0x348
   ...
  Kernel panic - not syncing: Asynchronous SError Interrupt

This was hit when reloading the module, unless the decoder happened to
be probed again within the autosuspend delay of its IOMMU.

The IOMMU outlives the VPU driver, so leave the resets of a VPU that is
behind an IOMMU deasserted on remove and on the probe error path. VPUs
without an IOMMU are still put into reset.

Fixes: ea71631b7129 ("media: hantro: add support for reset lines")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_drv.c | 20 ++++++++++++++++++--
 1 file changed, 18 insertions(+), 2 deletions(-)

diff --git a/drivers/media/platform/verisilicon/hantro_drv.c b/drivers/media/platform/verisilicon/hantro_drv.c
index 26e5d5547466..702d878c7b50 100644
--- a/drivers/media/platform/verisilicon/hantro_drv.c
+++ b/drivers/media/platform/verisilicon/hantro_drv.c
@@ -1069,6 +1069,22 @@ static struct v4l2_m2m_dev *hantro_get_v4l2_m2m_dev(struct hantro_dev *vpu)
 	return v4l2_m2m_init(&vpu_m2m_ops);
 }
 
+/*
+ * The resets may also cover the bus interface that the IOMMU of the VPU is
+ * accessed through, e.g. on the RK3588 AV1 decoder. The IOMMU is a separate
+ * device which is runtime resumed with the VPU while it is unbound, and
+ * accesses its registers again when it runtime suspends afterwards. Holding
+ * the VPU in reset at that point causes an asynchronous external abort, so
+ * leave the resets deasserted for a VPU behind an IOMMU.
+ */
+static void hantro_reset_assert(struct hantro_dev *vpu)
+{
+	if (device_iommu_mapped(vpu->dev))
+		return;
+
+	reset_control_assert(vpu->resets);
+}
+
 static int hantro_probe(struct platform_device *pdev)
 {
 	const struct of_device_id *match;
@@ -1267,7 +1283,7 @@ static int hantro_probe(struct platform_device *pdev)
 err_pm_disable_assert_reset:
 	pm_runtime_dont_use_autosuspend(vpu->dev);
 	pm_runtime_disable(vpu->dev);
-	reset_control_assert(vpu->resets);
+	hantro_reset_assert(vpu);
 	return ret;
 err_pm_disable:
 	pm_runtime_dont_use_autosuspend(vpu->dev);
@@ -1290,7 +1306,7 @@ static void hantro_remove(struct platform_device *pdev)
 	clk_bulk_unprepare(vpu->variant->num_clocks, vpu->clocks);
 	pm_runtime_dont_use_autosuspend(vpu->dev);
 	pm_runtime_disable(vpu->dev);
-	reset_control_assert(vpu->resets);
+	hantro_reset_assert(vpu);
 }
 
 static int hantro_runtime_resume(struct device *dev)

-- 
2.55.0

