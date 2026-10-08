From: Igor Velkov <iav@iav.lv>
Date: Thu, 08 Oct 2026 07:26:56 +0300
Subject: [PATCH] mmc: meson-gx: honour the busy timeout for R1b commands
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-meson-gx-busy-timeout-v1-1-d92f3c68c409@iav.lv>
X-B4-Tracking: v=1; b=H4sIAI8bx2oC/x3MSwqEMBBF0a1IjS2IhtamtyIO/Dy1BiaSMqKIe
 +/g8AzuvUkRBEq/7KaAQ1S8SyjyjIalczNYxmQqTVkVxnx4hXrH88l91It3WeHjzjW+sNM49Ba
 WUrsFTHK+36Z9nj8F1fTsZwAAAA==
To: Ulf Hansson <ulfh@kernel.org>
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 linux-mmc@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3870; i=iav@iav.lv;
 h=from:subject:message-id; bh=T7oobr9NpP0BRx9jjcdEGQ9sD4psJISkXHbN62KiO2U=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFnHpSe9NV/Q+DxiwluPyffc47acXirLP3tx2Rl21gdl6
 TPWBr237ShlYRDjYpAVU2SZcEjjVsaSq3/9PcwfwMxhZQIZwsDFKQATufaAkeFG2p0pt2wvqLDX
 LL+q6Ne3cYG+pnV6ecrBjpcvpDwmRnMw/A9nsoy8N+dx0Dpukd91x6dIz9w7hdvgxC4rxU32+84
 9duEEAA==
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For a command without data the driver programs a fixed 1024 ms into the
CMD_CFG timeout field, and for R1b the controller waits for the card to
release busy within that time. The driver does not set max_busy_timeout,
so the core sends erase and cache flush as R1b with busy timeouts of up
to 60 s and 30 s, and the controller gives up after one second:

  mmc_erase: erase error -110, status 0x0
  mmc1: cache flush error -110

Program the timeout from cmd->busy_timeout, rounded up to a power of
two and kept within 1024..32768 ms, and report 32768 ms, the largest
value the field holds, as max_busy_timeout. The core then sizes discards
to fit and, for a longer wait, sends R1 and polls for busy itself.
sdhci takes its command timeout from cmd->busy_timeout in the same way.

Fixes: 51c5d8447bd7 ("MMC: meson: initial support for GX platforms")
Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on ODROID-N2+ (S922X), 256 GB eMMC, btrfs root with discard=async, Armbian builds in docker as load.
Without the patch (7.3-rc6): 262 errors in 3 h and 68 in 2.5 h in two runs; the first came 4 and 43 min into the build.
With the patch (7.3-rc6): 0 in 2.4 h.
On 7.1 with the previous eMMC module, a synthetic test (20 GiB write + fstrim) gave 48 errors without the patch, 0 and 0 with it.

The timeout is rounded up to a power of two: the field holds powers of two only, and the timeout is a lower bound.
MMC_CAP_WAIT_WHILE_BUSY is not set: I have not checked that the controller waits for busy on every R1b command, HS400 switches included.
---
 drivers/mmc/host/meson-gx-mmc.c | 22 ++++++++++++++++++++--
 1 file changed, 20 insertions(+), 2 deletions(-)

diff --git a/drivers/mmc/host/meson-gx-mmc.c b/drivers/mmc/host/meson-gx-mmc.c
index 7ef16d7c03cb..8de3eb65ccb0 100644
--- a/drivers/mmc/host/meson-gx-mmc.c
+++ b/drivers/mmc/host/meson-gx-mmc.c
@@ -125,6 +125,7 @@
 #define SD_EMMC_CFG_RESP_TIMEOUT 256 /* in clock cycles */
 #define SD_EMMC_CMD_TIMEOUT 1024 /* in ms */
 #define SD_EMMC_CMD_TIMEOUT_DATA 4096 /* in ms */
+#define SD_EMMC_CMD_TIMEOUT_MAX 32768 /* in ms, 2^15: limit of CMD_CFG_TIMEOUT_MASK */
 #define SD_EMMC_CFG_CMD_GAP 16 /* in clock cycles */
 #define SD_EMMC_DESC_BUF_LEN PAGE_SIZE
 
@@ -212,7 +213,21 @@ static unsigned int meson_mmc_get_timeout_msecs(struct mmc_data *data)
 
 	timeout = roundup_pow_of_two(timeout);
 
-	return min(timeout, 32768U); /* max. 2^15 ms */
+	return min_t(unsigned int, timeout, SD_EMMC_CMD_TIMEOUT_MAX);
+}
+
+/* For R1b the controller waits for busy to be released within this timeout. */
+static unsigned int meson_mmc_get_cmd_timeout_msecs(struct mmc_command *cmd)
+{
+	unsigned int timeout = cmd->busy_timeout;
+
+	if (!timeout)
+		return SD_EMMC_CMD_TIMEOUT;
+
+	timeout = roundup_pow_of_two(timeout);
+
+	return clamp_t(unsigned int, timeout, SD_EMMC_CMD_TIMEOUT,
+		       SD_EMMC_CMD_TIMEOUT_MAX);
 }
 
 static struct mmc_command *meson_mmc_get_next_command(struct mmc_command *cmd)
@@ -841,7 +856,7 @@ static void meson_mmc_start_cmd(struct mmc_host *mmc, struct mmc_command *cmd)
 		cmd_data = host->bounce_dma_addr & CMD_DATA_MASK;
 	} else {
 		cmd_cfg |= FIELD_PREP(CMD_CFG_TIMEOUT_MASK,
-				      ilog2(SD_EMMC_CMD_TIMEOUT));
+				      ilog2(meson_mmc_get_cmd_timeout_msecs(cmd)));
 	}
 
 	/* Last descriptor */
@@ -1168,6 +1183,9 @@ static int meson_mmc_probe(struct platform_device *pdev)
 
 	mmc->caps |= MMC_CAP_CMD23;
 
+	/* The longest busy wait the CMD_CFG timeout field can hold. */
+	mmc->max_busy_timeout = SD_EMMC_CMD_TIMEOUT_MAX;
+
 	if (mmc->caps & MMC_CAP_SDIO_IRQ)
 		mmc->caps2 |= MMC_CAP2_SDIO_IRQ_NOTHREAD;
 

---
base-commit: fd9af27f6c2319713bb23832066585f8a59a1771
change-id: 20261005-meson-gx-busy-timeout-7e8e3fdcb3e3

Best regards,
-- 
Igor Velkov <iav@iav.lv>

