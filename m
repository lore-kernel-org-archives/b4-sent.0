From: Filippo Falezza <effeffe99@gmail.com>
Date: Mon, 26 Oct 2026 16:36:18 +0000
Subject: [PATCH] wifi: ath10k: Stop unanswered temperature reads
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-ath10k-temperature-v1-1-e5cd6fde7f1e@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBG4avIrBvIDCjUq5QuYvytY6mVSRRBv
 HvTdvkt3jsowRSJ2uogw6ZJ33MBXyqKY5gfcNoXk3hp2Iu4kEf2T5fxWmAhrwYn0jFfh77hOlI
 JF8Og+296u/+d1m5CzN8TnecHw2p5hnYAAAA=
X-Change-ID: 20261022-ath10k-temperature-22b119fd615c
To: Jeff Johnson <jjohnson@kernel.org>
Cc: Kalle Valo <kvalo@kernel.org>, linux-wireless@vger.kernel.org, 
 ath10k@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Filippo Falezza <effeffe99@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793032581; l=5266;
 i=effeffe99@gmail.com; s=20261022; h=from:subject:message-id;
 bh=dwxGaee4fItm4yw5npM2dzYMmeRZJveGMalugLg36eQ=;
 b=oDrvPeHUioisacqWVSHL44zmXPpkmrzfqqSI7Yprj+QBr3dRziYEl2zpBlt64PhqHoU8pbwAS
 oj251B6r7RrD0I66WzVYVQkzpBcOynmrCNtqfraCoiNdvKRfMQZBEa7
X-Developer-Key: i=effeffe99@gmail.com; a=ed25519;
 pk=7PPwl4QILojrh+ATB5QOpvXVmmoxaxyLQhrLRLWEL0I=
X-Endpoint-Received: by B4 Relay for effeffe99@gmail.com/20261022 with auth_id=1327
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reading the ath10k hwmon temperature sends WMI_PDEV_GET_TEMPERATURE and
waits up to 5 s (ATH10K_THERMAL_SYNC_TIMEOUT_HZ) for the reply event,
holding conf_mutex. Not all firmware answers: the WCN3990 firmware
WLAN.HL.3.3.1-00694-QCAHLSWMTPLZ-1 on a Motorola Moto G 5G Plus
codename nairo (SM7250) never sends the event, so every read of
temp1_input stalls for 5 s, logs

  ath10k_snoc 18800000.wifi: failed to synchronize thermal read

and returns -ETIMEDOUT. Tools that read all hwmon sensors, such as
lm-sensors, hang for 5 s on every run, and configuration changes of the
interface wait for conf_mutex in the meantime.

Whether the firmware answers cannot be told from the chip: firmware that
answers and firmware that does not both advertise
WMI_SERVICE_THERM_THROT, and WCN3990 firmware differs between devices.
Instead, remember that the running firmware did not answer, and return
-EOPNOTSUPP right away on later reads. Forget it when the firmware
starts, so that a restarted or updated firmware is asked again.

The first read after each firmware start still takes 5 s when the
firmware does not answer. Reads on firmware that answers are unchanged.

This change was written with the help of an AI coding assistant; see
the notes below.

Fixes: e98199a8c27f ("ath10k: enable QCA6174/QCA9377 to read the chip temperature")
Signed-off-by: Filippo Falezza <effeffe99@gmail.com>
---
Notes, not for the changelog:

- Tool: Claude Opus 5.5 in Claude Code wrote the code and this changelog
  during an interactive bring-up session for the Moto G 5G Plus. The
  request was to fix `sensors` hanging on every run because of ath10k.
  A first version disabled the read for all WCN3990 through a hw_params
  flag; it was replaced by this one so that it does not assume all
  WCN3990 firmware behaves the same, as Loic Poulain asked of another
  WCN3990 firmware workaround ("ath10k: WCN3990 firmware workarounds for
  WLAN.HL.3.2", March 2026).
- Tested on: Moto G 5G Plus (SM7250, WCN3990, firmware
  WLAN.HL.3.3.1-00694-QCAHLSWMTPLZ-1), linux-next next-20261021 plus
  device support patches, with this patch in place of a local WCN3990
  quirk. First read of temp1_input: 5065 ms, -ETIMEDOUT, one warning;
  next reads: 8 ms, -EOPNOTSUPP; a full `sensors` run: 25 ms (5 s or
  more before). After switching Wi-Fi off and on, which restarts the
  firmware session, the first read waits 5 s again, then -EOPNOTSUPP.
- Not tested: firmware that does answer the request (QCA6174, QCA9377,
  other WCN3990 firmware); for them only reads after a timeout change.
  Not run: sparse.
- Build: W=1 for arm64, no warnings; checkpatch --strict clean.
  Applies to ath-next (cd026e68f).
---
 drivers/net/wireless/ath/ath10k/core.c    | 1 +
 drivers/net/wireless/ath/ath10k/thermal.c | 9 ++++++++-
 drivers/net/wireless/ath/ath10k/thermal.h | 2 ++
 3 files changed, 11 insertions(+), 1 deletion(-)

diff --git a/drivers/net/wireless/ath/ath10k/core.c b/drivers/net/wireless/ath/ath10k/core.c
index 7c2939cbde5f..9467e4c3099a 100644
--- a/drivers/net/wireless/ath/ath10k/core.c
+++ b/drivers/net/wireless/ath/ath10k/core.c
@@ -2985,6 +2985,7 @@ int ath10k_core_start(struct ath10k *ar, enum ath10k_firmware_mode mode,
 	clear_bit(ATH10K_FLAG_CRASH_FLUSH, &ar->dev_flags);
 
 	ar->running_fw = fw;
+	ar->thermal.temperature_unanswered = false;
 
 	if (!test_bit(ATH10K_FW_FEATURE_NON_BMI,
 		      ar->running_fw->fw_file.fw_features)) {
diff --git a/drivers/net/wireless/ath/ath10k/thermal.c b/drivers/net/wireless/ath/ath10k/thermal.c
index 9bb486f8e920..1079d552cff4 100644
--- a/drivers/net/wireless/ath/ath10k/thermal.c
+++ b/drivers/net/wireless/ath/ath10k/thermal.c
@@ -75,6 +75,12 @@ static ssize_t ath10k_thermal_show_temp(struct device *dev,
 		goto out;
 	}
 
+	/* Don't stall every read on firmware that never answers */
+	if (ar->thermal.temperature_unanswered) {
+		ret = -EOPNOTSUPP;
+		goto out;
+	}
+
 	reinit_completion(&ar->thermal.wmi_sync);
 	ret = ath10k_wmi_pdev_get_temperature(ar);
 	if (ret) {
@@ -90,7 +96,8 @@ static ssize_t ath10k_thermal_show_temp(struct device *dev,
 	time_left = wait_for_completion_timeout(&ar->thermal.wmi_sync,
 						ATH10K_THERMAL_SYNC_TIMEOUT_HZ);
 	if (!time_left) {
-		ath10k_warn(ar, "failed to synchronize thermal read\n");
+		ath10k_warn(ar, "failed to synchronize thermal read, not asking again until the firmware restarts\n");
+		ar->thermal.temperature_unanswered = true;
 		ret = -ETIMEDOUT;
 		goto out;
 	}
diff --git a/drivers/net/wireless/ath/ath10k/thermal.h b/drivers/net/wireless/ath/ath10k/thermal.h
index 1f4de9fbf2b3..cb930da5c04a 100644
--- a/drivers/net/wireless/ath/ath10k/thermal.h
+++ b/drivers/net/wireless/ath/ath10k/thermal.h
@@ -19,6 +19,8 @@ struct ath10k_thermal {
 	/* protected by conf_mutex */
 	u32 throttle_state;
 	u32 quiet_period;
+	/* the running firmware did not answer a temperature request */
+	bool temperature_unanswered;
 	/* temperature value in Celsius degree
 	 * protected by data_lock
 	 */

---
base-commit: cd026e68fdbf88b9cc522b76c7a9d92c9a41f709
change-id: 20261022-ath10k-temperature-22b119fd615c

Best regards,
--  
Filippo Falezza <effeffe99@gmail.com>

