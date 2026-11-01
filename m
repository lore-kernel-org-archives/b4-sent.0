From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Sun, 01 Nov 2026 10:06:38 -0600
Subject: [PATCH ath-next] wifi: ath11k: report a station's TX retries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-b62-tx-retries-v1-1-c00d4e6e2739@gmail.com>
X-B4-Tracking: v=1; b=H4sIAI1j52oC/yWMwQrCMBAFf6Xs2YXuHtrir4iHND7b9RAlWSVQ+
 u+mehyGmY0KsqHQudso42PFnqmBnDqKa0gL2G6NSXsdRHrheVD2yhl+dAwZJSJMcVKlFr0y7lZ
 /wwsFXzmhOl3/prznB6IfP9r3L43ZscR8AAAA
X-Change-ID: 20261101-b62-tx-retries-e171cea8c822
To: Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793549197; l=3031;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=Pyj7rUa/qALXE2SogX70i3iq6z68HhjTQNXdCtw1Ngg=;
 b=utIthFnUbeVp92VTZjAi8ZhiEUnBoT+e26f339DHFflX3htYp/4WLq8BrY4h79myjasym9hS1
 N17OBjQt0BSB52eCjvUA2sUBtNd8tjcIeorw2vbbsmhK239jzWyBqdn
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ath11k_dp_tx_complete_msdu() hands mac80211 a status with no entry in
info->status.rates[], so that mac80211 does not update its rate
statistics from it, and a single rate with a try count of 1. mac80211
takes its retry count from info->status.rates[], so it counts none, and
"iw station dump" shows "tx retries: 0" for every station: on an Arista
C-360 (QCN9074, 6 GHz) a client showed 0 retries after 55284 frames at
HE-MCS 11.

The TX completion carries the frame's transmit count (try_cnt), which
the extended TX stats already use. Count the retransmissions per
station from it and report them as NL80211_STA_INFO_TX_RETRIES, as
ath12k does. mac80211's TX failed count (frames never acked) is
unchanged.

Tested-on: QCN9074 hw1.0 PCI WLAN.HK.2.5.r4-00683-QCAHKSWPL_SILICONZ-1
Tested-on: IPQ8074 hw2.0 AHB WLAN.HK.2.9.0.1-02146-QCAHKSWPL_SILICONZ-1

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
Seen on an Arista C-360 with OpenWrt, on its IPQ8074 and QCN9074 radios.
---
 drivers/net/wireless/ath/ath11k/core.h  | 1 +
 drivers/net/wireless/ath/ath11k/dp_tx.c | 2 ++
 drivers/net/wireless/ath/ath11k/mac.c   | 3 +++
 3 files changed, 6 insertions(+)

diff --git a/drivers/net/wireless/ath/ath11k/core.h b/drivers/net/wireless/ath/ath11k/core.h
index a0d725923ef24..ba32063092254 100644
--- a/drivers/net/wireless/ath/ath11k/core.h
+++ b/drivers/net/wireless/ath/ath11k/core.h
@@ -556,6 +556,7 @@ struct ath11k_sta {
 	struct rate_info last_txrate;
 	u64 rx_duration;
 	u64 tx_duration;
+	u64 tx_retries;
 	u8 rssi_comb;
 	struct ewma_avg_rssi avg_rssi;
 	s8 rssi_beacon;
diff --git a/drivers/net/wireless/ath/ath11k/dp_tx.c b/drivers/net/wireless/ath/ath11k/dp_tx.c
index cac970c92806a..2329c2449b572 100644
--- a/drivers/net/wireless/ath/ath11k/dp_tx.c
+++ b/drivers/net/wireless/ath/ath11k/dp_tx.c
@@ -637,6 +637,8 @@ static void ath11k_dp_tx_complete_msdu(struct ath11k *ar,
 		return;
 	}
 	arsta = ath11k_sta_to_arsta(peer->sta);
+	if (ts->try_cnt > 1)
+		arsta->tx_retries += ts->try_cnt - 1;
 	status.sta = peer->sta;
 	status.skb = msdu;
 	status.info = info;
diff --git a/drivers/net/wireless/ath/ath11k/mac.c b/drivers/net/wireless/ath/ath11k/mac.c
index 1a237adaa37d1..066a503d76d4c 100644
--- a/drivers/net/wireless/ath/ath11k/mac.c
+++ b/drivers/net/wireless/ath/ath11k/mac.c
@@ -9435,6 +9435,9 @@ static void ath11k_mac_op_sta_statistics(struct ieee80211_hw *hw,
 	sinfo->tx_duration = arsta->tx_duration;
 	sinfo->filled |= BIT_ULL(NL80211_STA_INFO_TX_DURATION);
 
+	sinfo->tx_retries = arsta->tx_retries;
+	sinfo->filled |= BIT_ULL(NL80211_STA_INFO_TX_RETRIES);
+
 	if (arsta->txrate.legacy || arsta->txrate.nss) {
 		if (arsta->txrate.legacy) {
 			sinfo->txrate.legacy = arsta->txrate.legacy;

---
base-commit: a3ddbb45768717b5c9f923489387cf55c838d1ad
change-id: 20261101-b62-tx-retries-e171cea8c822

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

