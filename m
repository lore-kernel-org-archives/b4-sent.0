From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Mon, 16 Nov 2026 19:37:03 +0000
Subject: [PATCH wireless v2] wifi: mac80211: check for a NULL link in the
 MLD station RX loop
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-mac80211-rx-null-link-v2-1-ea512ae98139@gmail.com>
X-B4-Tracking: v=1; b=H4sIAF5b+2oC/4WNQQ6CMBBFr0Jm7ZhOiZW48h6GBa0DTCzFtFoxh
 LvbcAGXLy///RUSR+EEl2qFyFmSzKGAPlTgxi4MjHIvDFppQ6Q0Tp1rlCbCuGB4e49ewgNNr1n
 Zk+qNtVC2z8i9LHv3Bh+J7DklaIsZJb3m+N0PM+3+TzsTEtZ1rayx1LizuQ5TJ/7o5gnabdt+A
 FfmVcQAAAA=
To: Johannes Berg <johannes@sipsolutions.net>, 
 Benjamin Berg <benjamin.berg@intel.com>, joasantonio108@gmail.com
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794857822; l=2604;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=aZzRCwDrJjSzerq/sLcLnuuDLZ11aHczEbNwIJoX7XQ=;
 b=jDCpi/RFWz9PlMH8/eSEDk4bEOkTS1I0UhEAtDMX/w3CZ6EcMKTc68kK9071y+TcF2Y3Nn+ue
 /FvMJYHQFAlBqCIhYoIvWfg77Lw3W9zThE8ZT7UIHjZwlcihaU9Ez48
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit 6d531b9af16e ("wifi: mac80211: rework RX packet handling"),
__ieee80211_rx_handle_packet() looks up the link of each MLD station
that matches addr2 and passes it straight to ieee80211_rx_valid_freq(),
which dereferences link->sdata and link->conf whenever status->freq is
set.  The non-MLD loop and the interface loop below it check the link,
this one does not.

The link can be NULL there.  ieee80211_vif_update_links() clears
sdata->link[link_id] for a removed link first, and only later, after
ieee80211_tear_down_links() (including its synchronize_rcu()) and
drv_change_vif_links(), calls ieee80211_sta_remove_link(), which takes
the link station out of the hash.  RX runs under RCU only, so a data
frame from that link's address arriving in this window finds the link
station but a NULL link, and the kernel oopses in softirq context.  A
link is removed this way for example when an associated AP announces
removal of one of its links (ieee80211_ml_reconf_work()), and the
frames only need a matching transmitter address, before any crypto.

Before the rework, ieee80211_rx_data_set_link() returned false for a
NULL link and the frame was skipped.  Skip it again.

Fixes: 6d531b9af16e ("wifi: mac80211: rework RX packet handling")
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
Found by LLM-assisted code review of the RX rework and confirmed by
reading the link removal path by hand.  I have not reproduced the oops
at runtime.

v1 got no replies but is marked "Changes Requested" in patchwork, so I
am not sure what is expected.  Please let me know if something else is
wanted here.
---
Changes in v2:
- Rebased on wireless/for-next (763b13f622e2), no code changes.
- Link to v1: https://lore.kernel.org/r/20261102-mac80211-rx-null-link-v1-1-3330b6b18c76@gmail.com
---
 net/mac80211/rx.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/net/mac80211/rx.c b/net/mac80211/rx.c
index f8cfd04c0c6c..a1db6488e4bc 100644
--- a/net/mac80211/rx.c
+++ b/net/mac80211/rx.c
@@ -5505,7 +5505,7 @@ static void __ieee80211_rx_handle_packet(struct ieee80211_hw *hw,
 			sdata =	sta->sdata;
 			link = rcu_dereference(sdata->link[link_sta->link_id]);
 
-			if (!ieee80211_rx_valid_freq(status->freq, link))
+			if (!link || !ieee80211_rx_valid_freq(status->freq, link))
 				continue;
 
 			if (rx_data_pending) {

---
base-commit: 763b13f622e2758726e8e3ecaef819db8fa0430a
change-id: 20261102-mac80211-rx-null-link-6f2e0b50f6bb

Best regards,
-- 
Joas Antonio dos Santos <joasantonio108@gmail.com>

