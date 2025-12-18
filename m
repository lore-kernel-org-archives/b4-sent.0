From: Mateusz Litwin <mateusz.litwin@nokia.com>
Date: Thu, 18 Dec 2025 22:33:05 +0100
Subject: [PATCH v2 2/2] spi: cadence-quadspi: Improve CQSPI_SLOW_SRAM quirk
 if flash is slow
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251218-cqspi_indirect_read_improve-v2-2-396079972f2a@nokia.com>
References: <20251218-cqspi_indirect_read_improve-v2-0-396079972f2a@nokia.com>
In-Reply-To: <20251218-cqspi_indirect_read_improve-v2-0-396079972f2a@nokia.com>
To: Mark Brown <broonie@kernel.org>
Cc: linux-spi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mateusz Litwin <mateusz.litwin@nokia.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766093707; l=3156;
 i=mateusz.litwin@nokia.com; s=20251217; h=from:subject:message-id;
 bh=wODUxc561XQK+ZcLXkwgTN2v7/VBU9osHmZCWSMuTWI=;
 b=kTLBLwJL1bPgEYaPRi1b7+gXIXL8+q8UpI3JXHdAEpYQgF3LToeISPaGKMku3x/g6xEBCWSNt
 P/pRtBdHieXC8/vzBIm885QNqZRwLORs4x7hmm5bY4C/n3MPJvvy/VW
X-Developer-Key: i=mateusz.litwin@nokia.com; a=ed25519;
 pk=9NV76cwWrtwYUektOrK/ht9GTzmhtkqSvghr3Td4hM4=
X-Endpoint-Received: by B4 Relay for mateusz.litwin@nokia.com/20251217 with auth_id=579
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

CQSPI_SLOW_SRAM quirk on the Stratix10 platform causes fewer interrupts,
but also causes timeouts if a small block is used or if flash devices are
slower than or equal in speed to SRAM's read operations. Adding the
CQSPI_REG_IRQ_IND_COMP interrupt would resolve the problem for small
reads, and removing the disabling of interrupts would resolve the issue
with lost interrupts.
This marginally increases IRQ count. Tests show that this will cause only
a few percent more interrupts.

Test:
$ dd if=/dev/mtd0 of=/dev/null bs=1M count=64
Results from the Stratix10 platform with mt25qu02g flash.
FIFO size in all tests: 128

Serviced interrupt call counts:
Without CQSPI_SLOW_SRAM quirk: 16 668 850
With CQSPI_SLOW_SRAM quirk: 204 176
With CQSPI_SLOW_SRAM and this commit: 224 528

Signed-off-by: Mateusz Litwin <mateusz.litwin@nokia.com>
---
 drivers/spi/spi-cadence-quadspi.c | 19 +++++--------------
 1 file changed, 5 insertions(+), 14 deletions(-)

diff --git a/drivers/spi/spi-cadence-quadspi.c b/drivers/spi/spi-cadence-quadspi.c
index 02d1ff53e61d..958788e0dac0 100644
--- a/drivers/spi/spi-cadence-quadspi.c
+++ b/drivers/spi/spi-cadence-quadspi.c
@@ -300,6 +300,9 @@ struct cqspi_driver_platdata {
 					 CQSPI_REG_IRQ_IND_SRAM_FULL	| \
 					 CQSPI_REG_IRQ_IND_COMP)
 
+#define CQSPI_IRQ_MASK_RD_SLOW_SRAM	(CQSPI_REG_IRQ_WATERMARK	| \
+					 CQSPI_REG_IRQ_IND_COMP)
+
 #define CQSPI_IRQ_MASK_WR		(CQSPI_REG_IRQ_IND_COMP		| \
 					 CQSPI_REG_IRQ_WATERMARK	| \
 					 CQSPI_REG_IRQ_UNDERFLOW)
@@ -381,7 +384,7 @@ static irqreturn_t cqspi_irq_handler(int this_irq, void *dev)
 	else if (!cqspi->slow_sram)
 		irq_status &= CQSPI_IRQ_MASK_RD | CQSPI_IRQ_MASK_WR;
 	else
-		irq_status &= CQSPI_REG_IRQ_WATERMARK | CQSPI_IRQ_MASK_WR;
+		irq_status &= CQSPI_IRQ_MASK_RD_SLOW_SRAM | CQSPI_IRQ_MASK_WR;
 
 	if (irq_status)
 		complete(&cqspi->transfer_complete);
@@ -757,7 +760,7 @@ static int cqspi_indirect_read_execute(struct cqspi_flash_pdata *f_pdata,
 	 */
 
 	if (use_irq && cqspi->slow_sram)
-		writel(CQSPI_REG_IRQ_WATERMARK, reg_base + CQSPI_REG_IRQMASK);
+		writel(CQSPI_IRQ_MASK_RD_SLOW_SRAM, reg_base + CQSPI_REG_IRQMASK);
 	else if (use_irq)
 		writel(CQSPI_IRQ_MASK_RD, reg_base + CQSPI_REG_IRQMASK);
 	else
@@ -775,13 +778,6 @@ static int cqspi_indirect_read_execute(struct cqspi_flash_pdata *f_pdata,
 						 msecs_to_jiffies(CQSPI_READ_TIMEOUT_MS)))
 			ret = -ETIMEDOUT;
 
-		/*
-		 * Disable all read interrupts until
-		 * we are out of "bytes to read"
-		 */
-		if (cqspi->slow_sram)
-			writel(0x0, reg_base + CQSPI_REG_IRQMASK);
-
 		/*
 		 * Prevent lost interrupt and race condition by reinitializing early.
 		 * A spurious wakeup and another wait cycle can occur here,
@@ -820,11 +816,6 @@ static int cqspi_indirect_read_execute(struct cqspi_flash_pdata *f_pdata,
 			remaining -= bytes_to_read;
 			bytes_to_read = cqspi_get_rd_sram_level(cqspi);
 		}
-
-		if (use_irq && remaining > 0) {
-			if (cqspi->slow_sram)
-				writel(CQSPI_REG_IRQ_WATERMARK, reg_base + CQSPI_REG_IRQMASK);
-		}
 	}
 
 	/* Check indirect done status */

-- 
2.43.0

