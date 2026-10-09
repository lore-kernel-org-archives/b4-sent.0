From: Igor Velkov <iav@iav.lv>
Date: Fri, 09 Oct 2026 17:02:57 +0000
Subject: [PATCH v3 1/4] mmc: meson-gx: name the limit of the CMD_CFG
 timeout field
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261009-meson-gx-busy-timeout-v3-1-67d0db3a8328@iav.lv>
References: <20261009-meson-gx-busy-timeout-v3-0-67d0db3a8328@iav.lv>
In-Reply-To: <20261009-meson-gx-busy-timeout-v3-0-67d0db3a8328@iav.lv>
To: Ulf Hansson <ulfh@kernel.org>
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 linux-mmc@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1222; i=iav@iav.lv;
 h=from:subject:message-id; bh=8VC1yXn3jZKERenMCKphBxv2rNREe/7oQ7Z39r7TC8Y=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFkn5cIE+th8OC4vD0jr2XH3csP+2S+e8f/YqXWho4xjs
 +HBSk/PjlIWBjEuBlkxRZYJhzRuZSy5+tffw/wBzBxWJpAhDFycAjCRKzKMDJcWHfBJNFlknH/q
 XWbdjXdr2O84NmdaX+Upz/S8em9zXxDDXznhmeI7k580L9P/sVD8o9G3eXunzJUUeTOp7v/ZKRd
 vHOcHAA==
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The data timeout is capped at a literal 32768 ms with a comment next to
it. Give the limit a name beside the other timeout constants.

Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
 drivers/mmc/host/meson-gx-mmc.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/mmc/host/meson-gx-mmc.c b/drivers/mmc/host/meson-gx-mmc.c
index 7ef16d7c03cb..06479ba38525 100644
--- a/drivers/mmc/host/meson-gx-mmc.c
+++ b/drivers/mmc/host/meson-gx-mmc.c
@@ -125,6 +125,7 @@
 #define SD_EMMC_CFG_RESP_TIMEOUT 256 /* in clock cycles */
 #define SD_EMMC_CMD_TIMEOUT 1024 /* in ms */
 #define SD_EMMC_CMD_TIMEOUT_DATA 4096 /* in ms */
+#define SD_EMMC_CMD_TIMEOUT_MAX 32768 /* in ms, 2^15: limit of CMD_CFG_TIMEOUT_MASK */
 #define SD_EMMC_CFG_CMD_GAP 16 /* in clock cycles */
 #define SD_EMMC_DESC_BUF_LEN PAGE_SIZE
 
@@ -212,7 +213,7 @@ static unsigned int meson_mmc_get_timeout_msecs(struct mmc_data *data)
 
 	timeout = roundup_pow_of_two(timeout);
 
-	return min(timeout, 32768U); /* max. 2^15 ms */
+	return min_t(unsigned int, timeout, SD_EMMC_CMD_TIMEOUT_MAX);
 }
 
 static struct mmc_command *meson_mmc_get_next_command(struct mmc_command *cmd)

-- 
2.43.0

