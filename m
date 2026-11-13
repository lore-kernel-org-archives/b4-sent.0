From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 16:40:33 +0000
Subject: [PATCH v3 02/12] media: verisilicon: Check the match data in
 hantro_probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-hantro-robust-v3-2-82383c722ad2@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794588032; l=2017;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=USarBI/8QLSUU7n4QQXOd3oICBoakGw0nlmY2gPzpAo=;
 b=VHn9biPtTSPgjKSK+LlZtbRsJG7aomHpah4FtXX6wvlrtziNtNDasva9saf6Y9Yd21xb7URUY
 Kjqx/X9W7idCWs6uQxrP6bjU0Ed9vIN+cDEtGVVGMiPaQ5Mq44mzyFX
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A device bound through driver_override may have no OF match, and
hantro_probe() then dereferences a NULL match. Use
device_get_match_data() and fail with -ENODEV without match data.

Fixes: 775fec69008d ("media: add Rockchip VPU JPEG encoder driver")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_drv.c | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/drivers/media/platform/verisilicon/hantro_drv.c b/drivers/media/platform/verisilicon/hantro_drv.c
index 26e5d5547466..e86eb943d16a 100644
--- a/drivers/media/platform/verisilicon/hantro_drv.c
+++ b/drivers/media/platform/verisilicon/hantro_drv.c
@@ -17,6 +17,7 @@
 #include <linux/platform_device.h>
 #include <linux/pm.h>
 #include <linux/pm_runtime.h>
+#include <linux/property.h>
 #include <linux/slab.h>
 #include <linux/videodev2.h>
 #include <linux/workqueue.h>
@@ -1071,7 +1072,6 @@ static struct v4l2_m2m_dev *hantro_get_v4l2_m2m_dev(struct hantro_dev *vpu)
 
 static int hantro_probe(struct platform_device *pdev)
 {
-	const struct of_device_id *match;
 	struct hantro_dev *vpu;
 	int num_bases;
 	int i, ret;
@@ -1085,8 +1085,9 @@ static int hantro_probe(struct platform_device *pdev)
 	mutex_init(&vpu->vpu_mutex);
 	spin_lock_init(&vpu->irqlock);
 
-	match = of_match_node(of_hantro_match, pdev->dev.of_node);
-	vpu->variant = match->data;
+	vpu->variant = device_get_match_data(&pdev->dev);
+	if (!vpu->variant)
+		return -ENODEV;
 
 	ret = hantro_disable_multicore(vpu);
 	if (ret)
@@ -1098,8 +1099,7 @@ static int hantro_probe(struct platform_device *pdev)
 	 * nxp,imx8mq-vpu-g1 or nxp,imx8mq-vpu-g2 instead.
 	 */
 	if (of_device_is_compatible(pdev->dev.of_node, "nxp,imx8mq-vpu"))
-		dev_warn(&pdev->dev, "%s compatible is deprecated\n",
-			 match->compatible);
+		dev_warn(&pdev->dev, "nxp,imx8mq-vpu compatible is deprecated\n");
 
 	INIT_DELAYED_WORK(&vpu->watchdog_work, hantro_watchdog);
 

-- 
2.55.0

