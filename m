From: Ahmet Zeren <niko3x@proton.me>
Date: Fri, 20 Nov 2026 01:09:29 +0300
Subject: [PATCH rtw-next 2/3] wifi: rtl8xxxu: honour the retry count of
 injected frames on gen1 chips
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-b4-inject-v1-2-1e1693af0c6b@proton.me>
References: <20261120-b4-inject-v1-0-1e1693af0c6b@proton.me>
In-Reply-To: <20261120-b4-inject-v1-0-1e1693af0c6b@proton.me>
To: Jes Sorensen <Jes.Sorensen@gmail.com>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ping-Ke Shih <pkshih@realtek.com>, Ahmet Zeren <niko3x@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795126169; l=3183;
 i=niko3x@proton.me; s=20261119; h=from:subject:message-id;
 bh=fY2p1RTdbGheeMu1sRky+i/mlFLrUXt2vgIPxb2pbA0=;
 b=1JE4sXPcxnUa9P/HS2a4uPiH3uMYeB0ELqmCa4bzpQ7PcSDJ0CsuQ8BI2J60/XEk2GkG5yWHj
 gcBcq5ASuS1AfznFr3gUr0SpkykXwV6WMcnu//WXuDtAiK3WwmalKjU
X-Developer-Key: i=niko3x@proton.me; a=ed25519;
 pk=J4zNm2pudzQ/wF+pQ8xO+wW6jpcNa9EJ2C1g4DUAjhM=
X-Endpoint-Received: by B4 Relay for niko3x@proton.me/20261119 with auth_id=1575
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

max_rate_tries is never set, so mac80211 clamps the retry count of every
injected frame to zero and the radiotap retries field has no effect.
Injected frames also ignore IEEE80211_TX_CTL_NO_ACK and use the default
hardware retry limit of 48. Unicast frames to an absent station then
take seconds each, which stalls all injection behind them.

Advertise the 6-bit retry limit of the TX descriptor, and on gen1 chips
program the retry limit of injected frames: none when no ACK is
expected, otherwise the radiotap retry count.

Tested on RTL8192CU (0bda:8178): 40 unicast frames at 1 Mbps to an
absent station drain in ~0.13 s with NOACK or 0 retries, ~0.45 s with
2, ~1.1 s with 4 and ~3.3 s with 6 retries. Without this patch the same
frames had not drained after 100 s, even with NOACK.

Signed-off-by: Ahmet Zeren <niko3x@proton.me>
---
 drivers/net/wireless/realtek/rtl8xxxu/core.c | 28 ++++++++++++++++++++++++++++
 1 file changed, 28 insertions(+)

diff --git a/drivers/net/wireless/realtek/rtl8xxxu/core.c b/drivers/net/wireless/realtek/rtl8xxxu/core.c
index 969875fd54..b159d9b64c 100644
--- a/drivers/net/wireless/realtek/rtl8xxxu/core.c
+++ b/drivers/net/wireless/realtek/rtl8xxxu/core.c
@@ -5245,6 +5245,24 @@ static bool rtl8xxxu_tx_rate_inject(struct ieee80211_tx_info *tx_info,
 	return true;
 }
 
+/*
+ * Retry limit of an injected frame: none if no ACK is expected, else the
+ * radiotap retry count. -1 leaves it to the hardware.
+ */
+static int rtl8xxxu_tx_retry_inject(struct ieee80211_tx_info *tx_info)
+{
+	if (!(tx_info->flags & IEEE80211_TX_CTL_INJECTED))
+		return -1;
+
+	if (tx_info->flags & IEEE80211_TX_CTL_NO_ACK)
+		return 0;
+
+	if (tx_info->control.flags & IEEE80211_TX_CTRL_RATE_INJECT)
+		return tx_info->control.rates[0].count - 1;
+
+	return -1;
+}
+
 /*
  * Fill in v1 (gen1) specific TX descriptor bits.
  * This format is used on 8188cu/8192cu/8723au
@@ -5262,9 +5280,11 @@ rtl8xxxu_fill_txdesc_v1(struct ieee80211_hw *hw, struct ieee80211_hdr *hdr,
 	u8 tid = qc[0] & IEEE80211_QOS_CTL_TID_MASK;
 	u32 rate = 0;
 	u16 seq_number;
+	int retries;
 	bool inject;
 
 	inject = rtl8xxxu_tx_rate_inject(tx_info, &rate, &sgi);
+	retries = rtl8xxxu_tx_retry_inject(tx_info);
 
 	if (rtl8xxxu_debug & RTL8XXXU_DEBUG_TX)
 		dev_info(dev, "%s: TX rate: %d, pkt size %u\n",
@@ -5314,6 +5334,12 @@ rtl8xxxu_fill_txdesc_v1(struct ieee80211_hw *hw, struct ieee80211_hdr *hdr,
 		tx_desc->txdw4 |= cpu_to_le32(TXDESC32_USE_DRIVER_RATE |
 					      TXDESC_DISABLE_DATA_FB);
 
+	if (retries >= 0) {
+		tx_desc->txdw5 &= ~cpu_to_le32(TXDESC32_RETRY_LIMIT_MASK);
+		tx_desc->txdw5 |= cpu_to_le32(retries << TXDESC32_RETRY_LIMIT_SHIFT |
+					      TXDESC32_RETRY_LIMIT_ENABLE);
+	}
+
 	/*
 	 * rts_rate is zero if RTS/CTS or CTS to SELF are not enabled
 	 */
@@ -7979,6 +8005,8 @@ static int rtl8xxxu_probe(struct usb_interface *interface,
 	SET_IEEE80211_PERM_ADDR(hw, priv->mac_addr);
 
 	hw->extra_tx_headroom = priv->fops->tx_desc_size;
+	/* The TX descriptor retry limit is 6 bits wide */
+	hw->max_rate_tries = 64;
 	ieee80211_hw_set(hw, SIGNAL_DBM);
 
 	/*

-- 
2.56.1

