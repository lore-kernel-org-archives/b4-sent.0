From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 22:21:32 +0000
Subject: [PATCH RFC 1/3] media: verisilicon: Split probe into hardware init
 and device registration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-hantro-multicore-v1-1-43811eea14c4@gmail.com>
References: <20261113-hantro-multicore-v1-0-43811eea14c4@gmail.com>
In-Reply-To: <20261113-hantro-multicore-v1-0-43811eea14c4@gmail.com>
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 iommu@lists.linux.dev, 
 =?utf-8?q?Sven_P=C3=BCschel?= <s.pueschel@pengutronix.de>, 
 Detlev Casanova <detlev.casanova@collabora.com>, 
 Sergei Khomenkov <shomenkow@gmail.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794608492; l=7068;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=w6qJkiLCLbyhDjp75hGrho7FBAJ1tiuNlQsSG9pOWtI=;
 b=rYwXShfgTY/VH8fB0R1BuB/+cbigqnJMUZkaZ08g0Lt7UmROosTg5UQ5qv9WHrKpHlgc1OvVi
 4DBeO39m2FmDCrGxq6OvY0bSM6zP6dZFqUppTlbzJ+NfgdDX1Cdjmt3
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the acquisition of the per-instance hardware resources (clocks,
resets, registers, interrupts, runtime PM) out of hantro_probe() into
hantro_hw_init()/hantro_hw_cleanup(), and the creation of the mem2mem,
video and media devices into hantro_register_devices() and
hantro_unregister_devices().

This prepares for multi-core support, where every core needs its
hardware set up, but only the main core registers the devices exposed to
userspace, and only once all cores are known.

No functional change intended.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_drv.c | 158 +++++++++++++++---------
 1 file changed, 101 insertions(+), 57 deletions(-)

diff --git a/drivers/media/platform/verisilicon/hantro_drv.c b/drivers/media/platform/verisilicon/hantro_drv.c
index 26e5d5547466..d02988fc19ae 100644
--- a/drivers/media/platform/verisilicon/hantro_drv.c
+++ b/drivers/media/platform/verisilicon/hantro_drv.c
@@ -1069,38 +1069,16 @@ static struct v4l2_m2m_dev *hantro_get_v4l2_m2m_dev(struct hantro_dev *vpu)
 	return v4l2_m2m_init(&vpu_m2m_ops);
 }
 
-static int hantro_probe(struct platform_device *pdev)
+/*
+ * Acquire and initialize the hardware resources of one VPU instance:
+ * clocks, resets, registers, interrupts and runtime PM.
+ */
+static int hantro_hw_init(struct hantro_dev *vpu)
 {
-	const struct of_device_id *match;
-	struct hantro_dev *vpu;
+	struct platform_device *pdev = vpu->pdev;
 	int num_bases;
 	int i, ret;
 
-	vpu = devm_kzalloc(&pdev->dev, sizeof(*vpu), GFP_KERNEL);
-	if (!vpu)
-		return -ENOMEM;
-
-	vpu->dev = &pdev->dev;
-	vpu->pdev = pdev;
-	mutex_init(&vpu->vpu_mutex);
-	spin_lock_init(&vpu->irqlock);
-
-	match = of_match_node(of_hantro_match, pdev->dev.of_node);
-	vpu->variant = match->data;
-
-	ret = hantro_disable_multicore(vpu);
-	if (ret)
-		return ret;
-
-	/*
-	 * Support for nxp,imx8mq-vpu is kept for backwards compatibility
-	 * but it's deprecated. Please update your DTS file to use
-	 * nxp,imx8mq-vpu-g1 or nxp,imx8mq-vpu-g2 instead.
-	 */
-	if (of_device_is_compatible(pdev->dev.of_node, "nxp,imx8mq-vpu"))
-		dev_warn(&pdev->dev, "%s compatible is deprecated\n",
-			 match->compatible);
-
 	INIT_DELAYED_WORK(&vpu->watchdog_work, hantro_watchdog);
 
 	vpu->clocks = devm_kcalloc(&pdev->dev, vpu->variant->num_clocks,
@@ -1213,18 +1191,39 @@ static int hantro_probe(struct platform_device *pdev)
 		goto err_pm_disable_assert_reset;
 	}
 
-	ret = v4l2_device_register(&pdev->dev, &vpu->v4l2_dev);
-	if (ret) {
-		dev_err(&pdev->dev, "Failed to register v4l2 device\n");
-		goto err_clk_unprepare;
-	}
-	platform_set_drvdata(pdev, vpu);
+	return 0;
+
+err_pm_disable_assert_reset:
+	pm_runtime_dont_use_autosuspend(vpu->dev);
+	pm_runtime_disable(vpu->dev);
+	reset_control_assert(vpu->resets);
+	return ret;
+err_pm_disable:
+	pm_runtime_dont_use_autosuspend(vpu->dev);
+	pm_runtime_disable(vpu->dev);
+	return ret;
+}
+
+static void hantro_hw_cleanup(struct hantro_dev *vpu)
+{
+	clk_bulk_unprepare(vpu->variant->num_clocks, vpu->clocks);
+	pm_runtime_dont_use_autosuspend(vpu->dev);
+	pm_runtime_disable(vpu->dev);
+	reset_control_assert(vpu->resets);
+}
+
+/*
+ * Create the mem2mem device and register the video and media devices that
+ * expose the VPU to userspace. The v4l2_device must already be registered.
+ */
+static int hantro_register_devices(struct hantro_dev *vpu)
+{
+	int ret;
 
 	vpu->m2m_dev = hantro_get_v4l2_m2m_dev(vpu);
 	if (IS_ERR(vpu->m2m_dev)) {
 		v4l2_err(&vpu->v4l2_dev, "Failed to init mem2mem device\n");
-		ret = PTR_ERR(vpu->m2m_dev);
-		goto err_v4l2_unreg;
+		return PTR_ERR(vpu->m2m_dev);
 	}
 
 	vpu->mdev.dev = vpu->dev;
@@ -1235,13 +1234,13 @@ static int hantro_probe(struct platform_device *pdev)
 
 	ret = hantro_add_enc_func(vpu);
 	if (ret) {
-		dev_err(&pdev->dev, "Failed to register encoder\n");
+		dev_err(vpu->dev, "Failed to register encoder\n");
 		goto err_m2m_rel;
 	}
 
 	ret = hantro_add_dec_func(vpu);
 	if (ret) {
-		dev_err(&pdev->dev, "Failed to register decoder\n");
+		dev_err(vpu->dev, "Failed to register decoder\n");
 		goto err_rm_enc_func;
 	}
 
@@ -1260,18 +1259,70 @@ static int hantro_probe(struct platform_device *pdev)
 err_m2m_rel:
 	media_device_cleanup(&vpu->mdev);
 	v4l2_m2m_put(vpu->m2m_dev);
+	return ret;
+}
+
+static void hantro_unregister_devices(struct hantro_dev *vpu)
+{
+	media_device_unregister(&vpu->mdev);
+	hantro_remove_dec_func(vpu);
+	hantro_remove_enc_func(vpu);
+	media_device_cleanup(&vpu->mdev);
+	v4l2_m2m_put(vpu->m2m_dev);
+}
+
+static int hantro_probe(struct platform_device *pdev)
+{
+	const struct of_device_id *match;
+	struct hantro_dev *vpu;
+	int ret;
+
+	vpu = devm_kzalloc(&pdev->dev, sizeof(*vpu), GFP_KERNEL);
+	if (!vpu)
+		return -ENOMEM;
+
+	vpu->dev = &pdev->dev;
+	vpu->pdev = pdev;
+	mutex_init(&vpu->vpu_mutex);
+	spin_lock_init(&vpu->irqlock);
+
+	match = of_match_node(of_hantro_match, pdev->dev.of_node);
+	vpu->variant = match->data;
+
+	ret = hantro_disable_multicore(vpu);
+	if (ret)
+		return ret;
+
+	/*
+	 * Support for nxp,imx8mq-vpu is kept for backwards compatibility
+	 * but it's deprecated. Please update your DTS file to use
+	 * nxp,imx8mq-vpu-g1 or nxp,imx8mq-vpu-g2 instead.
+	 */
+	if (of_device_is_compatible(pdev->dev.of_node, "nxp,imx8mq-vpu"))
+		dev_warn(&pdev->dev, "%s compatible is deprecated\n",
+			 match->compatible);
+
+	ret = hantro_hw_init(vpu);
+	if (ret)
+		return ret;
+
+	ret = v4l2_device_register(&pdev->dev, &vpu->v4l2_dev);
+	if (ret) {
+		dev_err(&pdev->dev, "Failed to register v4l2 device\n");
+		goto err_hw_cleanup;
+	}
+	platform_set_drvdata(pdev, vpu);
+
+	ret = hantro_register_devices(vpu);
+	if (ret)
+		goto err_v4l2_unreg;
+
+	return 0;
+
 err_v4l2_unreg:
 	v4l2_device_unregister(&vpu->v4l2_dev);
-err_clk_unprepare:
-	clk_bulk_unprepare(vpu->variant->num_clocks, vpu->clocks);
-err_pm_disable_assert_reset:
-	pm_runtime_dont_use_autosuspend(vpu->dev);
-	pm_runtime_disable(vpu->dev);
-	reset_control_assert(vpu->resets);
-	return ret;
-err_pm_disable:
-	pm_runtime_dont_use_autosuspend(vpu->dev);
-	pm_runtime_disable(vpu->dev);
+err_hw_cleanup:
+	hantro_hw_cleanup(vpu);
 	return ret;
 }
 
@@ -1281,16 +1332,9 @@ static void hantro_remove(struct platform_device *pdev)
 
 	v4l2_info(&vpu->v4l2_dev, "Removing %s\n", pdev->name);
 
-	media_device_unregister(&vpu->mdev);
-	hantro_remove_dec_func(vpu);
-	hantro_remove_enc_func(vpu);
-	media_device_cleanup(&vpu->mdev);
-	v4l2_m2m_put(vpu->m2m_dev);
+	hantro_unregister_devices(vpu);
 	v4l2_device_unregister(&vpu->v4l2_dev);
-	clk_bulk_unprepare(vpu->variant->num_clocks, vpu->clocks);
-	pm_runtime_dont_use_autosuspend(vpu->dev);
-	pm_runtime_disable(vpu->dev);
-	reset_control_assert(vpu->resets);
+	hantro_hw_cleanup(vpu);
 }
 
 static int hantro_runtime_resume(struct device *dev)

-- 
2.55.0

