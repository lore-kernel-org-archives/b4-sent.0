From: Igor Borodin <hatemosphere@protonmail.com>
Date: Fri, 23 Oct 2026 23:17:17 +0200
Subject: [PATCH wireless] wifi: mac80211: fix MLO multicast duplicate
 detection
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-mlo-mcast-dedup-v1-1-3f89b805390a@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/yWMzQrCQAwGX6V8ZwPdiK34KuKhZqNG+semrULpu
 7vqcRhmVrgmU8epWJF0MbehzxB2BeTR9Hcli5nBJVeh5D117UCdND5R1DiPxKGuKzkEiUdGrsa
 kN3v/jme8LGmr7rj8jc/Xp8r0HWLbPtcgDl19AAAA
X-Change-ID: 20261023-mlo-mcast-dedup-21776c51cd82
To: Johannes Berg <johannes@sipsolutions.net>
Cc: linux-wireless@vger.kernel.org, 
 Igor Borodin <hatemosphere@protonmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=7120;
 i=hatemosphere@protonmail.com; h=from:subject:message-id;
 bh=oKaGFcKL+evPW05fPWOfbx9QyJKjubsLXdxESkkiZUM=;
 b=kA0DAAgB74wQTOU5e+IByyZiAGrbzvGjT002llrdYERtQSSu/iI1CKyAS4eMP5zCQQZVT+eS6
 4kBTwQAAQgAORYhBPjCZDY+g8pfh1PFiO+MEEzlOXviBQJq287xGxSAAAAAAAQADm1hbnUyLDIu
 NSsxLjEyLDAsMwAKCRDvjBBM5Tl74vTpB/0ax/1P40aqZ6Gdm1+Xv7wwagiEuUbc938q7fGkM+o
 5MtUtm5DEpyZiQmPDuaRAgLOAqaMe1sbG6dGbEBhoWGLc/lphxgpJGroTlXxa8ipXSr/MVGG3xy
 xzrgown2tEhl4xP9NrynLMIVpPac/LlnznlA/l8d3CJLeYhBKzPEIodSnpN4qLW4PELlpZBheJg
 JX7q5jP100bXFwhL8tQrL8d4hbiiFzPN6GXZ3oWEdIf3YIi4TI0iPnVvkuLVAFVaPPIXPTTOuSc
 yq+2w8ge5irtDBshw2n0y47xG/8Igp+sWXgxLq80C/cLNtgOkA21hYqXFiFgmi9U1ogd5i2cvSQ i
X-Developer-Key: i=hatemosphere@protonmail.com; a=openpgp;
 fpr=F8C264363E83CA5F8753C588EF8C104CE5397BE2
X-Endpoint-Received: by B4 Relay for hatemosphere@protonmail.com/default with auth_id=1299
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit 676259100cf3 ("wifi: mac80211: implement MLO multicast
deduplication"), a station MLD drops a group addressed Data frame unless
its sequence number is newer than the last one it accepted
(mcast_seq_last).

That assumes all group addressed Data frames of the AP MLD come from a
single, increasing sequence number space. Some APs use more than one.
A TP-Link Deco (Wi-Fi 7 MLO network) interleaves two spaces on the same
link, the second one for frames with More Data set, apparently the
DTIM-buffered ones. Traced at ieee80211_rx_napi() on the station:

  sn=508 sn=2338 sn=510 sn=2339 sn=513 sn=2340 sn=515 ...

Once a frame of the leading space is accepted, every frame of the other
space is "not newer" and dropped as RX_DROP_U_DUP until that space
catches up, which takes minutes, after which the roles swap. Meanwhile
the station receives almost no broadcast or multicast: ARP requests from
the LAN are lost and the host becomes unreachable, while unicast keeps
working. With an RTL8922AE (rtw89) station on a single active link this
happened every 10-15 minutes, for several minutes each time.

IEEE 802.11be (10.3.2.14, RC16) has the station MLD discard a group
addressed Data frame it already received on any link, and leaves
sequence number wraparound handling to the implementation. Do that with
a small cache of the sequence number and source address of recently
received frames, as the mesh RMC does, instead of tracking only the
highest sequence number seen. The cache is much smaller than the
sequence number space, so a match cannot come from a wrapped number.

Fixes: 676259100cf3 ("wifi: mac80211: implement MLO multicast deduplication")
Assisted-by: LLM
Signed-off-by: Igor Borodin <hatemosphere@protonmail.com>
---
Spec: IEEE 802.11be 10.3.2.14 (SNS11 for group addressed Data of an AP MLD;
RC16: "A duplicated group addressed Data frame received on any link shall be
discarded", wraparound handling implementation specific), text as adopted in
https://mentor.ieee.org/802.11/dcn/23/11-23-0547-04-00be-cr-for-3-2-and-some-clauses-in-35.docx

Tested on v7.3 (Ubuntu 7.3.0-9), RTL8922AE (rtw89), TP-Link Deco
(Qualcomm-based) MLO network, single active link:
before: broadcast silences every 10-15 min, several minutes each, group
        frames dropped as RX_DROP_U_DUP
after:  no silences; group frames the AP repeated with the same SN and
        source (eg. around a channel switch) are still dropped
---
 net/mac80211/ieee80211_i.h | 10 +++++++++-
 net/mac80211/mlme.c        | 14 ++++++++++++--
 net/mac80211/rx.c          | 29 ++++++++++++++++++++++++++---
 3 files changed, 47 insertions(+), 6 deletions(-)

diff --git a/net/mac80211/ieee80211_i.h b/net/mac80211/ieee80211_i.h
index 9374c2942..b57a54c4a 100644
--- a/net/mac80211/ieee80211_i.h
+++ b/net/mac80211/ieee80211_i.h
@@ -522,6 +522,8 @@ struct ieee80211_adv_ttlm_info {
 
 DECLARE_EWMA(beacon_signal, 4, 4)
 
+#define IEEE80211_MCAST_DUP_ENTRIES	32
+
 struct ieee80211_if_managed {
 	struct timer_list timer;
 	struct timer_list conn_mon_timer;
@@ -549,7 +551,12 @@ struct ieee80211_if_managed {
 
 	unsigned int flags;
 
-	u16 mcast_seq_last;
+	/* recent group addressed Data frames, for MLD duplicate detection */
+	struct {
+		u8 sa[ETH_ALEN] __aligned(2);
+		u16 sn;
+	} mcast_dup[IEEE80211_MCAST_DUP_ENTRIES];
+	u8 mcast_dup_next;
 
 	bool status_acked;
 	bool status_received;
@@ -2007,6 +2014,7 @@ void ieee80211_uhr_disable_dbe_all_stas(struct ieee80211_link_data *link);
 
 /* STA code */
 void ieee80211_sta_setup_sdata(struct ieee80211_sub_if_data *sdata);
+void ieee80211_mgd_mcast_dup_reset(struct ieee80211_sub_if_data *sdata);
 int ieee80211_mgd_auth(struct ieee80211_sub_if_data *sdata,
 		       struct cfg80211_auth_request *req);
 int ieee80211_mgd_assoc(struct ieee80211_sub_if_data *sdata,
diff --git a/net/mac80211/mlme.c b/net/mac80211/mlme.c
index 3c31c1686..66e78d873 100644
--- a/net/mac80211/mlme.c
+++ b/net/mac80211/mlme.c
@@ -4750,7 +4750,7 @@ static void ieee80211_set_disassoc(struct ieee80211_sub_if_data *sdata,
 
 	ieee80211_vif_set_links(sdata, 0, 0);
 
-	ifmgd->mcast_seq_last = IEEE80211_SN_MODULO;
+	ieee80211_mgd_mcast_dup_reset(sdata);
 
 	ifmgd->epcs.enabled = false;
 	ifmgd->epcs.dialog_token = 0;
@@ -9495,6 +9495,16 @@ static void ieee80211_ml_sta_reconf_timeout(struct wiphy *wiphy,
 }
 
 /* interface setup */
+void ieee80211_mgd_mcast_dup_reset(struct ieee80211_sub_if_data *sdata)
+{
+	struct ieee80211_if_managed *ifmgd = &sdata->u.mgd;
+	int i;
+
+	for (i = 0; i < ARRAY_SIZE(ifmgd->mcast_dup); i++)
+		ifmgd->mcast_dup[i].sn = IEEE80211_SN_MODULO;
+	ifmgd->mcast_dup_next = 0;
+}
+
 void ieee80211_sta_setup_sdata(struct ieee80211_sub_if_data *sdata)
 {
 	struct ieee80211_if_managed *ifmgd = &sdata->u.mgd;
@@ -9532,7 +9542,7 @@ void ieee80211_sta_setup_sdata(struct ieee80211_sub_if_data *sdata)
 	spin_lock_init(&ifmgd->teardown_lock);
 	ifmgd->teardown_skb = NULL;
 	ifmgd->orig_teardown_skb = NULL;
-	ifmgd->mcast_seq_last = IEEE80211_SN_MODULO;
+	ieee80211_mgd_mcast_dup_reset(sdata);
 }
 
 static void ieee80211_recalc_smps_work(struct wiphy *wiphy,
diff --git a/net/mac80211/rx.c b/net/mac80211/rx.c
index 7ead50930..83df06d67 100644
--- a/net/mac80211/rx.c
+++ b/net/mac80211/rx.c
@@ -1517,6 +1517,31 @@ static void ieee80211_rx_reorder_ampdu(struct ieee80211_rx_data *rx,
 	__skb_queue_tail(frames, skb);
 }
 
+/*
+ * An AP MLD may send a group addressed Data frame on several links with
+ * the same SN (SNS11); a frame already received on any link is discarded
+ * (RC16, IEEE 802.11be 10.3.2.14). Remember recent SN/SA pairs, since a
+ * single "last SN" breaks with APs that use more than one SN space.
+ */
+static bool ieee80211_mgd_mcast_is_dup(struct ieee80211_sub_if_data *sdata,
+				       struct ieee80211_hdr *hdr, u16 sn)
+{
+	struct ieee80211_if_managed *ifmgd = &sdata->u.mgd;
+	int i;
+
+	for (i = 0; i < ARRAY_SIZE(ifmgd->mcast_dup); i++) {
+		if (ifmgd->mcast_dup[i].sn == sn &&
+		    ether_addr_equal(ifmgd->mcast_dup[i].sa, hdr->addr3))
+			return true;
+	}
+
+	i = ifmgd->mcast_dup_next;
+	ifmgd->mcast_dup_next = (i + 1) % ARRAY_SIZE(ifmgd->mcast_dup);
+	ifmgd->mcast_dup[i].sn = sn;
+	ether_addr_copy(ifmgd->mcast_dup[i].sa, hdr->addr3);
+	return false;
+}
+
 static ieee80211_rx_result debug_noinline
 ieee80211_rx_h_check_dup(struct ieee80211_rx_data *rx)
 {
@@ -1555,11 +1580,9 @@ ieee80211_rx_h_check_dup(struct ieee80211_rx_data *rx)
 		    sdata->vif.type != NL80211_IFTYPE_STATION)
 			return RX_CONTINUE;
 
-		if (sdata->u.mgd.mcast_seq_last != IEEE80211_SN_MODULO &&
-		    ieee80211_sn_less_eq(sn, sdata->u.mgd.mcast_seq_last))
+		if (ieee80211_mgd_mcast_is_dup(sdata, hdr, sn))
 			return RX_DROP_U_DUP;
 
-		sdata->u.mgd.mcast_seq_last = sn;
 		return RX_CONTINUE;
 	}
 

---
base-commit: 9d8ec0b5b5295bd23d979d1b2b905de25c36fff2
change-id: 20261023-mlo-mcast-dedup-21776c51cd82

Best regards,
--  
Igor Borodin <hatemosphere@protonmail.com>

