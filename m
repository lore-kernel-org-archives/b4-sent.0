From: Ricky Sorrell <rmsorrell@gmail.com>
Date: Mon, 16 Nov 2026 20:49:39 -0700
Subject: [PATCH] power: supply: surface_battery: Defer AC-triggered update
 across suspend
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-surface-battery-suspend-v1-1-71862c94435f@gmail.com>
X-B4-Tracking: v=1; b=H4sIANLO+2oC/yXMQQrCMBBG4auUWRtoChbxKuJikvzRcRHLTCqV0
 rs31eW3eG8lgwqMrt1Kio+YvEuDP3UUn1wecJKaaeiH0Xs/Ops1c4QLXCv022wTSnLhzCmEjEv
 PmVo9KbIsv/Pt/rfN4YVYjx1t2w5aWWcpewAAAA==
X-Change-ID: 20261116-surface-battery-suspend-b5adbbfe80af
To: Maximilian Luz <luzmaximilian@gmail.com>, 
 Sebastian Reichel <sre@kernel.org>
Cc: linux-pm@vger.kernel.org, platform-driver-x86@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Ricky Sorrell <rmsorrell@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794887378; l=3169;
 i=rmsorrell@gmail.com; s=20261117; h=from:subject:message-id;
 bh=Nm4oDrkT9c+zgZKLqwTPIM9uMxM/qKmEf83Eim2ZI+A=;
 b=Y/O3bQAP6wvKxqeZvxMj+O34ZAGKVr0Z9f4ZHmbJSD4q8f09awao2RXW0CsywUS10qWtfOPRh
 JXPLjkuhkpuA/ySi39H12X22FcsudwpHfdfxAS2dK2BdKJ3Ghv2iU29
X-Developer-Key: i=rmsorrell@gmail.com; a=ed25519;
 pk=iB5I4ZV9deYinB0dHWz2x12lFRsMIymvzUMBcvlbAKs=
X-Endpoint-Received: by B4 Relay for rmsorrell@gmail.com/20261117 with auth_id=1546
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the AC adapter is plugged in or removed, spwr_external_power_changed()
schedules a battery state update after five seconds, on system_wq. That
workqueue is not frozen for system suspend. If the system starts to
suspend within those five seconds, for example when the charger is
unplugged and the lid closed straight away, the work runs after the
Surface Aggregator controller has been suspended. The request then trips
the WARN_ON() in ssam_request_do_sync_with_buffer() and fails:

  WARNING: drivers/platform/surface/aggregator/controller.c:1703 at ssam_request_do_sync_with_buffer+0x15a/0x180 [surface_aggregator]
  Workqueue: events spwr_battery_update_bst_workfn [surface_battery]
  surface_battery 01:02:02:01:00: failed to update battery state: -19

Queue the work on system_freezable_wq instead. Freezable workqueues are
frozen before devices are suspended and thawed after they have resumed,
so a pending update now runs only once the controller is reachable again.
Nothing is lost by the delay: surface_battery_resume() already rechecks
the full battery state.

The problem was found, and this change written and tested, with the help
of an AI coding assistant (Claude Opus 5.5 in Claude Code). It was found
by reading the kernel log after suspend tests on a Surface Book 3, then
confirmed in the source. Reproduced and tested on a Surface Book 3 with
Linux 7.3.4: unplug the charger and close the lid within five seconds.
Before the change the warning above appeared; after it, the same test
gave no warning and correct battery state after resume.

Fixes: 167f77f7d0b3 ("power: supply: Add battery driver for Surface Aggregator Module")
Signed-off-by: Ricky Sorrell <rmsorrell@gmail.com>
---
Not done, so reviewers know: the change was built and tested against
Linux 7.3.4 only. Mainline's surface_battery.c differs from 7.3.4 only in
an unrelated devm_kzalloc_obj() line, and the patch applies to mainline,
but it was not built or run there.
---
 drivers/power/supply/surface_battery.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/power/supply/surface_battery.c b/drivers/power/supply/surface_battery.c
index dac19932c..a9b0cdfe3 100644
--- a/drivers/power/supply/surface_battery.c
+++ b/drivers/power/supply/surface_battery.c
@@ -417,9 +417,14 @@ static void spwr_external_power_changed(struct power_supply *psy)
 	 * event for the state (charging/discharging) change. Furthermore it
 	 * may take some time until the state is updated on the battery.
 	 * Schedule an update to solve this.
+	 *
+	 * Use the freezable workqueue so that the update does not run while
+	 * the system is suspending, when the EC can no longer be reached.
+	 * surface_battery_resume() rechecks the full state anyway.
 	 */
 
-	schedule_delayed_work(&bat->update_work, SPWR_AC_BAT_UPDATE_DELAY);
+	queue_delayed_work(system_freezable_wq, &bat->update_work,
+			   SPWR_AC_BAT_UPDATE_DELAY);
 }
 
 

---
base-commit: 666539eecdf4db623f5e3c3e55cf9f2dfad24aa4
change-id: 20261116-surface-battery-suspend-b5adbbfe80af

Best regards,
--  
Ricky Sorrell <rmsorrell@gmail.com>

