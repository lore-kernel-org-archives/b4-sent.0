From: Igor Velkov <iav@iav.lv>
Date: Thu, 08 Oct 2026 14:28:00 +0000
Subject: [PATCH v2 2/3] mmc: meson-gx: honour the busy timeout for R1b
 commands
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-meson-gx-busy-timeout-v2-2-8bde1adfb5b4@iav.lv>
References: <20261008-meson-gx-busy-timeout-v2-0-8bde1adfb5b4@iav.lv>
In-Reply-To: <20261008-meson-gx-busy-timeout-v2-0-8bde1adfb5b4@iav.lv>
To: Ulf Hansson <ulfh@kernel.org>
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 linux-mmc@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2127; i=iav@iav.lv;
 h=from:subject:message-id; bh=9xGrDCPi8rJjeIzvAyq5Lt1wlFmJSZrwiazD8/BoI9g=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFnHV5R0Zt1sTva8kntm1fkyxsgPc/LOLty0zGkma0Z6K
 O/ty3/vdZSyMIhxMciKKbJMOKRxK2PJ1b/+HuYPYOawMoEMYeDiFICJzDFhZLgwbbrvk6kLdXcu
 /GMVEry2SHbzsTcqb/PWMjoVPOTcYOXByHDArvTjzrxV37mmtXS3BJ1tEnh88mxp4Ca5GUtObWO
 zmM4GAA==
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For a command without data the driver programs a fixed 1024 ms into the
CMD_CFG timeout field, and for R1b the controller waits for the card to
release busy within that time. The core sends erase and cache flush as
R1b with busy timeouts of up to 60 s and 30 s, and the controller gives
up after one second:

  mmc_erase: erase error -110, status 0x0
  mmc1: cache flush error -110

Program the timeout from cmd->busy_timeout, rounded up to a power of
two and kept within 1024..32768 ms, the range the field holds. sdhci
takes its command timeout from cmd->busy_timeout in the same way.

Fixes: 51c5d8447bd7 ("MMC: meson: initial support for GX platforms")
Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
 drivers/mmc/host/meson-gx-mmc.c | 16 +++++++++++++++-
 1 file changed, 15 insertions(+), 1 deletion(-)

diff --git a/drivers/mmc/host/meson-gx-mmc.c b/drivers/mmc/host/meson-gx-mmc.c
index 06479ba38525..dd7d3d67f029 100644
--- a/drivers/mmc/host/meson-gx-mmc.c
+++ b/drivers/mmc/host/meson-gx-mmc.c
@@ -216,6 +216,20 @@ static unsigned int meson_mmc_get_timeout_msecs(struct mmc_data *data)
 	return min_t(unsigned int, timeout, SD_EMMC_CMD_TIMEOUT_MAX);
 }
 
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
+}
+
 static struct mmc_command *meson_mmc_get_next_command(struct mmc_command *cmd)
 {
 	if (cmd->opcode == MMC_SET_BLOCK_COUNT && !cmd->error)
@@ -842,7 +856,7 @@ static void meson_mmc_start_cmd(struct mmc_host *mmc, struct mmc_command *cmd)
 		cmd_data = host->bounce_dma_addr & CMD_DATA_MASK;
 	} else {
 		cmd_cfg |= FIELD_PREP(CMD_CFG_TIMEOUT_MASK,
-				      ilog2(SD_EMMC_CMD_TIMEOUT));
+				      ilog2(meson_mmc_get_cmd_timeout_msecs(cmd)));
 	}
 
 	/* Last descriptor */

-- 
2.43.0

