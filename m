From: Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>
Date: Wed, 26 Nov 2025 09:36:02 +0100
Subject: [PATCH v2 1/5] dma: fsl-edma: Add FSL_EDMA_DRV_MCF flag for
 ColdFire eDMA
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251126-dma-coldfire-v2-1-5b1e4544d609@yoseli.org>
References: <20251126-dma-coldfire-v2-0-5b1e4544d609@yoseli.org>
In-Reply-To: <20251126-dma-coldfire-v2-0-5b1e4544d609@yoseli.org>
To: Frank Li <Frank.Li@nxp.com>, Vinod Koul <vkoul@kernel.org>, 
 Angelo Dureghello <angelo@sysam.it>
Cc: Greg Ungerer <gerg@linux-m68k.org>, imx@lists.linux.dev, 
 dmaengine@vger.kernel.org, linux-m68k@lists.linux-m68k.org, 
 linux-kernel@vger.kernel.org, 
 Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764146162; l=2499;
 i=jeanmichel.hautbois@yoseli.org; s=20240925; h=from:subject:message-id;
 bh=9Rl/w8Flv4FYHKNwt2QAAOrN5X7BfFjFIc6s+uDV++s=;
 b=qxtJdH6M5NqML0HZbwh4Es0Y/QUSnr+NBgpH0A7u7ay9142548awxn+ruhMWpHWc4nIiSjk+d
 zdxCMuA6eGvA/cpjqTlKje7dvM+vNG2IsC+9xGT50DAinjJ/8aNrUFL
X-Developer-Key: i=jeanmichel.hautbois@yoseli.org; a=ed25519;
 pk=MsMTVmoV69wLIlSkHlFoACIMVNQFyvJzvsJSQsn/kq4=
X-Endpoint-Received: by B4 Relay for jeanmichel.hautbois@yoseli.org/20240925 with auth_id=570
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add FSL_EDMA_DRV_MCF driver flag to identify MCF ColdFire eDMA
controllers which have a native M68K register layout.

The edma_writeb() function applies an XOR ^ 0x3 byte-lane adjustment for
big-endian eDMA controllers where byte registers within a 32-bit word
need address correction.

However, the MCF54418 eDMA 8-bit registers (SERQ, CERQ, SEEI, CEEI,
CINT, CERR, SSRT, CDNE) are located at sequential byte addresses
(0x4018-0x401F) as documented in the MCF54418 Reference Manual Table
19-2. No byte-lane adjustment is needed, as applying the XOR causes
writes to target incorrect registers (writing to CERR at 0x401D would
actually access SSRT at 0x401E).

Set this flag in the MCF eDMA driver to bypass the XOR adjustment and
access registers at their documented addresses.

Reviewed-by: Frank Li <Frank.Li@nxp.com>
Signed-off-by: Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>
---
 drivers/dma/fsl-edma-common.h | 5 ++++-
 drivers/dma/mcf-edma-main.c   | 2 +-
 2 files changed, 5 insertions(+), 2 deletions(-)

diff --git a/drivers/dma/fsl-edma-common.h b/drivers/dma/fsl-edma-common.h
index 205a96489094..4c86f2f39c1d 100644
--- a/drivers/dma/fsl-edma-common.h
+++ b/drivers/dma/fsl-edma-common.h
@@ -225,6 +225,8 @@ struct fsl_edma_desc {
 #define FSL_EDMA_DRV_TCD64		BIT(15)
 /* All channel ERR IRQ share one IRQ line */
 #define FSL_EDMA_DRV_ERRIRQ_SHARE       BIT(16)
+/* MCF eDMA: Different register layout, no XOR for byte access */
+#define FSL_EDMA_DRV_MCF                BIT(17)
 
 
 #define FSL_EDMA_DRV_EDMA3	(FSL_EDMA_DRV_SPLIT_REG |	\
@@ -419,7 +421,8 @@ static inline void edma_writeb(struct fsl_edma_engine *edma,
 			       u8 val, void __iomem *addr)
 {
 	/* swap the reg offset for these in big-endian mode */
-	if (edma->big_endian)
+	/* MCF eDMA has different register layout, no XOR needed */
+	if (edma->big_endian && !(edma->drvdata->flags & FSL_EDMA_DRV_MCF))
 		iowrite8(val, (void __iomem *)((unsigned long)addr ^ 0x3));
 	else
 		iowrite8(val, addr);
diff --git a/drivers/dma/mcf-edma-main.c b/drivers/dma/mcf-edma-main.c
index 9e1c6400c77b..f95114829d80 100644
--- a/drivers/dma/mcf-edma-main.c
+++ b/drivers/dma/mcf-edma-main.c
@@ -145,7 +145,7 @@ static void mcf_edma_irq_free(struct platform_device *pdev,
 }
 
 static struct fsl_edma_drvdata mcf_data = {
-	.flags = FSL_EDMA_DRV_EDMA64,
+	.flags = FSL_EDMA_DRV_EDMA64 | FSL_EDMA_DRV_MCF,
 	.setup_irq = mcf_edma_irq_init,
 };
 

-- 
2.39.5

