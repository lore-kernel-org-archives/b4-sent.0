From: =?utf-8?q?F=C3=A9lix_Pi=C3=A9dallu?= <felix.piedallu@non.se.com>
Date: Fri, 06 Jun 2025 15:37:25 +0200
Subject: [PATCH 2/2] spi: omap2-mcspi: Disable multi-mode when the previous
 message kept CS asserted
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250606-cs_change_fix-v1-2-27191a98a2e5@non.se.com>
References: <20250606-cs_change_fix-v1-0-27191a98a2e5@non.se.com>
In-Reply-To: <20250606-cs_change_fix-v1-0-27191a98a2e5@non.se.com>
To: Mark Brown <broonie@kernel.org>, 
 Louis Chauvet <louis.chauvet@bootlin.com>
Cc: linux-spi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?F=C3=A9lix_Pi=C3=A9dallu?= <felix.piedallu@non.se.com>, 
 pascal.eberhard@se.com
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749217048; l=2225;
 i=felix.piedallu@non.se.com; s=20250606; h=from:subject:message-id;
 bh=ZfK7KhDeQVloCseH0ix7UHPadZvoLWxPnDeBOqVmuHc=;
 b=zAg37+l7LEpXbrIyD57QaE5LxdWhhzikt5JuQVFnSfTgdNHtR2dlVVo/MIXi+fh9L2k8bNtf+
 Csixkf4Oi5rAxvN/O43I2fBIZ7umaEKjlpquA+0lFQttGho9C/QsuWx
X-Developer-Key: i=felix.piedallu@non.se.com; a=ed25519;
 pk=Xe1dw6DIV7hmFbzuJfvaioG+S30kGix0QpIi5qPg99w=
X-Endpoint-Received: by B4 Relay for felix.piedallu@non.se.com/20250606 with auth_id=427
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the last transfer of a SPI message has the cs_change flag, the CS is kept
asserted after the message.
The next message can't use multi-mode because the CS will be briefly deasserted
before the first transfer.

Remove the early exit of the list_for_each_entry because the last transfer
actually needs to be always checked.

Fixes: d153ff4056cb ("spi: omap2-mcspi: Add support for MULTI-mode")
Signed-off-by: Félix Piédallu <felix.piedallu@non.se.com>
---
 drivers/spi/spi-omap2-mcspi.c | 20 ++++++++++----------
 1 file changed, 10 insertions(+), 10 deletions(-)

diff --git a/drivers/spi/spi-omap2-mcspi.c b/drivers/spi/spi-omap2-mcspi.c
index 05766b98de36f..4c5f12b76de6a 100644
--- a/drivers/spi/spi-omap2-mcspi.c
+++ b/drivers/spi/spi-omap2-mcspi.c
@@ -134,6 +134,7 @@ struct omap2_mcspi {
 	size_t			max_xfer_len;
 	u32			ref_clk_hz;
 	bool			use_multi_mode;
+	bool			last_msg_kept_cs;
 };
 
 struct omap2_mcspi_cs {
@@ -1269,6 +1270,10 @@ static int omap2_mcspi_prepare_message(struct spi_controller *ctlr,
 	 * multi-mode is applicable.
 	 */
 	mcspi->use_multi_mode = true;
+
+	if (mcspi->last_msg_kept_cs)
+		mcspi->use_multi_mode = false;
+
 	list_for_each_entry(tr, &msg->transfers, transfer_list) {
 		if (!tr->bits_per_word)
 			bits_per_word = msg->spi->bits_per_word;
@@ -1289,22 +1294,17 @@ static int omap2_mcspi_prepare_message(struct spi_controller *ctlr,
 
 		if (list_is_last(&tr->transfer_list, &msg->transfers)) {
 			/* Check if transfer asks to keep the CS status after the whole message */
-			if (tr->cs_change)
+			if (tr->cs_change) {
 				mcspi->use_multi_mode = false;
+				mcspi->last_msg_kept_cs = true;
+			} else {
+				mcspi->last_msg_kept_cs = false;
+			}
 		} else {
 			/* Check if transfer asks to change the CS status after the transfer */
 			if (!tr->cs_change)
 				mcspi->use_multi_mode = false;
 		}
-
-		/*
-		 * If at least one message is not compatible, switch back to single mode
-		 *
-		 * The bits_per_word of certain transfer can be different, but it will have no
-		 * impact on the signal itself.
-		 */
-		if (!mcspi->use_multi_mode)
-			break;
 	}
 
 	omap2_mcspi_set_mode(ctlr);

-- 
2.43.0

