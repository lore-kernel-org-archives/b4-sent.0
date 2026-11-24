From: Andreas Claesson <andreas@aclaesson.com>
Date: Tue, 24 Nov 2026 10:35:31 +0000
Subject: [PATCH] Revert "HID: corsair: cancel LED work again after
 unregistering the LED"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-hid-corsair-revert-redundant-cancel-v1-1-ba4c1418cfa8@aclaesson.com>
X-B4-Tracking: v=1; b=H4sIAHJoBWsC/yWNQQrCMBBFr1Jm7YBJSi1eRVwkk9GOSCqTtAild
 3fU1ect/nsbVFbhCuduA+VVqszFwB06oCmWO6NkY/BHPzjne5wkI81aoyjagbXZ5KXkWBpSLMR
 PHMMpJDcm7sMAZnop3+T9q1yuf65LejC1rxr2/QMSB1rVhwAAAA==
X-Change-ID: 20261124-hid-corsair-revert-redundant-cancel-8373b18be436
To: Benjamin Tissoires <bentiss@kernel.org>, Jiri Kosina <jikos@kernel.org>
Cc: linux-kernel@vger.kernel.org, 
 Danish Khateeb <danishkhateeb03@gmail.com>, linux-input@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795516530; l=2023;
 i=andreas@aclaesson.com; s=20261109; h=from:subject:message-id;
 bh=BJPb3ySj05euN2/xgTFuifJLkqlbmlH2K5dSAKbRMZA=;
 b=YGPG6bKX40TrHCZ1fi7j4asb2LuIQjbsfjOo8WdQ3Ipc4DIIoKkgYKec26pxdpfMFGf+rzD73
 Diy+ytSxsU9DSMCLHj4sUJDQ6gBa4FEmHft2W7p8uv0mU/YrGP2WfS+
X-Developer-Key: i=andreas@aclaesson.com; a=ed25519;
 pk=oC+38UX0rqcrEjNMgnKAF1zmrTUMbQ2aH/P5Z4TZOIQ=
X-Endpoint-Received: by B4 Relay for andreas@aclaesson.com/20261109 with auth_id=1465
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This reverts commit e624a56578e551b77ee66eef74dc2efcd42deb08.

It added a cancel_work_sync() after led_classdev_unregister()
in k90_cleanup_backlight() and k90_cleanup_macro_functions(), because
unregistering the LED turns it off and that used to queue the work
again.

Commit cc8d022e8679 ("HID: corsair: use disable_work_sync() to tear down
the LED workers") was applied to the same branch and fixes the same
problem differently: the work is disabled before the LED is
unregistered, so the LED-off request can no longer queue it. The added
cancel_work_sync() calls therefore do nothing, and the comment above
them is no longer true.

No functional change.

Assisted-by: Claude:claude-mythos-5-2
Signed-off-by: Andreas Claesson <andreas@aclaesson.com>
---
 drivers/hid/hid-corsair.c | 4 ----
 1 file changed, 4 deletions(-)

diff --git a/drivers/hid/hid-corsair.c b/drivers/hid/hid-corsair.c
index a9f2a0447f2d..f966005d69dd 100644
--- a/drivers/hid/hid-corsair.c
+++ b/drivers/hid/hid-corsair.c
@@ -526,8 +526,6 @@ static void k90_cleanup_backlight(struct hid_device *dev)
 		drvdata->backlight->removed = true;
 		disable_work_sync(&drvdata->backlight->work);
 		led_classdev_unregister(&drvdata->backlight->cdev);
-		/* unregister turns the LED off, which re-queues the work */
-		cancel_work_sync(&drvdata->backlight->work);
 		kfree(drvdata->backlight->cdev.name);
 		kfree(drvdata->backlight);
 	}
@@ -544,8 +542,6 @@ static void k90_cleanup_macro_functions(struct hid_device *dev)
 		k90->record_led.removed = true;
 		disable_work_sync(&k90->record_led.work);
 		led_classdev_unregister(&k90->record_led.cdev);
-		/* unregister turns the LED off, which re-queues the work */
-		cancel_work_sync(&k90->record_led.work);
 		kfree(k90->record_led.cdev.name);
 
 		kfree(k90);

---
base-commit: 10bc1d627c297097cfdc099377f8a13efdfffd86
change-id: 20261124-hid-corsair-revert-redundant-cancel-8373b18be436

Best regards,
--  
Andreas Claesson <andreas@aclaesson.com>

