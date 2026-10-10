From: benthecarman <benthecarman1@gmail.com>
Date: Fri, 09 Oct 2026 21:42:22 -0500
Subject: [PATCH 1/2] wifi: iwlwifi: mvm: Fix injected 5 GHz legacy rate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261009-next-v1-1-b370f5302d27@gmail.com>
References: <20261009-next-v1-0-b370f5302d27@gmail.com>
In-Reply-To: <20261009-next-v1-0-b370f5302d27@gmail.com>
To: Miri Korenblit <miriam.rachel.korenblit@intel.com>
Cc: Johannes Berg <johannes@sipsolutions.net>, 
 linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 benthecarman <benthecarman@live.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791600143; l=1797;
 i=benthecarman1@gmail.com; s=20261009; h=from:subject:message-id;
 bh=P1RM3YW4KpS+4q5w9KhQAa5Z7jbnUcHDOW45kcK15og=;
 b=OMaeSjn4aSgDqNa+kQSdmrGQL83w9Yy8oyxQiGaO6Pb72e9IuHSQgJ1llIVzIUz4TYBQCAXJO
 b9aDE2vEwgpAGUGkwqfL9vYYjaxT28Z3pWpXHRYkMlINlEW4Zkb7SNg
X-Developer-Key: i=benthecarman1@gmail.com; a=ed25519;
 pk=8RDA9X90+5wKUu3kkgPYpamlxYvX93l7iXqMWrkhvOY=
X-Endpoint-Received: by B4 Relay for benthecarman1@gmail.com/20261009 with auth_id=1149
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: benthecarman <benthecarman@live.com>

iwl_mvm_get_inject_tx_rate() passes the legacy rate index from
mac80211 straight to iwl_mvm_convert_rate_idx(). That index points
into the band's own bitrate table, which outside 2.4 GHz starts at
6 Mbps (iwl_cfg80211_rates[RATES_52_OFFS]), while the driver's indices
start with the four CCK rates. A frame injected at 12 Mbps on 5 or
6 GHz, index 2, therefore goes out as 5.5 Mbps CCK, which no receiver
on those bands can decode.

The non-injected path, iwl_mvm_get_tx_rate(), already adds
IWL_FIRST_OFDM_RATE outside 2.4 GHz. Do the same for injection.

Seen on an AX211 injecting data frames at 12 Mbps on channel 44: the
TX response showed rate_n_flags 0x8002 (CCK) and the peer never ACKed.
With this change it shows 0x8102 (12 Mbps OFDM) and every unicast
frame is ACKed on the first attempt.

Fixes: b99c4607973a ("wifi: iwlwifi: mvm: refactor TX rate handling")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: benthecarman <benthecarman@live.com>
---
 drivers/net/wireless/intel/iwlwifi/mvm/tx.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/net/wireless/intel/iwlwifi/mvm/tx.c b/drivers/net/wireless/intel/iwlwifi/mvm/tx.c
index d3c2fe830..fb7e48aa3 100644
--- a/drivers/net/wireless/intel/iwlwifi/mvm/tx.c
+++ b/drivers/net/wireless/intel/iwlwifi/mvm/tx.c
@@ -331,6 +331,14 @@ static u32 iwl_mvm_get_inject_tx_rate(struct iwl_mvm *mvm,
 	} else {
 		int rate_idx = info->control.rates[0].idx;
 
+		/*
+		 * mac80211 indexes the band's bitrates, which start at
+		 * 6 Mbps outside 2.4 GHz; remap to our rate indices as
+		 * iwl_mvm_get_tx_rate() does.
+		 */
+		if (info->band != NL80211_BAND_2GHZ)
+			rate_idx += IWL_FIRST_OFDM_RATE;
+
 		result = iwl_mvm_convert_rate_idx(mvm, info, rate_idx);
 	}
 

-- 
2.55.0

