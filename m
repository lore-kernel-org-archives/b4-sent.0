From: =?utf-8?q?Caio_Jord=C3=A3o_Calisto?= <caio.jcalisto@gmail.com>
Date: Mon, 05 Oct 2026 15:13:03 -0700
Subject: [PATCH RFC wireless-next] wifi: mac80211: deauth the old AP MLD
 when roaming without FT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261005-mlo-roam-deauth-v1-1-a863e35a190b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MzQrCMBAGX6Xs2YUk/oFXwQfwKh5C88UutIlsa
 lsofXejxxmYWalABYUuzUqKSYrkVMHuGmo7n15gCZXJGXeyxhx56DNr9gMH+M/YsQttDPa8txE
 HqtVbEWX5Hx90v11/bhZFj1I4YRnpuW1fu0TiLncAAAA=
X-Change-ID: 20261005-mlo-roam-deauth-2dcfd1731fe4
To: Johannes Berg <johannes@sipsolutions.net>
Cc: linux-wireless@vger.kernel.org, 
 Miri Korenblit <miriam.rachel.korenblit@intel.com>, 
 =?utf-8?q?Caio_Jord=C3=A3o_Calisto?= <caio.jcalisto@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791238385; l=6782;
 i=caio.jcalisto@gmail.com; s=b4-20261005; h=from:subject:message-id;
 bh=jk1onJJXvWGT2KWmiejrqd3BEoTS4blc9Lg3Qb5bKz4=;
 b=Z3ghWNewP4QRpJq2pXa9dcly+0cKw4Rxb8BnsCGScl5BRtYZQlL4PxffAKjCvzjAGRFB1yrOQ
 zr3lljMdk5uDkPodSB1+ZjSfLJG5Q+8LSMQUYHt3ZLoi9pMmN/Oa501
X-Developer-Key: i=caio.jcalisto@gmail.com; a=ed25519;
 pk=a3chPQaRqMBVlrmx3pXPNsOkBA86+kINTxEWwB2xpjE=
X-Endpoint-Received: by B4 Relay for caio.jcalisto@gmail.com/b4-20261005 with auth_id=1119
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When userspace SME (wpa_supplicant) roams, it requests authentication
with the new AP while we are still associated. ieee80211_mgd_auth() then
drops the current association locally ("disconnect from AP %pM for new
auth to %pM") but passes tx=false to ieee80211_set_disassoc(), so the
old AP is never told that we left.

That breaks roaming between the two co-located BSSs (2.4 GHz and 5 GHz,
same SSID) of an AT&T residential Wi-Fi 7 gateway when the station is
associated as a non-AP MLD (Intel BE200, iwlwifi/iwlmld). The first
association attempt on the new BSS gets no response, going back to the
old BSS is rejected three times with status 30 and a comeback time of
1 TU, and after that the gateway ignores every association request from
this station on both BSSs for about five minutes, even across a reboot
of the client:

  wlp8s0f0: disconnect from AP 8e:66:37:xx:xx:58 for new auth to 8e:66:37:xx:xx:60
  wlp8s0f0: authenticated
  wlp8s0f0: associate with 8e:66:37:xx:xx:60 (try 1/3)
  wlp8s0f0: associate with 8e:66:37:xx:xx:60 (try 2/3)
  wlp8s0f0: associate with 8e:66:37:xx:xx:60 (try 3/3)
  wlp8s0f0: association with 8e:66:37:xx:xx:60 timed out
  wlp8s0f0: authenticated
  wlp8s0f0: associate with 8e:66:37:xx:xx:58 (try 1/3)
  wlp8s0f0: RX AssocResp from 8e:66:37:xx:xx:58 (capab=0x1431 status=30 aid=0)
  wlp8s0f0: 8e:66:37:xx:xx:58 rejected association temporarily; comeback duration 1 TU (1 ms)
  [... 2 more times ...]
  wlp8s0f0: association with 8e:66:37:xx:xx:58 timed out

All 8 roams between the two BSSs failed this way, 6 triggered by BSS
Transition Management requests from the AP and 2 by wpa_supplicant's
bgscan. In the same logs, the two moves to the other BSS that were
preceded by a deauth (one sent locally, one sent by the AP) associated
on the first attempt.

When the current association is an MLO one and the new authentication is
not FT, transmit the Deauthentication frame to the AP MLD we are leaving
instead of only building it for the cfg80211 event. It goes through the
same path as a userspace-requested deauth, while the keys are still
installed, so it is protected when MFP is in use. Leave FT alone because
the current association must stay valid until the FT reassociation
completes, and leave non-MLO associations alone to keep the behaviour
change small.

With this change the next 4 roams between the two BSSs (3 triggered by
BTM requests, 1 by bgscan) associated on the first attempt.

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Caio Jordão Calisto <caio.jcalisto@gmail.com>
---
Notes for reviewers (not for the commit log):

- RFC: this is arguably a workaround for an AP-side problem. I could not
  capture frames on air; the AP-side explanation (a stale MFP-protected
  entry for the non-AP MLD) is inferred from the client logs.

- Tool disclosure: the log analysis, the code change and this text were
  produced with an AI assistant (Claude) working from the logs of my
  machine and the kernel source. The installation and the on-air test
  were done on my hardware.

- Testing: only on a distribution kernel, Ubuntu 7.0.0-38.38-generic
  (based on 7.0.14), which was tainted by out-of-tree modules (nvidia,
  vboxdrv). Not reproduced on mainline. The hunk below is against
  v7.3-rc5, where this block of ieee80211_mgd_auth() is identical; it
  was not checked against the wireless-next tip. An unpatched
  out-of-tree build of net/mac80211 against the Ubuntu headers
  reproduces the distro module's .text byte for byte, and with the
  patch only ieee80211_mgd_auth() changes.

- Setup: Lenovo 83ME, Intel BE200 (PCI 272b/00f4), firmware
  101.6e695a70.0 gl-c0-fm-c0-c101.ucode, NetworkManager 1.54.3,
  wpa_supplicant from Ubuntu 26.04 (2.11 in the archive). AT&T fiber
  gateway (model not checked); SAE and MFP in use, as far as the client
  log shows. wpa_supplicant reports ap_mld_addr equal to the BSSID on
  each band ("[link 1]" on 2.4 GHz, "[link 0]" on 5 GHz), so each BSS
  appears to be its own single-link AP MLD.

- With the patch (kernel log, MAC addresses shortened):

    18:13:14 wlp8s0f0: disconnect from AP 8e:66:37:xx:xx:60 for new auth to 8e:66:37:xx:xx:58 (sending deauth)
    18:13:15 wlp8s0f0: associated
    18:14:10 wlp8s0f0: disconnect from AP 8e:66:37:xx:xx:58 for new auth to 8e:66:37:xx:xx:60 (sending deauth)
    18:14:10 wlp8s0f0: associated
    18:19:07 wlp8s0f0: disconnect from AP 8e:66:37:xx:xx:60 for new auth to 8e:66:37:xx:xx:58 (sending deauth)
    18:19:07 wlp8s0f0: associated
    18:22:38 wlp8s0f0: disconnect from AP 8e:66:37:xx:xx:58 for new auth to 8e:66:37:xx:xx:60 (sending deauth)
    18:22:38 wlp8s0f0: associated

- wpa_supplicant prints "nl80211: kernel reports: link ID must be set
  for MLO group key" three times at every roam, failed or not. It looks
  unrelated.

- Questions: is sending the deauth here acceptable, or should this be
  limited further or done in wpa_supplicant before it requests the new
  authentication?
---
 net/mac80211/mlme.c | 21 ++++++++++++++++++---
 1 file changed, 18 insertions(+), 3 deletions(-)

diff --git a/net/mac80211/mlme.c b/net/mac80211/mlme.c
index 6ec45a9f7..9e900f196 100644
--- a/net/mac80211/mlme.c
+++ b/net/mac80211/mlme.c
@@ -10099,13 +10099,28 @@ int ieee80211_mgd_auth(struct ieee80211_sub_if_data *sdata,
 
 	if (ifmgd->associated) {
 		u8 frame_buf[IEEE80211_DEAUTH_FRAME_LEN];
+		bool tx;
+
+		/*
+		 * When a non-AP MLD leaves its AP MLD for another AP without
+		 * using FT, tell the old AP MLD that we are gone instead of
+		 * silently dropping the association. Some AP MLD
+		 * implementations keep the MFP-protected MLD-level entry of
+		 * the non-AP MLD around and then ignore, or temporarily
+		 * reject (status 30), every (re)association attempt of the
+		 * same non-AP MLD on their other co-located BSSs until that
+		 * stale entry expires minutes later.
+		 */
+		tx = ieee80211_vif_is_mld(&sdata->vif) &&
+		     req->auth_type != NL80211_AUTHTYPE_FT;
 
 		sdata_info(sdata,
-			   "disconnect from AP %pM for new auth to %pM\n",
-			   sdata->vif.cfg.ap_addr, auth_data->ap_addr);
+			   "disconnect from AP %pM for new auth to %pM%s\n",
+			   sdata->vif.cfg.ap_addr, auth_data->ap_addr,
+			   tx ? " (sending deauth)" : "");
 		ieee80211_set_disassoc(sdata, IEEE80211_STYPE_DEAUTH,
 				       WLAN_REASON_UNSPECIFIED,
-				       false, frame_buf);
+				       tx, frame_buf);
 
 		ieee80211_report_disconnect(sdata, frame_buf,
 					    sizeof(frame_buf), true,

---
base-commit: 49e1f44dc3a659ff450eafe59375e2590ad5cf33
change-id: 20261005-mlo-roam-deauth-2dcfd1731fe4

Best regards,
-- 
Caio Jordão Calisto <caio.jcalisto@gmail.com>

