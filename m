From: Igor Velkov <iav@iav.lv>
Date: Fri, 27 Nov 2026 04:55:38 +0200
Subject: [PATCH] spi: meson-spifc: round the clock divider up
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-b4-meson-spifc-div-round-up-v1-1-e927ca0d0c8a@iav.lv>
X-B4-Tracking: v=1; b=H4sIACnxCGsC/x3MQQqAIBAAwK/EnltIicS+Eh1Mt9pDKi5FEP096
 TiXeUCoMAmMzQOFLhZOsUK1DfjdxY2QQzXoTg9KaYNLjwdJiiiZV4+BLyzpjAHPjC4s1nhlh84
 R1CEXWvn+92l+3w8UV6PabQAAAA==
To: Mark Brown <broonie@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-spi@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2042; i=iav@iav.lv;
 h=from:subject:message-id; bh=Rt0Bq6tvIo11qsWLzpWdcysvdzpavIURklDKm0ZG7KU=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDNkcH7Vn5T2fc+jIndtfvNcseRUx354tb1oeZ5dpHstfM
 cvUvyv+dZSyMIhxMciKKbJMOKRxK2PJ1b/+HuYPYOawMoEMYeDiFICJ3K5kZNg+NfdMdEWT65lc
 ZiaJbFbjb/21h177BqY8Fr0zp7CQ8yrD/9Czqnc+pD//5+elwOx9LngOq7jkBfPFr1LKNeK2/E/
 8xQgA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

meson_spifc_setup_speed() computes the divider as parent / speed - 1,
which rounds the divisor down and makes SCLK faster than requested.
On ODROID-N2+ (clk81 222.2 MHz) a 104 MHz spi-max-frequency gives
n = 1 and SCLK = 111.1 MHz.

Round the divisor up so SCLK does not exceed the requested rate, and
round min_speed_hz and max_speed_hz up to match: with an odd parent
rate, rate >> 1 would need n = 2 instead of 1, and rate >> 6 would
need n = 64, which does not fit the 6-bit divider field.

Fixes: c3e4bc5434d2 ("spi: meson: Add support for Amlogic Meson SPIFC")
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on ODROID-N2+ with the patch on 7.3.6: for 104 MHz REG_CLOCK
goes from 0x1001 to 0x2002 (SCLK 111 -> 74 MHz). The board's
MX25U6435F read with READ (03h) misread 36 of 50 4 KiB blocks before,
0 of 200 after.
---
 drivers/spi/spi-meson-spifc.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/spi/spi-meson-spifc.c b/drivers/spi/spi-meson-spifc.c
index 1580797f4a84..865440793a8b 100644
--- a/drivers/spi/spi-meson-spifc.c
+++ b/drivers/spi/spi-meson-spifc.c
@@ -168,7 +168,7 @@ static void meson_spifc_setup_speed(struct meson_spifc *spifc, u32 speed)
 	int n;
 
 	parent = clk_get_rate(spifc->clk);
-	n = max_t(int, parent / speed - 1, 1);
+	n = max_t(int, DIV_ROUND_UP(parent, speed) - 1, 1);
 
 	dev_dbg(spifc->dev, "parent %lu, speed %u, n %d\n", parent,
 		speed, n);
@@ -320,8 +320,8 @@ static int meson_spifc_probe(struct platform_device *pdev)
 	host->bits_per_word_mask = SPI_BPW_MASK(8);
 	host->auto_runtime_pm = true;
 	host->transfer_one = meson_spifc_transfer_one;
-	host->min_speed_hz = rate >> 6;
-	host->max_speed_hz = rate >> 1;
+	host->min_speed_hz = DIV_ROUND_UP(rate, 64);
+	host->max_speed_hz = DIV_ROUND_UP(rate, 2);
 
 	meson_spifc_hw_init(spifc);
 

---
base-commit: 63083539d2bf955ccf84042d4b044d1133752bed
change-id: 20261127-b4-meson-spifc-div-round-up-adb97c1960ae

Best regards,
-- 
Igor Velkov <iav@iav.lv>

