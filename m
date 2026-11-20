From: Congcong Yao <congcong.yao@mediatek.com>
Date: Fri, 20 Nov 2026 11:24:56 +0800
Subject: [PATCH v13 2/2] memory: mtk-smi: mt8188: Add SMI reset and clamp
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-8188-smi-clamp-reset-v13-2-9a9516e81c1d@mediatek.com>
References: <20261120-8188-smi-clamp-reset-v13-0-9a9516e81c1d@mediatek.com>
In-Reply-To: <20261120-8188-smi-clamp-reset-v13-0-9a9516e81c1d@mediatek.com>
To: Yong Wu <yong.wu@mediatek.com>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Rob Herring <robh@kernel.org>, Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-mediatek@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Friday Yang <friday.yang@mediatek.com>, 
 Congcong Yao <congcong.yao@mediatek.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795145107; l=8390;
 i=congcong.yao@mediatek.com; s=20260722; h=from:subject:message-id;
 bh=sy/zYJrfiLSDfi1YF3uJe1dLxyJUidxbNuEHEhkjjL4=;
 b=vEQbEwKrUX+gm6Fw4C4MxCyBOIsb0Zyh4HTMvtakjBnGc50BnpTanfJkLmBpnJi+taC1lr+Hj
 mRwWvc+3fo0AMC+f4FzxD9mYHgHe77X+hjQdP7XveTM0jTrROuIyBY+
X-Developer-Key: i=congcong.yao@mediatek.com; a=ed25519;
 pk=tIrmGxKQQxnfyb48iCCd19063tppPj89U3nupGYAIxg=
X-Endpoint-Received: by B4 Relay for congcong.yao@mediatek.com/20260722 with auth_id=889
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Friday Yang <friday.yang@mediatek.com>

To prevent handling glitch signals during MTCMOS on/off transitions,
SMI requires clamp and reset operations. Parse the reset settings for
SMI LARBs and the clamp settings for the SMI Sub-Common. Register
genpd callback for the SMI LARBs located in image, camera and IPE
subsystems, and apply reset and clamp operations within the callback.

Signed-off-by: Friday Yang <friday.yang@mediatek.com>
Signed-off-by: Congcong Yao <congcong.yao@mediatek.com>
---
 drivers/memory/mtk-smi.c | 120 ++++++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 119 insertions(+), 1 deletion(-)

diff --git a/drivers/memory/mtk-smi.c b/drivers/memory/mtk-smi.c
index 0ebbaf3411aa..5ec277fea04f 100644
--- a/drivers/memory/mtk-smi.c
+++ b/drivers/memory/mtk-smi.c
@@ -14,7 +14,9 @@
 #include <linux/of.h>
 #include <linux/of_platform.h>
 #include <linux/platform_device.h>
+#include <linux/pm_domain.h>
 #include <linux/pm_runtime.h>
+#include <linux/reset.h>
 #include <linux/soc/mediatek/mtk_sip_svc.h>
 #include <soc/mediatek/smi.h>
 #include <dt-bindings/memory/mt2701-larb-port.h>
@@ -34,6 +36,8 @@
 #define SMI_FIFO_TH1			0x238
 #define SMI_FIFO_TH2			0x23c
 #define SMI_DCM				0x300
+#define SMI_COMMON_CLAMP_EN_SET		0x3c4
+#define SMI_COMMON_CLAMP_EN_CLR		0x3c8
 #define SMI_DUMMY			0x444
 
 /* SMI LARB */
@@ -134,6 +138,7 @@ struct mtk_smi_larb_gen {
 	unsigned int			larb_direct_to_common_mask;
 	unsigned int			flags_general;
 	const u8			(*ostd)[SMI_LARB_PORT_NR_MAX];
+	const u8			*clamp_port;
 };
 
 struct mtk_smi {
@@ -150,6 +155,7 @@ struct mtk_smi {
 };
 
 struct mtk_smi_larb { /* larb: local arbiter */
+	struct device			*dev;
 	struct mtk_smi			smi;
 	void __iomem			*base;
 	struct device			*smi_common_dev; /* common or sub-common dev */
@@ -158,6 +164,9 @@ struct mtk_smi_larb { /* larb: local arbiter */
 	u32				*mmu;
 	unsigned char			*bank;
 	bool				bound; /* set once the iommu binds us */
+	u8				smi_comm_in_port_id; /* smi-comm or sub-comm */
+	struct notifier_block		nb;
+	struct reset_control		*rst_con;
 };
 
 static int
@@ -514,6 +523,19 @@ static const u8 mtk_smi_larb_mt8195_ostd[][SMI_LARB_PORT_NR_MAX] = {
 	[28] = {0x1a, 0x0e, 0x0a, 0x0a, 0x0c, 0x0e, 0x10,},
 };
 
+static const u8 mtk_smi_larb_clamp_port_mt8188[MTK_LARB_NR_MAX] = {
+	[9]	= BIT(1), /* larb10 */
+	[10]	= BIT(2), /* larb11a */
+	[11]	= BIT(2), /* larb11b */
+	[12]	= BIT(3), /* larb11c */
+	[13]	= BIT(0), /* larb12 */
+	[16]	= BIT(1), /* larb15 */
+	[17]	= BIT(2), /* larb16a */
+	[18]	= BIT(2), /* larb16b */
+	[19]	= BIT(3), /* larb17a */
+	[20]	= BIT(3), /* larb17b */
+};
+
 static const struct mtk_smi_larb_gen mtk_smi_larb_mt2701 = {
 	.port_in_larb = {
 		LARB0_PORT_OFFSET, LARB1_PORT_OFFSET,
@@ -567,6 +589,7 @@ static const struct mtk_smi_larb_gen mtk_smi_larb_mt8188 = {
 	.flags_general	            = MTK_SMI_FLAG_THRT_UPDATE | MTK_SMI_FLAG_SW_FLAG |
 				      MTK_SMI_FLAG_SLEEP_CTL | MTK_SMI_FLAG_CFG_PORT_SEC_CTL,
 	.ostd		            = mtk_smi_larb_mt8188_ostd,
+	.clamp_port                 = mtk_smi_larb_clamp_port_mt8188,
 };
 
 static const struct mtk_smi_larb_gen mtk_smi_larb_mt8189 = {
@@ -626,6 +649,43 @@ static void mtk_smi_larb_sleep_ctrl_disable(struct mtk_smi_larb *larb)
 	writel_relaxed(0, larb->base + SMI_LARB_SLP_CON);
 }
 
+static void mtk_smi_larb_clamp_protect_enable(struct mtk_smi_larb *larb, bool enable)
+{
+	struct mtk_smi *common = dev_get_drvdata(larb->smi_common_dev);
+	u32 clamp_offset;
+
+	clamp_offset = enable ? SMI_COMMON_CLAMP_EN_SET : SMI_COMMON_CLAMP_EN_CLR;
+	writel(larb->smi_comm_in_port_id, common->base + clamp_offset);
+}
+
+static int mtk_smi_genpd_callback(struct notifier_block *nb,
+				  unsigned long event, void *data)
+{
+	struct mtk_smi_larb *larb = container_of(nb, struct mtk_smi_larb, nb);
+	int ret;
+
+	switch (event) {
+	case GENPD_NOTIFY_PRE_ON:
+	case GENPD_NOTIFY_PRE_OFF:
+		/* Clamp this larb to avoid the redundant commands */
+		mtk_smi_larb_clamp_protect_enable(larb, true);
+		break;
+	case GENPD_NOTIFY_ON:
+		ret = reset_control_reset(larb->rst_con);
+		if (ret) {
+			dev_err(larb->dev, "Failed to reset smi larb %d\n", ret);
+			return NOTIFY_BAD;
+		}
+
+		mtk_smi_larb_clamp_protect_enable(larb, false);
+		break;
+	default:
+		break;
+	}
+
+	return NOTIFY_OK;
+}
+
 static int mtk_smi_device_link_common(struct device *dev, struct device **com_dev)
 {
 	struct platform_device *smi_com_pdev;
@@ -685,6 +745,28 @@ static int mtk_smi_dts_clk_init(struct device *dev, struct mtk_smi *smi,
 	return ret;
 }
 
+static int mtk_smi_larb_parse_reset(struct mtk_smi_larb *larb)
+{
+	struct device *dev = larb->dev;
+	int ret;
+
+	larb->smi_comm_in_port_id = larb->larb_gen->clamp_port[larb->larbid];
+	larb->rst_con = devm_reset_control_get_exclusive(dev, "larb");
+	if (IS_ERR(larb->rst_con))
+		return dev_err_probe(dev, PTR_ERR(larb->rst_con),
+				     "Failed to get reset controller\n");
+
+	larb->nb.notifier_call = mtk_smi_genpd_callback;
+	ret = dev_pm_genpd_add_notifier(dev, &larb->nb);
+	if (ret) {
+		larb->nb.notifier_call = NULL;
+		return dev_err_probe(dev, ret,
+				     "Failed to add genpd callback\n");
+	}
+
+	return 0;
+}
+
 static int mtk_smi_larb_probe(struct platform_device *pdev)
 {
 	struct mtk_smi_larb *larb;
@@ -695,6 +777,7 @@ static int mtk_smi_larb_probe(struct platform_device *pdev)
 	if (!larb)
 		return -ENOMEM;
 
+	larb->dev = dev;
 	larb->larb_gen = of_device_get_match_data(dev);
 	larb->base = devm_platform_ioremap_resource(pdev, 0);
 	if (IS_ERR(larb->base))
@@ -711,15 +794,41 @@ static int mtk_smi_larb_probe(struct platform_device *pdev)
 	if (ret < 0)
 		return ret;
 
-	pm_runtime_enable(dev);
 	platform_set_drvdata(pdev, larb);
+
+	/* The larbid are sequential for IOMMU if this property is not present */
+	ret = of_property_read_u32(dev->of_node, "mediatek,larb-id", &larb->larbid);
+	if (ret == -EINVAL)
+		goto pm_runtime_en;
+	if (ret || larb->larbid >= MTK_LARB_NR_MAX) {
+		ret = -EINVAL;
+		goto err_link_remove;
+	}
+
+	/*
+	 * Only SMI LARBs in camera, image and IPE subsys need to
+	 * apply clamp and reset operations, others can be skipped.
+	 */
+	if (larb->larb_gen->clamp_port && larb->larb_gen->clamp_port[larb->larbid]) {
+		ret = mtk_smi_larb_parse_reset(larb);
+		if (ret)
+			goto err_link_remove;
+	}
+
+pm_runtime_en:
+	pm_runtime_enable(dev);
 	ret = component_add(dev, &mtk_smi_larb_component_ops);
 	if (ret)
 		goto err_pm_disable;
 	return 0;
 
 err_pm_disable:
+	if (larb->nb.notifier_call)
+		dev_pm_genpd_remove_notifier(&pdev->dev);
+
 	pm_runtime_disable(dev);
+
+err_link_remove:
 	device_link_remove(dev, larb->smi_common_dev);
 	put_device(larb->smi_common_dev);
 	return ret;
@@ -729,6 +838,9 @@ static void mtk_smi_larb_remove(struct platform_device *pdev)
 {
 	struct mtk_smi_larb *larb = platform_get_drvdata(pdev);
 
+	if (larb->nb.notifier_call)
+		dev_pm_genpd_remove_notifier(&pdev->dev);
+
 	device_link_remove(&pdev->dev, larb->smi_common_dev);
 	pm_runtime_disable(&pdev->dev);
 	component_del(&pdev->dev, &mtk_smi_larb_component_ops);
@@ -865,6 +977,11 @@ static const struct mtk_smi_common_plat mtk_smi_common_mt8188_vpp = {
 	.init     = mtk_smi_common_mt8195_init,
 };
 
+static const struct mtk_smi_common_plat mtk_smi_sub_common_mt8188 = {
+	.type     = MTK_SMI_GEN2_SUB_COMM,
+	.has_gals = true,
+};
+
 static const struct mtk_smi_common_plat mtk_smi_common_mt8189 = {
 	.type     = MTK_SMI_GEN2,
 	.bus_sel  = F_MMU1_LARB(1) | F_MMU1_LARB(3) | F_MMU1_LARB(5) |
@@ -920,6 +1037,7 @@ static const struct of_device_id mtk_smi_common_of_ids[] = {
 	{.compatible = "mediatek,mt8186-smi-common", .data = &mtk_smi_common_mt8186},
 	{.compatible = "mediatek,mt8188-smi-common-vdo", .data = &mtk_smi_common_mt8188_vdo},
 	{.compatible = "mediatek,mt8188-smi-common-vpp", .data = &mtk_smi_common_mt8188_vpp},
+	{.compatible = "mediatek,mt8188-smi-sub-common", .data = &mtk_smi_sub_common_mt8188},
 	{.compatible = "mediatek,mt8189-smi-common",     .data = &mtk_smi_common_mt8189},
 	{.compatible = "mediatek,mt8189-smi-sub-common", .data = &mtk_smi_sub_common_mt8189},
 	{.compatible = "mediatek,mt8192-smi-common", .data = &mtk_smi_common_mt8192},

-- 
2.43.0

