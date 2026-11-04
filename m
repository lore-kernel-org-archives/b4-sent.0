From: orkunsari <sariorkunemin@gmail.com>
Date: Wed, 04 Nov 2026 14:56:18 +0300
Subject: [PATCH wireless] wifi: mac80211: check for a NULL link in the MLD
 data RX station loop
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-mac80211-mld-null-link-v1-1-4cc9a00bbbaa@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQrCMBAAv1L27EI2FAl+RTw0yUZX0yjZVgulf
 2/U4zDMrKBchRVO3QqV36LyLA3o0EG4DeXKKLExWGOPRKbHcQjOWCIcc8Qy54xZygOdTaH3zqe
 YCFr8qpxk+Y3P8JHKmVXh8jc6+zuH6fuFbdsBMF0ghYQAAAA=
X-Change-ID: 20261104-mac80211-mld-null-link-82fc4b8bfdf1
To: Johannes Berg <johannes@sipsolutions.net>, 
 Benjamin Berg <benjamin.berg@intel.com>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 orkunsari <sariorkunemin@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793793377; l=1765;
 i=sariorkunemin@gmail.com; s=20261103; h=from:subject:message-id;
 bh=R4DVcGmhbdWe+b3QFvbYRb9TQYVI7s9L2sx1d5WG1rQ=;
 b=dMPK1NSn0yZQ9+t4JrJyygrZyb2mRH6moFkv3IhuRP687NJWXba5gz7PtDT1+IIUyfARFQnn2
 TAbL+MUJ0s/ARqo6oNYR5UlPFVn/Y0OlX98CpLyUHeDeP4KWAsmj+qv
X-Developer-Key: i=sariorkunemin@gmail.com; a=ed25519;
 pk=MJ3Y3somkGDQVAXOSR189QAqWOcfzYCRkL1cSQgJXnE=
X-Endpoint-Received: by B4 Relay for sariorkunemin@gmail.com/20261103 with auth_id=1408
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit 6d531b9af16e ("wifi: mac80211: rework RX packet
handling"), the loop over MLD link stations in
__ieee80211_rx_handle_packet() passes the result of
rcu_dereference(sdata->link[link_sta->link_id]) straight to
ieee80211_rx_valid_freq(), which dereferences link->sdata.

ieee80211_vif_update_links() clears sdata->link[] for a removed link
before ieee80211_sta_remove_link() and sta_info_flush() take the
corresponding link stations out of the hash table, so a frame received
from that link's address in between finds a link station whose link
pointer is NULL.  The management frame path already checks for this.

Skip link stations without a link, as the management path does.

This was found by AI-assisted code review (Claude Code).  The fix has
been build-tested with W=1 only; no reproducer was run.

Fixes: 6d531b9af16e ("wifi: mac80211: rework RX packet handling")
Signed-off-by: orkunsari <sariorkunemin@gmail.com>
---
Regression in v7.4-rc1 only; released kernels are not affected.
---
 net/mac80211/rx.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/net/mac80211/rx.c b/net/mac80211/rx.c
index ecee9348c7..038bca60a7 100644
--- a/net/mac80211/rx.c
+++ b/net/mac80211/rx.c
@@ -5469,7 +5469,7 @@ static void __ieee80211_rx_handle_packet(struct ieee80211_hw *hw,
 			sdata =	sta->sdata;
 			link = rcu_dereference(sdata->link[link_sta->link_id]);
 
-			if (!ieee80211_rx_valid_freq(status->freq, link))
+			if (!link || !ieee80211_rx_valid_freq(status->freq, link))
 				continue;
 
 			if (rx_data_pending) {

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261104-mac80211-mld-null-link-82fc4b8bfdf1

Best regards,
--  
orkunsari <sariorkunemin@gmail.com>

