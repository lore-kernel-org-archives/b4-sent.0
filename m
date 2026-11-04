From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Wed, 04 Nov 2026 09:37:45 -0600
Subject: [PATCH] VLAN: Open the link event socket only for a BSS that has
 VLANs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-b140-vlan-socket-only-when-needed-v1-1-c6d18a85267b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAEhR62oC/yXNQQrCMBBG4auUWTuQ1FDEq4iLJvPXRstEklqV0
 rsbdflt3lupIEcUOjYrZSyxxKQVdtdQGHu9gKNUU2vazlrj2FtneJl65ZLCDTMnnd78HKGsgEC
 423vxdhB3EEO1c88Y4uv3OJ3/Lg9/RZi/Ydq2D9QcSV6FAAAA
X-Change-ID: 20261104-b140-vlan-socket-only-when-needed-63bdb1fd48d0
To: hostap@lists.infradead.org
Cc: Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793806664; l=2465;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=+y3+f1a44XpZ50F61RbvhDkO1IBbUaHgD73z4m4qFSU=;
 b=+hLazDcU1ez+AIWQ6/VUJLvAyZIAnO228+ZAI6marX/pHRLj1dSnoBKjvv+NAZmMiMB5buLRX
 VsppQO059iuBrVaH1vavGRLGV/GZFP9sWk7oT0hECZvXWoR2d4DtYK7
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vlan_init() opens a NETLINK_ROUTE socket in the RTMGRP_LINK group for
every BSS when hostapd is built with CONFIG_FULL_DYNAMIC_VLAN, whether
or not the BSS uses VLANs. Its events matter only to the BSS's VLAN
interfaces: vlan_newlink() and vlan_dellink() match them against
conf->vlan. A BSS with dynamic_vlan disabled, no per_sta_vif and no
VLAN list receives every link event in the system and uses none. When
hostapd is busy during a burst of link events, each of these sockets
overflows, and each BSS logs "VLAN: vlan_event_receive: recvfrom
failed: No buffer space available" at error level.

Open the socket only when the BSS can have VLAN interfaces. The rest
of the VLAN setup in vlan_init() already depends on the same settings,
and vlan_init() runs only at BSS setup.

Tested on OpenWrt (wpad, 4 BSSes without VLANs, on an Arista W-318).
hostapd held 5 NETLINK_ROUTE link sockets before (one per BSS and the
driver's) and 1 after. With hostapd stopped during 1000 up/down
toggles of a test bridge, the 4 per-BSS sockets overflowed and each
logged the error. With this change only the driver's socket
overflowed; it logs "netlink: Link events lost, request the link
state" and recovers.

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
Seen as one error line per BSS on OpenWrt APs with several BSSes and
no VLANs, at boot and around channel switches.
---
 src/ap/vlan_init.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/src/ap/vlan_init.c b/src/ap/vlan_init.c
index 53eacfb..02b9a9f 100644
--- a/src/ap/vlan_init.c
+++ b/src/ap/vlan_init.c
@@ -133,7 +133,10 @@ static void vlan_dynamic_remove(struct hostapd_data *hapd,
 int vlan_init(struct hostapd_data *hapd)
 {
 #ifdef CONFIG_FULL_DYNAMIC_VLAN
-	hapd->full_dynamic_vlan = full_dynamic_vlan_init(hapd);
+	/* Only a BSS that can have VLAN interfaces needs their link events */
+	if (hapd->conf->ssid.dynamic_vlan != DYNAMIC_VLAN_DISABLED ||
+	    hapd->conf->ssid.per_sta_vif || hapd->conf->vlan)
+		hapd->full_dynamic_vlan = full_dynamic_vlan_init(hapd);
 #endif /* CONFIG_FULL_DYNAMIC_VLAN */
 
 	if ((hapd->conf->ssid.dynamic_vlan != DYNAMIC_VLAN_DISABLED ||

---
base-commit: 412ff0d7f4d2b346df63be52c4201ee7ab0dc804
change-id: 20261104-b140-vlan-socket-only-when-needed-63bdb1fd48d0

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

