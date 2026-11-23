From: Athira Palliprath <palliprath@chromium.org>
Date: Mon, 23 Nov 2026 06:52:08 +0000
Subject: [PATCH v2] mmc: core: poll busy at HS clock if CMD6 errors in
 mmc_select_hs400
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-fix-hs400-clock-v2-1-ad3b935bd9f9@chromium.org>
X-B4-Tracking: v=1; b=H4sIAJfiA2sC/3WNTQ6CMBCFr0Jm7Zh2QGJdeQ/DotZCJwolUyUa0
 rtb2bt738v7WSF5YZ/gVK0gfuHEcSpAuwpcsNPgkW+FgRS1WpPCnt8YUqMUukd0dzSm6P6qGnI
 KSmsWXyLb4qUrHDg9o3y2g0X/3P9bi0aNpj0Q6fpobe3PLkgc+TXuowzQ5Zy/BylIY7EAAAA=
X-Change-ID: 20261120-fix-hs400-clock-99400fb042c0
To: Ulf Hansson <ulfh@kernel.org>, Ziyuan Xu <xzy.xu@rock-chips.com>
Cc: linux-mmc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 palliprath@google.com, Athira Palliprath <palliprath@chromium.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795416730; l=4337;
 i=palliprath@chromium.org; s=20261118; h=from:subject:message-id;
 bh=LgH1THntmAvlqiGNxlcLpYqtPqoAxQtaL85fDfG/ZnQ=;
 b=kU4ot6vnYSfPC/tm5TT5gNcJTkEkEeW7Ooh0EGqLGPDmIiLl8QMQ0J14O522sygH7K+cKjzDv
 3R1HBjwETOnAt8ItX0eS4Dss+i1630e6xGr92zprEvJAak5ZfmjkbSD
X-Developer-Key: i=palliprath@chromium.org; a=ed25519;
 pk=OTJWz85nJwutJ218eeYfQMyFjDnPEnUi0L8N9EGsTa4=
X-Endpoint-Received: by B4 Relay for palliprath@chromium.org/20261118 with auth_id=1580
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When switching from HS200 to HS in mmc_select_hs400(), some eMMC cards
immediately switch to 52 MHz HS timing upon receiving CMD6, causing the
host at 200 MHz to fail sampling the R1b response (-EILSEQ / -ETIMEDOUT)
and leaving the host stuck at 200 MHz HS200 while the card is in 52 MHz
HS mode.

To keep JEDEC JESD84-B51 ordering (send CMD6 first, then lower clock to
<= 52 MHz), pass retries = 0 to __mmc_switch() and, if it fails with
-EILSEQ or -ETIMEDOUT, switch the host to HS timing and 52 MHz first
before polling for busy completion at 52 MHz. Other error codes still
fail immediately.

Also temporarily set host->retune_crc_disable across the HS200->HS
__mmc_switch() and fallback mmc_poll_for_busy(). Since mmc_select_hs400()
runs right after HS200 tuning enables host->can_retune, an expected
-EILSEQ on CMD6 (or on a retried CMD13 while polling) would otherwise
flag host->need_retune in mmc_request_done(), triggering invalid tuning
at 52 MHz HS timing on resume/reset or leaving re-tuning pending after
returning to HS400.

The retries parameter in __mmc_switch() was added in
commit 5e52a168be37 ("mmc: core: Add a retries parameter to __mmc_switch
function") specifically so callers where retrying CMD6 is harmful (such
as eMMC sanitize in commit 5b96247c68d8 ("mmc: core: Let eMMC sanitize
not retry in case of timeout/failure")) can pass 0 instead of
MMC_CMD_RETRIES. Passing 0 here trades off automatic retries if a
transient bus error corrupts the CMD6 request itself at 200 MHz, in
order to avoid retrying CMD6 at 200 MHz after the card has already
switched to 52 MHz.

Fixes: 649c6059d237 ("mmc: mmc: Fix HS switch failure in mmc_select_hs400()")
Signed-off-by: Athira Palliprath <palliprath@chromium.org>
---
Changes in v2:
- Temporarily set host->retune_crc_disable across the HS200->HS
  __mmc_switch() and fallback mmc_poll_for_busy() so expected -EILSEQ
  errors do not set host->need_retune (reported by Sashiko AI review).
- Link to v1: https://lore.kernel.org/r/20261120-fix-hs400-clock-v1-1-96522138aa3e@chromium.org
---
 drivers/mmc/core/mmc.c | 26 +++++++++++++++++++++++---
 1 file changed, 23 insertions(+), 3 deletions(-)

diff --git a/drivers/mmc/core/mmc.c b/drivers/mmc/core/mmc.c
index a02b04938e1a0..d4fc0bab690f6 100644
--- a/drivers/mmc/core/mmc.c
+++ b/drivers/mmc/core/mmc.c
@@ -1181,6 +1181,7 @@ static int mmc_select_hs_ddr(struct mmc_card *card)
 static int mmc_select_hs400(struct mmc_card *card)
 {
 	struct mmc_host *host = card->host;
+	bool retune_crc_disable;
 	unsigned int max_dtr;
 	int err = 0;
 	u8 val;
@@ -1192,13 +1193,22 @@ static int mmc_select_hs400(struct mmc_card *card)
 	      host->ios.bus_width == MMC_BUS_WIDTH_8))
 		return 0;
 
-	/* Switch card to HS mode */
+	/*
+	 * Switch card to HS mode.
+	 * Temporarily suppress CRC-triggered re-tuning because non-compliant
+	 * cards may switch to 52 MHz HS immediately on CMD6, causing an
+	 * expected -EILSEQ at 200 MHz (or on a retried CMD13 while polling)
+	 * that would otherwise set host->need_retune.
+	 */
 	val = EXT_CSD_TIMING_HS;
+	retune_crc_disable = host->retune_crc_disable;
+	host->retune_crc_disable = true;
 	err = __mmc_switch(card, EXT_CSD_CMD_SET_NORMAL,
 			   EXT_CSD_HS_TIMING, val,
 			   card->ext_csd.generic_cmd6_time, 0,
-			   false, true, MMC_CMD_RETRIES);
-	if (err) {
+			   false, true, 0);
+	if (err && err != -EILSEQ && err != -ETIMEDOUT) {
+		host->retune_crc_disable = retune_crc_disable;
 		pr_err("%s: switch to high-speed from hs200 failed, err:%d\n",
 			mmc_hostname(host), err);
 		return err;
@@ -1215,6 +1225,16 @@ static int mmc_select_hs400(struct mmc_card *card)
 	max_dtr = card->ext_csd.hs_max_dtr;
 	mmc_set_clock(host, max_dtr);
 
+	if (err)
+		err = mmc_poll_for_busy(card, card->ext_csd.generic_cmd6_time,
+					true, MMC_BUSY_CMD6);
+	host->retune_crc_disable = retune_crc_disable;
+	if (err) {
+		pr_err("%s: switch to high-speed from hs200 failed, err:%d\n",
+		       mmc_hostname(host), err);
+		return err;
+	}
+
 	err = mmc_switch_status(card, true);
 	if (err)
 		goto out_err;

---
base-commit: d2616724e01132376c78872b8324f38659af9f28
change-id: 20261120-fix-hs400-clock-99400fb042c0

Best regards,
-- 
Athira Palliprath <palliprath@chromium.org>

