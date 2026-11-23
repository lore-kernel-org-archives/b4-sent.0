From: Andreas Claesson <andreas@aclaesson.com>
Date: Mon, 23 Nov 2026 08:59:00 +0000
Subject: [PATCH] wifi: cfg80211: don't warn if the joined IBSS has no IBSS
 BSS entry
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-wifi-ibss-joined-lookup-v1-1-0d84745eac94@aclaesson.com>
X-B4-Tracking: v=1; b=H4sIAFMABGsC/yXMPQ7CMAxA4atUnrFUeyg/V0EMpHbALUqqmFKkq
 ncnwPgN763gWkwdTs0KRV/mllMF7Rro79d0UzSpBm65I2LCxaKhBXccsiUVfOQ8zhPyXgILHUK
 UI9R6Khrt/TufL3/7HAbtn98dbNsHnSk4FHsAAAA=
X-Change-ID: 20261121-wifi-ibss-joined-lookup-27db2d18bfd9
To: Johannes Berg <johannes@sipsolutions.net>
Cc: linux-kernel@vger.kernel.org, linux-wireless@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795424340; l=3767;
 i=andreas@aclaesson.com; s=20261109; h=from:subject:message-id;
 bh=m7h+52YKRxR9ZLb3Ud63XWtQSFI2V8VSZyV0cDOPuJs=;
 b=yVvqn1HysF3ujS3h/7QVcvjXvSDAnOKJu/ORYIRi70GOGGQc8x0+5v3oegB3ziKkpriWcRF6R
 wPduLp0uMb8BoSH4uliiptIKMvtqehfdZq2XpeezPJ1Wv9yuxy5WbTM
X-Developer-Key: i=andreas@aclaesson.com; a=ed25519;
 pk=oC+38UX0rqcrEjNMgnKAF1zmrTUMbQ2aH/P5Z4TZOIQ=
X-Endpoint-Received: by B4 Relay for andreas@aclaesson.com/20261109 with auth_id=1465
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cfg80211_ibss_joined() looks up the BSS entry of the IBSS that was just
joined, by BSSID and channel and restricted to entries with the IBSS
capability, and warns if it does not find one. mac80211 calls
cfg80211_inform_bss_frame_data() with its own probe response right
before, which is expected to guarantee that the entry exists.

It does not. Beacons are added to the BSS table from the RX path at
any time, also when no scan is running, and the wiphy mutex held by the
IBSS work does not exclude that. A beacon with the BSSID and SSID of
the IBSS that does not have the IBSS capability bit set updates the
same entry and overwrites its capability. If it is processed between
the inform and the lookup, no IBSS entry is found:

  wlan1: Creating new IBSS network, BSSID 50:50:50:50:50:50
  !bss
  WARNING: net/wireless/ibss.c:72 at cfg80211_ibss_joined+0x3a7/0x5b0
  Workqueue: events_unbound cfg80211_wiphy_work
  Call Trace:
   __ieee80211_sta_join_ibss+0xdd3/0x1660 net/mac80211/ibss.c:375
   ieee80211_sta_create_ibss+0x300/0x480 net/mac80211/ibss.c:1287
   ieee80211_sta_find_ibss net/mac80211/ibss.c:1416 [inline]
   ieee80211_ibss_work+0xd9b/0x1060 net/mac80211/ibss.c:1637
   cfg80211_wiphy_work+0x29e/0x420 net/wireless/core.c:610

The beacon comes from the air, so the warning can be triggered by
anybody in range of a station that is joining an IBSS, and the join
event is not delivered when it happens.

If there is no IBSS entry, look the entry up without the type
restriction, and do not warn if there is none at all, since the RX
path can also unlink entries.

This is not the trigger fixed by commit 2531f6539d2f ("wifi: cfg80211:
validate WEXT station BSSID"), which is in the tested kernels: the
BSSID here is a valid unicast address.

Found with syzkaller. Reproduced with mac80211_hwsim on wireless
(dcf495789037) by joining and leaving an IBSS with fixed BSSID and
channel in a loop while injecting beacons with the same BSSID and SSID
and the ESS capability. Without this patch, 124 of 778 joins hit the
warning and exactly those 124 joins had no NL80211_CMD_JOIN_IBSS
event. With it, 1456 joins gave 1456 events and no warning. The case
where no entry is found at all was not reproduced.

Fixes: 04a773ade068 ("cfg80211/nl80211: add IBSS API")
Cc: stable@vger.kernel.org
Assisted-by: Claude:claude-mythos-5-2
Signed-off-by: Andreas Claesson <andreas@aclaesson.com>
---
Found with syzkaller on 7.4-rc1 and reproduced with mac80211_hwsim;
the reproducer is a small C program that I can send if it is of use.
Based on wireless.
---
 net/wireless/ibss.c | 12 +++++++++++-
 1 file changed, 11 insertions(+), 1 deletion(-)

diff --git a/net/wireless/ibss.c b/net/wireless/ibss.c
index 81dff0bace286..cb33fb403b786 100644
--- a/net/wireless/ibss.c
+++ b/net/wireless/ibss.c
@@ -69,7 +69,17 @@ void cfg80211_ibss_joined(struct net_device *dev, const u8 *bssid,
 
 	bss = cfg80211_get_bss(wdev->wiphy, channel, bssid, NULL, 0,
 			       IEEE80211_BSS_TYPE_IBSS, IEEE80211_PRIVACY_ANY);
-	if (WARN_ON(!bss))
+	/*
+	 * The driver informed us about this BSS, but a frame received since
+	 * then may have changed the capability of the entry, so that it no
+	 * longer looks like an IBSS, or may even have removed the entry.
+	 * Neither is a driver bug, so do not warn about it.
+	 */
+	if (!bss)
+		bss = cfg80211_get_bss(wdev->wiphy, channel, bssid, NULL, 0,
+				       IEEE80211_BSS_TYPE_ANY,
+				       IEEE80211_PRIVACY_ANY);
+	if (!bss)
 		return;
 
 	ev = kzalloc_obj(*ev, gfp);

---
base-commit: dcf495789037ab78d8ddf5844239cf85d92ac5f1
change-id: 20261121-wifi-ibss-joined-lookup-27db2d18bfd9

Best regards,
--  
Andreas Claesson <andreas@aclaesson.com>

