From: Ahmet Zeren <niko3x@proton.me>
Date: Fri, 20 Nov 2026 01:09:28 +0300
Subject: [PATCH rtw-next 1/3] wifi: rtl8xxxu: honour the rate of injected
 frames on gen1 chips
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-b4-inject-v1-1-1e1693af0c6b@proton.me>
References: <20261120-b4-inject-v1-0-1e1693af0c6b@proton.me>
In-Reply-To: <20261120-b4-inject-v1-0-1e1693af0c6b@proton.me>
To: Jes Sorensen <Jes.Sorensen@gmail.com>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ping-Ke Shih <pkshih@realtek.com>, Ahmet Zeren <niko3x@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795126169; l=2543;
 i=niko3x@proton.me; s=20261119; h=from:subject:message-id;
 bh=29W25p5uamZL66BmTAE8xfDsBvBCRxEXCMdXGOu9KFc=;
 b=85a6xrx2qldGLsd2Xt272vl8LqgEdHvG2dkH90+GlY4qTQGJWJb1V/4j9JxljZnoQTv2OXvQw
 Jo7WLq8yGlmBIvimNfIlQxEtXnB4TaPYXJHwyo584NiiWSgm6bLzLv0
X-Developer-Key: i=niko3x@proton.me; a=ed25519;
 pk=J4zNm2pudzQ/wF+pQ8xO+wW6jpcNa9EJ2C1g4DUAjhM=
X-Endpoint-Received: by B4 Relay for niko3x@proton.me/20261119 with auth_id=1575
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a frame is injected with a rate in its radiotap header, the driver
ignores it and leaves the choice to the firmware rate adaptation. On a
RTL8192CU every injected frame went out at MCS 7, whatever was asked.

Use the injected rate and guard interval, and disable rate fallback so
the frame is sent at exactly that rate.

Tested on RTL8192CU (0bda:8178) in monitor mode on 2.4 GHz: 1, 5.5, 6
and 54 Mbps, MCS 0/7/8/15 with long and short GI were all received at
the requested rate. Frames without a radiotap rate are unchanged.

Signed-off-by: Ahmet Zeren <niko3x@proton.me>
---
 drivers/net/wireless/realtek/rtl8xxxu/core.c | 29 ++++++++++++++++++++++++++++
 1 file changed, 29 insertions(+)

diff --git a/drivers/net/wireless/realtek/rtl8xxxu/core.c b/drivers/net/wireless/realtek/rtl8xxxu/core.c
index 604bb1e5b0..969875fd54 100644
--- a/drivers/net/wireless/realtek/rtl8xxxu/core.c
+++ b/drivers/net/wireless/realtek/rtl8xxxu/core.c
@@ -5223,6 +5223,28 @@ static void rtl8xxxu_dump_action(struct device *dev,
 	}
 }
 
+/*
+ * Use the rate from the radiotap header of an injected frame, if any.
+ * mac80211 has already checked it against what we advertise.
+ */
+static bool rtl8xxxu_tx_rate_inject(struct ieee80211_tx_info *tx_info,
+				    u32 *rate, bool *sgi)
+{
+	struct ieee80211_tx_rate *txrate = &tx_info->control.rates[0];
+
+	if (!(tx_info->control.flags & IEEE80211_TX_CTRL_RATE_INJECT))
+		return false;
+
+	if (txrate->flags & IEEE80211_TX_RC_MCS)
+		*rate = DESC_RATE_MCS0 + txrate->idx;
+	else
+		*rate = rtl8xxxu_legacy_ratetable[txrate->idx].hw_value;
+
+	*sgi = txrate->flags & IEEE80211_TX_RC_SHORT_GI;
+
+	return true;
+}
+
 /*
  * Fill in v1 (gen1) specific TX descriptor bits.
  * This format is used on 8188cu/8192cu/8723au
@@ -5240,6 +5262,9 @@ rtl8xxxu_fill_txdesc_v1(struct ieee80211_hw *hw, struct ieee80211_hdr *hdr,
 	u8 tid = qc[0] & IEEE80211_QOS_CTL_TID_MASK;
 	u32 rate = 0;
 	u16 seq_number;
+	bool inject;
+
+	inject = rtl8xxxu_tx_rate_inject(tx_info, &rate, &sgi);
 
 	if (rtl8xxxu_debug & RTL8XXXU_DEBUG_TX)
 		dev_info(dev, "%s: TX rate: %d, pkt size %u\n",
@@ -5285,6 +5310,10 @@ rtl8xxxu_fill_txdesc_v1(struct ieee80211_hw *hw, struct ieee80211_hdr *hdr,
 	if (sgi)
 		tx_desc->txdw5 |= cpu_to_le32(TXDESC32_SHORT_GI);
 
+	if (inject)
+		tx_desc->txdw4 |= cpu_to_le32(TXDESC32_USE_DRIVER_RATE |
+					      TXDESC_DISABLE_DATA_FB);
+
 	/*
 	 * rts_rate is zero if RTS/CTS or CTS to SELF are not enabled
 	 */

-- 
2.56.1

