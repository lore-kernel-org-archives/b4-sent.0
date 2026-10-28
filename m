From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Wed, 28 Oct 2026 14:37:38 -0500
Subject: [PATCH ath-next 1/2] wifi: ath11k: give a 6 GHz capable radio's 5
 GHz band HT and VHT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-b4-ath11k-qcn907x-caps-v1-1-c7daa6f1c02c@gmail.com>
References: <20261028-b4-ath11k-qcn907x-caps-v1-0-c7daa6f1c02c@gmail.com>
In-Reply-To: <20261028-b4-ath11k-qcn907x-caps-v1-0-c7daa6f1c02c@gmail.com>
To: Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793216257; l=2244;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=LoAHMWFP0FpoZiJJt9l8o390qNJjKYVd9pyVzPAa5+I=;
 b=LaMXa7wTct2ML3K347ffAKeqcWaIx8xIkvSSAAFcymjA4tghkB2xpTuw0BXQTYP4mnlg4dP5s
 cVJmPgCg+uuCOnny7j6z8FNw70jcdC/4ULuECpWYhb/nXflKovoOn27
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ath11k_mac_setup_ht_vht_cap() sets the 5 GHz band's HT and VHT
capabilities only for a single_pdev_only device or a radio that does
not support 6 GHz, on the understanding that a QCN9074 covers 6 GHz
only. A QCN9074 can cover 5 GHz as well: ath11k_mac_setup_channels_rates()
then registers its 5 GHz band too, with HE capabilities
(ath11k_mac_setup_he_cap() sets HE for any 5 GHz capable radio), but
without HT and VHT. mac80211 can't use HE on 5 GHz without them, so on
that band the radio uses legacy rates only. On an Arista C-360, its
QCN9072 (which takes the QCN9074's hw_params) associated to an 802.11ax
AP on 5 GHz at 24-54 Mbit/s with no MCS, and `iw phy` showed its 5 GHz
band with HE capabilities and no HT or VHT ones.

Give the 5 GHz band HT and VHT whenever it was registered with channels,
which ath11k_mac_setup_channels_rates() does before this runs. With
this, the QCN9072's 5 GHz band shows HT (HT20/HT40) and VHT in `iw phy`.

Tested-on: QCN9074 hw1.0 PCI fw_version 0x250affff (vendor build)
Tested-on: IPQ8074 hw2.0 AHB WLAN.HK.2.9.0.1-02146-QCAHKSWPL_SILICONZ-1

Fixes: 22eeadcdeab6 ("ath11k: add support for 6GHz radio in driver")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
 drivers/net/wireless/ath/ath11k/mac.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/drivers/net/wireless/ath/ath11k/mac.c b/drivers/net/wireless/ath/ath11k/mac.c
index 1a237adaa37d..af01ef1cf4c9 100644
--- a/drivers/net/wireless/ath/ath11k/mac.c
+++ b/drivers/net/wireless/ath/ath11k/mac.c
@@ -5783,9 +5783,12 @@ static void ath11k_mac_setup_ht_vht_cap(struct ath11k *ar,
 						    rate_cap_rx_chainmask);
 	}
 
+	/* A 6 GHz capable radio may cover 5 GHz as well, as a QCN9074 does:
+	 * its 5 GHz band, where one was registered, needs HT and VHT as much
+	 * as any other radio's.
+	 */
 	if (cap->supported_bands & WMI_HOST_WLAN_5G_CAP &&
-	    (ar->ab->hw_params.single_pdev_only ||
-	     !ar->supports_6ghz)) {
+	    ar->mac.sbands[NL80211_BAND_5GHZ].n_channels) {
 		band = &ar->mac.sbands[NL80211_BAND_5GHZ];
 		ht_cap = cap->band[NL80211_BAND_5GHZ].ht_cap_info;
 		if (ht_cap_info)

-- 
2.43.0

