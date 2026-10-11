From: Momo Chiyoda <risingnusun@gmail.com>
Date: Sun, 11 Oct 2026 16:10:28 +0900
Subject: [PATCH RFC wireless-next] wifi: mac80211: wait longer for the
 assoc response after TX ACK
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-assoc-timeout-rfc-v1-1-c6cd52166968@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQrCMBAAv1L23IUkQqBeBR/gtfSQpltd0ER2U
 1so/bvR4wzM7KAkTArnZgehDyvnVMG2DcRHSHdCniqDM85bYy0G1Ryx8IvyUlDmiJ0/jW7yrjM
 mQO3eQjNv/2cPt+vl51YWepIqJtoKDMfxBRkYrs95AAAA
X-Change-ID: 20261011-assoc-timeout-rfc-963b2d62900a
To: Johannes Berg <johannes@sipsolutions.net>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Emmanuel Grumbach <emmanuel.grumbach@intel.com>, 
 Momo Chiyoda <risingnusun@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791702629; l=3760;
 i=risingnusun@gmail.com; s=20261011; h=from:subject:message-id;
 bh=LOdM8a/v+emxV+3GmbWc+lYJdyPdcTUSe9gIToWDKyA=;
 b=G6UVCe/v5uILeWL4BKWHHduBF9xXMArOQtDkI5qXFtigNsrkT3DhWMfs1TV3mUVyuC4boOns1
 JoIj13gGPG/CMsqQY6B5ncsQMi+hguxSBa2bbiQCMUi0cvfOn5XpTgQ
X-Developer-Key: i=risingnusun@gmail.com; a=ed25519;
 pk=ExWtmy9phzUICIOOPUfUaW25aiqDA86U5ztzz8t7T4I=
X-Endpoint-Received: by B4 Relay for risingnusun@gmail.com/20261011 with auth_id=1153
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After the (Re)Association Request is ACKed, mac80211 waits only
IEEE80211_ASSOC_TIMEOUT_SHORT (100 ms) for the response before sending
the request again. That value comes from commit 1672c0e31917 ("mac80211:
start auth/assoc timeout on frame status"), which assumed a typical
response time of 30 ms.

An NEC Aterm 7200D8BE AP with MLO enabled needs about 180-250 ms to send
the Association Response. With an Intel BE201 (iwlmld) every association
therefore sends a second request about 105 ms after the first one:

  associate with ... (try 1/3)
  associate with ... (try 2/3)
  RX AssocResp from ... (capab=0x1931 status=0 aid=1024)

The AP answers the first request, the STA completes the 4-way handshake
and installs the keys, and about 330 ms later the AP also answers the
second request with status 0. From then on all individually addressed
protected frames from the AP fail to decrypt on the STA, although the
STA keys were not changed, so the AP has apparently set the association
up again. About 5 s later the AP sends an unprotected Deauthentication
frame. With PMF this ends in an SA Query timeout in wpa_supplicant and
a locally generated deauth with reason 2. The connection never survives
more than 7-10 s, and since every new attempt hits the same race it
loops forever.

The AP is at fault for resetting an established association on a
duplicate request, but retrying while the response is still on its way
makes this easy to hit. Use IEEE80211_ASSOC_TIMEOUT_LONG (500 ms) once
the request has been ACKed. A request that was not ACKed is still
retried immediately, so only an AP that ACKs the request and then does
not respond takes longer to fail (3 * 500 ms instead of 3 * 100 ms).

IEEE80211_ASSOC_TIMEOUT_SHORT is kept since it is also used for the ML
reconfiguration timeout.

Tested with the same change on the iwlwifi backport tree on top of
Ubuntu 7.0.0-38: before, 33 MLO associations had 66 retried requests
and 31 reason 2 deauths. After, 12 associations in 8 days had no
retried request, and the current connection has been up for more than
5 days. On wireless-next this is only compile-tested.

The trace analysis and this patch were done with an AI coding
assistant.

Closes: https://bugzilla.kernel.org/show_bug.cgi?id=221868
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Momo Chiyoda <risingnusun@gmail.com>
---
RFC because this changes association timing for everyone:
- Is 500 ms acceptable, or should the longer wait be limited to MLO?
- I left out a Fixes: tag on purpose, since this works around AP behaviour.
  Please tell me if you want one (and stable).

Emmanuel Grumbach suggested sending this as an RFC in
https://bugzilla.kernel.org/show_bug.cgi?id=221868
---
 net/mac80211/mlme.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/net/mac80211/mlme.c b/net/mac80211/mlme.c
index 6ec45a9f7..b3704b6e8 100644
--- a/net/mac80211/mlme.c
+++ b/net/mac80211/mlme.c
@@ -9207,8 +9207,13 @@ void ieee80211_sta_work(struct ieee80211_sub_if_data *sdata)
 			 * the response to be received and processed first.
 			 */
 			if (status_acked) {
+				/*
+				 * Some APs need ~200 ms to respond (seen with
+				 * MLO) and treat a retried request as a new
+				 * association, so don't retry too early.
+				 */
 				ifmgd->assoc_data->timeout =
-					jiffies + IEEE80211_ASSOC_TIMEOUT_SHORT;
+					jiffies + IEEE80211_ASSOC_TIMEOUT_LONG;
 				run_again(sdata, ifmgd->assoc_data->timeout);
 			} else {
 				ifmgd->assoc_data->timeout = jiffies - 1;

---
base-commit: fbfa27d9b06f025c5f2cfa79d0e01e6400eeff2a
change-id: 20261011-assoc-timeout-rfc-963b2d62900a

Best regards,
-- 
Momo Chiyoda <risingnusun@gmail.com>

