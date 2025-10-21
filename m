From: Joel Selvaraj <foss@joelselvaraj.com>
Date: Tue, 21 Oct 2025 13:53:06 -0500
Subject: [PATCH v2] backlight: qcom-wled: fix unbalanced ovp irq enable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251021-qcom-wled-fix-unbalanced-ovp-irq-enable-v2-1-7ff115b4ffe7@joelselvaraj.com>
X-B4-Tracking: v=1; b=H4sIAJHW92gC/5WNQQ7CIBBFr9KwdgxgIdGV9zBdDGW0NAgtKGqa3
 l3sDVy+n/z3FpYpOcrs1CwsUXHZxVBB7hrWDxhuBM5WZpJLJbgUMPfxDi9PFq7uDc9g0GPoK8Y
 ygUszUEDjCVTbaiO4RnvUrNqmRPWwlS5d5cHlR0yfLVzEb/2/UQQIIGsPvLVCK1TnMZLP5AsmH
 PfVwrp1Xb+2OdUg5QAAAA==
X-Change-ID: 20251021-qcom-wled-fix-unbalanced-ovp-irq-enable-5446b106ad96
To: Lee Jones <lee@kernel.org>, Daniel Thompson <danielt@kernel.org>, 
 Jingoo Han <jingoohan1@gmail.com>, Helge Deller <deller@gmx.de>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 linux-fbdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joel Selvaraj <foss@joelselvaraj.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761072806; l=4368;
 i=foss@joelselvaraj.com; s=20250919; h=from:subject:message-id;
 bh=+zxsXoGdLJQYgRVd89LWEBBj6NGtlp3Yp8wwgEWlx8w=;
 b=5LCIDELJydjgakfLZUSdmtVysbCZBFc51OM6rE+/GwWadfxB/8xX6wtr4L6MMAreYmFRTKba8
 p0+GvI2mgiIBg6NHMuFOHjhwfHWdPlAXUjEJPXkualGFTiWWFQXE7gA
X-Developer-Key: i=foss@joelselvaraj.com; a=ed25519;
 pk=BBMos4ph15apUFh2AkG9rLZIrBWl5LD4egPOhEv63X0=
X-Endpoint-Received: by B4 Relay for foss@joelselvaraj.com/20250919 with auth_id=529
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In Xiaomi Poco F1 and at least few other devices, the qcom wled driver
triggers unbalanced ovp irq enable warning like the following during
boot up.

[    1.151677] ------------[ cut here ]------------
[    1.151680] Unbalanced enable for IRQ 176
[    1.151693] WARNING: CPU: 0 PID: 160 at kernel/irq/manage.c:774 __enable_irq+0x50/0x80
[    1.151710] Modules linked in:
[    1.151717] CPU: 0 PID: 160 Comm: kworker/0:11 Not tainted 5.17.0-sdm845 #4
[    1.151724] Hardware name: Xiaomi Pocophone F1 (DT)
[    1.151728] Workqueue: events wled_ovp_work
...<snip>...
[    1.151833] Call trace:
[    1.151836]  __enable_irq+0x50/0x80
[    1.151841]  enable_irq+0x48/0xa0
[    1.151846]  wled_ovp_work+0x18/0x24
[    1.151850]  process_one_work+0x1d0/0x350
[    1.151858]  worker_thread+0x13c/0x460
[    1.151862]  kthread+0x110/0x114
[    1.151868]  ret_from_fork+0x10/0x20
[    1.151876] ---[ end trace 0000000000000000 ]---

Fix it by storing and checking the state of ovp irq before enabling and
disabling it.

Signed-off-by: Joel Selvaraj <foss@joelselvaraj.com>
---
I was able to debug the issue a little further. This happens mainly because
devm_request_threaded_irq already enables the ovp irq during probe. Then ovp
work gets scheduled when update_status happens and in turn enables the irq again.
Tracking the status makes it easy to avoid the double irq enable. But I am
open to try a different approach if there is any suggestion.
---
Changes in v2:
- Track ovp irq status using ovp_irq_enabled flag instead of ovp_irq_disabled. (Konrad Dybcio)
- Use short wrapper functions for ovp irq enable and disable. (Konrad Dybcio)
- Link to v1: https://lore.kernel.org/r/20251021-qcom-wled-fix-unbalanced-ovp-irq-enable-v1-1-edd304d165a5@joelselvaraj.com
---
 drivers/video/backlight/qcom-wled.c | 27 +++++++++++++++++++++++----
 1 file changed, 23 insertions(+), 4 deletions(-)

diff --git a/drivers/video/backlight/qcom-wled.c b/drivers/video/backlight/qcom-wled.c
index a63bb42c8f8b0333cd6d0ddc5bda93916da3fef3..3f49e4b3cdeb12541c057e56bac871a8ff680283 100644
--- a/drivers/video/backlight/qcom-wled.c
+++ b/drivers/video/backlight/qcom-wled.c
@@ -197,6 +197,7 @@ struct wled {
 	bool disabled_by_short;
 	bool has_short_detect;
 	bool cabc_disabled;
+	bool ovp_irq_enabled;
 	int short_irq;
 	int ovp_irq;
 
@@ -290,11 +291,27 @@ static int wled5_set_brightness(struct wled *wled, u16 brightness)
 	return rc;
 }
 
+static void wled_enable_ovp_irq(struct wled *wled)
+{
+	if (!wled->ovp_irq_enabled) {
+		enable_irq(wled->ovp_irq);
+		wled->ovp_irq_enabled = true;
+	}
+}
+
+static void wled_disable_ovp_irq(struct wled *wled)
+{
+	if (wled->ovp_irq_enabled) {
+		disable_irq(wled->ovp_irq);
+		wled->ovp_irq_enabled = false;
+	}
+}
+
 static void wled_ovp_work(struct work_struct *work)
 {
 	struct wled *wled = container_of(work,
 					 struct wled, ovp_work.work);
-	enable_irq(wled->ovp_irq);
+	wled_enable_ovp_irq(wled);
 }
 
 static int wled_module_enable(struct wled *wled, int val)
@@ -322,7 +339,7 @@ static int wled_module_enable(struct wled *wled, int val)
 			schedule_delayed_work(&wled->ovp_work, HZ / 100);
 		} else {
 			if (!cancel_delayed_work_sync(&wled->ovp_work))
-				disable_irq(wled->ovp_irq);
+				wled_disable_ovp_irq(wled);
 		}
 	}
 
@@ -1607,6 +1624,8 @@ static int wled_configure_ovp_irq(struct wled *wled,
 		return 0;
 	}
 
+	wled->ovp_irq_enabled = true;
+
 	rc = regmap_read(wled->regmap, wled->ctrl_addr +
 			 WLED3_CTRL_REG_MOD_EN, &val);
 	if (rc < 0)
@@ -1614,7 +1633,7 @@ static int wled_configure_ovp_irq(struct wled *wled,
 
 	/* Keep OVP irq disabled until module is enabled */
 	if (!(val & WLED3_CTRL_REG_MOD_EN_MASK))
-		disable_irq(wled->ovp_irq);
+		wled_disable_ovp_irq(wled);
 
 	return 0;
 }
@@ -1726,7 +1745,7 @@ static void wled_remove(struct platform_device *pdev)
 	mutex_destroy(&wled->lock);
 	cancel_delayed_work_sync(&wled->ovp_work);
 	disable_irq(wled->short_irq);
-	disable_irq(wled->ovp_irq);
+	wled_disable_ovp_irq(wled);
 }
 
 static const struct of_device_id wled_match_table[] = {

---
base-commit: fe45352cd106ae41b5ad3f0066c2e54dbb2dfd70
change-id: 20251021-qcom-wled-fix-unbalanced-ovp-irq-enable-5446b106ad96

Best regards,
-- 
Joel Selvaraj <foss@joelselvaraj.com>

