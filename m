From: Ahmet Zeren <niko3x@proton.me>
Date: Sun, 22 Nov 2026 08:59:31 +0300
Subject: [PATCH rtw-next v2 3/3] wifi: rtl8xxxu: honour the bandwidth of
 injected frames on gen1 chips
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-inject-v2-3-0ee720fe706d@proton.me>
References: <20261122-b4-inject-v2-0-0ee720fe706d@proton.me>
In-Reply-To: <20261122-b4-inject-v2-0-0ee720fe706d@proton.me>
To: Jes Sorensen <Jes.Sorensen@gmail.com>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ping-Ke Shih <pkshih@realtek.com>, Ahmet Zeren <niko3x@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795327172; l=2300;
 i=niko3x@proton.me; s=20261119; h=from:subject:message-id;
 bh=BWt8I4IM+KIbVr++O0EYE71ngSU1pr2qh46dYNVlYmg=;
 b=+kcGfWu4ZKd3LaMliWy36LGjq2rfKOYXsnXnjlNalYDAaoMUb7TwLJazC7uEVYmdnfrOlm159
 SIw3DEYHTr+CyClWPcpyKAzuCtukkATnEmr4+xjawVGiplPVbksjkEu
X-Developer-Key: i=niko3x@proton.me; a=ed25519;
 pk=J4zNm2pudzQ/wF+pQ8xO+wW6jpcNa9EJ2C1g4DUAjhM=
X-Endpoint-Received: by B4 Relay for niko3x@proton.me/20261119 with auth_id=1575
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Injected frames are always sent at 20 MHz, even when they ask for 40 MHz
on a 40 MHz channel, because only QoS data frames get the 40 MHz bits in
the TX descriptor.

Set them for injected frames with IEEE80211_TX_RC_40_MHZ_WIDTH.

Tested on RTL8192CU (0bda:8178) on channel 6 HT40+ and HT40-, received
by a second radio sniffing at 40 MHz: MCS 0 and 7 requested at 40 MHz
arrive at 40 MHz (without this patch: 20 MHz), requested at 20 MHz they
stay at 20 MHz.

Acked-by: Ping-Ke Shih <pkshih@realtek.com>
Signed-off-by: Ahmet Zeren <niko3x@proton.me>
---
 drivers/net/wireless/realtek/rtl8xxxu/core.c | 22 ++++++++++++++--------
 1 file changed, 14 insertions(+), 8 deletions(-)

diff --git a/drivers/net/wireless/realtek/rtl8xxxu/core.c b/drivers/net/wireless/realtek/rtl8xxxu/core.c
index 7d6f5243f64..0f7c4ee4437 100644
--- a/drivers/net/wireless/realtek/rtl8xxxu/core.c
+++ b/drivers/net/wireless/realtek/rtl8xxxu/core.c
@@ -5278,6 +5278,7 @@ rtl8xxxu_fill_txdesc_v1(struct ieee80211_hw *hw, struct ieee80211_hdr *hdr,
 	u16 seq_number;
 	int retries;
 	bool inject;
+	bool bw40;
 
 	inject = rtl8xxxu_tx_rate_inject(tx_info, &rate, &sgi);
 	retries = rtl8xxxu_tx_retry_inject(tx_info);
@@ -5313,17 +5314,22 @@ rtl8xxxu_fill_txdesc_v1(struct ieee80211_hw *hw, struct ieee80211_hdr *hdr,
 		tx_desc->txdw5 |= cpu_to_le32(TXDESC32_RETRY_LIMIT_ENABLE);
 	}
 
-	if (ieee80211_is_data_qos(hdr->frame_control)) {
+	if (ieee80211_is_data_qos(hdr->frame_control))
 		tx_desc->txdw4 |= cpu_to_le32(TXDESC32_QOS);
 
-		if (conf_is_ht40(&hw->conf)) {
-			tx_desc->txdw4 |= cpu_to_le32(TXDESC_DATA_BW);
+	if (inject)
+		bw40 = tx_info->control.rates[0].flags & IEEE80211_TX_RC_40_MHZ_WIDTH;
+	else
+		bw40 = ieee80211_is_data_qos(hdr->frame_control) &&
+		       conf_is_ht40(&hw->conf);
 
-			if (conf_is_ht40_minus(&hw->conf))
-				tx_desc->txdw4 |= cpu_to_le32(TXDESC_PRIME_CH_OFF_UPPER);
-			else
-				tx_desc->txdw4 |= cpu_to_le32(TXDESC_PRIME_CH_OFF_LOWER);
-		}
+	if (bw40) {
+		tx_desc->txdw4 |= cpu_to_le32(TXDESC_DATA_BW);
+
+		if (conf_is_ht40_minus(&hw->conf))
+			tx_desc->txdw4 |= cpu_to_le32(TXDESC_PRIME_CH_OFF_UPPER);
+		else
+			tx_desc->txdw4 |= cpu_to_le32(TXDESC_PRIME_CH_OFF_LOWER);
 	}
 
 	if (short_preamble)

-- 
2.56.1

