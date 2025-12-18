From: Mateusz Litwin <mateusz.litwin@nokia.com>
Date: Thu, 18 Dec 2025 22:33:04 +0100
Subject: [PATCH v2 1/2] spi: cadence-quadspi: Prevent lost complete() call
 during indirect read
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251218-cqspi_indirect_read_improve-v2-1-396079972f2a@nokia.com>
References: <20251218-cqspi_indirect_read_improve-v2-0-396079972f2a@nokia.com>
In-Reply-To: <20251218-cqspi_indirect_read_improve-v2-0-396079972f2a@nokia.com>
To: Mark Brown <broonie@kernel.org>
Cc: linux-spi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mateusz Litwin <mateusz.litwin@nokia.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766093707; l=2014;
 i=mateusz.litwin@nokia.com; s=20251217; h=from:subject:message-id;
 bh=idoBq4rF6Q69PiKVn5u/tYsDt9xIXPjO/l/HiqJtOWY=;
 b=6r95aUUM4dSqa65hhpy12h1ymd/dXj56QaT8LzPcDE1Rlq88MbJov48zh0UmGrsIGps1+x7PP
 6oPn3ZuSCluDSv0taiStN2nhtXj4gh3VA4E/4eb9OKXCrpdq055UGLn
X-Developer-Key: i=mateusz.litwin@nokia.com; a=ed25519;
 pk=9NV76cwWrtwYUektOrK/ht9GTzmhtkqSvghr3Td4hM4=
X-Endpoint-Received: by B4 Relay for mateusz.litwin@nokia.com/20251217 with auth_id=579
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A race condition exists between the read loop and IRQ `complete()` call.
An interrupt could call the complete() between the inner loop and
reinit_completion(), potentially losing the completion event and causing
an unnecessary timeout. Moving reinit_completion() before the loop
prevents this. A premature signal will only result in a spurious wakeup
and another wait cycle, which is preferable to waiting for a timeout.

Signed-off-by: Mateusz Litwin <mateusz.litwin@nokia.com>
---
 drivers/spi/spi-cadence-quadspi.c | 10 +++++++++-
 1 file changed, 9 insertions(+), 1 deletion(-)

diff --git a/drivers/spi/spi-cadence-quadspi.c b/drivers/spi/spi-cadence-quadspi.c
index a390b1815fde..02d1ff53e61d 100644
--- a/drivers/spi/spi-cadence-quadspi.c
+++ b/drivers/spi/spi-cadence-quadspi.c
@@ -769,6 +769,7 @@ static int cqspi_indirect_read_execute(struct cqspi_flash_pdata *f_pdata,
 	readl(reg_base + CQSPI_REG_INDIRECTRD); /* Flush posted write. */
 
 	while (remaining > 0) {
+		ret = 0;
 		if (use_irq &&
 		    !wait_for_completion_timeout(&cqspi->transfer_complete,
 						 msecs_to_jiffies(CQSPI_READ_TIMEOUT_MS)))
@@ -781,6 +782,14 @@ static int cqspi_indirect_read_execute(struct cqspi_flash_pdata *f_pdata,
 		if (cqspi->slow_sram)
 			writel(0x0, reg_base + CQSPI_REG_IRQMASK);
 
+		/*
+		 * Prevent lost interrupt and race condition by reinitializing early.
+		 * A spurious wakeup and another wait cycle can occur here,
+		 * which is preferable to waiting until timeout if interrupt is lost.
+		 */
+		if (use_irq)
+			reinit_completion(&cqspi->transfer_complete);
+
 		bytes_to_read = cqspi_get_rd_sram_level(cqspi);
 
 		if (ret && bytes_to_read == 0) {
@@ -813,7 +822,6 @@ static int cqspi_indirect_read_execute(struct cqspi_flash_pdata *f_pdata,
 		}
 
 		if (use_irq && remaining > 0) {
-			reinit_completion(&cqspi->transfer_complete);
 			if (cqspi->slow_sram)
 				writel(CQSPI_REG_IRQ_WATERMARK, reg_base + CQSPI_REG_IRQMASK);
 		}

-- 
2.43.0

