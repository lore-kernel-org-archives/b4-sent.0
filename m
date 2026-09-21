From: Roman Vivchar <rva333@protonmail.com>
Date: Mon, 21 Sep 2026 17:35:49 +0300
Subject: [PATCH v4 3/3] nvmem: mtk-efuse: add mt6572 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-6572-nvmem-v4-3-e9c14156559a@protonmail.com>
References: <20260921-6572-nvmem-v4-0-e9c14156559a@protonmail.com>
In-Reply-To: <20260921-6572-nvmem-v4-0-e9c14156559a@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790001369; l=1270;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=xNpih/0wX5BB+DZCyvEE4EZcS9hf5v5IbyspXQH1sz4=;
 b=lQfi3rcoqxM26rYqiq3bdUfpJqvAXdKZsW6kWv2PX/ps2k/moNydRJooy2jRo67aZWa92Xxwz
 dgNzuOabuoEA0ujfG0LmGrMa2s8dybc+OU7Pzaky9T4g1uYPRgBsOAU
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a platform data struct for the efuse controller.

Reviewed-by: AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 drivers/nvmem/mtk-efuse.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/nvmem/mtk-efuse.c b/drivers/nvmem/mtk-efuse.c
index 980c29d01337..43cc2da2cc1d 100644
--- a/drivers/nvmem/mtk-efuse.c
+++ b/drivers/nvmem/mtk-efuse.c
@@ -131,6 +131,11 @@ static int mtk_efuse_probe(struct platform_device *pdev)
 	return 0;
 }
 
+static const struct mtk_efuse_pdata mtk_mt6572_efuse_pdata = {
+	.uses_post_processing = false,
+	.needs_aligned_read = true,
+};
+
 static const struct mtk_efuse_pdata mtk_mt8186_efuse_pdata = {
 	.uses_post_processing = true,
 	.needs_aligned_read = false,
@@ -142,6 +147,7 @@ static const struct mtk_efuse_pdata mtk_efuse_pdata = {
 };
 
 static const struct of_device_id mtk_efuse_of_match[] = {
+	{ .compatible = "mediatek,mt6572-efuse", .data = &mtk_mt6572_efuse_pdata },
 	{ .compatible = "mediatek,mt8173-efuse", .data = &mtk_efuse_pdata },
 	{ .compatible = "mediatek,mt8186-efuse", .data = &mtk_mt8186_efuse_pdata },
 	{ .compatible = "mediatek,efuse", .data = &mtk_efuse_pdata },

-- 
2.55.0

