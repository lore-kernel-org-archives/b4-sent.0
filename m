From: =?utf-8?q?Burak_G=C3=B6nc=C3=BC?= <burakgon12@gmail.com>
Date: Thu, 15 Oct 2026 00:36:18 +0300
Subject: [PATCH] wifi: mac80211: deauthenticate from the old AP when
 roaming with MFP
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261015-mac80211-roam-mfp-deauth-v1-1-9ccc69b434fd@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQrCMAyA4VcZORtoinXqq8gOMUtdhG6j3UQYe
 3erHr/D/29QNJsWuDYbZH1ZsWmsoEMDMvD4ULS+GrzzJ3IUMLGcnSfCPHHCFGfslddlwJaPIUT
 2rVwEaj5njfb+rW/d32W9P1WW7w/2/QO3kckYfAAAAA==
X-Change-ID: 20261015-mac80211-roam-mfp-deauth-7a455fa27c9c
To: Johannes Berg <johannes@sipsolutions.net>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Burak_G=C3=B6nc=C3=BC?= <burakgon12@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792013780; l=4901;
 i=burakgon12@gmail.com; s=20261006; h=from:subject:message-id;
 bh=Ul1ZvEqnkBoUEz9VVXngoZ5xKwBtEcW5F7kwW3H4QSw=;
 b=jbXBl7rWy9/VgeNn3ICHgskkoOItRMi8jvwXHyf+medVTHEbTR/+hXr5/778Sq77m0y74Awxj
 6E+DgD4NNYKDWuoj9ZGMuDEgMJLqEEMcs/nXT2UQnWpkyXyWazHTlTG
X-Developer-Key: i=burakgon12@gmail.com; a=ed25519;
 pk=qcexQajnoYGkNqFOy3eFqTzvqTOR/P++ksapi6qUbvw=
X-Endpoint-Received: by B4 Relay for burakgon12@gmail.com/20261006 with auth_id=1126
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When userspace starts authentication with a new AP while we are still
associated, mac80211 drops the association locally and does not tell
the AP. With management frame protection the AP still holds a protected
association with us. An AP in that state has to treat a (re)association
from us as possibly forged: it refuses it temporarily and first checks
the old association with an SA Query, which we no longer answer. The new
association can then only succeed once the SA Query has timed out (1000
TU by default), but we give up after three (re)association attempts
100 ms apart.

This hits every roam to an AP that shares the old AP's state, for
example between the AP MLDs of an AP that runs one single-link AP MLD
per band and steers clients between them with BSS transition
management, and every reassociation with the current AP. With a TP-Link
Deco BE65/BE85 mesh (Qualcomm) and an Intel BE201 (iwlmld), each of ten
roams between the 5 GHz and the 6 GHz AP MLD of the same unit over nine
days timed out: the AP acknowledged all three Reassociation Request
frames and answered none, then deauthenticated us with reason 9 when we
fell back to the old AP MLD. Reassociating with the current AP got
reason 9 right away. A Reassociation Request sent 1 s after the first
one was accepted at once; one sent after 500 ms was still ignored.

Send the Deauthentication frame when MFP is in use. The AP then drops
the old association at once, and the same roams completed with the
first Reassociation Request, answered within 75 ms.

Assisted-by: LLM
Signed-off-by: Burak Göncü <burakgon12@gmail.com>
---
I ran into this with a TP-Link Deco BE65/BE85 mesh and an Intel BE201
(iwlmld) on 7.2.9. The Deco has 802.11v enabled and steers clients
from its 5 GHz to its 6 GHz AP MLD, so after every resume the laptop
failed that roam and ended up on a distant node for a few minutes.

To narrow it down I used a test build of mac80211 with two runtime
switches: the wait for the response after an acknowledged
(Re)Association Request, and transmitting the Deauthentication frame.
All roams below are between the 5 GHz and the 6 GHz AP MLD of one unit:

- stock: Reassociation Requests at 0, 100 and 200 ms, all ACKed, none
  answered; the fallback to the old AP MLD then got reason 9
- 500 ms wait: requests at 0, 500 and 1000 ms, only the third answered
- 3 s wait: the second request, at 3 s, answered within 64 ms
- Deauthentication sent, stock timing: answered on the first request
  within 64-74 ms, in both directions (one of them steered by BTM),
  and the same for roams between units and for reassociations with
  the current AP

I limited the change to MFP connections, where the AP has to protect
the old association; without MFP the AP can simply replace it. If you
prefer to send the frame unconditionally, I can respin.
---
 net/mac80211/mlme.c | 16 ++++++++++++++--
 1 file changed, 14 insertions(+), 2 deletions(-)

diff --git a/net/mac80211/mlme.c b/net/mac80211/mlme.c
index 6ec45a9f7..b6e38d210 100644
--- a/net/mac80211/mlme.c
+++ b/net/mac80211/mlme.c
@@ -10099,13 +10099,19 @@ int ieee80211_mgd_auth(struct ieee80211_sub_if_data *sdata,
 
 	if (ifmgd->associated) {
 		u8 frame_buf[IEEE80211_DEAUTH_FRAME_LEN];
+		/*
+		 * With MFP the AP protects our association and may not
+		 * accept a new (re)association from us until an SA Query
+		 * on the old one times out, so tell it that we leave.
+		 */
+		bool tx = ifmgd->flags & IEEE80211_STA_MFP_ENABLED;
 
 		sdata_info(sdata,
 			   "disconnect from AP %pM for new auth to %pM\n",
 			   sdata->vif.cfg.ap_addr, auth_data->ap_addr);
 		ieee80211_set_disassoc(sdata, IEEE80211_STYPE_DEAUTH,
 				       WLAN_REASON_UNSPECIFIED,
-				       false, frame_buf);
+				       tx, frame_buf);
 
 		ieee80211_report_disconnect(sdata, frame_buf,
 					    sizeof(frame_buf), true,
@@ -10452,13 +10458,19 @@ int ieee80211_mgd_assoc(struct ieee80211_sub_if_data *sdata,
 
 	if (ifmgd->associated) {
 		u8 frame_buf[IEEE80211_DEAUTH_FRAME_LEN];
+		/*
+		 * With MFP the AP protects our association and may not
+		 * accept a new (re)association from us until an SA Query
+		 * on the old one times out, so tell it that we leave.
+		 */
+		bool tx = ifmgd->flags & IEEE80211_STA_MFP_ENABLED;
 
 		sdata_info(sdata,
 			   "disconnect from AP %pM for new assoc to %pM\n",
 			   sdata->vif.cfg.ap_addr, assoc_data->ap_addr);
 		ieee80211_set_disassoc(sdata, IEEE80211_STYPE_DEAUTH,
 				       WLAN_REASON_UNSPECIFIED,
-				       false, frame_buf);
+				       tx, frame_buf);
 
 		ieee80211_report_disconnect(sdata, frame_buf,
 					    sizeof(frame_buf), true,

---
base-commit: a4190accbf7e05496754004bb701fb3e7d04e57f
change-id: 20261015-mac80211-roam-mfp-deauth-7a455fa27c9c

Best regards,
--  
Burak Göncü <burakgon12@gmail.com>

