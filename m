From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Sat, 24 Oct 2026 19:32:35 -0500
Subject: [PATCH ath-next] wifi: ath11k: update rx_channel on a channel
 switch
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261024-ath11k-rx-channel-switch-v1-1-5fc2ba53ca8f@gmail.com>
X-B4-Tracking: v=1; b=H4sIACJO3WoC/yWMywrCMBAAf6Xs2YUk9CH+iniI27XZKlGyUQOl/
 25qj8Mws4ByElY4NQsk/ojKM1awhwYo+DgxylgZnHG9Na5Fn4O1d0wFNx/5gfqVTAFbz6ajwR/
 dQFDzV+KblP/6DLXCyCXDZTf6vs5MeTvDuv4AidJlIYYAAAA=
X-Change-ID: 20261024-ath11k-rx-channel-switch-4ae05c7a827c
To: Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792888354; l=2001;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=kTWUZESPAc792VYyFo+r+HGw4s7n/5MRkmKtIAEAtgs=;
 b=vhyYKPGw9EbnJzDdV9aqEFWsjo+UfoGalyF9npk5BmC5+Nej8/Dl7s6197KrPyx2dCKeKoTHE
 TpUmvfL9JLVBd1D2SG9KfcR/JLMxqrrAWJLUffoKzCC8ItdU1HQ+wiv
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ath11k keeps the radio's current channel in ar->rx_channel: survey dumps
flag that channel as in use, and only for it is the bss channel info
requested. ath11k_mac_op_add_chanctx() sets it, but a channel switch
(CSA, or hostapd's switch_chan) goes through ath11k_mac_update_vif_chan(),
which leaves it at the old channel ("TODO: Update ar->rx_channel"). After
a switch the survey keeps marking the old channel as in use and never
refreshes the new one.

Set it to the new context's channel, as ath10k does in its
ath10k_mac_update_vif_chan(). ath11k uses one channel context per radio,
so every vif in the switch moves to the same channel.

Tested-on: IPQ8074 hw2.0 AHB WLAN.HK.2.9.0.1-02146-QCAHKSWPL_SILICONZ-1

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
Found on an Arista C-260 (IPQ8074) while chasing a wrong survey noise
floor; the noise floor fix itself is sent separately ("wifi: ath11k:
report the measured noise floor of the channel in use") and relies on
this one after a channel switch.
---
 drivers/net/wireless/ath/ath11k/mac.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/drivers/net/wireless/ath/ath11k/mac.c b/drivers/net/wireless/ath/ath11k/mac.c
index 1a237adaa..57873c875 100644
--- a/drivers/net/wireless/ath/ath11k/mac.c
+++ b/drivers/net/wireless/ath/ath11k/mac.c
@@ -7800,7 +7800,11 @@ ath11k_mac_update_vif_chan(struct ath11k *ar,
 	 * should be available for the channel switch now.
 	 */
 
-	/* TODO: Update ar->rx_channel */
+	if (n_vifs) {
+		spin_lock_bh(&ar->data_lock);
+		ar->rx_channel = vifs[0].new_ctx->def.chan;
+		spin_unlock_bh(&ar->data_lock);
+	}
 
 	for (i = 0; i < n_vifs; i++) {
 		arvif = ath11k_vif_to_arvif(vifs[i].vif);

---
base-commit: cd026e68fdbf88b9cc522b76c7a9d92c9a41f709
change-id: 20261024-ath11k-rx-channel-switch-4ae05c7a827c

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

