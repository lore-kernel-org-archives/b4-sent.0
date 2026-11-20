From: Rong Chen <rong.chen@amlogic.com>
Date: Fri, 20 Nov 2026 13:53:23 +0800
Subject: [PATCH] mmc: meson-gx: Add reset for Response Mode Error Mask
 (RMEM)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-a4_mmc-v1-1-5a84cbcdcace@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAFLg/2oC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQyMD3UST+NzcZN2UFJMkyyRjs+QkAwMloOKCotS0zAqwQdGxtbUAKoW
 1klgAAAA=
X-Change-ID: 20261120-a4_mmc-dd4b9b36cb00
To: Ulf Hansson <ulfh@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-mmc@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rong Chen <rong.chen@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795154005; l=1328;
 i=rong.chen@amlogic.com; s=20261116; h=from:subject:message-id;
 bh=ldcBzSWY8qmDPf31J18ds1oMT+JS17QVuWgrGqm9XrQ=;
 b=vUz2tYdPH+vzuS5s+wTBf+hkZRqWYYUyOdbqg+YHDpmn5FeQ9cDaWszezykoMJ1UlbazSXAHf
 h8TBoKOe9beBd9UcK2PbvOvH2MvbmouhGCLdFdEwtpaXhSYmstq5V9C
X-Developer-Key: i=rong.chen@amlogic.com; a=ed25519;
 pk=vFtPE1jHKfpAuk10u/dq9u25ZzVsUM3t2Sew8vz0YWc=
X-Endpoint-Received: by B4 Relay for rong.chen@amlogic.com/20261116 with auth_id=1539
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For T7 and older SoC families, the RMEM has no effect. Starting from
the SoC family A4, RMEM acts as an interrupt mask for the device status
field received in R1/R1b responses.

By setting RMEM to zero, the device status is ignored, thereby
preventing controller hangs caused by spurious IRQs under specific
device states.

Signed-off-by: Rong Chen <rong.chen@amlogic.com>
---
 drivers/mmc/host/meson-gx-mmc.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/mmc/host/meson-gx-mmc.c b/drivers/mmc/host/meson-gx-mmc.c
index 49df33bbd8e5..9d9b00b199b6 100644
--- a/drivers/mmc/host/meson-gx-mmc.c
+++ b/drivers/mmc/host/meson-gx-mmc.c
@@ -113,6 +113,7 @@
 #define SD_EMMC_CMD_RSP1 0x60
 #define SD_EMMC_CMD_RSP2 0x64
 #define SD_EMMC_CMD_RSP3 0x68
+#define SD_EMMC_CMD_RMEM 0x150
 
 #define SD_EMMC_RXD 0x94
 #define SD_EMMC_TXD 0x94
@@ -1086,6 +1087,9 @@ static void meson_mmc_cfg_init(struct meson_host *host)
 	cfg |= CFG_ERR_ABORT;
 
 	writel(cfg, host->regs + SD_EMMC_CFG);
+
+	/* ignore status in response */
+	writel(0x0, host->regs + SD_EMMC_CMD_RMEM);
 }
 
 static int meson_mmc_card_busy(struct mmc_host *mmc)

---
base-commit: d2616724e01132376c78872b8324f38659af9f28
change-id: 20261120-a4_mmc-dd4b9b36cb00

Best regards,
-- 
Rong Chen <rong.chen@amlogic.com>

