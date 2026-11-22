From: Ahmet Zeren <niko3x@proton.me>
Date: Sun, 22 Nov 2026 08:59:30 +0300
Subject: [PATCH rtw-next v2 2/3] wifi: rtl8xxxu: honour the retry count of
 injected frames on gen1 chips
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-inject-v2-2-0ee720fe706d@proton.me>
References: <20261122-b4-inject-v2-0-0ee720fe706d@proton.me>
In-Reply-To: <20261122-b4-inject-v2-0-0ee720fe706d@proton.me>
To: Jes Sorensen <Jes.Sorensen@gmail.com>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ping-Ke Shih <pkshih@realtek.com>, Ahmet Zeren <niko3x@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795327172; l=3823;
 i=niko3x@proton.me; s=20261119; h=from:subject:message-id;
 bh=yewKtZbOqiVYEC6A4BqBFsXNHbOn+2HnCr+UJYQVgPo=;
 b=D6zkB2jmTTpgLJ8ErJv9qZKFf5p9VjLsJnh64bkAJ+jNqnxxccgwufuRPQDJnsCaLbYYIlDwd
 ougwPO+IpQZCQuvqLFyEkF5N28F6qgLJcsCcxZzUYEsx5Uq5JymDrb3
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
 drivers/net/wireless/realtek/rtl8xxxu/core.c     | 29 +++++++++++++++++++++++-
 drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h |  1 +
 2 files changed, 29 insertions(+), 1 deletion(-)

diff --git a/drivers/net/wireless/realtek/rtl8xxxu/core.c b/drivers/net/wireless/realtek/rtl8xxxu/core.c
index 3b77a7ce884..7d6f5243f64 100644
--- a/drivers/net/wireless/realtek/rtl8xxxu/core.c
+++ b/drivers/net/wireless/realtek/rtl8xxxu/core.c
@@ -5241,6 +5241,24 @@ static bool rtl8xxxu_tx_rate_inject(struct ieee80211_tx_info *tx_info,
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
@@ -5258,9 +5276,11 @@ rtl8xxxu_fill_txdesc_v1(struct ieee80211_hw *hw, struct ieee80211_hdr *hdr,
 	u8 tid = qc[0] & IEEE80211_QOS_CTL_TID_MASK;
 	u32 rate = 0;
 	u16 seq_number;
+	int retries;
 	bool inject;
 
 	inject = rtl8xxxu_tx_rate_inject(tx_info, &rate, &sgi);
+	retries = rtl8xxxu_tx_retry_inject(tx_info);
 
 	if (rtl8xxxu_debug & RTL8XXXU_DEBUG_TX)
 		dev_info(dev, "%s: TX rate: %d, pkt size %u\n",
@@ -5283,7 +5303,13 @@ rtl8xxxu_fill_txdesc_v1(struct ieee80211_hw *hw, struct ieee80211_hdr *hdr,
 	if (ieee80211_is_mgmt(hdr->frame_control)) {
 		tx_desc->txdw5 = cpu_to_le32(rate);
 		tx_desc->txdw4 |= cpu_to_le32(TXDESC32_USE_DRIVER_RATE);
-		tx_desc->txdw5 |= cpu_to_le32(6 << TXDESC32_RETRY_LIMIT_SHIFT);
+		if (retries < 0)
+			retries = 6;
+	}
+
+	if (retries >= 0) {
+		tx_desc->txdw5 |= le32_encode_bits(retries,
+						   TXDESC32_RETRY_LIMIT_MASK);
 		tx_desc->txdw5 |= cpu_to_le32(TXDESC32_RETRY_LIMIT_ENABLE);
 	}
 
@@ -7975,6 +8001,7 @@ static int rtl8xxxu_probe(struct usb_interface *interface,
 	SET_IEEE80211_PERM_ADDR(hw, priv->mac_addr);
 
 	hw->extra_tx_headroom = priv->fops->tx_desc_size;
+	hw->max_rate_tries = TXDESC32_RETRY_LIMIT_MAX + 1;
 	ieee80211_hw_set(hw, SIGNAL_DBM);
 
 	/*
diff --git a/drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h b/drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h
index 8cbadcf7190..8f75be83e9e 100644
--- a/drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h
+++ b/drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h
@@ -575,6 +575,7 @@ struct rtl8xxxu_txdesc40 {
 #define TXDESC32_RETRY_LIMIT_ENABLE	BIT(17)
 #define TXDESC32_RETRY_LIMIT_SHIFT	18
 #define TXDESC32_RETRY_LIMIT_MASK	0x00fc0000
+#define TXDESC32_RETRY_LIMIT_MAX	63
 
 /* Word 6 */
 #define TXDESC_MAX_AGG_SHIFT		11

-- 
2.56.1

