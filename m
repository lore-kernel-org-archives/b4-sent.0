From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Fri, 16 Oct 2026 03:00:17 +0000
Subject: [PATCH] dmaengine: amlogic: Fix regmap error check issue
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-fix-a9-dma-complier-v1-1-024421d5b3c8@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAECT0WoC/x2MQQqAIBAAvxJ7biELNu0r0cFyq4VKUYgg/HvSc
 WBmXkgchRMM1QuRb0nirwKqrmDZ7bUxiisMbdOSahThKg9ag+60uPgzHMIRVa9nYqLe6A5KGSI
 X7b+OU84f8l1hJWUAAAA=
X-Change-ID: 20261016-fix-a9-dma-complier-178b6e667983
To: Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>
Cc: linux-amlogic@lists.infradead.org, dmaengine@vger.kernel.org, 
 linux-kernel@vger.kernel.org, kernel test robot <lkp@intel.com>, 
 Dan Carpenter <error27@gmail.com>, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792119618; l=1413;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=q70ArngI8F9kaZ0a86j08SCXsqeF7k11fJnEBCve2NM=;
 b=b8gfpJGQQxHZblcSRlbmR0x8knLQCBnlci0XZWs2RwdViFJw9m3CKpHz1TgeXXp0l32aEMgXU
 OP7Nu80bFXUCx/LJjuNHlrhQbpiIIcJgZoXLxE1W51B5c/WyZhuq40T
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The func devm_regmap_init_mmio() only returns an error pointer on failure,
Use IS_ERR() instead to make the intent clearer. And Fix the following
compilation issue at the same time.

Smatch warnings:
drivers/dma/amlogic-dma.c:636 aml_dma_probe() warn: passing zero to 'PTR_ERR'

Fixes: b84b5197e344 ("dmaengine: amlogic: Add general DMA driver for A9")
Reported-by: kernel test robot <lkp@intel.com>
Closes: https://lore.kernel.org/r/202610080953.C5TYlCaA-lkp@intel.com/
Reported-by: Dan Carpenter <error27@gmail.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Fix regmap error check issue.
---
 drivers/dma/amlogic-dma.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/dma/amlogic-dma.c b/drivers/dma/amlogic-dma.c
index 78ee2337ae71..684121d13fca 100644
--- a/drivers/dma/amlogic-dma.c
+++ b/drivers/dma/amlogic-dma.c
@@ -632,7 +632,7 @@ static int aml_dma_probe(struct platform_device *pdev)
 
 	aml_dma->regmap = devm_regmap_init_mmio(&pdev->dev, aml_dma->base,
 						&aml_regmap_config);
-	if (IS_ERR_OR_NULL(aml_dma->regmap))
+	if (IS_ERR(aml_dma->regmap))
 		return PTR_ERR(aml_dma->regmap);
 
 	aml_dma->clk = devm_clk_get_enabled(&pdev->dev, NULL);

---
base-commit: 42c31fec1ca76b8b5f7759def122d418dff2cd4b
change-id: 20261016-fix-a9-dma-complier-178b6e667983

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

