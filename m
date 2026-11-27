From: Ahmet Zeren <niko3x@proton.me>
Date: Fri, 27 Nov 2026 11:59:59 +0300
Subject: [PATCH RFT rtw-next v2 1/2] wifi: rtw88: use the rate, bandwidth
 and GI of injected frames
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-b4-rtw88-inject-v2-1-f9701b9243a3@proton.me>
References: <20261127-b4-rtw88-inject-v2-0-f9701b9243a3@proton.me>
In-Reply-To: <20261127-b4-rtw88-inject-v2-0-f9701b9243a3@proton.me>
To: Ping-Ke Shih <pkshih@realtek.com>
Cc: linux-wireless@vger.kernel.org, Luka Gejak <luka.gejak@linux.dev>, 
 Bitterblue Smith <rtl8821cerfe2@gmail.com>, linux-kernel@vger.kernel.org, 
 Ahmet Zeren <niko3x@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795770000; l=2582;
 i=niko3x@proton.me; s=20261119; h=from:subject:message-id;
 bh=FhYrSNa12y54f8TuWwnmFaCq9qmcQT+x3fX15vMZZZc=;
 b=2qZllMslEIoqqQfuU7er/nYfcqlWngHobLmvSRT+likvQP3ryNUusWTFCJzTi5Q++uzKIzd7e
 wRILA2UjkkEAF5EMlUMu6YxC6QsiSIm423eQXJ+ieayraFfYCeMDGab
X-Developer-Key: i=niko3x@proton.me; a=ed25519;
 pk=J4zNm2pudzQ/wF+pQ8xO+wW6jpcNa9EJ2C1g4DUAjhM=
X-Endpoint-Received: by B4 Relay for niko3x@proton.me/20261119 with auth_id=1575
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Injected frames ignore the rate, bandwidth and guard interval requested
in their radiotap header. Data frames have no station, so USE_RATE is not
set and the firmware rate adaptation picks the rate. Management frames
are sent at the lowest basic rate.

Use the injected rate, bandwidth and guard interval and disable rate
fallback, like rtw89 does since commit e96abe4fd7cd ("wifi: rtw89:
consider data rate/bandwidth/GI for injected packets"). Injected frames
without a radiotap rate are unchanged.

Signed-off-by: Ahmet Zeren <niko3x@proton.me>
---
 drivers/net/wireless/realtek/rtw88/tx.c | 35 +++++++++++++++++++++++++++++++++
 1 file changed, 35 insertions(+)

diff --git a/drivers/net/wireless/realtek/rtw88/tx.c b/drivers/net/wireless/realtek/rtw88/tx.c
index 701ed7c4f3f..dd5537d0cf1 100644
--- a/drivers/net/wireless/realtek/rtw88/tx.c
+++ b/drivers/net/wireless/realtek/rtw88/tx.c
@@ -405,6 +405,38 @@ out:
 	}
 }
 
+static void rtw_tx_injected_pkt_info_update(struct rtw_dev *rtwdev,
+					    struct rtw_tx_pkt_info *pkt_info,
+					    struct ieee80211_tx_info *info)
+{
+	struct ieee80211_tx_rate *rate = &info->control.rates[0];
+	u8 nss, mcs;
+
+	if (!(info->control.flags & IEEE80211_TX_CTRL_RATE_INJECT))
+		return;
+
+	if (rate->flags & IEEE80211_TX_RC_VHT_MCS) {
+		nss = ieee80211_rate_get_vht_nss(rate);
+		mcs = ieee80211_rate_get_vht_mcs(rate);
+		pkt_info->rate = DESC_RATEVHT1SS_MCS0 + (nss - 1) * 10 + mcs;
+	} else if (rate->flags & IEEE80211_TX_RC_MCS) {
+		pkt_info->rate = DESC_RATEMCS0 + rate->idx;
+	} else {
+		pkt_info->rate = ieee80211_get_tx_rate(rtwdev->hw, info)->hw_value;
+	}
+
+	if (rate->flags & IEEE80211_TX_RC_80_MHZ_WIDTH)
+		pkt_info->bw = RTW_CHANNEL_WIDTH_80;
+	else if (rate->flags & IEEE80211_TX_RC_40_MHZ_WIDTH)
+		pkt_info->bw = RTW_CHANNEL_WIDTH_40;
+	else
+		pkt_info->bw = RTW_CHANNEL_WIDTH_20;
+
+	pkt_info->short_gi = rate->flags & IEEE80211_TX_RC_SHORT_GI;
+	pkt_info->use_rate = true;
+	pkt_info->dis_rate_fallback = true;
+}
+
 void rtw_tx_pkt_info_update(struct rtw_dev *rtwdev,
 			    struct rtw_tx_pkt_info *pkt_info,
 			    struct ieee80211_sta *sta,
@@ -432,6 +464,9 @@ void rtw_tx_pkt_info_update(struct rtw_dev *rtwdev,
 	else if (ieee80211_is_data(fc))
 		rtw_tx_data_pkt_info_update(rtwdev, pkt_info, sta, skb);
 
+	if (unlikely(info->flags & IEEE80211_TX_CTL_INJECTED))
+		rtw_tx_injected_pkt_info_update(rtwdev, pkt_info, info);
+
 	bmc = is_broadcast_ether_addr(hdr->addr1) ||
 	      is_multicast_ether_addr(hdr->addr1);
 

-- 
2.56.1

