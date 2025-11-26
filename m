From: Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>
Date: Wed, 26 Nov 2025 09:36:04 +0100
Subject: [PATCH v2 3/5] dma: mcf-edma: Fix interrupt handler for 64 DMA
 channels
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251126-dma-coldfire-v2-3-5b1e4544d609@yoseli.org>
References: <20251126-dma-coldfire-v2-0-5b1e4544d609@yoseli.org>
In-Reply-To: <20251126-dma-coldfire-v2-0-5b1e4544d609@yoseli.org>
To: Frank Li <Frank.Li@nxp.com>, Vinod Koul <vkoul@kernel.org>, 
 Angelo Dureghello <angelo@sysam.it>
Cc: Greg Ungerer <gerg@linux-m68k.org>, imx@lists.linux.dev, 
 dmaengine@vger.kernel.org, linux-m68k@lists.linux-m68k.org, 
 linux-kernel@vger.kernel.org, 
 Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764146162; l=1734;
 i=jeanmichel.hautbois@yoseli.org; s=20240925; h=from:subject:message-id;
 bh=HaOGswepi6CQhV7Li1tzKCLUeD5NEzStbHTwZzESV9o=;
 b=uFIDruW6J6TJ+c/uGZMkDzQ/D/jTLyW/AytHC0gVcBXZ66liZBJ8QDBtWrrynsG1Cls5WGZ8J
 GuJc3xn1sxaDlDURdqZcfavyBHNAI+E2XOyQpcFkJWXJRWsFH+fzsJU
X-Developer-Key: i=jeanmichel.hautbois@yoseli.org; a=ed25519;
 pk=MsMTVmoV69wLIlSkHlFoACIMVNQFyvJzvsJSQsn/kq4=
X-Endpoint-Received: by B4 Relay for jeanmichel.hautbois@yoseli.org/20240925 with auth_id=570
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the DMA completion interrupt handler to properly handle all 64
channels on MCF54418 ColdFire processors.

The previous code used BIT(ch) to test interrupt status bits, which
causes undefined behavior on 32-bit architectures when ch >= 32 because
unsigned long is 32 bits and the shift would exceed the type width.

Replace with bitmap_from_u64() and for_each_set_bit() which correctly
handle 64-bit values on 32-bit systems by using a proper bitmap
representation.

Reviewed-by: Frank Li <Frank.Li@nxp.com>
Signed-off-by: Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>
---
 drivers/dma/mcf-edma-main.c | 13 +++++++------
 1 file changed, 7 insertions(+), 6 deletions(-)

diff --git a/drivers/dma/mcf-edma-main.c b/drivers/dma/mcf-edma-main.c
index 6a7d88895501..6353303df957 100644
--- a/drivers/dma/mcf-edma-main.c
+++ b/drivers/dma/mcf-edma-main.c
@@ -18,7 +18,8 @@ static irqreturn_t mcf_edma_tx_handler(int irq, void *dev_id)
 {
 	struct fsl_edma_engine *mcf_edma = dev_id;
 	struct edma_regs *regs = &mcf_edma->regs;
-	unsigned int ch;
+	unsigned long ch;
+	DECLARE_BITMAP(status_mask, 64);
 	u64 intmap;
 
 	intmap = ioread32(regs->inth);
@@ -27,11 +28,11 @@ static irqreturn_t mcf_edma_tx_handler(int irq, void *dev_id)
 	if (!intmap)
 		return IRQ_NONE;
 
-	for (ch = 0; ch < mcf_edma->n_chans; ch++) {
-		if (intmap & BIT(ch)) {
-			iowrite8(EDMA_MASK_CH(ch), regs->cint);
-			fsl_edma_tx_chan_handler(&mcf_edma->chans[ch]);
-		}
+	bitmap_from_u64(status_mask, intmap);
+
+	for_each_set_bit(ch, status_mask, mcf_edma->n_chans) {
+		iowrite8(EDMA_MASK_CH(ch), regs->cint);
+		fsl_edma_tx_chan_handler(&mcf_edma->chans[ch]);
 	}
 
 	return IRQ_HANDLED;

-- 
2.39.5

