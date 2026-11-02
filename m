From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Sun, 01 Nov 2026 23:14:09 -0600
Subject: [PATCH ath-next 1/3] wifi: ath11k: size monitor MPDUs by the
 chip's rx descriptor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-b8-monitor-frames-v1-1-f0a43d9630e5@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793596448; l=4542;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=A4A9iBgn+H+lp5REIyv/F4O/tf6R5XCCM4Z11kdHy5w=;
 b=AavwHSr+3kshmLM+ZxJ3/rk3ost96GccyiyjZevVa+7h4ZAXMRVU4XiKgJYwiN4tT4O2bP3qT
 lEwPl9Jdrt5DGPCMGUeGzlyNEAF1VvTZ8f2WJiwDLnqJvD2Zve3Ss8U
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The monitor destination ring path sets each buffer's length from
sizeof(struct hal_rx_desc), but pulls the chip's own descriptor,
hw_params.hal_desc_sz, off its front. struct hal_rx_desc is the union
of the descriptors of all supported chips; it is 392 bytes, WCN6855's
size. IPQ8074, IPQ6018 and QCN9074 use a 384-byte descriptor, so on
them every MPDU a monitor interface gets ends with 8 bytes the hardware
did not write. After the RAW path trims the FCS, a frame still carries
its FCS plus 4 stale bytes, and the radiotap header flags neither.
Wireshark shows such management frames as malformed.

ath11k_dp_mon_set_frag_len() uses the same size for the payload of a
continuation buffer, so the last buffer of a long MPDU is another
8 bytes too long for each buffer before it.

Use hal_desc_sz in both places, as the rest of the rx path does.

Seen on an Arista C-360 (IPQ8074 plus QCN9074): a monitor capture of a
management frame had the FCS and 4 more bytes after the body.

Fixes: e4073430ee1d ("ath11k: add dp support for WCN6855")
Tested-on: QCN9074 hw1.0 PCI WLAN.HK.2.5.r4-00683-QCAHKSWPL_SILICONZ-1

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
 drivers/net/wireless/ath/ath11k/dp_rx.c | 26 ++++++++++++++++----------
 1 file changed, 16 insertions(+), 10 deletions(-)

diff --git a/drivers/net/wireless/ath/ath11k/dp_rx.c b/drivers/net/wireless/ath/ath11k/dp_rx.c
index 31faeda461acf..4e0b717b6f06d 100644
--- a/drivers/net/wireless/ath/ath11k/dp_rx.c
+++ b/drivers/net/wireless/ath/ath11k/dp_rx.c
@@ -4524,10 +4524,13 @@ int ath11k_dp_rx_pdev_alloc(struct ath11k_base *ab, int mac_id)
 	return 0;
 }
 
-static void ath11k_dp_mon_set_frag_len(u32 *total_len, u32 *frag_len)
+static void ath11k_dp_mon_set_frag_len(struct ath11k_base *ab,
+				       u32 *total_len, u32 *frag_len)
 {
-	if (*total_len >= (DP_RX_BUFFER_SIZE - sizeof(struct hal_rx_desc))) {
-		*frag_len = DP_RX_BUFFER_SIZE - sizeof(struct hal_rx_desc);
+	u32 hal_rx_desc_sz = ab->hw_params.hal_desc_sz;
+
+	if (*total_len >= (DP_RX_BUFFER_SIZE - hal_rx_desc_sz)) {
+		*frag_len = DP_RX_BUFFER_SIZE - hal_rx_desc_sz;
 		*total_len -= *frag_len;
 	} else {
 		*frag_len = *total_len;
@@ -4675,7 +4678,8 @@ static bool ath11k_dp_rx_mon_comp_ppduid(u32 msdu_ppdu_id, u32 *ppdu_id,
 	return false;
 }
 
-static void ath11k_dp_mon_get_buf_len(struct hal_rx_msdu_desc_info *info,
+static void ath11k_dp_mon_get_buf_len(struct ath11k_base *ab,
+				      struct hal_rx_msdu_desc_info *info,
 				      bool *is_frag, u32 *total_len,
 				      u32 *frag_len, u32 *msdu_cnt)
 {
@@ -4684,11 +4688,11 @@ static void ath11k_dp_mon_get_buf_len(struct hal_rx_msdu_desc_info *info,
 			*total_len = info->msdu_len;
 			*is_frag = true;
 		}
-		ath11k_dp_mon_set_frag_len(total_len,
+		ath11k_dp_mon_set_frag_len(ab, total_len,
 					   frag_len);
 	} else {
 		if (*is_frag) {
-			ath11k_dp_mon_set_frag_len(total_len,
+			ath11k_dp_mon_set_frag_len(ab, total_len,
 						   frag_len);
 		} else {
 			*frag_len = info->msdu_len;
@@ -4826,7 +4830,7 @@ u32 ath11k_dp_rx_mon_mpdu_pop(struct ath11k *ar, int mac_id,
 
 			rx_desc = (struct hal_rx_desc *)msdu->data;
 
-			rx_pkt_offset = sizeof(struct hal_rx_desc);
+			rx_pkt_offset = ar->ab->hw_params.hal_desc_sz;
 			l2_hdr_offset = ath11k_dp_rx_h_msdu_end_l3pad(ar->ab, rx_desc);
 
 			if (is_first_msdu) {
@@ -4855,7 +4859,8 @@ u32 ath11k_dp_rx_mon_mpdu_pop(struct ath11k *ar, int mac_id,
 				pmon->mon_last_linkdesc_paddr = paddr;
 				is_first_msdu = false;
 			}
-			ath11k_dp_mon_get_buf_len(&msdu_list.msdu_info[i],
+			ath11k_dp_mon_get_buf_len(ar->ab,
+						  &msdu_list.msdu_info[i],
 						  &is_frag, &total_len,
 						  &frag_len, &msdu_cnt);
 			rx_buf_size = rx_pkt_offset + l2_hdr_offset + frag_len;
@@ -5458,7 +5463,7 @@ ath11k_dp_rx_full_mon_mpdu_pop(struct ath11k *ar,
 
 			rx_desc = (struct hal_rx_desc *)msdu->data;
 
-			rx_pkt_offset = sizeof(struct hal_rx_desc);
+			rx_pkt_offset = ar->ab->hw_params.hal_desc_sz;
 			l2_hdr_offset = ath11k_dp_rx_h_msdu_end_l3pad(ar->ab, rx_desc);
 
 			if (is_first_msdu) {
@@ -5471,7 +5476,8 @@ ath11k_dp_rx_full_mon_mpdu_pop(struct ath11k *ar,
 				is_first_msdu = false;
 			}
 
-			ath11k_dp_mon_get_buf_len(&msdu_list.msdu_info[i],
+			ath11k_dp_mon_get_buf_len(ar->ab,
+						  &msdu_list.msdu_info[i],
 						  &is_frag, &total_len,
 						  &frag_len, &msdu_cnt);
 

-- 
2.43.0

