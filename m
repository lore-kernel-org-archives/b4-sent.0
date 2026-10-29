From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Thu, 29 Oct 2026 17:15:48 -0500
Subject: [PATCH ath-next] wifi: ath11k: add the measured noise floor, not
 -95, to a received signal
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-ath11k-signal-noise-floor-v1-1-dd5d6a04dcf2@gmail.com>
X-B4-Tracking: v=1; b=H4sIAJPF42oC/2WP0U7EIBREf6XhWRIgbYH+itkHuFy2aBcUaK3Z7
 L/LajUaHydzZ87cKymYAxYydVeScQslpNgEf+gIzCaekQbXNBFMjJwJTU2dOX+mJZyjWWhMoSD
 1S0qZgrSceQGOWUda/iWjD/tn9yNpMRpxr+T05ZTVPiHUe/Vxm/F1bfh6BH7oU3ew+2923undj
 bjQ8hYqzLQ3yAaQRgkJ08bJ7/X/82XNG77/3a7MoEGBUr4/CqxpLqTLJdSpa0+JEUflnfVKWQ0
 wCGHl2JjaaQHa9NxLpsnpdvsAljUqc1QBAAA=
X-Change-ID: 20261029-ath11k-signal-noise-floor-c7b10f2cd0bd
To: Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 ath11k@lists.infradead.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793312148; l=14047;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=an+cFuf9qofjguKNKpiOOW55It8wu9JPo5kVIgrvAJA=;
 b=Sjf7zhxr8VdGzQAV7i8iwQhfQ8UY0QGDsx4ENXSVeOOXv0iGbNrlhebYvbnR6EjHEivqRqiRS
 AVsqllwqHewA+TOpawy+k0h8TFPLcR36YEGjmvCoQ7hdEaEG7/DyPk+
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The firmware gives a received signal (rssi_comb of a PPDU, the ack rssi
of a tx completion, the snr of a management frame) in dB above the noise
floor it measures on the channel. Without the firmware's own conversion
to dBm (WMI_TLV_SERVICE_HW_DB2DBM_CONVERSION_SUPPORT), ath11k adds a
fixed ATH11K_DEFAULT_NOISE_FLOOR (-95 dBm), so every signal it reports
reads low by as much as the channel's floor is above -95 dBm: 5 dB on a
channel at -90, 7 dB at -88.

On an IPQ8074 (WLAN.HK.2.9.0.1) the HTT PDEV RX rate stats give each
chain's signal of the last PPDU in dB and in dBm. Their difference is
that chain's measured floor (-87 to -95 dBm across chains and channels),
and the chains' summed power is rssi_comb plus the channel noise floor
of the pdev stats to within about 1 dB, on 2.4 and 5 GHz. A client whose
chains summed to -42 dBm on a 5 GHz channel at -90 showed as -46 in a
station dump.

Keep the measured floor of the channel in use per radio, read from the
pdev stats when the survey of that channel is read or a station dump
finds it older than 10 s, and add it in place of -95 to the station
signal and its average, the ack signal, management frames received on
that channel, and monitor frames. Drop it when the radio changes
channel; until it is read again, and for frames on another channel
(during a scan), -95 stays. Chips with db2dbm are unchanged. ath12k
already adds the noise floor its firmware reports.

Tested on an Arista C-360 (IPQ8074): a client whose chains summed to -42
to -44 dBm on a 5 GHz channel at -90 now shows -40 to -42, where -95 gave
-45 to -48. The management frame and monitor paths were not checked
separately; they take the same offset.

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
This applies on top of two ath11k patches I sent on 2026-10-24, listed
as prerequisites: "wifi: ath11k: update rx_channel on a channel switch"
and "wifi: ath11k: report the measured noise floor of the channel in
use". It reads the floor where the second one does and drops it where
the first one moves rx_channel.

Found on an Arista C-360 running OpenWrt, where an AP on a channel with
a raised floor (-88 dBm) seemed to hear its clients 8-10 dB worse than
they heard it. On an IPQ8074 5 GHz radio with a floor of -90 dBm, the
HTT PDEV RX rate stats of the last PPDU gave per-chain signals of
40/37/36/39 dB and -51/-51/-57/-52 dBm (chain floors -91/-88/-93/-91);
the chains summed to -46.1 to -47.1 dBm with rssi_comb at 44. With this
patch the station dump shows -46, without it -51. On 2.4 GHz (floor -94)
the chains summed to within 1 dB of rssi_comb plus the floor as well.
The firmware's combined rssi_in_dbm in the same stats did not follow the
chains on two of three radios, so I did not use it.

Not tested: the management frame and monitor paths on their own (they
take the same offset), and chips other than IPQ8074. The QCN9074 and
QCN9072 in the same AP read their floors the same way, but I did not
compare their chains. Chips with db2dbm are unchanged.

The investigation and the patch were done with Claude Code
(claude-opus-5-5): it found the offset by comparing the per-chain dB and
dBm figures with the pdev noise floor, wrote the patch and its
changelog, and ran the tests on the APs. Tested on OpenWrt's
backports-7.2 ath11k with the two prerequisites; built with W=1 on
ath-next with them applied.
---
 drivers/net/wireless/ath/ath11k/core.h  | 25 ++++++++++
 drivers/net/wireless/ath/ath11k/dp_rx.c |  2 +-
 drivers/net/wireless/ath/ath11k/dp_tx.c |  4 +-
 drivers/net/wireless/ath/ath11k/mac.c   | 88 +++++++++++++++++++++++++--------
 drivers/net/wireless/ath/ath11k/wmi.c   |  2 +-
 5 files changed, 97 insertions(+), 24 deletions(-)

diff --git a/drivers/net/wireless/ath/ath11k/core.h b/drivers/net/wireless/ath/ath11k/core.h
index a0d725923ef2..0901695de015 100644
--- a/drivers/net/wireless/ath/ath11k/core.h
+++ b/drivers/net/wireless/ath/ath11k/core.h
@@ -716,6 +716,14 @@ struct ath11k {
 	/* valid during scan; needed for mgmt rx during scan */
 	struct ieee80211_channel *scan_channel;
 
+	/* measured noise floor (dBm) of rx_channel for the signals reported
+	 * on it, or 0 until it is read; set under conf_mutex and data_lock,
+	 * read without them on the rx and tx paths
+	 */
+	s32 noise_floor;
+	u32 noise_floor_freq;
+	unsigned long noise_floor_time;
+
 	u8 cfg_tx_chainmask;
 	u8 cfg_rx_chainmask;
 	u8 num_rx_chains;
@@ -1370,6 +1378,23 @@ static inline const char *ath11k_bus_str(enum ath11k_bus bus)
 	return "unknown";
 }
 
+/* The firmware gives a received signal (rssi_comb, ack rssi, management
+ * snr) in dB above the noise floor it measures on the channel. Without its
+ * own conversion to dBm (db2dbm), add that measured noise floor, not a
+ * nominal -95 dBm, or every signal reads low by as much as the floor is
+ * above -95. A frame on another channel than the one in use (freq given),
+ * or a channel whose floor has not been read yet, gets the nominal one.
+ */
+static inline s32 ath11k_noise_floor(struct ath11k *ar, u32 freq)
+{
+	s32 nf = READ_ONCE(ar->noise_floor);
+
+	if (!nf || (freq && freq != READ_ONCE(ar->noise_floor_freq)))
+		return ATH11K_DEFAULT_NOISE_FLOOR;
+
+	return nf;
+}
+
 void ath11k_core_pm_notifier_unregister(struct ath11k_base *ab);
 
 #endif /* _CORE_H_ */
diff --git a/drivers/net/wireless/ath/ath11k/dp_rx.c b/drivers/net/wireless/ath/ath11k/dp_rx.c
index 6d95f7b343a5..8c6bec1d6fa8 100644
--- a/drivers/net/wireless/ath/ath11k/dp_rx.c
+++ b/drivers/net/wireless/ath/ath11k/dp_rx.c
@@ -5050,7 +5050,7 @@ static void ath11k_update_radiotap(struct ath11k *ar,
 	u8 *ptr = NULL;
 
 	rxs->flag |= RX_FLAG_MACTIME_START;
-	rxs->signal = ppduinfo->rssi_comb + ATH11K_DEFAULT_NOISE_FLOOR;
+	rxs->signal = ppduinfo->rssi_comb + ath11k_noise_floor(ar, rxs->freq);
 
 	if (ppduinfo->nss)
 		rxs->nss = ppduinfo->nss;
diff --git a/drivers/net/wireless/ath/ath11k/dp_tx.c b/drivers/net/wireless/ath/ath11k/dp_tx.c
index cac970c92806..6cd03258a5d1 100644
--- a/drivers/net/wireless/ath/ath11k/dp_tx.c
+++ b/drivers/net/wireless/ath/ath11k/dp_tx.c
@@ -358,7 +358,7 @@ ath11k_dp_tx_htt_tx_complete_buf(struct ath11k_base *ab,
 
 			if (!test_bit(WMI_TLV_SERVICE_HW_DB2DBM_CONVERSION_SUPPORT,
 				      ab->wmi_ab.svc_map))
-				info->status.ack_signal += ATH11K_DEFAULT_NOISE_FLOOR;
+				info->status.ack_signal += ath11k_noise_floor(ar, 0);
 
 			info->status.flags |=
 				IEEE80211_TX_STATUS_ACK_SIGNAL_VALID;
@@ -593,7 +593,7 @@ static void ath11k_dp_tx_complete_msdu(struct ath11k *ar,
 
 		if (!test_bit(WMI_TLV_SERVICE_HW_DB2DBM_CONVERSION_SUPPORT,
 			      ab->wmi_ab.svc_map))
-			info->status.ack_signal += ATH11K_DEFAULT_NOISE_FLOOR;
+			info->status.ack_signal += ath11k_noise_floor(ar, 0);
 
 		info->status.flags |= IEEE80211_TX_STATUS_ACK_SIGNAL_VALID;
 	}
diff --git a/drivers/net/wireless/ath/ath11k/mac.c b/drivers/net/wireless/ath/ath11k/mac.c
index 155ce76d9a2a..ada0f3a3c856 100644
--- a/drivers/net/wireless/ath/ath11k/mac.c
+++ b/drivers/net/wireless/ath/ath11k/mac.c
@@ -7522,6 +7522,20 @@ static int ath11k_mac_op_ampdu_action(struct ieee80211_hw *hw,
 	return ret;
 }
 
+/* how long a station dump reports signals with a noise floor before it
+ * reads the floor again
+ */
+#define ATH11K_NOISE_FLOOR_REFRESH	(10 * HZ)
+
+/* forget the noise floor of the channel the radio is leaving */
+static void ath11k_mac_clear_noise_floor(struct ath11k *ar)
+{
+	lockdep_assert_held(&ar->data_lock);
+
+	WRITE_ONCE(ar->noise_floor, 0);
+	ar->noise_floor_time = jiffies - ATH11K_NOISE_FLOOR_REFRESH - 1;
+}
+
 static int ath11k_mac_op_add_chanctx(struct ieee80211_hw *hw,
 				     struct ieee80211_chanctx_conf *ctx)
 {
@@ -7539,6 +7553,7 @@ static int ath11k_mac_op_add_chanctx(struct ieee80211_hw *hw,
 	 * Rx PPDU desc information.
 	 */
 	ar->rx_channel = ctx->def.chan;
+	ath11k_mac_clear_noise_floor(ar);
 	spin_unlock_bh(&ar->data_lock);
 
 	mutex_unlock(&ar->conf_mutex);
@@ -7563,6 +7578,7 @@ static void ath11k_mac_op_remove_chanctx(struct ieee80211_hw *hw,
 	 * rx_channel with the channel of that remaining channel context.
 	 */
 	ar->rx_channel = NULL;
+	ath11k_mac_clear_noise_floor(ar);
 	spin_unlock_bh(&ar->data_lock);
 
 	mutex_unlock(&ar->conf_mutex);
@@ -7803,6 +7819,7 @@ ath11k_mac_update_vif_chan(struct ath11k *ar,
 	if (n_vifs) {
 		spin_lock_bh(&ar->data_lock);
 		ar->rx_channel = vifs[0].new_ctx->def.chan;
+		ath11k_mac_clear_noise_floor(ar);
 		spin_unlock_bh(&ar->data_lock);
 	}
 
@@ -9342,44 +9359,71 @@ ath11k_mac_update_bss_chan_survey(struct ath11k *ar,
 		ath11k_warn(ar->ab, "bss channel survey timed out\n");
 }
 
-/* The noise floor in the firmware's bss channel info event is not the
- * channel's measured noise floor: on IPQ8074 it reads about -109 dBm on
- * 5 GHz and -102 dBm on 2.4 GHz, and barely moves, while the measured value
- * the firmware reports in its pdev stats is -94 and -96. Report the measured
- * one for the channel in use, as the channel info events of a scan do for
- * the other channels.
+/* Read the measured noise floor of the channel in use from the firmware's
+ * pdev stats, and keep it for the signals reported on that channel (see
+ * ath11k_noise_floor()). Return it, or 0 if there is none.
  */
-static void ath11k_mac_get_chan_noise_floor(struct ath11k *ar,
-					    struct survey_info *ar_survey,
-					    struct survey_info *survey)
+static s32 ath11k_mac_read_noise_floor(struct ath11k *ar)
 {
 	struct ath11k_fw_stats_pdev *pdev;
+	bool db2dbm = test_bit(WMI_TLV_SERVICE_HW_DB2DBM_CONVERSION_SUPPORT,
+			       ar->ab->wmi_ab.svc_map);
 	s32 nf;
 
 	lockdep_assert_held(&ar->conf_mutex);
 
-	if (ar->scan.state != ATH11K_SCAN_IDLE)
-		return;
+	ar->noise_floor_time = jiffies;
+
+	if (!ar->rx_channel || ar->scan.state != ATH11K_SCAN_IDLE)
+		return 0;
 
 	if (ath11k_mac_get_fw_stats(ar, ar->pdev->pdev_id, 0,
 				    WMI_REQUEST_PDEV_STAT))
-		return;
+		return 0;
 
 	spin_lock_bh(&ar->data_lock);
 	pdev = list_first_entry_or_null(&ar->fw_stats.pdevs,
 					struct ath11k_fw_stats_pdev, list);
 	nf = pdev ? pdev->ch_noise_floor : 0;
+	if (nf >= 0 || nf <= -127)
+		nf = 0;
+	if (nf && !db2dbm) {
+		WRITE_ONCE(ar->noise_floor_freq, ar->rx_channel->center_freq);
+		WRITE_ONCE(ar->noise_floor, nf);
+	}
+	spin_unlock_bh(&ar->data_lock);
+
+	ath11k_dbg(ar->ab, ATH11K_DBG_MAC, "noise floor %d dBm on %u MHz\n",
+		   nf, ar->rx_channel->center_freq);
+
+	return nf;
+}
+
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
+	s32 nf = ath11k_mac_read_noise_floor(ar);
+
+	if (!nf)
+		return;
+
 	/* keep it for the channel too, so its survey shows the last measured
 	 * value once the radio has left it
 	 */
-	if (nf < 0 && nf > -127)
-		ar_survey->noise = nf;
+	spin_lock_bh(&ar->data_lock);
+	ar_survey->noise = nf;
 	spin_unlock_bh(&ar->data_lock);
 
-	if (nf < 0 && nf > -127) {
-		survey->noise = nf;
-		survey->filled |= SURVEY_INFO_NOISE_DBM;
-	}
+	survey->noise = nf;
+	survey->filled |= SURVEY_INFO_NOISE_DBM;
 }
 
 static int ath11k_mac_op_get_survey(struct ieee80211_hw *hw, int idx,
@@ -9507,6 +9551,10 @@ static void ath11k_mac_op_sta_statistics(struct ieee80211_hw *hw,
 		ath11k_mac_put_chain_rssi(sinfo, arsta, "fw stats", true);
 	}
 
+	if (!db2dbm &&
+	    time_after(jiffies, ar->noise_floor_time + ATH11K_NOISE_FLOOR_REFRESH))
+		ath11k_mac_read_noise_floor(ar);
+
 	signal = arsta->rssi_comb;
 	if (!signal &&
 	    arsta->arvif->vdev_type == WMI_VDEV_TYPE_STA &&
@@ -9521,14 +9569,14 @@ static void ath11k_mac_op_sta_statistics(struct ieee80211_hw *hw,
 		   db2dbm, arsta->rssi_comb, arsta->rssi_beacon);
 
 	if (signal) {
-		sinfo->signal = db2dbm ? signal : signal + ATH11K_DEFAULT_NOISE_FLOOR;
+		sinfo->signal = db2dbm ? signal : signal + ath11k_noise_floor(ar, 0);
 		sinfo->filled |= BIT_ULL(NL80211_STA_INFO_SIGNAL);
 	}
 
 	sinfo->signal_avg = ewma_avg_rssi_read(&arsta->avg_rssi);
 
 	if (!db2dbm)
-		sinfo->signal_avg += ATH11K_DEFAULT_NOISE_FLOOR;
+		sinfo->signal_avg += ath11k_noise_floor(ar, 0);
 
 	sinfo->filled |= BIT_ULL(NL80211_STA_INFO_SIGNAL_AVG);
 }
diff --git a/drivers/net/wireless/ath/ath11k/wmi.c b/drivers/net/wireless/ath/ath11k/wmi.c
index 08fd6795ed9e..dfb8509ede75 100644
--- a/drivers/net/wireless/ath/ath11k/wmi.c
+++ b/drivers/net/wireless/ath/ath11k/wmi.c
@@ -7695,7 +7695,7 @@ static void ath11k_mgmt_rx_event(struct ath11k_base *ab, struct sk_buff *skb)
 		status->freq = ieee80211_channel_to_frequency(rx_ev.channel,
 							      status->band);
 
-	status->signal = rx_ev.snr + ATH11K_DEFAULT_NOISE_FLOOR;
+	status->signal = rx_ev.snr + ath11k_noise_floor(ar, status->freq);
 	status->rate_idx = ath11k_mac_bitrate_to_idx(sband, rx_ev.rate / 100);
 
 	hdr = (struct ieee80211_hdr *)skb->data;

---
base-commit: cd026e68fdbf88b9cc522b76c7a9d92c9a41f709
change-id: 20261029-ath11k-signal-noise-floor-c7b10f2cd0bd
prerequisite-change-id: 20261024-ath11k-rx-channel-switch-4ae05c7a827c:v1
prerequisite-patch-id: 56c9f55a2b8fc7289ed2f2d736587a8869952253
prerequisite-change-id: 20261024-ath11k-survey-noise-floor-c8a59c8c88f4:v1
prerequisite-patch-id: 2d448d49f848e484eda837fc11f04458b594c770

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

