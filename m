From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Wed, 08 Apr 2026 13:42:42 +0100
Subject: [PATCH v3 3/4] dmaengine: dma-axi-dmac: Drop struct clk from main
 struct
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260408-dma-dmac-handle-vunmap-v3-3-2456ad292154@analog.com>
References: <20260408-dma-dmac-handle-vunmap-v3-0-2456ad292154@analog.com>
In-Reply-To: <20260408-dma-dmac-handle-vunmap-v3-0-2456ad292154@analog.com>
To: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, Vinod Koul <vkoul@kernel.org>, 
 Frank Li <Frank.Li@kernel.org>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775652161; l=1271;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=QvJ5ia4JnsZhnq/kgtM2oBkAf3EjDDkcD8ZAMJui6c0=;
 b=VDVFL1nBPgidACu/Oxb7bKfwAFlRGTnHyQQTbmPz3w+FqQ3LJqFiZ9vT2jAI9qrJHTy0nsABH
 YIUgLcKB2CMD7LXdskLMQ38jX4EIoAyAfouFDwzge5o3xUbQ0hGKq68
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There's no reason to keep struct clk in struct axi_dmac. Hence, use a
local clk variable in .probe() and be done with it.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/dma/dma-axi-dmac.c | 9 ++++-----
 1 file changed, 4 insertions(+), 5 deletions(-)

diff --git a/drivers/dma/dma-axi-dmac.c b/drivers/dma/dma-axi-dmac.c
index 127c3cf80a0e..41898d594be7 100644
--- a/drivers/dma/dma-axi-dmac.c
+++ b/drivers/dma/dma-axi-dmac.c
@@ -170,8 +170,6 @@ struct axi_dmac {
 	void __iomem *base;
 	int irq;
 
-	struct clk *clk;
-
 	struct dma_device dma_dev;
 	struct axi_dmac_chan chan;
 };
@@ -1198,6 +1196,7 @@ static int axi_dmac_probe(struct platform_device *pdev)
 {
 	struct dma_device *dma_dev;
 	struct axi_dmac *dmac;
+	struct clk *clk;
 	struct regmap *regmap;
 	unsigned int version;
 	u32 irq_mask = 0;
@@ -1217,9 +1216,9 @@ static int axi_dmac_probe(struct platform_device *pdev)
 	if (IS_ERR(dmac->base))
 		return PTR_ERR(dmac->base);
 
-	dmac->clk = devm_clk_get_enabled(&pdev->dev, NULL);
-	if (IS_ERR(dmac->clk))
-		return PTR_ERR(dmac->clk);
+	clk = devm_clk_get_enabled(&pdev->dev, NULL);
+	if (IS_ERR(clk))
+		return PTR_ERR(clk);
 
 	version = axi_dmac_read(dmac, ADI_AXI_REG_VERSION);
 

-- 
2.53.0

