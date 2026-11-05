From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Thu, 05 Nov 2026 13:20:18 -0600
Subject: [PATCH] wifi: ath11k: keep the PPDU status for the full monitor
 delivery
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-ath11k-full-mon-ppdu-status-v1-1-819a3e225b9b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAPHW7GoC/yXMwQ6CMAwA0F8hPduEzcDBXzEexlqkiGNZN2JC+
 HenHN/l7aCchBVuzQ6JN1FZQ4W5NOAnF56MQtVgW9sb03bo8mTMC8eyLPheA8ZIBTW7XBRp8D0
 RdXy1HuoQE4/y+e/3x2ktw8w+/0o4ji9o+0FSfwAAAA==
X-Change-ID: 20261105-ath11k-full-mon-ppdu-status-dbc6ddd5e32c
To: Jeff Johnson <jjohnson@kernel.org>, 
 Aloka Dixit <quic_alokad@quicinc.com>, Kalle Valo <kvalo@kernel.org>, 
 Baochen Qiang <baochen.qiang@oss.qualcomm.com>, 
 Matthew Leach <matthew.leach@collabora.com>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Jeff Johnson <jeff.johnson@oss.qualcomm.com>, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793906418; l=3067;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=4fc48RxbyexxMZuKcYsZ86QAk9wyIus7mswxJpeNaL4=;
 b=WK2YA9h1OGQghson9ByDiVw1Yk8uOT5wEVWfCpprjGXlhy4pmBnjrs0003SkGBXpkiJhACRHO
 rkV3EfhvuD3AunvDGwOYvlu78FVAhnPm60sL1gMENVBq2FgoAarSVdq
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In full monitor mode (QCN9074), ath11k_dp_rx_process_full_mon_status_ring()
reaps the status buffer of the held PPDU with
ath11k_dp_rx_process_mon_status() and then delivers the PPDU's MPDUs with
pmon->mon_ppdu_info, the status that function parsed. But
ath11k_dp_rx_process_mon_status() clears mon_ppdu_info again after each
status buffer whose PPDU names a peer ID, whether the peer is found or
not. Since commit 2a2451a34afd ("wifi: ath11k: fix peer resolution on rx
path when peer_id=0") a PPDU from a station without a peer, which is
every frame a monitor hears from other BSSs, names peer ID 0 and is
cleared too. Every frame a QCN9074 monitor delivers then has an empty
status: signal -95 dBm (the default noise floor and a zero rssi_comb),
no TSFT, and the rate of its rx descriptor instead of its PPDU's.

Each status buffer is already parsed from a cleared status. Drop the
clear after it, so that the status of the last parsed PPDU stays for the
delivery. The other monitor path is not affected: it delivers from
within the loop, before the clear.

On a QCN9074 alone in monitor mode on 6 GHz (5975, 6135 and 6455 MHz,
frames from neighbouring APs), 311 of 313 frames had signal -95 dBm and
TSFT 0 before. After, 307 of 309 had their received level (-79 and
-80 dBm for the nearest AP's beacons) and their TSFT, and the beacons
their 6 Mb/s rate instead of 48.

Tested-on: QCN9074 hw1.0 PCI WLAN.HK.2.5.r4-00683-QCAHKSWPL_SILICONZ-1

Fixes: 67a9d399fcb0 ("ath11k: enable RX PPDU stats in monitor co-exist mode")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
 drivers/net/wireless/ath/ath11k/dp_rx.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/net/wireless/ath/ath11k/dp_rx.c b/drivers/net/wireless/ath/ath11k/dp_rx.c
index 6d95f7b343a55..8bee3bfe33dfe 100644
--- a/drivers/net/wireless/ath/ath11k/dp_rx.c
+++ b/drivers/net/wireless/ath/ath11k/dp_rx.c
@@ -5290,6 +5290,10 @@ int ath11k_dp_rx_process_mon_status(struct ath11k_base *ab, int mac_id,
 		if (log_type != ATH11K_PKTLOG_TYPE_INVALID)
 			trace_ath11k_htt_rxdesc(ar, skb->data, log_type, rx_buf_sz);
 
+		/* Each status buffer is parsed from a clear status. The last one's
+		 * stays in mon_ppdu_info: full monitor mode delivers its PPDU after
+		 * this returns, with that status (signal, TSFT, rate).
+		 */
 		memset(ppdu_info, 0, sizeof(*ppdu_info));
 		ppdu_info->peer_id = HAL_INVALID_PEERID;
 		hal_status = ath11k_hal_rx_parse_mon_status(ab, ppdu_info, skb);
@@ -5334,8 +5338,6 @@ int ath11k_dp_rx_process_mon_status(struct ath11k_base *ab, int mac_id,
 		rcu_read_unlock();
 
 		dev_kfree_skb_any(skb);
-		memset(ppdu_info, 0, sizeof(*ppdu_info));
-		ppdu_info->peer_id = HAL_INVALID_PEERID;
 	}
 exit:
 	return num_buffs_reaped;

---
base-commit: 5c8eab13e391aaabd5a1ad58f3ee4bb10ce7573e
change-id: 20261105-ath11k-full-mon-ppdu-status-dbc6ddd5e32c

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

