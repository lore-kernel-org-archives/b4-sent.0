From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Sat, 24 Oct 2026 19:32:42 -0500
Subject: [PATCH ath-next] wifi: ath11k: report the measured noise floor of
 the channel in use
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261024-ath11k-survey-noise-floor-v1-1-8eb03002aab8@gmail.com>
X-B4-Tracking: v=1; b=H4sIAClO3WoC/yWMQQrCMBAAv1L27EITaol+RTyk68auSiLZtFRK/
 26sx2GYWUE5CyucmxUyz6KSYgVzaIBGH++McqsMtrW9aW2HvozGPFGnPPMHYxJlDK+UMpLzxxM
 5ci50UPt35iDL/r5AzTDyUuD6NzoND6byW8O2fQFrcLFyhwAAAA==
X-Change-ID: 20261024-ath11k-survey-noise-floor-c8a59c8c88f4
To: Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792888361; l=4101;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=qzZpKyEkcevX8rqLtU57o7fduxhGno+SZWFUzasBvOE=;
 b=R0N9mUzH4SMm1KlvBjfjsJOkVQZRGfvnfOe/ESbC1iLVtxPLZF0dGGkLLf1uHQTi5xKJnLavu
 Afy7b6eaiiUB4G/Xv0Btmfz0qx2VpOwylsc7HbeXlr9lh+9PdZ+1Fnk
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For the channel in use, ath11k fills the survey's noise from the
firmware's pdev bss channel info event. That value is not the channel's
measured noise floor: on IPQ8074 it reads -108 to -109 dBm on 5 GHz and
-101 to -102 dBm on 2.4 GHz and barely moves, while the firmware's pdev
stats report the channel's noise floor as -94 and -96 dBm at the same
moment, and the channel info events of a scan give -93 to -96 dBm for the
other channels. A noise floor near -109 dBm is not physical for an
80 MHz channel, so `iw survey dump` and anything built on it show the
channel in use 10 to 15 dB quieter than it is.

Request the pdev stats when the survey of the channel in use is read,
and report their channel noise floor, when it is plausible, in place of
the bss channel info one. Keep it in the channel's survey entry as well,
so the channel shows its last measured value once the radio has left it.

With this, on an IPQ8074 AP the in-use survey reads -95 dBm (5 GHz) and
-96 dBm (2.4 GHz), equal to the pdev stats, instead of -106 and -102;
after a channel switch the new channel reads -92 dBm, as the pdev stats
do, and the old one keeps its last measured value.

Tested-on: IPQ8074 hw2.0 AHB WLAN.HK.2.9.0.1-02146-QCAHKSWPL_SILICONZ-1

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
Pairs with "wifi: ath11k: update rx_channel on a channel switch", sent
separately. Without it, after a channel switch the survey flags the old
channel as in use, and this patch would report its noise floor there.
---
 drivers/net/wireless/ath/ath11k/mac.c | 44 ++++++++++++++++++++++++++++++++++-
 1 file changed, 43 insertions(+), 1 deletion(-)

diff --git a/drivers/net/wireless/ath/ath11k/mac.c b/drivers/net/wireless/ath/ath11k/mac.c
index 1a237adaa..570321f76 100644
--- a/drivers/net/wireless/ath/ath11k/mac.c
+++ b/drivers/net/wireless/ath/ath11k/mac.c
@@ -9338,6 +9338,46 @@ ath11k_mac_update_bss_chan_survey(struct ath11k *ar,
 		ath11k_warn(ar->ab, "bss channel survey timed out\n");
 }
 
+/* The noise floor in the firmware's bss channel info event is not the
+ * channel's measured noise floor: on IPQ8074 it reads about -109 dBm on
+ * 5 GHz and -102 dBm on 2.4 GHz, and barely moves, while the measured value
+ * the firmware reports in its pdev stats is -94 and -96. Report the measured
+ * one for the channel in use, as the channel info events of a scan do for
+ * the other channels.
+ */
+static void ath11k_mac_get_chan_noise_floor(struct ath11k *ar,
+					    struct survey_info *ar_survey,
+					    struct survey_info *survey)
+{
+	struct ath11k_fw_stats_pdev *pdev;
+	s32 nf;
+
+	lockdep_assert_held(&ar->conf_mutex);
+
+	if (ar->scan.state != ATH11K_SCAN_IDLE)
+		return;
+
+	if (ath11k_mac_get_fw_stats(ar, ar->pdev->pdev_id, 0,
+				    WMI_REQUEST_PDEV_STAT))
+		return;
+
+	spin_lock_bh(&ar->data_lock);
+	pdev = list_first_entry_or_null(&ar->fw_stats.pdevs,
+					struct ath11k_fw_stats_pdev, list);
+	nf = pdev ? pdev->ch_noise_floor : 0;
+	/* keep it for the channel too, so its survey shows the last measured
+	 * value once the radio has left it
+	 */
+	if (nf < 0 && nf > -127)
+		ar_survey->noise = nf;
+	spin_unlock_bh(&ar->data_lock);
+
+	if (nf < 0 && nf > -127) {
+		survey->noise = nf;
+		survey->filled |= SURVEY_INFO_NOISE_DBM;
+	}
+}
+
 static int ath11k_mac_op_get_survey(struct ieee80211_hw *hw, int idx,
 				    struct survey_info *survey)
 {
@@ -9381,8 +9421,10 @@ static int ath11k_mac_op_get_survey(struct ieee80211_hw *hw, int idx,
 
 	survey->channel = &sband->channels[idx];
 
-	if (ar->rx_channel == survey->channel)
+	if (ar->rx_channel == survey->channel) {
 		survey->filled |= SURVEY_INFO_IN_USE;
+		ath11k_mac_get_chan_noise_floor(ar, ar_survey, survey);
+	}
 
 exit:
 	mutex_unlock(&ar->conf_mutex);

---
base-commit: cd026e68fdbf88b9cc522b76c7a9d92c9a41f709
change-id: 20261024-ath11k-survey-noise-floor-c8a59c8c88f4

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

