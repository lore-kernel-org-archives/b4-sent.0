From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 16:40:41 +0000
Subject: [PATCH v3 10/12] iommu/vsi: Deassert the reset lines on probe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-hantro-robust-v3-10-82383c722ad2@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794588032; l=1757;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=7/YPVx4qDegy0I+GiqV2r/FsoZZRHAX+0GSiqjWtgfw=;
 b=RiRLVgOv5pP2Pg5WhcuY0uoPfjdZHU4KYIfUkYibCYOOm52LnjxGzvZnsvK/sAGVwxBHc7owp
 0UZfNiAFK65BlIdcxaALT7rfzaivOz8pb627vsKnG3AaDiutbEVuHuF
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RK3588 AV1 IOMMU shares its reset lines with the decoder, and its
registers can't be accessed while they are asserted. It writes them on
attach, before the decoder's probe deasserts the resets.

Deassert the resets on probe. They are released exclusive controls,
acquired only for that, so the decoder can still use them.

Suggested-by: Philipp Zabel <p.zabel@pengutronix.de>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/iommu/vsi-iommu.c | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/drivers/iommu/vsi-iommu.c b/drivers/iommu/vsi-iommu.c
index 5dac20b143a5..a3ec2fe5ecd5 100644
--- a/drivers/iommu/vsi-iommu.c
+++ b/drivers/iommu/vsi-iommu.c
@@ -33,6 +33,7 @@
 #include <linux/of_platform.h>
 #include <linux/platform_device.h>
 #include <linux/pm_runtime.h>
+#include <linux/reset.h>
 #include <linux/slab.h>
 #include <linux/spinlock.h>
 
@@ -669,6 +670,7 @@ MODULE_DEVICE_TABLE(of, vsi_iommu_dt_ids);
 static int vsi_iommu_probe(struct platform_device *pdev)
 {
 	struct device *dev = &pdev->dev;
+	struct reset_control *resets;
 	struct vsi_iommu *iommu;
 	int err;
 
@@ -688,6 +690,20 @@ static int vsi_iommu_probe(struct platform_device *pdev)
 	if  (iommu->num_clocks < 0)
 		return iommu->num_clocks;
 
+	/* Shared with the decoder. */
+	resets = devm_reset_control_array_get(dev, RESET_CONTROL_OPTIONAL_EXCLUSIVE_RELEASED);
+	if (IS_ERR(resets))
+		return PTR_ERR(resets);
+
+	err = reset_control_acquire(resets);
+	if (err)
+		return err;
+
+	err = reset_control_deassert(resets);
+	reset_control_release(resets);
+	if (err)
+		return err;
+
 	err = clk_bulk_prepare(iommu->num_clocks, iommu->clocks);
 	if (err)
 		return err;

-- 
2.55.0

