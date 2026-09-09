From: Roman Vivchar <rva333@protonmail.com>
Date: Wed, 09 Sep 2026 17:14:06 +0300
Subject: [PATCH 2/3] iommu/mediatek-v1: fix IOMMU device binding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260909-6572-iommu-v1-2-de261da09fb2@protonmail.com>
References: <20260909-6572-iommu-v1-0-de261da09fb2@protonmail.com>
In-Reply-To: <20260909-6572-iommu-v1-0-de261da09fb2@protonmail.com>
To: Yong Wu <yong.wu@mediatek.com>, "Joerg Roedel (AMD)" <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: iommu@lists.linux.dev, linux-mediatek@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, Roman Vivchar <rva333@protonmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788963261; l=4888;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=EcGIcOox9foAPPSzCZAPzZ4As2FunuolmFilHRQ5qcg=;
 b=soNtO8zKf8oyMiaDfTmWSrvH5R6+Rzyfb/MHjpHC1PLcyTcvCY4+RsyYiRV/GmHNQ5XuEQcZL
 2eh4Z8weCS2AwlTxK5SzzdxX4aW+pOYoocewtcaUIK+KIP3UxUMNLTs
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently the driver silently fails to bind devices and DRM subsystem
(which is the primary IOMMU user on MediaTek SoCs) falls back to PA mode.

Fix this by providing of_xlate callback, which lets the driver actually
bind devices and use VA mode.

The fix can be verified by reading overlay engine input address.
Before:
~ # devmem 0x14007040 32
0xBB900000

After:
~ # devmem 0x14007040 32
0x00000000

Fixes: b17336c55d89 ("iommu/mediatek: add support for mtk iommu generation one HW")
Cc: stable@vger.kernel.org
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
Untested on mt2701.
---
 drivers/iommu/mtk_iommu_v1.c | 86 ++++++++++++++++++++------------------------
 1 file changed, 39 insertions(+), 47 deletions(-)

diff --git a/drivers/iommu/mtk_iommu_v1.c b/drivers/iommu/mtk_iommu_v1.c
index ac97dd2868d4..72355f41c36a 100644
--- a/drivers/iommu/mtk_iommu_v1.c
+++ b/drivers/iommu/mtk_iommu_v1.c
@@ -413,38 +413,10 @@ static const struct iommu_ops mtk_iommu_v1_ops;
  * MTK generation one iommu HW only support one iommu domain, and all the client
  * sharing the same iova address space.
  */
-static int mtk_iommu_v1_create_mapping(struct device *dev,
-				       const struct of_phandle_args *args)
+static int mtk_iommu_v1_create_mapping(struct device *dev)
 {
 	struct mtk_iommu_v1_data *data;
-	struct platform_device *m4updev;
 	struct dma_iommu_mapping *mtk_mapping;
-	int ret;
-
-	if (args->args_count != 1) {
-		dev_err(dev, "invalid #iommu-cells(%d) property for IOMMU\n",
-			args->args_count);
-		return -EINVAL;
-	}
-
-	ret = iommu_fwspec_init(dev, of_fwnode_handle(args->np));
-	if (ret)
-		return ret;
-
-	if (!dev_iommu_priv_get(dev)) {
-		/* Get the m4u device */
-		m4updev = of_find_device_by_node(args->np);
-		if (WARN_ON(!m4updev))
-			return -EINVAL;
-
-		dev_iommu_priv_set(dev, platform_get_drvdata(m4updev));
-
-		put_device(&m4updev->dev);
-	}
-
-	ret = iommu_fwspec_add_ids(dev, args->args, 1);
-	if (ret)
-		return ret;
 
 	data = dev_iommu_priv_get(dev);
 	mtk_mapping = data->mapping;
@@ -462,27 +434,12 @@ static int mtk_iommu_v1_create_mapping(struct device *dev,
 
 static struct iommu_device *mtk_iommu_v1_probe_device(struct device *dev)
 {
-	struct iommu_fwspec *fwspec = NULL;
-	struct of_phandle_args iommu_spec;
+	struct iommu_fwspec *fwspec = dev_iommu_fwspec_get(dev);
 	struct mtk_iommu_v1_data *data;
-	int err, idx = 0, larbid, larbidx;
+	int idx, larbid, larbidx;
 	struct device_link *link;
 	struct device *larbdev;
 
-	while (!of_parse_phandle_with_args(dev->of_node, "iommus",
-					   "#iommu-cells",
-					   idx, &iommu_spec)) {
-
-		err = mtk_iommu_v1_create_mapping(dev, &iommu_spec);
-		of_node_put(iommu_spec.np);
-		if (err)
-			return ERR_PTR(err);
-
-		/* dev->iommu_fwspec might have changed */
-		fwspec = dev_iommu_fwspec_get(dev);
-		idx++;
-	}
-
 	if (!fwspec)
 		return ERR_PTR(-ENODEV);
 
@@ -519,9 +476,15 @@ static void mtk_iommu_v1_probe_finalize(struct device *dev)
 	__maybe_unused struct mtk_iommu_v1_data *data = dev_iommu_priv_get(dev);
 	int err;
 
+	err = mtk_iommu_v1_create_mapping(dev);
+	if (err) {
+		dev_err(dev, "Can't create IOMMU mapping - DMA-OPS will not work\n");
+		return;
+	}
+
 	err = arm_iommu_attach_device(dev, data->mapping);
 	if (err)
-		dev_err(dev, "Can't create IOMMU mapping - DMA-OPS will not work\n");
+		dev_err(dev, "Can't attach to IOMMU mapping - DMA-OPS will not work\n");
 }
 
 static void mtk_iommu_v1_release_device(struct device *dev)
@@ -537,6 +500,34 @@ static void mtk_iommu_v1_release_device(struct device *dev)
 	device_link_remove(dev, larbdev);
 }
 
+static int mtk_iommu_v1_of_xlate(struct device *dev,
+				 const struct of_phandle_args *args)
+{
+	struct platform_device *m4updev;
+	int ret;
+
+	if (args->args_count != 1) {
+		dev_err(dev, "invalid #iommu-cells(%d) property for IOMMU\n",
+			args->args_count);
+		return -EINVAL;
+	}
+
+	ret = iommu_fwspec_init(dev, of_fwnode_handle(args->np));
+	if (ret)
+		return ret;
+
+	if (!dev_iommu_priv_get(dev)) {
+		m4updev = of_find_device_by_node(args->np);
+		if (WARN_ON(!m4updev))
+			return -EINVAL;
+
+		dev_iommu_priv_set(dev, platform_get_drvdata(m4updev));
+		put_device(&m4updev->dev);
+	}
+
+	return iommu_fwspec_add_ids(dev, args->args, 1);
+}
+
 static int mtk_iommu_v1_hw_init(const struct mtk_iommu_v1_data *data)
 {
 	u32 regval;
@@ -585,6 +576,7 @@ static const struct iommu_ops mtk_iommu_v1_ops = {
 	.probe_finalize = mtk_iommu_v1_probe_finalize,
 	.release_device	= mtk_iommu_v1_release_device,
 	.device_group	= generic_device_group,
+	.of_xlate	= mtk_iommu_v1_of_xlate,
 	.owner          = THIS_MODULE,
 	.default_domain_ops = &(const struct iommu_domain_ops) {
 		.attach_dev	= mtk_iommu_v1_attach_device,

-- 
2.55.0

