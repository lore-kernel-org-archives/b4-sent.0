From: Janne Grunau <j@jannau.net>
Date: Mon, 11 Mar 2024 23:53:17 +0100
Subject: [PATCH] spi: Restore delays for non-GPIO chip select
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240311-spi-cs-delays-regression-v1-1-0075020a90b2@jannau.net>
X-B4-Tracking: v=1; b=H4sIAFyL72UC/x3MQQqDQAxG4atI1gZmtCD2KuJCZv5oQKwkIIp49
 067fIvv3eQwhdO7uslwqOtnKxHritIybTNYc2lqQvMKbYzsu3Jyzliny9kwG/yHWHLXhl5SgAg
 VvhtEz/96GJ/nC/j50RJqAAAA
To: Mark Brown <broonie@kernel.org>, 
 Amit Kumar Mahapatra <amit.kumar-mahapatra@amd.com>
Cc: linux-spi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, regressions@lists.linux.dev, 
 Janne Grunau <j@jannau.net>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2363; i=j@jannau.net;
 h=from:subject:message-id; bh=wRDHwpl4qwb+1xQqHZ8GOwHiYZo9FyBukC2YvocLxcw=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhtT33cnaglMK9z3v/5Ym+9av/Lh+ZOKhvpkPEnPUTv9Y3
 WD/Nsmxo5SFQYyLQVZMkSVJ+2UHw+oaxZjaB2Ewc1iZQIYwcHEKwETK9jMyPH+/Y1rw509F7TK7
 T/GczXKfLBL79yDLk0TrGUv770x8zsTwT3mqVBW36BrJytNsylktK66xHPS5pqdsN3FpxSL+WJP
 T/AA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SPI controller with integrated chip select handling still need to adhere
to SPI device's CS setup, hold and inactive delays. For controller
without set_cs_timing spi core shall handle the delays to avoid
duplicated delay handling in each controller driver.
Fixes a regression for the out of tree SPI controller and SPI HID
transport on Apple M1/M1 Pro/Max notebooks.

Fixes: 4d8ff6b0991d ("spi: Add multi-cs memories support in SPI core")
Signed-off-by: Janne Grunau <j@jannau.net>
---
#regzbot ^introduced 4d8ff6b0991d5e86b17b235fc46ec62e9195cb9
---
 drivers/spi/spi.c | 24 ++++++++++++++----------
 1 file changed, 14 insertions(+), 10 deletions(-)

diff --git a/drivers/spi/spi.c b/drivers/spi/spi.c
index f2170f4b5077..71be2ba8402f 100644
--- a/drivers/spi/spi.c
+++ b/drivers/spi/spi.c
@@ -1042,10 +1042,14 @@ static void spi_set_cs(struct spi_device *spi, bool enable, bool force)
 	if (spi->mode & SPI_CS_HIGH)
 		enable = !enable;
 
-	if (spi_is_csgpiod(spi)) {
-		if (!spi->controller->set_cs_timing && !activate)
-			spi_delay_exec(&spi->cs_hold, NULL);
+	/*
+	 * Handle chip select delays for GPIO based CS or controllers without
+	 * programmable chip select timing.
+	 */
+	if ((spi_is_csgpiod(spi) || !spi->controller->set_cs_timing) && !activate)
+		spi_delay_exec(&spi->cs_hold, NULL);
 
+	if (spi_is_csgpiod(spi)) {
 		if (!(spi->mode & SPI_NO_CS)) {
 			/*
 			 * Historically ACPI has no means of the GPIO polarity and
@@ -1079,16 +1083,16 @@ static void spi_set_cs(struct spi_device *spi, bool enable, bool force)
 		if ((spi->controller->flags & SPI_CONTROLLER_GPIO_SS) &&
 		    spi->controller->set_cs)
 			spi->controller->set_cs(spi, !enable);
-
-		if (!spi->controller->set_cs_timing) {
-			if (activate)
-				spi_delay_exec(&spi->cs_setup, NULL);
-			else
-				spi_delay_exec(&spi->cs_inactive, NULL);
-		}
 	} else if (spi->controller->set_cs) {
 		spi->controller->set_cs(spi, !enable);
 	}
+
+	if (spi_is_csgpiod(spi) || !spi->controller->set_cs_timing) {
+		if (activate)
+			spi_delay_exec(&spi->cs_setup, NULL);
+		else
+			spi_delay_exec(&spi->cs_inactive, NULL);
+	}
 }
 
 #ifdef CONFIG_HAS_DMA

---
base-commit: e8f897f4afef0031fe618a8e94127a0934896aba
change-id: 20240311-spi-cs-delays-regression-fd7309fc0eff

Best regards,
-- 
Janne Grunau <j@jannau.net>

