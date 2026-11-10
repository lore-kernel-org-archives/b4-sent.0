From: Igor Velkov <iav@iav.lv>
Date: Tue, 10 Nov 2026 04:30:24 +0000
Subject: [PATCH] clk: rockchip: rk356x: Set twice the SD/SDIO card clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-rk3568-sdmmc-clk-v1-1-482eeb42f571@iav.lv>
X-B4-Tracking: v=1; b=H4sIAN+d8moC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0MD3aJsY1MzC93ilNzcZN3knGxdS9Ok5OTEVHMjI3NzJaC2gqLUtMw
 KsJHRsbW1ANN1e+hiAAAA
To: Kever Yang <kever.yang@rock-chips.com>, 
 Quentin Schulz <u-boot@0leil.net>
Cc: Simon Glass <sjg@chromium.org>, Lukasz Majewski <lukma@nabladev.com>, 
 Tom Rini <trini@konsulko.com>, Elaine Zhang <zhangqing@rock-chips.com>, 
 Jonas Karlman <jonas@kwiboo.se>, u-boot@lists.u-boot-project.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3285; i=iav@iav.lv;
 h=from:subject:message-id; bh=R2OKm69sEn6Alznt2gmTcH5ZSpX61IlnRP6pIL+WazA=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFmf5j5I7Vh+ziZF11Lp3h6ZSPlkUT2l5QuUjn2q5Vj8Y
 gc/p/rijlIWBjEuBlkxRZYJhzRuZSy5+tffw/wBzBxWJpAhDFycAjCRNe4M//PiT7768bac/ezU
 M+vnM/zebL9GNml1xP81eS6Nma3TvJQY/lklpr0M07OXqRJQCj7kduD2uceXbul1rO3iuiFafaX
 jISsA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The dw_mmc controllers divide their input clock by 2, but
rk3568_sdmmc_set_clk() selects a parent equal to the requested card
clock, so the card runs at half of it: 25 MHz instead of 50 MHz in high
speed mode. The RK3399 and RK3328 clock drivers already set twice the
rate for their dw_mmc controllers.

Select the fastest parent that does not exceed twice the requested
rate, or the slowest one, and report half of the parent rate.

On ODROID-M1 with a SanDisk 128 GB card in high speed mode, reading
512 MiB with mmc read takes 22 s instead of 44 s.

Fixes: 4a262feba3a5 ("rockchip: rk3568: add clock driver")
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on ODROID-M1 with this change on v2026.07: CLKSEL_CON(30) selects
the 100 MHz parent for a 50 MHz card clock. The CRC32 of a 512 MiB block
read with mmc read is the same at 25 and 50 MHz, and the CRC32 of another
block is the same as computed in Linux. With the SPL erased from SPI, SPL
and U-Boot load from the SD card, also after two resets with sysrq-b.
---
 drivers/clk/rockchip/clk_rk3568.c | 43 +++++++++++++++------------------------
 1 file changed, 16 insertions(+), 27 deletions(-)

diff --git a/drivers/clk/rockchip/clk_rk3568.c b/drivers/clk/rockchip/clk_rk3568.c
index 181917cf92a..06d7d4741c6 100644
--- a/drivers/clk/rockchip/clk_rk3568.c
+++ b/drivers/clk/rockchip/clk_rk3568.c
@@ -1426,19 +1426,20 @@ static ulong rk3568_sdmmc_get_clk(struct rk3568_clk_priv *priv, ulong clk_id)
 		return -ENOENT;
 	}
 
+	/* The card clock is half of the parent: dw_mmc divides it by 2 */
 	switch (sel) {
 	case CLK_SDMMC_SEL_24M:
-		return OSC_HZ;
+		return OSC_HZ / 2;
 	case CLK_SDMMC_SEL_400M:
-		return 400 * MHz;
+		return 400 * MHz / 2;
 	case CLK_SDMMC_SEL_300M:
-		return 300 * MHz;
+		return 300 * MHz / 2;
 	case CLK_SDMMC_SEL_100M:
-		return 100 * MHz;
+		return 100 * MHz / 2;
 	case CLK_SDMMC_SEL_50M:
-		return 50 * MHz;
+		return 50 * MHz / 2;
 	case CLK_SDMMC_SEL_750K:
-		return 750 * KHz;
+		return 750 * KHz / 2;
 	default:
 		return -ENOENT;
 	}
@@ -1448,34 +1449,22 @@ static ulong rk3568_sdmmc_set_clk(struct rk3568_clk_priv *priv,
 				  ulong clk_id, ulong rate)
 {
 	struct rk3568_cru *cru = priv->cru;
+	ulong parent = rate * 2;
 	int src_clk;
 
-	switch (rate) {
-	case OSC_HZ:
-	case 26 * MHz:
-	case 25 * MHz:
-		src_clk = CLK_SDMMC_SEL_24M;
-		break;
-	case 400 * MHz:
+	/* Fastest parent not above twice the card clock, or the slowest one */
+	if (parent >= 400 * MHz)
 		src_clk = CLK_SDMMC_SEL_400M;
-		break;
-	case 300 * MHz:
+	else if (parent >= 300 * MHz)
 		src_clk = CLK_SDMMC_SEL_300M;
-		break;
-	case 100 * MHz:
+	else if (parent >= 100 * MHz)
 		src_clk = CLK_SDMMC_SEL_100M;
-		break;
-	case 52 * MHz:
-	case 50 * MHz:
+	else if (parent >= 50 * MHz)
 		src_clk = CLK_SDMMC_SEL_50M;
-		break;
-	case 750 * KHz:
-	case 400 * KHz:
+	else if (parent >= OSC_HZ)
+		src_clk = CLK_SDMMC_SEL_24M;
+	else
 		src_clk = CLK_SDMMC_SEL_750K;
-		break;
-	default:
-		return -ENOENT;
-	}
 
 	switch (clk_id) {
 	case HCLK_SDMMC0:

---
base-commit: ecdcf9e365df6249a57cd8cc946e7026804ff4ae
change-id: 20261110-rk3568-sdmmc-clk-95bccae72277

Best regards,
-- 
Igor Velkov <iav@iav.lv>

