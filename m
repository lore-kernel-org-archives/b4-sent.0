From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Sun, 01 Nov 2026 23:14:11 -0600
Subject: [PATCH ath-next 3/3] wifi: ath11k: report a monitor frame's MCS
 and NSS only from the PPDU's SIG
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-b8-monitor-frames-v1-3-f0a43d9630e5@gmail.com>
References: <20261101-b8-monitor-frames-v1-0-f0a43d9630e5@gmail.com>
In-Reply-To: <20261101-b8-monitor-frames-v1-0-f0a43d9630e5@gmail.com>
To: Jeff Johnson <jjohnson@kernel.org>, 
 Jouni Malinen <quic_jouni@quicinc.com>, Kalle Valo <kvalo@kernel.org>, 
 Baochen Qiang <baochen.qiang@oss.qualcomm.com>, 
 Julia Lawall <julia.lawall@lip6.fr>, kbuild test robot <lkp@intel.com>, 
 Manikanta Pubbisetty <quic_mpubbise@quicinc.com>, 
 Venkateswara Naralasetty <quic_vnaralas@quicinc.com>, 
 Pradeep Kumar Chitrapu <quic_pradeepc@quicinc.com>, 
 Anilkumar Kolli <quic_akolli@quicinc.com>, Miles Hu <milehu@codeaurora.org>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Govindaraj Saminathan <quic_gsamin@quicinc.com>, 
 Sriram R <sriram.ramachandran@oss.qualcomm.com>, 
 Shashidhar Lakkavalli <slakkavalli@datto.com>, 
 Rajkumar Manoharan <rmanohar@codeaurora.org>, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793596448; l=4679;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=J4jRf5l59+FWEVGn47cCD/3aF3TptpB1fGEP1KJUXLA=;
 b=bmG75PeLmhL3oUTVAm+ZrW60a0gibEUkuhKP79wvs56n1yY43XiE9zmwYPAl4VwJ4b5VqU79V
 6hPVtoKyQnUBCed6G7Zy0QidhWv6iD3jnpQ+hKWbuBg3JvKL23gUjT6
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ath11k_update_radiotap() sets an HT, VHT or HE monitor frame's
rate_idx from ppduinfo->rate. That is the L-SIG rate code, not the MCS
that the SIG TLV gave (ppduinfo->mcs). ath12k had the same bug, fixed
by commit 10085a654a4c ("wifi: ath12k: fix incorrect HT/VHT/HE/EHT MCS
reporting in monitor mode").

The function also takes the preamble from the PPDU's user stats, which
can arrive without the SIG TLV. The status of one PPDU can span more
than one buffer, and since commit 01d2f285e3e5 ("ath11k: decode HE
status tlv") ppdu_info holds only what the last buffer had. The frame
then goes up as VHT or HE with MCS 0 and no spatial stream, and
mac80211 drops it, warning once:

  Rate marked as a VHT rate but data is invalid: MCS: 0, NSS: 0

An Arista C-360 with monitor interfaces up logs this, and the HE
equivalent, once per boot. Because the warning is WARN_ONCE(), every
later such frame is dropped without a message.

Take the MCS from ppduinfo->mcs, adding the stream offset for HT.
Use the PPDU's HT, VHT or HE rate only when its SIG TLV was seen with a
valid NSS and MCS. Otherwise keep the rate from the MPDU's rx
descriptor, and if that names VHT or HE with no stream, report one
rather than lose the frame.

ath11k_dp_rx_deliver_msdu() sets RX_FLAG_RADIOTAP_HE on the rx_status
that all skbs of an MPDU share. Clear the HE radiotap flags for each
skb, so that each skb's flags match the radiotap data pushed onto it.

Fixes: ab0a9ef605cf ("ath11k: translate HE status to radiotap format")
Tested-on: QCN9074 hw1.0 PCI WLAN.HK.2.5.r4-00683-QCAHKSWPL_SILICONZ-1

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
 drivers/net/wireless/ath/ath11k/dp_rx.c | 37 ++++++++++++++++++++++++++++++---
 1 file changed, 34 insertions(+), 3 deletions(-)

diff --git a/drivers/net/wireless/ath/ath11k/dp_rx.c b/drivers/net/wireless/ath/ath11k/dp_rx.c
index 7809c92baa325..53d7b19d8807c 100644
--- a/drivers/net/wireless/ath/ath11k/dp_rx.c
+++ b/drivers/net/wireless/ath/ath11k/dp_rx.c
@@ -5075,26 +5075,49 @@ static void ath11k_update_radiotap(struct ath11k *ar,
 	rxs->flag |= RX_FLAG_MACTIME_START;
 	rxs->signal = ppduinfo->rssi_comb + ath11k_noise_floor(ar, rxs->freq);
 
+	/* Each skb of the MPDU carries its own HE radiotap data, if any:
+	 * drop the flags the last one left, ath11k_dp_rx_deliver_msdu()
+	 * included.
+	 */
+	rxs->flag &= ~(RX_FLAG_RADIOTAP_HE | RX_FLAG_RADIOTAP_HE_MU);
+
+	/* An HT, VHT or HE PPDU's MCS and NSS come from its SIG TLV, its
+	 * preamble type (the *_flags) from its user stats. The status can
+	 * hold the latter without the former, as when it spans more than
+	 * one buffer. Keep the rate the MPDU's rx descriptor gave
+	 * (ath11k_dp_rx_h_ppdu()) then: reporting the preamble with no
+	 * spatial stream gets the frame dropped by mac80211.
+	 */
+	if ((ppduinfo->he_mu_flags || ppduinfo->he_flags ||
+	     ppduinfo->vht_flags || ppduinfo->ht_flags) &&
+	    (!ppduinfo->nss || ppduinfo->nss > HAL_RX_MAX_NSS ||
+	     ppduinfo->mcs > ATH11K_HE_MCS_MAX))
+		goto out;
+
 	if (ppduinfo->nss)
 		rxs->nss = ppduinfo->nss;
 
+	/* ppduinfo->rate is the L-SIG rate; an HT, VHT or HE PPDU's MCS is
+	 * ppduinfo->mcs, as the SIG TLV gives it.
+	 */
 	if (ppduinfo->he_mu_flags) {
 		rxs->flag |= RX_FLAG_RADIOTAP_HE_MU;
 		rxs->encoding = RX_ENC_HE;
 		ptr = skb_push(mon_skb, sizeof(struct ieee80211_radiotap_he_mu));
 		ath11k_dp_rx_update_radiotap_he_mu(ppduinfo, ptr);
+		rxs->rate_idx = ppduinfo->mcs;
 	} else if (ppduinfo->he_flags) {
 		rxs->flag |= RX_FLAG_RADIOTAP_HE;
 		rxs->encoding = RX_ENC_HE;
 		ptr = skb_push(mon_skb, sizeof(struct ieee80211_radiotap_he));
 		ath11k_dp_rx_update_radiotap_he(ppduinfo, ptr);
-		rxs->rate_idx = ppduinfo->rate;
+		rxs->rate_idx = ppduinfo->mcs;
 	} else if (ppduinfo->vht_flags) {
 		rxs->encoding = RX_ENC_VHT;
-		rxs->rate_idx = ppduinfo->rate;
+		rxs->rate_idx = ppduinfo->mcs;
 	} else if (ppduinfo->ht_flags) {
 		rxs->encoding = RX_ENC_HT;
-		rxs->rate_idx = ppduinfo->rate;
+		rxs->rate_idx = ppduinfo->mcs + 8 * (ppduinfo->nss - 1);
 	} else {
 		rxs->encoding = RX_ENC_LEGACY;
 		sband = &ar->mac.sbands[rxs->band];
@@ -5102,6 +5125,14 @@ static void ath11k_update_radiotap(struct ath11k *ar,
 							  ppduinfo->cck_flag);
 	}
 
+out:
+	/* The descriptor can name VHT or HE with no spatial stream too.
+	 * Report one rather than lose the frame.
+	 */
+	if ((rxs->encoding == RX_ENC_VHT || rxs->encoding == RX_ENC_HE) &&
+	    !rxs->nss)
+		rxs->nss = 1;
+
 	rxs->mactime = ppduinfo->tsft;
 }
 

-- 
2.43.0

