From: Shunsuke Nagashima <shunsuke@nagashi.ma>
Date: Fri, 16 Oct 2026 09:17:56 +0900
Subject: [PATCH ath-next 3/3] wifi: ath10k: bring down a station vdev that
 never came up
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-ath10k-series-v1-send-v1-3-c847697b3558@nagashi.ma>
References: <20261016-ath10k-series-v1-send-v1-0-c847697b3558@nagashi.ma>
In-Reply-To: <20261016-ath10k-series-v1-send-v1-0-c847697b3558@nagashi.ma>
To: Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, ath10k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Fabricio Akio <fabricioakio@gmail.com>, 
 Shunsuke Nagashima <shunsuke@nagashi.ma>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792109874; l=9056;
 i=shunsuke@nagashi.ma; s=20260927; h=from:subject:message-id;
 bh=IpDSM5sXKBRxL+7+jlud5JT+85akbP75BzzmUNmbQ5E=;
 b=+eO50zj00w5+e00fulnunDRfCkQpWGSFu6qivzhEIkt6fLpbZM+egu08XTHAuxRRGNpqtywm0
 0UZwoQ9MCVxBEQDWYB6RN7vj54owUfXHILKP9Dvw4Fmg2PXUg1Sbln+
X-Developer-Key: i=shunsuke@nagashi.ma; a=ed25519;
 pk=5WP8Bzifiy3DFoCeQ1lLy2osPmlNAkq71Un7ly9lbpk=
X-Endpoint-Received: by B4 Relay for shunsuke@nagashi.ma/20260927 with auth_id=1069
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a connection attempt fails before the station vdev is brought up
(authentication timeout, SAE failure, association rejected, or an Auth
burst the AP never acknowledged), mac80211 removes the AP station and
unassigns the channel context. ath10k deletes the peer and sends
WMI_VDEV_STOP, but no WMI_VDEV_DOWN: for a station vdev that never came
up, the down would only come from ath10k_bss_disassoc(), which a failed
connection attempt never reaches.

On WCN3990 firmware WLAN.HL.2.0.c10-00459 and c10-00236, the Auth frames
of the next attempt on the same vdev are then not transmitted
(management tx completion status "discard") until about 20 s after the
first Auth frame of the failed attempt. In sniffer captures, 241 such
holds ended 19.94-20.03 s after that frame. Some lasted longer (in one
overnight run, 29 of 226 had not ended when the cycle ended), for
example when user space gave up on the attempt during the hold. Probe
requests still go out. The state belongs to the vdev: an attempt to
another network (another BSS on the same AP) on the same vdev was held
too (2 of 2), and re-creating the vdev cleared it (2 of 2). This happens
on WPA2 networks as well as WPA3. An older firmware build,
WLAN.HL.2.0-01387, did not hold the frames (0 of 7 reconnects after
status 30).

With the stock driver in its production configuration, a reconnect
after an association rejection with status 30 took 24.3 and 24.4 s
(2 of 2). In an overnight run of PMF connections on the stock driver,
using a local firmware-5.bin with the MFP feature bit set (the same
effect as the first patch of this series), 142 of 6946 connection
cycles failed, and every one of the 142 failures included such a hold.

Until commit 077efc8c42e8 ("ath10k: clean up sta auth/assoc code")
ath10k_bss_disassoc() ran on every AP station removal and sent
VDEV_STOP followed by VDEV_DOWN, with the comment "If we don't call
VDEV-DOWN after VDEV-STOP FW will remain active". That commit moved
the stop to the station removal (today the channel context
unassignment) and kept the down only for the disassociation, so a
station vdev that never came up has been stopped without a down ever
since. ath12k_mac_station_remove() still sends the down on every
station removal of a station vdev, whether or not it came up.

Remember whether the vdev has been brought up since it was last
started and, in ath10k_mac_op_unassign_vif_chanctx(), send
WMI_VDEV_DOWN after WMI_VDEV_STOP for a station vdev that never came
up. Checking is_up alone would not do: ath10k_bss_disassoc() clears
it after sending its own down, so every normal disconnect would get a
second down. Normal disconnects, where the vdev was up, are not changed.
The order matters: the down has to follow the peer deletion and the
stop, because on this firmware a down while the peer still exists
makes the firmware assert. AP, IBSS and monitor vdevs are not touched.
Nothing in the change is specific to WCN3990, but only WCN3990 was
tested.

With this patch alone in the production configuration (no ath10k
debug), 6 of 6 reconnects after an association rejection with status 30
took 6.8-9.2 s. Sniffer captures showed every Auth frame of the next
attempt on the air at once, with none held. All 105 WPA3 cycles (103
with a status-30 rejection first) and all 50 WPA2 cycles connected,
with no kernel WARN. Link loss during a pending association (3 of 3),
rfkill, AP mode, and an SAE password mismatch with a firmware file
having the MFP feature bit also worked. A further 480 cycles, half
WPA3 and half WPA2, all connected.

With all three patches of this series (an earlier form of the first
patch) in the production configuration, the next correct connection
after an SAE password mismatch on the same vdev sent its first Auth
0.18-0.23 s after the failed attempt ended and connected (4 of 4; with
the final version of the series, 4 of 4 connected in 0.76-0.85 s). In
7,100 cycles over about 10 hours (WPA3, WPA2/WPA3 transition and WPA2),
no Auth was held in the first 8 hours, which were checked on the air:
all 13,511 Auth transmissions that mac80211 logged there were seen on
the air.

With a CONFIG_ATH10K_DEBUG build of this patch together with the
previous patch, a normal disconnect sent exactly one VDEV_DOWN, from
ath10k_bss_disassoc(), and a failed attempt one VDEV_DOWN after
VDEV_STOP (5 WPA3 cycles, 4 of them with status 30 first, and 5 WPA2
cycles).

Tested-on: WCN3990 hw1.0 SNOC WLAN.HL.2.0.c10-00459-QCAHLSWMTPLZ-1

Assisted-by: LLM sparse
Signed-off-by: Shunsuke Nagashima <shunsuke@nagashi.ma>
---
Notes:

- Only WCN3990 was tested (hw1.0 SNOC, WLAN.HL.2.0.c10-00459). TDLS,
  P2P client and multiple vifs were not tested.

- An earlier revision with the same WMI command order ran 4603 cycles
  overnight with 2229 failed attempts; the next attempt's first Auth
  went out at once after every one of them.

- A separate, rare problem: right after an association, all host data
  is dropped (HTT tx completion status 5) for about 45-59 s. On the air,
  after EAPOL M4 the station sends no data, no ADDBA and gets no Block
  Ack from the AP; it only sends QoS Null frames, and the protected
  Deauth at the end carries PN 0. On one AP, I saw it 3 times in 14,937
  PMF associations on three earlier test builds (an earlier revision of
  this patch alone; this patch and the previous one in a debug build;
  all three patches with an earlier form of the first patch). Two of
  these three builds did not set the PMF peer flag (no first patch, and
  the stock firmware file). On a different AP (a WPA3-only mobile
  router), with a firmware file having the MFP feature bit, it happened
  2 times in 27,360 SAE/PMF connection cycles over about 42 hours with a
  debug build without patches 2 and 3 (whose vdev down and
  disassociation code is the stock code), and once in about 36,800
  SAE/PMF connection cycles with the final version of the series. So no
  single patch of this series is needed for it to happen. These counts
  come from different setups and are not a controlled comparison. The
  cause is not known.

- Test kernel: a v7.2-based kernel on a comma four (SDM845) that also
  carries three out-of-tree ath10k patches (MAC address, in-order rx
  A-MSDU, SET_KEY wait).

AI-assistance disclosure:

I worked on this with Claude (mainly claude-opus-5-5 and
claude-fable-5-1) and Codex (gpt-6-astra). They helped go through the
logs and sniffer captures, draft the code changes and the debug builds,
and write the English of the commit messages. I reviewed the code. All
device tests ran on my own comma four, and the results above come from
those runs.
---
 drivers/net/wireless/ath/ath10k/core.h |  2 ++
 drivers/net/wireless/ath/ath10k/mac.c  | 21 +++++++++++++++++++++
 2 files changed, 23 insertions(+)

diff --git a/drivers/net/wireless/ath/ath10k/core.h b/drivers/net/wireless/ath/ath10k/core.h
index dfee432615eb..373b84082128 100644
--- a/drivers/net/wireless/ath/ath10k/core.h
+++ b/drivers/net/wireless/ath/ath10k/core.h
@@ -605,6 +605,8 @@ struct ath10k_vif {
 	union {
 		struct {
 			u32 uapsd;
+			/* vdev was brought up since it was last started */
+			bool was_up;
 		} sta;
 		struct {
 			/* 512 stations */
diff --git a/drivers/net/wireless/ath/ath10k/mac.c b/drivers/net/wireless/ath/ath10k/mac.c
index 88ebcd2d1110..a95c016cbb34 100644
--- a/drivers/net/wireless/ath/ath10k/mac.c
+++ b/drivers/net/wireless/ath/ath10k/mac.c
@@ -3170,6 +3170,7 @@ static void ath10k_bss_assoc(struct ieee80211_hw *hw,
 	}
 
 	arvif->is_up = true;
+	arvif->u.sta.was_up = true;
 
 	ath10k_mac_set_sar_power(ar);
 
@@ -9023,6 +9024,9 @@ ath10k_mac_op_assign_vif_chanctx(struct ieee80211_hw *hw,
 
 	arvif->is_started = true;
 
+	if (arvif->vdev_type == WMI_VDEV_TYPE_STA)
+		arvif->u.sta.was_up = false;
+
 	ret = ath10k_mac_vif_setup_ps(arvif);
 	if (ret) {
 		ath10k_warn(ar, "failed to update vdev %i ps: %d\n",
@@ -9106,6 +9110,23 @@ ath10k_mac_op_unassign_vif_chanctx(struct ieee80211_hw *hw,
 		ath10k_warn(ar, "failed to stop vdev %i: %d\n",
 			    arvif->vdev_id, ret);
 
+	/* A connection attempt that fails before the vdev is up never reaches
+	 * ath10k_bss_disassoc(), so the station vdev would be stopped without
+	 * ever being brought down. At least WCN3990 firmware then holds the
+	 * Auth frames of the next attempt for about 20 seconds. Bring it down
+	 * here, after the peer is gone and the vdev is stopped: a down while
+	 * the peer still exists asserts the firmware.
+	 */
+	if (arvif->vdev_type == WMI_VDEV_TYPE_STA && !arvif->u.sta.was_up) {
+		ath10k_dbg(ar, ATH10K_DBG_MAC, "mac vdev %i down (never up)\n",
+			   arvif->vdev_id);
+
+		ret = ath10k_wmi_vdev_down(ar, arvif->vdev_id);
+		if (ret)
+			ath10k_warn(ar, "failed to down vdev %i after stop: %d\n",
+				    arvif->vdev_id, ret);
+	}
+
 	arvif->is_started = false;
 
 	mutex_unlock(&ar->conf_mutex);

-- 
Git-157)

