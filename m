From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Tue, 17 Nov 2026 22:11:21 -0800
Subject: [PATCH wireless-next] wifi: mac80211: don't limit the fq memory of
 HE radios to 4 MB
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-mac80211-fq-he-v1-1-9d5e4985677e@gmail.com>
X-B4-Tracking: v=1; b=H4sIAIhB/WoC/yWMwQ6CMBAFf4Xs2U3Y0iD6K8YD1oes0SpdVBLCv
 1P1OJnMzGRICqN9MVPCW00fMYNsCgp9Gy9gPWcmV7paRDzf29CUToS7gXvwrmoqJz4EbD3l6Jn
 Q6fQbHuijCTeYccQ00vGv7XW6IozfKS3LCrZ/NaiBAAAA
X-Change-ID: 20261114-mac80211-fq-he-9383214cce74
To: Johannes Berg <johannes@sipsolutions.net>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794982280; l=3461;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=A5chuA+mk1Jxt5uqOsj5kFLbFwFtNAbJvoydU9CX6F0=;
 b=tsEpH85/SLJp598QuL1nEUfdtqycq0j4cazPHc5I1xOD0xsnkVhH7JoHezTvc7yFswSCaRAIf
 aiD6jPMP7QuBxsXz2qYOmPhX3FGHgtonyVz5gXtdiT4phO4iSuImbdC
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ieee80211_txq_setup_flows() lowers the fq memory limit from 16 MB to
4 MB when no band of the wiphy supports VHT, since 4 MB is 64 max-size
802.11n aggregates. A radio that supports HE but not VHT falls under
that limit too: a 6 GHz only radio, where VHT does not exist, and a
2.4 GHz only HE radio. Such a radio aggregates far more than 802.11n
allows; HE alone raises the block ack window to 256 MPDUs.

The limit binds once the driver leaves frames in the mac80211 queues,
as it does with airtime queue limits. On an ath11k QCN9074 6 GHz only
radio (HE160, 2x2) running the pending ath11k airtime queue limit
series [1], a TCP download to one station ran at 1314 Mbit/s with
11968 retransmits while fq_overmemory rose by 374. With the limit set
to 16 MB through debugfs it ran at 1446 Mbit/s with 2721.

Count HE like VHT. An EHT radio supports HE, so it is covered as well.

This change and message were written with Claude, an AI coding assistant.

Link: https://lore.kernel.org/all/20261018174904.1757161-1-julius@bairaktaris.de/ [1]
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
Found while testing the pending ath11k airtime queue limit series on an
Arista C-360 (IPQ8074 plus a QCN9074 6 GHz radio) running OpenWrt. The
6 GHz radio is its own wiphy, so it has no VHT and got the 4 MB limit;
the same holds for the board's 2.4 GHz radio.

Compile-tested on wireless-next. On that board (OpenWrt, kernel 6.18,
backports 7.2 with this change applied), the 6 GHz only and 2.4 GHz only
radios come up with a 16 MB limit instead of 4 MB, and the two radios
with VHT keep 16 MB. The throughput numbers in the changelog were
measured with the limit changed through debugfs, not with this patch
loaded.
---
 net/mac80211/tx.c | 12 +++++++++---
 1 file changed, 9 insertions(+), 3 deletions(-)

diff --git a/net/mac80211/tx.c b/net/mac80211/tx.c
index 14885c2ce..a3a3ed370 100644
--- a/net/mac80211/tx.c
+++ b/net/mac80211/tx.c
@@ -1647,6 +1647,7 @@ int ieee80211_txq_setup_flows(struct ieee80211_local *local)
 	int ret;
 	int i;
 	bool supp_vht = false;
+	bool supp_he = false;
 	enum nl80211_band band;
 
 	ret = fq_init(fq, 4096);
@@ -1654,10 +1655,12 @@ int ieee80211_txq_setup_flows(struct ieee80211_local *local)
 		return ret;
 
 	/*
-	 * If the hardware doesn't support VHT, it is safe to limit the maximum
-	 * queue size. 4 Mbytes is 64 max-size aggregates in 802.11n.
+	 * If the hardware supports neither VHT nor HE, it is safe to limit the
+	 * maximum queue size. 4 Mbytes is 64 max-size aggregates in 802.11n.
+	 * HE counts as well, since a 6 GHz only radio has no VHT.
 	 */
 	for (band = 0; band < NUM_NL80211_BANDS; band++) {
+		const struct ieee80211_sband_iftype_data *iftd;
 		struct ieee80211_supported_band *sband;
 
 		sband = local->hw.wiphy->bands[band];
@@ -1665,9 +1668,12 @@ int ieee80211_txq_setup_flows(struct ieee80211_local *local)
 			continue;
 
 		supp_vht = supp_vht || sband->vht_cap.vht_supported;
+
+		for_each_sband_iftype_data(sband, i, iftd)
+			supp_he = supp_he || iftd->he_cap.has_he;
 	}
 
-	if (!supp_vht)
+	if (!supp_vht && !supp_he)
 		fq->memory_limit = 4 << 20; /* 4 Mbytes */
 
 	codel_params_init(&local->cparams);

---
base-commit: 5dbf2415ca9821a611d09308e3b29d2c37e7cd77
change-id: 20261114-mac80211-fq-he-9383214cce74

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

