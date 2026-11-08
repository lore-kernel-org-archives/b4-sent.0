From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Sun, 08 Nov 2026 16:45:29 -0600
Subject: [PATCH 1/2] wifi: ath11k: report TX airtime to mac80211
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-ath11k-tx-airtime-v1-1-f1a02b2372d4@gmail.com>
References: <20261108-ath11k-tx-airtime-v1-0-f1a02b2372d4@gmail.com>
In-Reply-To: <20261108-ath11k-tx-airtime-v1-0-f1a02b2372d4@gmail.com>
To: Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794177928; l=3065;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=zAGNDCci+NrWD77ftsAlGwIki6RsHsOwcH4VFGyismo=;
 b=2vusuqHf4uq8QZiEe/1l+A/qBvkFBYziwTATE3j7XuQXLKs1bcDINSDo5W3GhOWzicy33hUdD
 gQ1j98m4d7pB9Fes4Wt/OF5XWFKnSrU8S3Hr9t/5j2D/JVxPD/S4y/O
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mac80211's airtime fairness schedules a station's TX queues by the
airtime the driver reports with ieee80211_sta_register_airtime().
ath11k never reports any, so on every ath11k radio each station's
deficit stays where it started and the scheduler falls back to round
robin: the station's airtime file in debugfs reads "TX: 0 us" however
much it sends, though airtime_flags has TX and RX set.

The firmware reports each PPDU's frame exchange duration in the HTT
PPDU stats (fes_duration_us), and ath11k_update_per_peer_tx_stats()
already adds it to arsta->tx_duration for the station dump. Register it
with mac80211 as well, as the station's TX airtime on the PPDU's TID,
split evenly among the users of an MU PPDU. PPDUs without a QoS TID
are skipped, as the peer stats skip them, and the call is made after
base_lock is dropped, since mac80211 takes its own active_txq_lock.
ath10k (htt_rx.c) and mt76 feed mac80211 the same way.

On an IPQ8074 AP with a QCN9074 6 GHz radio at 160 MHz, with this and
the next patch: each station's airtime now accrues (50 s and 20 s of TX
for two clients under load, deficits moving), one client's TCP download
ran 1777 Mbit/s against 1672 before (means of 6 and 12 runs of 30 s),
two clients together 1540 and 1524 against 1569 and 1566, and the 95th
percentile ping under the two-client load fell from 61 to 42-50 ms for
one client and from 56-77 to 31-44 ms for the other.

The change, this message and the test were written with Claude, an AI
coding assistant.

Tested-on: QCN9074 hw1.0 PCI WLAN.HK.2.5.r4-00683-QCAHKSWPL_SILICONZ-1
Tested-on: IPQ8074 hw2.0 AHB WLAN.HK.2.9.0.1-02146-QCAHKSWPL_SILICONZ-1
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
 drivers/net/wireless/ath/ath11k/dp_rx.c | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/drivers/net/wireless/ath/ath11k/dp_rx.c b/drivers/net/wireless/ath/ath11k/dp_rx.c
index 6d95f7b343a55..b394a4cfaaaa9 100644
--- a/drivers/net/wireless/ath/ath11k/dp_rx.c
+++ b/drivers/net/wireless/ath/ath11k/dp_rx.c
@@ -1380,7 +1380,7 @@ ath11k_update_per_peer_tx_stats(struct ath11k *ar,
 	u8 flags, mcs, nss, bw, sgi, dcm, rate_idx = 0;
 	u32 succ_bytes = 0;
 	u16 rate = 0, succ_pkts = 0;
-	u32 tx_duration = 0;
+	u32 tx_duration = 0, airtime = 0;
 	u8 tid = HTT_PPDU_STATS_NON_QOS_TID;
 	bool is_ampdu = false;
 
@@ -1496,6 +1496,9 @@ ath11k_update_per_peer_tx_stats(struct ath11k *ar,
 	 * So skip peer stats update for mgmt packets.
 	 */
 	if (tid < HTT_PPDU_STATS_NON_QOS_TID) {
+		/* the users of an MU PPDU share its frame exchange */
+		airtime = tx_duration / max_t(u8, common->num_users, 1);
+
 		memset(peer_stats, 0, sizeof(*peer_stats));
 		peer_stats->succ_pkts = succ_pkts;
 		peer_stats->succ_bytes = succ_bytes;
@@ -1510,6 +1513,10 @@ ath11k_update_per_peer_tx_stats(struct ath11k *ar,
 	}
 
 	spin_unlock_bh(&ab->base_lock);
+
+	if (airtime)
+		ieee80211_sta_register_airtime(sta, tid, airtime, 0);
+
 	rcu_read_unlock();
 }
 

-- 
2.43.0

