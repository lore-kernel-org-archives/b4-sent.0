From: Roman Vivchar <rva333@protonmail.com>
Date: Wed, 15 Jul 2026 17:27:47 +0300
Subject: [PATCH 2/3] nvmem: mtk-efuse: add support for 32-bit aligned reads
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260715-6572-nvmem-v1-2-9c13be99d077@protonmail.com>
References: <20260715-6572-nvmem-v1-0-9c13be99d077@protonmail.com>
In-Reply-To: <20260715-6572-nvmem-v1-0-9c13be99d077@protonmail.com>
To: Srinivas Kandagatla <srini@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Andrew-CT Chen <andrew-ct.chen@mediatek.com>, 
 Lala Lin <lala.lin@mediatek.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784125843; l=3135;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=gOEk3xV/ih0Hcv+/D9l/u/kTXVslxW9X99D1kWTUUDw=;
 b=q7erFPeQUkoybLyUukh26Ulgz+g/gbaNCEYnLZ0l2O9BHFQ2r6pMpOfwAeh02qLqtGkF7s0QU
 V4bXXhD1MkXAi4268YXyYMS/PwzfqYCaVW+w+m+jt4am6mOtThmMMc0
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some MediaTek SoCs, such as mt6572, don't support 8-bit reads, leading
to zeroes or garbage data. 32-bit aligned reads must be used instead.

Introduce an 'needs_aligned_read' field to the platform data to enforce
32-bit aligned register access. All reads will be performed by reading
4-byte words and masking them.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 drivers/nvmem/mtk-efuse.c | 31 ++++++++++++++++++++++++++++---
 1 file changed, 28 insertions(+), 3 deletions(-)

diff --git a/drivers/nvmem/mtk-efuse.c b/drivers/nvmem/mtk-efuse.c
index af953e1d9230..1462f2760818 100644
--- a/drivers/nvmem/mtk-efuse.c
+++ b/drivers/nvmem/mtk-efuse.c
@@ -4,6 +4,7 @@
  * Author: Andrew-CT Chen <andrew-ct.chen@mediatek.com>
  */
 
+#include <linux/align.h>
 #include <linux/device.h>
 #include <linux/module.h>
 #include <linux/mod_devicetable.h>
@@ -14,10 +15,12 @@
 
 struct mtk_efuse_pdata {
 	bool uses_post_processing;
+	bool needs_aligned_read;
 };
 
 struct mtk_efuse_priv {
 	void __iomem *base;
+	const struct mtk_efuse_pdata *data;
 };
 
 static int mtk_reg_read(void *context,
@@ -28,6 +31,26 @@ static int mtk_reg_read(void *context,
 	u8 *val = _val;
 	int i;
 
+	if (priv->data->needs_aligned_read) {
+		u32 pos, shift, val32;
+
+		for (i = 0; i < bytes; i++, val++) {
+			pos = reg + i;
+
+			/*
+			 * Read on 32-bit word boundary or if it's the first
+			 * iteration
+			 */
+			if (i == 0 || IS_ALIGNED(pos, 4))
+				val32 = readl(priv->base + (pos & ~3));
+
+			shift = (pos & 3) * 8;
+			*val = (val32 >> shift) & 0xff;
+		}
+
+		return 0;
+	}
+
 	for (i = 0; i < bytes; i++, val++)
 		*val = readb(addr + i);
 
@@ -67,7 +90,6 @@ static int mtk_efuse_probe(struct platform_device *pdev)
 	struct nvmem_device *nvmem;
 	struct nvmem_config econfig = {};
 	struct mtk_efuse_priv *priv;
-	const struct mtk_efuse_pdata *pdata;
 	struct platform_device *socinfo;
 
 	priv = devm_kzalloc(dev, sizeof(*priv), GFP_KERNEL);
@@ -78,7 +100,8 @@ static int mtk_efuse_probe(struct platform_device *pdev)
 	if (IS_ERR(priv->base))
 		return PTR_ERR(priv->base);
 
-	pdata = device_get_match_data(dev);
+	priv->data = device_get_match_data(dev);
+
 	econfig.add_legacy_fixed_of_cells = true;
 	econfig.stride = 1;
 	econfig.word_size = 1;
@@ -86,7 +109,7 @@ static int mtk_efuse_probe(struct platform_device *pdev)
 	econfig.size = resource_size(res);
 	econfig.priv = priv;
 	econfig.dev = dev;
-	if (pdata->uses_post_processing)
+	if (priv->data->uses_post_processing)
 		econfig.fixup_dt_cell_info = &mtk_efuse_fixup_dt_cell_info;
 	nvmem = devm_nvmem_register(dev, &econfig);
 	if (IS_ERR(nvmem))
@@ -103,10 +126,12 @@ static int mtk_efuse_probe(struct platform_device *pdev)
 
 static const struct mtk_efuse_pdata mtk_mt8186_efuse_pdata = {
 	.uses_post_processing = true,
+	.needs_aligned_read = false,
 };
 
 static const struct mtk_efuse_pdata mtk_efuse_pdata = {
 	.uses_post_processing = false,
+	.needs_aligned_read = false,
 };
 
 static const struct of_device_id mtk_efuse_of_match[] = {

-- 
2.54.0

