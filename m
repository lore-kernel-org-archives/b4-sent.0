From: Joel Selvaraj <foss@joelselvaraj.com>
Date: Tue, 21 Oct 2025 02:33:23 -0500
Subject: [PATCH] backlight: qcom-wled: fix unbalanced ovp irq enable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251021-qcom-wled-fix-unbalanced-ovp-irq-enable-v1-1-edd304d165a5@joelselvaraj.com>
X-B4-Tracking: v=1; b=H4sIAEI392gC/x3NQQrCMBCF4auUWTuQhDagVxEXk2TUgZi0CdZC6
 d07uPwW/3s7dG7CHW7DDo1X6VKLwl4GiG8qL0ZJanDGTdY4i0usH/xlTviUDb8lUKYSlXWdUdq
 CXChkxmkcfbDGU7p60LW5sQb/p/vjOE5zlSnweQAAAA==
X-Change-ID: 20251021-qcom-wled-fix-unbalanced-ovp-irq-enable-5446b106ad96
To: Lee Jones <lee@kernel.org>, Daniel Thompson <danielt@kernel.org>, 
 Jingoo Han <jingoohan1@gmail.com>, Helge Deller <deller@gmx.de>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 linux-fbdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joel Selvaraj <foss@joelselvaraj.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761032009; l=3415;
 i=foss@joelselvaraj.com; s=20250919; h=from:subject:message-id;
 bh=TgO0CVPZO00Cf30CCD6Yj7u97D72h24ioMyPxeIISiA=;
 b=yX/Y7aeTGZuyQpEDbLe8dX/oAgeOGDp2FkygKfpZZ62PMf7+MuuNncznQinNhRQ3og0ZjqdTy
 1Xe2rZJ1399BBHxdszQPKd4v164bVEHrCwKZc2Qtw8ur1ehxF1x82SE
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
I am not entirely sure if this is the ideal fix. But this patch provides
an okayish stopgap solution till we can properly fix it. I am open to 
try a different approach if there is any suggestion.
---
 drivers/video/backlight/qcom-wled.c | 15 ++++++++++++---
 1 file changed, 12 insertions(+), 3 deletions(-)

diff --git a/drivers/video/backlight/qcom-wled.c b/drivers/video/backlight/qcom-wled.c
index a63bb42c8f8b0333cd6d0ddc5bda93916da3fef3..36e2fe5c5fa37cfb8750254a75eff612741983c8 100644
--- a/drivers/video/backlight/qcom-wled.c
+++ b/drivers/video/backlight/qcom-wled.c
@@ -197,6 +197,7 @@ struct wled {
 	bool disabled_by_short;
 	bool has_short_detect;
 	bool cabc_disabled;
+	bool ovp_irq_disabled;
 	int short_irq;
 	int ovp_irq;
 
@@ -294,7 +295,10 @@ static void wled_ovp_work(struct work_struct *work)
 {
 	struct wled *wled = container_of(work,
 					 struct wled, ovp_work.work);
-	enable_irq(wled->ovp_irq);
+	if (wled->ovp_irq_disabled) {
+		enable_irq(wled->ovp_irq);
+		wled->ovp_irq_disabled = false;
+	}
 }
 
 static int wled_module_enable(struct wled *wled, int val)
@@ -321,8 +325,10 @@ static int wled_module_enable(struct wled *wled, int val)
 			 */
 			schedule_delayed_work(&wled->ovp_work, HZ / 100);
 		} else {
-			if (!cancel_delayed_work_sync(&wled->ovp_work))
+			if (!cancel_delayed_work_sync(&wled->ovp_work) && !wled->ovp_irq_disabled) {
 				disable_irq(wled->ovp_irq);
+				wled->ovp_irq_disabled = true;
+			}
 		}
 	}
 
@@ -1613,8 +1619,10 @@ static int wled_configure_ovp_irq(struct wled *wled,
 		return rc;
 
 	/* Keep OVP irq disabled until module is enabled */
-	if (!(val & WLED3_CTRL_REG_MOD_EN_MASK))
+	if (!(val & WLED3_CTRL_REG_MOD_EN_MASK)) {
 		disable_irq(wled->ovp_irq);
+		wled->ovp_irq_disabled = true;
+	}
 
 	return 0;
 }
@@ -1727,6 +1735,7 @@ static void wled_remove(struct platform_device *pdev)
 	cancel_delayed_work_sync(&wled->ovp_work);
 	disable_irq(wled->short_irq);
 	disable_irq(wled->ovp_irq);
+	wled->ovp_irq_disabled = true;
 }
 
 static const struct of_device_id wled_match_table[] = {

---
base-commit: fe45352cd106ae41b5ad3f0066c2e54dbb2dfd70
change-id: 20251021-qcom-wled-fix-unbalanced-ovp-irq-enable-5446b106ad96

Best regards,
-- 
Joel Selvaraj <foss@joelselvaraj.com>

