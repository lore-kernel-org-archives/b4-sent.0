From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Thu, 23 Jul 2026 06:43:43 +0000
Subject: [PATCH v2 2/4] spi: amlogic: spisg: Fix transfer size limit and
 timeout handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-a9-spisg-v2-2-9fc39106b7e2@amlogic.com>
References: <20260723-a9-spisg-v2-0-9fc39106b7e2@amlogic.com>
In-Reply-To: <20260723-a9-spisg-v2-0-9fc39106b7e2@amlogic.com>
To: Sunny Luo <sunny.luo@amlogic.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-spi@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784789030; l=1947;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=BRq2nLOiEjtiR+0vj/uM6L8HPr1w32uaAGwS/r33K78=;
 b=PgCQZw3mX0UQF39rzre8XLicz8qQXc+g7Wvu8j+DV8pNFDId2rQQuwKINbqgS1PSUnglS1j7Y
 rUOXJreyVG8Aj2RH0Hk9o4kRGLtkgtqyt+v3Unci8I/MoDGBXl26Svo
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The CFG_BLOCK_NUM field can encode at most 20 bits, so reduce
SPISG_BLOCK_MAX to 0xfffff to avoid programming a zero-length transfer.

Perform the delay calculation in 64-bit arithmetic to avoid overflow
when converting nanoseconds to SPI clock cycles.

Stop the controller on transfer timeout by clearing the descriptor list
register before returning an error.

Fixes: cef9991e04ae ("spi: Add Amlogic SPISG driver")
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 drivers/spi/spi-amlogic-spisg.c | 11 +++++++----
 1 file changed, 7 insertions(+), 4 deletions(-)

diff --git a/drivers/spi/spi-amlogic-spisg.c b/drivers/spi/spi-amlogic-spisg.c
index afc8af04638d..a6123975a37c 100644
--- a/drivers/spi/spi-amlogic-spisg.c
+++ b/drivers/spi/spi-amlogic-spisg.c
@@ -95,7 +95,7 @@
 
 #define SPISG_MAX_REG			0x40
 
-#define SPISG_BLOCK_MAX			0x100000
+#define SPISG_BLOCK_MAX			0xFFFFF
 
 #define SPISG_OP_MODE_WRITE_CMD		0
 #define SPISG_OP_MODE_READ_STS		1
@@ -175,7 +175,7 @@ static int spi_delay_to_sclk(u32 slck_speed_hz, struct spi_delay *delay)
 	if (ns < 0)
 		return 0;
 
-	return DIV_ROUND_UP_ULL(slck_speed_hz * ns, NSEC_PER_SEC);
+	return DIV_ROUND_UP_ULL((u64)slck_speed_hz * ns, NSEC_PER_SEC);
 }
 
 static inline u32 aml_spisg_sem_down_read(struct spisg_device *spisg)
@@ -565,10 +565,13 @@ static int aml_spisg_transfer_one_message(struct spi_controller *ctlr,
 	aml_spisg_pending(spisg, descs_paddr, false, true);
 	if (wait_for_completion_timeout(&spisg->completion,
 					spi_controller_is_target(spisg->controller) ?
-					MAX_SCHEDULE_TIMEOUT : msecs_to_jiffies(ms)))
+					MAX_SCHEDULE_TIMEOUT : msecs_to_jiffies(ms))) {
 		ret = spisg->status ? -EIO : 0;
-	else
+	} else {
+		/* stop transfer */
+		regmap_write(spisg->map, SPISG_REG_DESC_LIST_H, 0);
 		ret = -ETIMEDOUT;
+	}
 
 	dma_unmap_single(dev, descs_paddr, descs_len, DMA_TO_DEVICE);
 end:

-- 
2.52.0

