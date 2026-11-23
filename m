From: Radu Sabau <radu.sabau@analog.com>
Date: Mon, 23 Nov 2026 15:25:31 +0200
Subject: [PATCH 7/7] iio: imu: adis16607: Report loss of external sync
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-adis-fifo-v1-7-f6ad9e493e19@analog.com>
References: <20261123-adis-fifo-v1-0-f6ad9e493e19@analog.com>
In-Reply-To: <20261123-adis-fifo-v1-0-f6ad9e493e19@analog.com>
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Ramona Gradinariu <ramona.bolboaca13@gmail.com>, 
 Radu Sabau <radu.sabau@analog.com>
Cc: linux-iio@vger.kernel.org, linux@analog.com, 
 linux-kernel@vger.kernel.org, Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795440327; l=1798;
 i=radu.sabau@analog.com; s=20261001; h=from:subject:message-id;
 bh=Cp1Fu3Up9G3W8L90aBKjL0TvrVLAhTasEOIocguqkbg=;
 b=M4ct0O7E+ID8rn8AVHwZd2n77cUbhjyYPlkWuVA4RUjG+s5vsLCBsQgz0NLgB8/cpLjPdRsny
 aG97jOW3yyPBxvzot11SWkG/K5oz0IykH+OJ4b0wz9WLUZgt/Vng3sl
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=XOZSO/Ut8qfYw7khL8lUF65Pgl+VLihISyS+Iy9jY8c=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20261001 with auth_id=1094
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Loss of the external clock or of the sync PLL lock raises DEV_NOK like any
other DIAG_STAT flag, and the interrupt handler already reads DIAG_STAT.
Warn about SYNC_LOST and DPLL_UNLOCKED there, rate limited, without
stopping the capture, since a short loss of the clock can recover. An
interrupt raised by one of these flags is handled even when the FIFO
threshold is not met.

Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 drivers/iio/imu/adis16607.c | 15 ++++++++++++++-
 1 file changed, 14 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/imu/adis16607.c b/drivers/iio/imu/adis16607.c
index 60433c97a855..dddbe3c7fb52 100644
--- a/drivers/iio/imu/adis16607.c
+++ b/drivers/iio/imu/adis16607.c
@@ -83,6 +83,10 @@
 #define ADIS16607_FIFO_THR_MET_MASK	BIT(0)
 #define ADIS16607_FIFO_DATA_CMD		0xA9
 
+/* DIAG_STAT sync flags */
+#define ADIS16607_DIAG_DPLL_UNLOCKED	BIT(1)
+#define ADIS16607_DIAG_SYNC_LOST	BIT(2)
+
 /* FIFO limits */
 #define ADIS16607_MAX_FIFO_WM		38
 #define ADIS16607_FIFO_WORDS_PER_SAMPLE	26
@@ -396,8 +400,17 @@ static irqreturn_t adis16607_irq_thread(int irq, void *p)
 	if (ret)
 		return IRQ_HANDLED;
 
+	/* Only warn: a short loss of the clock should not stop the capture */
+	if (diag_stat & ADIS16607_DIAG_SYNC_LOST)
+		dev_warn_ratelimited(&st->adis.spi->dev, "external sync lost\n");
+
+	if (diag_stat & ADIS16607_DIAG_DPLL_UNLOCKED)
+		dev_warn_ratelimited(&st->adis.spi->dev, "sync PLL unlocked\n");
+
 	if (!(diag_stat & ADIS16607_FIFO_THR_MET_MASK))
-		return IRQ_NONE;
+		return diag_stat & (ADIS16607_DIAG_SYNC_LOST |
+				    ADIS16607_DIAG_DPLL_UNLOCKED) ?
+		       IRQ_HANDLED : IRQ_NONE;
 
 	ret = __adis_read_reg_16(&st->adis, ADIS16607_REG_FIFO_WORD_CNT, &word_cnt);
 	if (ret)

-- 
2.43.0

