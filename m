From: =?utf-8?q?F=C3=A9lix_Pi=C3=A9dallu?= <felix.piedallu@non.se.com>
Date: Fri, 06 Jun 2025 15:37:24 +0200
Subject: [PATCH 1/2] spi: omap2-mcspi: Disable multi mode when CS should be
 kept asserted after message
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250606-cs_change_fix-v1-1-27191a98a2e5@non.se.com>
References: <20250606-cs_change_fix-v1-0-27191a98a2e5@non.se.com>
In-Reply-To: <20250606-cs_change_fix-v1-0-27191a98a2e5@non.se.com>
To: Mark Brown <broonie@kernel.org>, 
 Louis Chauvet <louis.chauvet@bootlin.com>
Cc: linux-spi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?F=C3=A9lix_Pi=C3=A9dallu?= <felix.piedallu@non.se.com>, 
 pascal.eberhard@se.com
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749217048; l=1438;
 i=felix.piedallu@non.se.com; s=20250606; h=from:subject:message-id;
 bh=JnAoqQPfwv0/3qSqrSpr+Emp+bDl4r2kMZHc5R7JQHQ=;
 b=8Ly+pvHTwUY2wFGqufeGI2YcF55VFo+rqbUDf1C5kiDONvrNB6+y6N6gl5YdAjDtCD3poym5O
 Ld5KT/ZUM/yDjrWLG8AjzZEGZcDAHgB3oXXN3oIGQ1wYZiSfUeASf8F
X-Developer-Key: i=felix.piedallu@non.se.com; a=ed25519;
 pk=Xe1dw6DIV7hmFbzuJfvaioG+S30kGix0QpIi5qPg99w=
X-Endpoint-Received: by B4 Relay for felix.piedallu@non.se.com/20250606 with auth_id=427
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the last transfer of a SPI message has the cs_change flag, the CS is kept
asserted after the message.
Multi-mode can't respect this as CS is deasserted by the hardware at the end of
the message.

Disable multi-mode when not applicable to the current message.

Fixes: d153ff4056cb ("spi: omap2-mcspi: Add support for MULTI-mode")
Signed-off-by: Félix Piédallu <felix.piedallu@non.se.com>
---
 drivers/spi/spi-omap2-mcspi.c | 12 +++++++++---
 1 file changed, 9 insertions(+), 3 deletions(-)

diff --git a/drivers/spi/spi-omap2-mcspi.c b/drivers/spi/spi-omap2-mcspi.c
index 532b2e9c31d0d..05766b98de36f 100644
--- a/drivers/spi/spi-omap2-mcspi.c
+++ b/drivers/spi/spi-omap2-mcspi.c
@@ -1287,9 +1287,15 @@ static int omap2_mcspi_prepare_message(struct spi_controller *ctlr,
 			mcspi->use_multi_mode = false;
 		}
 
-		/* Check if transfer asks to change the CS status after the transfer */
-		if (!tr->cs_change)
-			mcspi->use_multi_mode = false;
+		if (list_is_last(&tr->transfer_list, &msg->transfers)) {
+			/* Check if transfer asks to keep the CS status after the whole message */
+			if (tr->cs_change)
+				mcspi->use_multi_mode = false;
+		} else {
+			/* Check if transfer asks to change the CS status after the transfer */
+			if (!tr->cs_change)
+				mcspi->use_multi_mode = false;
+		}
 
 		/*
 		 * If at least one message is not compatible, switch back to single mode

-- 
2.43.0

