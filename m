From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Sat, 07 Nov 2026 18:02:50 -0600
Subject: [PATCH wireless] wifi: mac80211: keep the operation elements of a
 duplicated beacon
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-mac80211-beacon-dup-oper-v1-1-560a1bda4c92@gmail.com>
X-B4-Tracking: v=1; b=H4sIACm872oC/yWMwQrCMBAFf6Xs2YUkFG39FfGQJq+6oknItiqU/
 rtVj8Mws5CiCpSOzUIVT1HJaQO7ayhcfbqAJW5Mzri9tebADx8646zlAT7kxHEunAsqo+27Fj3
 G6EBbXipGef/WJ3pJxR2qdP4bnYcbwvQ907p+AFc/nfyGAAAA
X-Change-ID: 20261107-mac80211-beacon-dup-oper-e4984e9efd2e
To: Johannes Berg <johannes@sipsolutions.net>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794096169; l=3611;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=DCAiZMD10Y1x+ygXE8qpchuzeKQmywabx9INKvjeu68=;
 b=AQVQ4PtsT03ZaN0enKk+fOAGv/j+yDwTbuGIaAfepgK/U4UNs7GJCLFxxWDG2zsgBlLsYlLhE
 3nD0V62OsriBt4N9X7AgLiWMdJKeoDQ5Vn+1LGGh8bUx4Y3WfPhX+J+
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit c9b62ab79133 ("wifi: mac80211: fix per-station PHY
capability bandwidth"), ieee80211_assign_beacon() derives the AP's HE
and lower bandwidth from the HT, VHT and HE operation elements of the
beacon, and updates every station when it changes. nl80211 finds those
elements in the beacon tail and passes pointers to them, but
cfg80211_beacon_dup() doesn't set them in the copy.

mac80211 installs such a copy when a channel switch or a BSS color
change completes. With no operation elements, the bandwidth comes out
as 20 MHz and every station is set to 20 MHz, until hostapd's next
beacon update sets it back.

On an IPQ8074 AP with ath11k, every channel switch, also one to the
same width, made ath11k send the firmware a 20 MHz peer bandwidth and
phymode for each station and the right ones about 10 ms later. Once,
after a switch from 80 to 40 MHz, the AP kept sending to a client at
20 MHz until it reassociated.

Point the operation element pointers of the copy into its tail.

With the change, on the same AP, a channel switch at the same width
left the stations' bandwidth alone, and a switch from 40 to 80 MHz and
back updated each station once, to 80 and then to 40 MHz.

Fixes: c9b62ab79133 ("wifi: mac80211: fix per-station PHY capability bandwidth")

The change, this message and the test were written with Claude, an AI
coding assistant.

Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
Found on an Arista C-360 (IPQ8074, ath11k) running OpenWrt: ath11k's
debug log showed a 20 MHz bandwidth update for every station at the end
of every channel switch, followed by the right one, and a stack trace
put it at ieee80211_csa_finalize() -> ieee80211_assign_beacon().

The BSS color change path installs a cfg80211_beacon_dup() copy too
(beacon_next), so it should have the same effect; I tested only the
channel switch.
---
 net/mac80211/cfg.c | 22 ++++++++++++++++++++++
 1 file changed, 22 insertions(+)

diff --git a/net/mac80211/cfg.c b/net/mac80211/cfg.c
index 9608c07bcea7d..7356788a8d060 100644
--- a/net/mac80211/cfg.c
+++ b/net/mac80211/cfg.c
@@ -4586,6 +4586,18 @@ static void ieee80211_end_cac(struct wiphy *wiphy,
 	}
 }
 
+static const void *
+ieee80211_dup_tail_elem(const struct cfg80211_beacon_data *old,
+			const struct cfg80211_beacon_data *new, const void *elem)
+{
+	const u8 *pos = elem;
+
+	if (!pos || pos < old->tail || pos >= old->tail + old->tail_len)
+		return NULL;
+
+	return new->tail + (pos - old->tail);
+}
+
 static struct cfg80211_beacon_data *
 cfg80211_beacon_dup(struct cfg80211_beacon_data *beacon)
 {
@@ -4639,6 +4651,16 @@ cfg80211_beacon_dup(struct cfg80211_beacon_data *beacon)
 		new_beacon->tail = pos;
 		memcpy(pos, beacon->tail, beacon->tail_len);
 		pos += beacon->tail_len;
+
+		/* nl80211 found the operation elements in the tail */
+		new_beacon->ht_oper = ieee80211_dup_tail_elem(beacon, new_beacon,
+							      beacon->ht_oper);
+		new_beacon->vht_oper = ieee80211_dup_tail_elem(beacon, new_beacon,
+							       beacon->vht_oper);
+		new_beacon->he_oper = ieee80211_dup_tail_elem(beacon, new_beacon,
+							      beacon->he_oper);
+		new_beacon->eht_oper = ieee80211_dup_tail_elem(beacon, new_beacon,
+							       beacon->eht_oper);
 	}
 	if (beacon->beacon_ies_len) {
 		new_beacon->beacon_ies_len = beacon->beacon_ies_len;

---
base-commit: c4328134f3f7c2ce141121a8f82a5ec0cc8a709c
change-id: 20261107-mac80211-beacon-dup-oper-e4984e9efd2e

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

