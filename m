From: benthecarman <benthecarman1@gmail.com>
Date: Fri, 09 Oct 2026 21:42:23 -0500
Subject: [PATCH 2/2] wifi: iwlwifi: mld: Fix injected 5 GHz legacy rate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261009-next-v1-2-b370f5302d27@gmail.com>
References: <20261009-next-v1-0-b370f5302d27@gmail.com>
In-Reply-To: <20261009-next-v1-0-b370f5302d27@gmail.com>
To: Miri Korenblit <miriam.rachel.korenblit@intel.com>
Cc: Johannes Berg <johannes@sipsolutions.net>, 
 linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 benthecarman <benthecarman@live.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791600143; l=1532;
 i=benthecarman1@gmail.com; s=20261009; h=from:subject:message-id;
 bh=pSIiTmEuNFIkLVvwgBMZ4Ct5zrF6uVX3C8GZKbTPvWA=;
 b=LIAybz80fCTnZ1BSv6A41an3QQM+78UE2NYejokmHRGdhMv+t4aeX1WlabimIBXQMxuxoxA7i
 VSAF7/aH+wpCCTuHlncsizrXRhnpJUfiPIeeP4dFvRXgRkkv3QWeuRD
X-Developer-Key: i=benthecarman1@gmail.com; a=ed25519;
 pk=8RDA9X90+5wKUu3kkgPYpamlxYvX93l7iXqMWrkhvOY=
X-Endpoint-Received: by B4 Relay for benthecarman1@gmail.com/20261009 with auth_id=1149
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: benthecarman <benthecarman@live.com>

iwl_mld_get_inject_tx_rate() hands the legacy rate index from mac80211
to iwl_mld_mac80211_rate_idx_to_fw(), which expects the driver's rate
indices. Outside 2.4 GHz the mac80211 index points into a bitrate
table that starts at 6 Mbps, so a 12 Mbps injection on 5 or 6 GHz goes
out as 5.5 Mbps CCK.

Add IWL_FIRST_OFDM_RATE outside 2.4 GHz, as mvm does for frames that
are not injected.

Fixes: d1e879ec600f ("wifi: iwlwifi: add iwlmld sub-driver")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: benthecarman <benthecarman@live.com>
---
 drivers/net/wireless/intel/iwlwifi/mld/tx.c | 11 ++++++++++-
 1 file changed, 10 insertions(+), 1 deletion(-)

diff --git a/drivers/net/wireless/intel/iwlwifi/mld/tx.c b/drivers/net/wireless/intel/iwlwifi/mld/tx.c
index fc501ac0c..317573b5e 100644
--- a/drivers/net/wireless/intel/iwlwifi/mld/tx.c
+++ b/drivers/net/wireless/intel/iwlwifi/mld/tx.c
@@ -599,7 +599,16 @@ static u32 iwl_mld_get_inject_tx_rate(struct iwl_mld *mld,
 		if (u32_get_bits(info->flags, IEEE80211_TX_CTL_STBC))
 			result |= RATE_MCS_STBC_MSK;
 	} else {
-		result = iwl_mld_mac80211_rate_idx_to_fw(mld, info, rate->idx);
+		int rate_idx = rate->idx;
+
+		/*
+		 * mac80211 indexes the band's bitrates, which start at
+		 * 6 Mbps outside 2.4 GHz; remap to our rate indices.
+		 */
+		if (info->band != NL80211_BAND_2GHZ)
+			rate_idx += IWL_FIRST_OFDM_RATE;
+
+		result = iwl_mld_mac80211_rate_idx_to_fw(mld, info, rate_idx);
 	}
 
 	if (info->control.antennas)

-- 
2.55.0

