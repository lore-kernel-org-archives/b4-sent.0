From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Wed, 28 Oct 2026 09:57:51 -0500
Subject: [PATCH wireless-next] wifi: mac80211: flush TX for a new key only
 if it needs tailroom
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-b4-mac80211-tailroom-v1-1-f3cfbab9ef5f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAG4N4moC/yWMQQrCMBAAv1L27EIS2hL8inhI0o2utIlkoxZK/
 26qx2GY2UCoMAmcuw0KvVk4pwb61EG4u3Qj5KkxGGVGrYxF3+PiglVGa6yO55Lzgr0dVPR2Iho
 jtPRZKPL6217gw4VmEsFEa4XrX8vLPyjUYw37/gVFEo1OhwAAAA==
X-Change-ID: 20261028-b4-mac80211-tailroom-4850fb8dee6f
To: Johannes Berg <johannes@sipsolutions.net>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793199470; l=6194;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=VVRIR+z05sVgNPbb1Hz7v+/VmM8Tn2LY06AEVY6Gvuo=;
 b=riVuGQy3wUiwpyg36tH+bNlgkKY6M1SeroWWKn6mwxv9nf1y7Wx1dMHzWRLWeXRgc4dTLYe8o
 4RKBBP/wyA4AwZASA8w2AbLqbBlEyUcY5j4CCW/9vKJ5ozKwKwda7ww
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ieee80211_key_link() counts every key it installs as needing tailroom
before ieee80211_key_replace() uploads it to the driver, and
increment_tailroom_need_count() runs synchronize_net() when that count
goes from zero to one. On an AP whose keys are all in hardware the count
is zero between stations, so each station's pairwise key waits for an
RCU grace period, and hostapd waits on its NL80211_CMD_NEW_KEY before
it authorizes the station and serves anyone else. Commit 133bf90dbb8b
("mac80211: restrict delayed tailroom needed decrement") keeps the
delayed decrement, which avoids this on a roam, to station interfaces.

Measured on an IPQ8074 AP (ath11k, HZ=100), WPA2-PSK, the same non-MFP
station roaming in, hostapd's NEW_KEY for the pairwise key to its next
step: 31-65 ms (median ~42, 10 joins) on a BSS without PMF; 0-2 ms on
the same BSS with ieee80211w=1, whose software BIP keys (ath11k leaves
BIP to mac80211) keep the count above zero. A driver that does BIP in
hardware pays it with PMF on too.

The flush keeps frames sized without tailroom from meeting a key that
needs it in software. A key that replaces none can't be met before
ieee80211_key_replace() publishes it, by which time it is known whether
it went to the hardware without needing tailroom, giving the count
back. So keep counting it beforehand, but flush on the count's
transition from zero to one only if the key still needs tailroom when
it is about to be published. A key replacing another is handled as
before, since the old key may drop to software while still in use.

With this, the same joins took 0-2 ms without PMF (13 handshakes).

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
 net/mac80211/key.c | 61 ++++++++++++++++++++++++++++++++++++++++++++----------
 1 file changed, 50 insertions(+), 11 deletions(-)

diff --git a/net/mac80211/key.c b/net/mac80211/key.c
index d32c61a90..ee646f5d5 100644
--- a/net/mac80211/key.c
+++ b/net/mac80211/key.c
@@ -73,6 +73,20 @@ update_vlan_tailroom_need_count(struct ieee80211_sub_if_data *sdata, int delta)
 	rcu_read_unlock();
 }
 
+/*
+ * Count a key as needing tailroom, and return whether the count went from
+ * zero to one, so that TX must be flushed before a key needing tailroom is
+ * used (see increment_tailroom_need_count()).
+ */
+static bool __increment_tailroom_need_count(struct ieee80211_sub_if_data *sdata)
+{
+	lockdep_assert_wiphy(sdata->local->hw.wiphy);
+
+	update_vlan_tailroom_need_count(sdata, 1);
+
+	return !sdata->crypto_tx_tailroom_needed_cnt++;
+}
+
 static void increment_tailroom_need_count(struct ieee80211_sub_if_data *sdata)
 {
 	/*
@@ -94,11 +108,7 @@ static void increment_tailroom_need_count(struct ieee80211_sub_if_data *sdata)
 	 * http://mid.gmane.org/1308590980.4322.19.camel@jlt3.sipsolutions.net
 	 */
 
-	lockdep_assert_wiphy(sdata->local->hw.wiphy);
-
-	update_vlan_tailroom_need_count(sdata, 1);
-
-	if (!sdata->crypto_tx_tailroom_needed_cnt++) {
+	if (__increment_tailroom_need_count(sdata)) {
 		/*
 		 * Flush all XMIT packets currently using HW encryption or no
 		 * encryption at all if the count transition is from 0 -> 1.
@@ -569,10 +579,11 @@ int ieee80211_key_slot_lookup(struct ieee80211_sub_if_data *sdata,
 	return err;
 }
 
-static int ieee80211_key_replace(struct ieee80211_sub_if_data *sdata,
-				 struct ieee80211_key_slot *slot,
-				 struct ieee80211_key *old,
-				 struct ieee80211_key *new)
+static int __ieee80211_key_replace(struct ieee80211_sub_if_data *sdata,
+				   struct ieee80211_key_slot *slot,
+				   struct ieee80211_key *old,
+				   struct ieee80211_key *new,
+				   bool flush)
 {
 	bool defunikey, defmultikey, defmgmtkey, defbeaconkey;
 	struct ieee80211_local *local = sdata->local;
@@ -618,6 +629,15 @@ static int ieee80211_key_replace(struct ieee80211_sub_if_data *sdata,
 			if (!ieee80211_key_needs_tailroom(new))
 				decrease_tailroom_need_count(sdata, 1);
 		}
+
+		/*
+		 * The new key isn't visible to TX yet. If counting it took the
+		 * tailroom count from zero to one, flush TX before it is,
+		 * unless it went to the hardware needing no tailroom and so
+		 * gave the count back.
+		 */
+		if (!ret && flush && ieee80211_key_needs_tailroom(new))
+			synchronize_net();
 	}
 
 	if (ret)
@@ -693,6 +713,14 @@ static int ieee80211_key_replace(struct ieee80211_sub_if_data *sdata,
 	return 0;
 }
 
+static int ieee80211_key_replace(struct ieee80211_sub_if_data *sdata,
+				 struct ieee80211_key_slot *slot,
+				 struct ieee80211_key *old,
+				 struct ieee80211_key *new)
+{
+	return __ieee80211_key_replace(sdata, slot, old, new, false);
+}
+
 struct ieee80211_key *
 ieee80211_key_alloc(u32 cipher, int idx, size_t key_len,
 		    const u8 *key_data,
@@ -964,6 +992,7 @@ int ieee80211_key_link(struct ieee80211_sub_if_data *sdata,
 	static atomic_t key_color = ATOMIC_INIT(0);
 	struct ieee80211_key *old_key = NULL;
 	int idx = key->conf.keyidx;
+	bool flush = false;
 	int ret;
 
 	lockdep_assert_wiphy(sdata->local->hw.wiphy);
@@ -1031,9 +1060,19 @@ int ieee80211_key_link(struct ieee80211_sub_if_data *sdata,
 		goto out;
 	}
 
-	increment_tailroom_need_count(sdata);
+	/*
+	 * A key replacing another is counted, and TX flushed if that takes
+	 * the count from zero to one, here: the old key may drop to software
+	 * while still in use. A new key isn't used before it is published,
+	 * once it is known whether it went to the hardware without needing
+	 * tailroom, so __ieee80211_key_replace() flushes TX only if not.
+	 */
+	if (old_key)
+		increment_tailroom_need_count(sdata);
+	else
+		flush = __increment_tailroom_need_count(sdata);
 
-	ret = ieee80211_key_replace(sdata, slot, old_key, key);
+	ret = __ieee80211_key_replace(sdata, slot, old_key, key, flush);
 	if (ret) {
 		decrease_tailroom_need_count(sdata, 1);
 		key->local = NULL;

---
base-commit: 2c50cd5d10e8723797f28c7978f1f61688e0c0d2
change-id: 20261028-b4-mac80211-tailroom-4850fb8dee6f

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

