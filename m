From: =?utf-8?q?Lo=C3=AFc_Kassel?= <loic.kassel@gmail.com>
Date: Fri, 23 Oct 2026 19:21:54 +0200
Subject: [PATCH wireless] wifi: mac80211_hwsim: use CLOCK_BOOTTIME for the
 beacon timer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261023-hwsim-beacon-clock-v1-1-9b3f3ffc099b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQrCMBBG4auUWTuQRJC2VxEXcfrXDraJZKARS
 u9ucPkt3jvIUBRGY3dQwa6mOTX4S0eyxPQC69RMwYWbd+HKSzXd+IkoObGsWd6M2M/wk5Nh6Km
 Fn4JZv//pnaoWrDCjx3n+AGkPCAZuAAAA
X-Change-ID: 20261023-hwsim-beacon-clock-ea8fe1d0c998
To: Johannes Berg <johannes@sipsolutions.net>, 
 Benjamin Berg <benjamin.berg@intel.com>, 
 Miri Korenblit <miriam.rachel.korenblit@intel.com>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Lo=C3=AFc_Kassel?= <loic.kassel@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792776149; l=2489;
 i=loic.kassel@gmail.com; s=20261023; h=from:subject:message-id;
 bh=pcL4DXeSmeZCNbu0odCOcRBBfSJ6zAv3ONG4ux6DNnE=;
 b=U3rRFkEZroe2nHeMsYy0UB62+omfo4r4pYx8C4+PAvwcAnH4Oakmla/sLkFzEO8wb33TzCkbo
 /Lu/O+6TjsUBW9ZoFFUPEZBRF3gEUDpgJnfExmkIgfK7JMrXM31YAps
X-Developer-Key: i=loic.kassel@gmail.com; a=ed25519;
 pk=8MjN6l7+bGFfW7/nYXQfpGkxGFb6lH8T7uhKv5XLruA=
X-Endpoint-Received: by B4 Relay for loic.kassel@gmail.com/20261023 with auth_id=1290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The simulated TSF is based on boottime, and the beacon timer is re-armed
with an absolute expiry derived from the TSF through
mac80211_hwsim_tsf_to_boottime(). The timer itself is however still set
up with CLOCK_MONOTONIC.

Boottime keeps running while the system is suspended, monotonic does
not. After the host has been suspended once, every beacon is therefore
scheduled too late by the total time spent in suspend, and APs
practically stop sending beacons.

Set the beacon timer up with CLOCK_BOOTTIME so that it is consistent
with the TSF.

The bug was analysed, and this change and commit message drafted, with
the help of an AI assistant (Claude, Opus 5.5). I reviewed the change
and tested it on v7.2.11 (Fedora 44), applying the same one-line change
to that kernel's mac80211_hwsim and loading it as an out-of-tree module.
With hostapd started after a suspend (boottime 61 s ahead of monotonic),
an associated station received about 10 beacons per second with no
beacon loss, and scans found all APs. With the unmodified module, in the
same situation, beacons practically stopped and APs without associated
stations were not found by scans.

Fixes: 933f5bec98a1 ("wifi: mac80211_hwsim: register beacon timer by calculating TBTT")
Closes: https://lore.kernel.org/linux-wireless/CAAzpgGdksHZjx4jc20zqnAG_PQ2e1ggANQjt2eiycUiWc+vPHg@mail.gmail.com/
Signed-off-by: Loïc Kassel <loic.kassel@gmail.com>
---
Benjamin confirmed the analysis in the report thread and suggested that
I send the fix myself. This is my first kernel patch.
---
 drivers/net/wireless/virtual/mac80211_hwsim_main.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/wireless/virtual/mac80211_hwsim_main.c b/drivers/net/wireless/virtual/mac80211_hwsim_main.c
index b9446577ff..203bf9a4b9 100644
--- a/drivers/net/wireless/virtual/mac80211_hwsim_main.c
+++ b/drivers/net/wireless/virtual/mac80211_hwsim_main.c
@@ -6136,7 +6136,7 @@ static int mac80211_hwsim_new_radio(struct genl_info *info,
 
 	for (i = 0; i < ARRAY_SIZE(data->link_data); i++) {
 		hrtimer_setup(&data->link_data[i].beacon_timer, mac80211_hwsim_beacon,
-			      CLOCK_MONOTONIC, HRTIMER_MODE_ABS_SOFT);
+			      CLOCK_BOOTTIME, HRTIMER_MODE_ABS_SOFT);
 		data->link_data[i].link_id = i;
 	}
 

---
base-commit: 9d8ec0b5b5295bd23d979d1b2b905de25c36fff2
change-id: 20261023-hwsim-beacon-clock-ea8fe1d0c998

Best regards,
-- 
Loïc Kassel <loic.kassel@gmail.com>

