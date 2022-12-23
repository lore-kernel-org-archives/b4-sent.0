From: Konstantin Ryabitsev <icon@mricon.com>
Date: Fri, 23 Dec 2022 13:20:23 -0500
Subject: 
 [PATCH v2] wifi: rtlwifi: rtl8723ae: fix obvious spelling error tyep->type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20221222-rtl8723ae-typo-fix-v2-1-71b6b67df3f5@mricon.com>
X-B4-Tracking: v=1; b=H4sIAGfxpWMC/32NTQ6CMBBGr0K6dowd0KIr72FYtGWQJtKSadNIC
 He3cACX7/vJW0UkdhTFo1oFU3bRBV8AT5Wwo/ZvAtcXFnhBlIgInD6twloTpGUOMLgvXK1VQ28U
 9bdBlKPRkcCw9nbcr5OOiXgvZqayP2yvrvDoYgq8HPIs9/SvJ0uQ0DZtUzdGqrtVz4mdDf5swyS
 6bdt+hIUvSM4AAAA=
To: Ping-Ke Shih <pkshih@realtek.com>, Kalle Valo <kvalo@kernel.org>,
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>,
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: linux-wireless@vger.kernel.org, netdev@vger.kernel.org,
 linux-kernel@vger.kernel.org, Jens Schleusener <Jens.Schleusener@fossies.org>,
 Konstantin Ryabitsev <mricon@kernel.org>,
 Konstantin Ryabitsev <icon@mricon.com>
X-Mailer: b4 0.11.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1671819624; l=1637;
 i=icon@mricon.com; s=20221221; h=from:subject:message-id;
 bh=57gO259Fc/KT9ex4SOU3uyVtvu/dYwCeWFrRcLQPeeo=;
 b=caFDCH83b5cJQQhl9O6KJ+wtipnd0wu1TvUnFsdV2pLp9ntgoczGWiWaqaE5og9SBsi9upMf1Xr+
 J9LU85qRCeAXRT3YAbT1qGTO4MTE7F5DzdJBVTPj6SWepd4Ajpus
X-Developer-Key: i=icon@mricon.com; a=ed25519;
 pk=24L8+ejW6PwbTbrJ/uT8HmSM8XkvGGtjTZ6NftSSI6I=
X-Endpoint-Received: by B4 Submission Endpoint for icon@mricon.com/20221221 with auth_id=17
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

This appears to be an obvious spelling error, initially identified in a
codespell report and never addressed.

Reported-by: Jens Schleusener <Jens.Schleusener@fossies.org>
Link: https://bugzilla.kernel.org/show_bug.cgi?id=205891
Signed-off-by: Konstantin Ryabitsev <icon@mricon.com>
---
Changes in v2:
- Updated commit subject based on feedback.
- Link to v1: https://lore.kernel.org/r/20221222-rtl8723ae-typo-fix-v1-1-848434b179c7@mricon.com
---
 drivers/net/wireless/realtek/rtlwifi/rtl8723ae/hal_bt_coexist.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/wireless/realtek/rtlwifi/rtl8723ae/hal_bt_coexist.h b/drivers/net/wireless/realtek/rtlwifi/rtl8723ae/hal_bt_coexist.h
index 0455a3712f3e..12cdecdafc32 100644
--- a/drivers/net/wireless/realtek/rtlwifi/rtl8723ae/hal_bt_coexist.h
+++ b/drivers/net/wireless/realtek/rtlwifi/rtl8723ae/hal_bt_coexist.h
@@ -116,7 +116,7 @@ void rtl8723e_dm_bt_hw_coex_all_off(struct ieee80211_hw *hw);
 long rtl8723e_dm_bt_get_rx_ss(struct ieee80211_hw *hw);
 void rtl8723e_dm_bt_balance(struct ieee80211_hw *hw,
 			    bool balance_on, u8 ms0, u8 ms1);
-void rtl8723e_dm_bt_agc_table(struct ieee80211_hw *hw, u8 tyep);
+void rtl8723e_dm_bt_agc_table(struct ieee80211_hw *hw, u8 type);
 void rtl8723e_dm_bt_bb_back_off_level(struct ieee80211_hw *hw, u8 type);
 u8 rtl8723e_dm_bt_check_coex_rssi_state(struct ieee80211_hw *hw,
 					u8 level_num, u8 rssi_thresh,

---
base-commit: 830b3c68c1fb1e9176028d02ef86f3cf76aa2476
change-id: 20221222-rtl8723ae-typo-fix-5cc7fdb7ed6f

Best regards,
-- 
Konstantin Ryabitsev <icon@mricon.com>
