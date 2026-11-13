From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 16:40:39 +0000
Subject: [PATCH v3 08/12] media: verisilicon: Acquire the reset lines only
 while using them
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-hantro-robust-v3-8-82383c722ad2@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794588032; l=4115;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=DgHWOwtiMWRIc2UDuvJ7/ad5T9I1cEKGr7IVqd0TNqU=;
 b=Pz0rWgvs751W58G0yVV7YcqRJj4gbON0x2nffi0LB0drWSdsB2a4Eaucp1Zi0ySLkNlU48he/
 TL15X6x6kzMDLjiwM/Li+rp9w3k/8gxRMmY291rAq4GKtO259+bob4w
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RK3588 AV1 IOMMU has no reset lines of its own: it shares the four
AV1 resets with the decoder. Get them as released exclusive controls and
acquire them only around their use, so that the IOMMU driver can
deassert them too.

Suggested-by: Philipp Zabel <p.zabel@pengutronix.de>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_drv.c       | 10 ++++++++--
 drivers/media/platform/verisilicon/rockchip_vpu_hw.c  | 12 ++++++++++--
 drivers/media/platform/verisilicon/stm32mp25_vpu_hw.c |  4 ++++
 drivers/media/platform/verisilicon/sunxi_vpu_hw.c     |  4 ++++
 4 files changed, 26 insertions(+), 4 deletions(-)

diff --git a/drivers/media/platform/verisilicon/hantro_drv.c b/drivers/media/platform/verisilicon/hantro_drv.c
index 9bb4d1582622..823be057e167 100644
--- a/drivers/media/platform/verisilicon/hantro_drv.c
+++ b/drivers/media/platform/verisilicon/hantro_drv.c
@@ -1188,7 +1188,9 @@ static int hantro_probe(struct platform_device *pdev)
 			return PTR_ERR(vpu->clocks[0].clk);
 	}
 
-	vpu->resets = devm_reset_control_array_get_optional_exclusive(&pdev->dev);
+	/* Released: the IOMMU of a core can share its reset lines. */
+	vpu->resets = devm_reset_control_array_get(&pdev->dev,
+						   RESET_CONTROL_OPTIONAL_EXCLUSIVE_RELEASED);
 	if (IS_ERR(vpu->resets))
 		return PTR_ERR(vpu->resets);
 
@@ -1267,7 +1269,11 @@ static int hantro_probe(struct platform_device *pdev)
 	pm_runtime_use_autosuspend(vpu->dev);
 	pm_runtime_enable(vpu->dev);
 
-	ret = reset_control_deassert(vpu->resets);
+	ret = reset_control_acquire(vpu->resets);
+	if (!ret) {
+		ret = reset_control_deassert(vpu->resets);
+		reset_control_release(vpu->resets);
+	}
 	if (ret) {
 		dev_err(&pdev->dev, "Failed to deassert resets\n");
 		goto err_pm_disable;
diff --git a/drivers/media/platform/verisilicon/rockchip_vpu_hw.c b/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
index 113b6977031d..f1188a6435b1 100644
--- a/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
+++ b/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
@@ -481,10 +481,16 @@ static void rockchip_vpu_enc_hw_reset(struct hantro_dev *vpu)
 	if (!vpu->resets)
 		return;
 
+	ret = reset_control_acquire(vpu->resets);
+	if (ret) {
+		dev_warn(vpu->dev, "Failed to acquire resets: %d\n", ret);
+		return;
+	}
+
 	ret = reset_control_assert(vpu->resets);
 	if (ret) {
 		dev_warn(vpu->dev, "Failed to assert resets: %d\n", ret);
-		return;
+		goto release;
 	}
 
 	udelay(5);
@@ -492,10 +498,12 @@ static void rockchip_vpu_enc_hw_reset(struct hantro_dev *vpu)
 	ret = reset_control_deassert(vpu->resets);
 	if (ret) {
 		dev_err(vpu->dev, "Failed to deassert resets: %d\n", ret);
-		return;
+		goto release;
 	}
 
 	hantro_iommu_restore(vpu);
+release:
+	reset_control_release(vpu->resets);
 }
 
 static void rockchip_vpu1_enc_reset(struct hantro_ctx *ctx)
diff --git a/drivers/media/platform/verisilicon/stm32mp25_vpu_hw.c b/drivers/media/platform/verisilicon/stm32mp25_vpu_hw.c
index 833821120b20..a16c43bdeb24 100644
--- a/drivers/media/platform/verisilicon/stm32mp25_vpu_hw.c
+++ b/drivers/media/platform/verisilicon/stm32mp25_vpu_hw.c
@@ -115,7 +115,11 @@ static void stm32mp25_venc_reset(struct hantro_ctx *ctx)
 {
 	struct hantro_dev *vpu = ctx->dev;
 
+	if (reset_control_acquire(vpu->resets))
+		return;
+
 	reset_control_reset(vpu->resets);
+	reset_control_release(vpu->resets);
 }
 
 /*
diff --git a/drivers/media/platform/verisilicon/sunxi_vpu_hw.c b/drivers/media/platform/verisilicon/sunxi_vpu_hw.c
index 02ce8b064a8f..f15ead62dc96 100644
--- a/drivers/media/platform/verisilicon/sunxi_vpu_hw.c
+++ b/drivers/media/platform/verisilicon/sunxi_vpu_hw.c
@@ -91,7 +91,11 @@ static void sunxi_vpu_reset(struct hantro_ctx *ctx)
 {
 	struct hantro_dev *vpu = ctx->dev;
 
+	if (reset_control_acquire(vpu->resets))
+		return;
+
 	reset_control_reset(vpu->resets);
+	reset_control_release(vpu->resets);
 }
 
 static const struct hantro_codec_ops sunxi_vpu_codec_ops[] = {

-- 
2.55.0

