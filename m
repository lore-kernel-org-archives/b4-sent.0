From: Athira Palliprath <palliprath@chromium.org>
Date: Fri, 20 Nov 2026 05:02:43 +0000
Subject: [PATCH] mmc: core: poll busy at HS clock if CMD6 errors in
 mmc_select_hs400
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-fix-hs400-clock-v1-1-96522138aa3e@chromium.org>
X-B4-Tracking: v=1; b=H4sIAHLU/2oC/x2MQQqAMAwEv1JyNpAWEepXxIPWVINipQURpH83e
 JuB2X2hcBYu0JsXMt9SJJ0qtjEQtulcGWVRB0eus9YRRnlwKy0RhiOFHb1XjjO1LhDo6sqsyf8
 4jLV+taE0Z2EAAAA=
X-Change-ID: 20261120-fix-hs400-clock-99400fb042c0
To: Ulf Hansson <ulfh@kernel.org>, Ziyuan Xu <xzy.xu@rock-chips.com>
Cc: linux-mmc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 palliprath@google.com, Athira Palliprath <palliprath@chromium.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795150964; l=2681;
 i=palliprath@chromium.org; s=20261118; h=from:subject:message-id;
 bh=YLwtxDOh0JfJFa+O1qwwy7UmOgrYuamaO4eozXT5naM=;
 b=fMjFiQmZr5ZDCT2h3dwJgoqw0ECRQFpDbxvzXo4v63Zh9UtEoyHeEvLp89+XIIBRq8YsaFp2s
 KvNnzW2Od8tDJP6NwFpWavhXM6ghhVRzUr3i0ccRqRU4H5O9MM6cN7g
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
 drivers/mmc/core/mmc.c | 14 ++++++++++++--
 1 file changed, 12 insertions(+), 2 deletions(-)

diff --git a/drivers/mmc/core/mmc.c b/drivers/mmc/core/mmc.c
index a02b04938e1a0..03a60b74c3aba 100644
--- a/drivers/mmc/core/mmc.c
+++ b/drivers/mmc/core/mmc.c
@@ -1197,8 +1197,8 @@ static int mmc_select_hs400(struct mmc_card *card)
 	err = __mmc_switch(card, EXT_CSD_CMD_SET_NORMAL,
 			   EXT_CSD_HS_TIMING, val,
 			   card->ext_csd.generic_cmd6_time, 0,
-			   false, true, MMC_CMD_RETRIES);
-	if (err) {
+			   false, true, 0);
+	if (err && err != -EILSEQ && err != -ETIMEDOUT) {
 		pr_err("%s: switch to high-speed from hs200 failed, err:%d\n",
 			mmc_hostname(host), err);
 		return err;
@@ -1215,6 +1215,16 @@ static int mmc_select_hs400(struct mmc_card *card)
 	max_dtr = card->ext_csd.hs_max_dtr;
 	mmc_set_clock(host, max_dtr);
 
+	if (err) {
+		err = mmc_poll_for_busy(card, card->ext_csd.generic_cmd6_time,
+					true, MMC_BUSY_CMD6);
+		if (err) {
+			pr_err("%s: switch to high-speed from hs200 failed, err:%d\n",
+				mmc_hostname(host), err);
+			return err;
+		}
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

