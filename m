From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Sat, 31 Oct 2026 09:50:44 -0500
Subject: [PATCH] nl80211: Do not drop DFS state events for a BSS without a
 frequency
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-b115-dfs-state-events-v1-1-4265a0f76be2@gmail.com>
X-B4-Tracking: v=1; b=H4sIAEMA5moC/yXMQQ6CMBBG4auQWTsJ0wYwXsW4oPBXx0U1nUpMC
 Hen6PJbvLeSISuMLs1KGYuavlKFnBqaHmO6g3WuJte6XlovHEQ6nqOxlbGAsSAVYxfPnUfoh8E
 7qu07I+r3973e/rZPeGIqx4y2bQei9uYaeQAAAA==
X-Change-ID: 20261031-b115-dfs-state-events-2f853eb67732
To: hostap@lists.infradead.org
Cc: Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793458243; l=3485;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=R74XYjqzxrX56Ike3La4t0vtcWG094FI71GbZ54tEJE=;
 b=AiEbsxD3999WwL7ON7tg8Xu9DGcF3uZxrBXTLvBSOATcoMHKvdaUCgg9hiS7EIwLzD3G0ukou
 FO2WsyMNn8JCmdJZew2lQrGgx/uE4HntjjzZ6NYwlnt74SBjNmn5UM2
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

NL80211_RADAR_NOP_FINISHED and NL80211_RADAR_PRE_CAC_EXPIRED come
without an interface, and nl80211_radar_event() hands them to the BSS
whose link frequency matches the event, or failing that, any BSS on a
5 GHz frequency. A BSS that is not beaconing has no frequency: the
removal of its beacon clears it. So an event that arrives while the
interface restarts and runs ACS reaches no BSS and is dropped with only
a debug message.

That loses a pre-CAC expiry in a common case. An AP on a DFS channel
whose interface is reconfigured stops beaconing, reads the channel list
while the channel is still available, and runs ACS. About two seconds
after the channel stops being used, cfg80211 expires its CAC (outside
ETSI) and sends PRE_CAC_EXPIRED, which is dropped. If ACS then picks the
same channel, hostapd skips CAC on a channel it still has as available,
the kernel refuses it ("Could not set channel for kernel driver"), and
the interface ends up disabled.

Seen on IPQ8074 (ath11k) APs in the US, 5 GHz HE40 with ACS: a
reconfigure on channel 108 re-picked 108 twelve seconds later and
failed, while the kernel already listed 108 and 112 as usable; one on
140 failed the same way. From a non-DFS channel, or from a cold start,
the same change ran CAC and came up.

Pass these two events to the first BSS when no BSS matched. Both
handlers already ignore a frequency outside the interface's own
hardware, and wpa_supplicant handles NOP_FINISHED only for an AP or
mesh interface.

Tested on an IPQ8074 AP on channel 60 HE40, with the channel list
limited to the channel in use and a reload: without this change ACS
re-picked 60 and the interface failed as above; with it hostapd logged
DFS-PRE-CAC-EXPIRED for 5300 and 5320 MHz during ACS, ran CAC and came
up.

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
Seen with OpenWrt's hostapd on ath11k; main routes these events the
same way.
---
 src/drivers/driver_nl80211_event.c | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/src/drivers/driver_nl80211_event.c b/src/drivers/driver_nl80211_event.c
index 005a3d2..de0ccb2 100644
--- a/src/drivers/driver_nl80211_event.c
+++ b/src/drivers/driver_nl80211_event.c
@@ -2868,6 +2868,21 @@ static void nl80211_radar_event(struct i802_bss *bss, struct nlattr **tb)
 	if (hit)
 		return;
 
+	/* NOP_FINISHED and PRE_CAC_EXPIRED change the DFS state of a channel
+	 * of the wiphy and come without an interface. A BSS that is not
+	 * beaconing, e.g., while it restarts and runs ACS, has no frequency to
+	 * match, but its interface still keeps the state of that channel.
+	 * Losing the event leaves the channel available there after the
+	 * kernel expired its CAC, so a later start on it skips CAC and the
+	 * kernel refuses the channel. The handlers ignore a frequency outside
+	 * the interface's own range. */
+	if (event_type == NL80211_RADAR_NOP_FINISHED ||
+	    event_type == NL80211_RADAR_PRE_CAC_EXPIRED) {
+		data.dfs_event.link_id = NL80211_DRV_LINK_ID_NA;
+		nl80211_process_radar_event(drv->first_bss, &data, event_type);
+		return;
+	}
+
 	wpa_printf(MSG_DEBUG, "nl80211: DFS event on unknown freq on %s",
 		   bss->ifname);
 }

---
base-commit: ee5021e41b83060d69115ed91b66485f2fc888e0
change-id: 20261031-b115-dfs-state-events-2f853eb67732

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

