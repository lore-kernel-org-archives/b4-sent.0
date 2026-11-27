From: Ahmet Zeren <niko3x@proton.me>
Date: Fri, 27 Nov 2026 12:00:00 +0300
Subject: [PATCH RFT rtw-next v2 2/2] wifi: rtw88: honour the retry count
 and NO_ACK of injected frames
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-b4-rtw88-inject-v2-2-f9701b9243a3@proton.me>
References: <20261127-b4-rtw88-inject-v2-0-f9701b9243a3@proton.me>
In-Reply-To: <20261127-b4-rtw88-inject-v2-0-f9701b9243a3@proton.me>
To: Ping-Ke Shih <pkshih@realtek.com>
Cc: linux-wireless@vger.kernel.org, Luka Gejak <luka.gejak@linux.dev>, 
 Bitterblue Smith <rtl8821cerfe2@gmail.com>, linux-kernel@vger.kernel.org, 
 Ahmet Zeren <niko3x@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795770000; l=4930;
 i=niko3x@proton.me; s=20261119; h=from:subject:message-id;
 bh=POOXTH3H0L3oyee8z36H+ZnuQn4Fh7XcOGuPBQbULUU=;
 b=8qWHhhf9NWi8e6rK9TvWkG2sBZfZjETpMs+88M1I4qfGjeaqUl+8GsNroyaT56s5RBun8aB/3
 h6PyjGJFLr+Duhu7fqdFebQf+xo8LHoBzoVNKQh2I4i3sRKuF/3+//G
X-Developer-Key: i=niko3x@proton.me; a=ed25519;
 pk=J4zNm2pudzQ/wF+pQ8xO+wW6jpcNa9EJ2C1g4DUAjhM=
X-Endpoint-Received: by B4 Relay for niko3x@proton.me/20261119 with auth_id=1575
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

max_rate_tries is not set, so mac80211 clamps the radiotap retry count
of injected frames to zero, and the TX descriptor retry limit is never
programmed. Injected unicast frames, even NO_ACK ones, are retried up to
the default limit, so frames to an absent station stall injection. The
TX report path also reports NO_ACK frames as not acked.

Limit max_rate_tries by both the TX descriptor retry limit and
IEEE80211_MAX_TX_RETRY, and program the descriptor retry limit for
injected frames: no retries for NO_ACK frames, otherwise the radiotap
retry count if the frame has a usable radiotap rate. In the TX report,
report NO_ACK frames that were sent as IEEE80211_TX_STAT_NOACK_TRANSMITTED
rather than acked; this includes group addressed frames.

rtw89 got similar changes in commit 92608bb5f14f ("wifi: rtw89: honor
ASSIGN_SEQ, retries, and NO_ACK for injected frames"). The retry limit
fields are at the same place as TXDESC40_RETRY_LIMIT_* in the
RTL8192EU/RTL8723BU TX descriptor of rtl8xxxu.

Signed-off-by: Ahmet Zeren <niko3x@proton.me>
---
 drivers/net/wireless/realtek/rtw88/main.c |  1 +
 drivers/net/wireless/realtek/rtw88/main.h |  3 +++
 drivers/net/wireless/realtek/rtw88/tx.c   | 16 ++++++++++++++--
 drivers/net/wireless/realtek/rtw88/tx.h   |  2 ++
 4 files changed, 20 insertions(+), 2 deletions(-)

diff --git a/drivers/net/wireless/realtek/rtw88/main.c b/drivers/net/wireless/realtek/rtw88/main.c
index 826e1bc3724..c715a6e86a1 100644
--- a/drivers/net/wireless/realtek/rtw88/main.c
+++ b/drivers/net/wireless/realtek/rtw88/main.c
@@ -2273,6 +2273,7 @@ int rtw_register_hw(struct rtw_dev *rtwdev, struct ieee80211_hw *hw)
 		max_tx_headroom += RTW_SDIO_DATA_PTR_ALIGN;
 
 	hw->extra_tx_headroom = max_tx_headroom;
+	hw->max_rate_tries = min(RTW_TX_DATA_RTY_LMT_MAX + 1, IEEE80211_MAX_TX_RETRY);
 	hw->queues = IEEE80211_NUM_ACS;
 	hw->txq_data_size = sizeof(struct rtw_txq);
 	hw->sta_data_size = sizeof(struct rtw_sta_info);
diff --git a/drivers/net/wireless/realtek/rtw88/main.h b/drivers/net/wireless/realtek/rtw88/main.h
index 525f17590ad..7888033376c 100644
--- a/drivers/net/wireless/realtek/rtw88/main.h
+++ b/drivers/net/wireless/realtek/rtw88/main.h
@@ -625,6 +625,9 @@ struct rtw_tx_pkt_info {
 	bool stbc;
 	bool ldpc;
 	bool dis_rate_fallback;
+	bool rty_lmt_en;
+	u8 data_rty_lmt;
+#define RTW_TX_DATA_RTY_LMT_MAX	0x3f
 	bool bmc;
 	bool use_rate;
 	bool ls;
diff --git a/drivers/net/wireless/realtek/rtw88/tx.c b/drivers/net/wireless/realtek/rtw88/tx.c
index dd5537d0cf1..32621b5c4fa 100644
--- a/drivers/net/wireless/realtek/rtw88/tx.c
+++ b/drivers/net/wireless/realtek/rtw88/tx.c
@@ -66,7 +66,9 @@ void rtw_tx_fill_tx_desc(struct rtw_dev *rtwdev,
 		      le32_encode_bits(pkt_info->nav_use_hdr, RTW_TX_DESC_W3_NAVUSEHDR) |
 		      le32_encode_bits(pkt_info->ampdu_factor, RTW_TX_DESC_W3_MAX_AGG_NUM);
 
-	tx_desc->w4 = le32_encode_bits(pkt_info->rate, RTW_TX_DESC_W4_DATARATE);
+	tx_desc->w4 = le32_encode_bits(pkt_info->rate, RTW_TX_DESC_W4_DATARATE) |
+		      le32_encode_bits(pkt_info->rty_lmt_en, RTW_TX_DESC_W4_RTY_LMT_EN) |
+		      le32_encode_bits(pkt_info->data_rty_lmt, RTW_TX_DESC_W4_DATA_RTY_LMT);
 
 	if (rtwdev->chip->old_datarate_fb_limit)
 		tx_desc->w4 |= le32_encode_bits(0x1f, RTW_TX_DESC_W4_DATARATE_FB_LIMIT);
@@ -224,7 +226,9 @@ static void rtw_tx_report_tx_status(struct rtw_dev *rtwdev,
 
 	info = IEEE80211_SKB_CB(skb);
 	ieee80211_tx_info_clear_status(info);
-	if (acked)
+	if (acked && info->flags & IEEE80211_TX_CTL_NO_ACK)
+		info->flags |= IEEE80211_TX_STAT_NOACK_TRANSMITTED;
+	else if (acked)
 		info->flags |= IEEE80211_TX_STAT_ACK;
 	else
 		info->flags &= ~IEEE80211_TX_STAT_ACK;
@@ -412,6 +416,14 @@ static void rtw_tx_injected_pkt_info_update(struct rtw_dev *rtwdev,
 	struct ieee80211_tx_rate *rate = &info->control.rates[0];
 	u8 nss, mcs;
 
+	if (info->flags & IEEE80211_TX_CTL_NO_ACK) {
+		pkt_info->rty_lmt_en = true;
+		pkt_info->data_rty_lmt = 0;
+	} else if (info->control.flags & IEEE80211_TX_CTRL_RATE_INJECT) {
+		pkt_info->rty_lmt_en = true;
+		pkt_info->data_rty_lmt = rate->count - 1;
+	}
+
 	if (!(info->control.flags & IEEE80211_TX_CTRL_RATE_INJECT))
 		return;
 
diff --git a/drivers/net/wireless/realtek/rtw88/tx.h b/drivers/net/wireless/realtek/rtw88/tx.h
index 168f48e8785..b6c687d33db 100644
--- a/drivers/net/wireless/realtek/rtw88/tx.h
+++ b/drivers/net/wireless/realtek/rtw88/tx.h
@@ -46,6 +46,8 @@ struct rtw_tx_desc {
 #define RTW_TX_DESC_W3_MAX_AGG_NUM GENMASK(21, 17)
 #define RTW_TX_DESC_W4_DATARATE GENMASK(6, 0)
 #define RTW_TX_DESC_W4_DATARATE_FB_LIMIT GENMASK(12, 8)
+#define RTW_TX_DESC_W4_RTY_LMT_EN BIT(17)
+#define RTW_TX_DESC_W4_DATA_RTY_LMT GENMASK(23, 18)
 #define RTW_TX_DESC_W4_RTSRATE GENMASK(28, 24)
 #define RTW_TX_DESC_W5_DATA_SHORT BIT(4)
 #define RTW_TX_DESC_W5_DATA_BW GENMASK(6, 5)

-- 
2.56.1

