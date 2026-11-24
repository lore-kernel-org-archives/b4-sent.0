From: Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
Date: Tue, 24 Nov 2026 03:21:26 +0200
Subject: [PATCH v3] EDAC/mc: Convert the poll period to jiffies when it is
 changed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-edac-mc-poll-msec-jiffies-v3-1-a377fda35aed@ahmedabdelfattah.dev>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/43NzQ6CMBAE4FchPbuGLoLWk+9hPJR2V0r4MS02G
 sO7W/TiReNxkplvHiKQdxTEPnsIT9EFNw4pFKtMmEYPZwJnUxaYYyWlVEBWG+gNXMaugz6QgdY
 xJwK43rLCiqVEI9L+4ond7WUfT+8crnVLZlrApdG4MI3+/jqPcun98xMlSGAqUKlixzpXB930q
 V5b6lhPk27WlqJYLiN+oFj8QjGh+SbfGlNiWVb2CzrP8xPdgyVnNAEAAA==
X-Change-ID: 20261119-edac-mc-poll-msec-jiffies-fb7f926f112c
To: Borislav Petkov <bp@alien8.de>, Tony Luck <tony.luck@intel.com>
Cc: Qiuxu Zhuo <qzhuo@nvidia.com>, linux-edac@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795483290; l=5834;
 i=me@ahmedabdelfattah.dev; s=20261106; h=from:subject:message-id;
 bh=jADiePoQwyKWlx1hQxkiCPwJnWF2b74pDalVFuubc6A=;
 b=htkZo4cGp+F7yGqN7zcLryOPbYzkS2swJeQ6vfLfbw8eiEE749i5oOFyGaUw710BqC9tC/qGr
 zo16EuLMSWYBJSYz8tj24bq+yLDTh1KPZDeqNHKMfiyDybSxoSHzA+b
X-Developer-Key: i=me@ahmedabdelfattah.dev; a=ed25519;
 pk=DHEHKU4PddrkJ/iYMZpwyyXsFyIQ6ySjTttKLrt9YqI=
X-Endpoint-Received: by B4 Relay for me@ahmedabdelfattah.dev/20261106 with auth_id=1438
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Writing edac_mc_poll_msec at run time re-arms every polled memory
controller through edac_mc_reset_delay_period(), which passes the new
value to edac_mod_work() as it is. mod_delayed_work() takes jiffies, so
the first poll after the write comes that many jiffies later, not that
many milliseconds: at HZ=300, writing 2000 puts the next poll 6.7 s
out. edac_mc_workq_function() re-arms with msecs_to_jiffies(), so only
that first poll is off.

Before commit c4cf3b454eca ("EDAC: Rework workqueue handling") this
path converted the value through edac_mc_workq_setup(), and
edac_device_reset_delay_period() still does. Convert it here as well.

All other callers of edac_mod_work() and edac_queue_work() already pass
jiffies. Name the arguments after the unit they are in: "jiffies" for
the two workqueue helpers, and "msec" for edac_mc_reset_delay_period(),
as edac_device_reset_delay_period() has it.

Fixes: c4cf3b454eca ("EDAC: Rework workqueue handling")
Signed-off-by: Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
---
I noticed this while timing ie31200_edac's polls in a KVM guest: the
first poll after a write to edac_mc_poll_msec came late.

Tested on v7.4-rc3+ (4405c18c95d2) at HZ=300, with ie31200_edac bound
to a QEMU model of the Kaby Lake host bridge (a local device model, not
upstream QEMU), timing edac_mc_workq_function() with a kprobe. Without
the patch the first poll came 6.76 s after writing 2000 and 3.51 s after
writing 1000, with the polls after it every 2.13 s and 1.01 s. With the
patch the first poll comes 2.11 s and 1.02 s after the write, in line
with the ones after it. Writes below 1000 are still rejected.
---
Changes in v3:
- Dropped Qiuxu's Reviewed-by: he gave it for the one-line conversion
  in v1, and v2 added the argument renames on top of that (Borislav).
- No code changes.
- Link to v2: https://patch.msgid.link/20261123-edac-mc-poll-msec-jiffies-v2-1-0407cc52556d@ahmedabdelfattah.dev

Changes in v2:
- Went through the callers of edac_mod_work() and edac_queue_work(). The
  others already pass jiffies: edac_device keeps msecs_to_jiffies(msec)
  in edac_dev->delay, edac_pci and the other edac_mc callers convert at
  the call. So the fix is the same as in v1.
- Renamed the "delay" argument of both helpers to "jiffies" (Borislav).
  The "value" in the v1 hunk is edac_mc_reset_delay_period()'s argument
  and is in milliseconds, so that one is now "msec". As an argument name
  "jiffies" shadows the global one, which only W=2 complains about; I
  can call it something else if you prefer.
- Added Qiuxu's Reviewed-by and retested.
- Link to v1: https://patch.msgid.link/20261119-edac-mc-poll-msec-jiffies-v1-1-fe329938fa09@ahmedabdelfattah.dev
---
 drivers/edac/edac_mc.c     | 6 +++---
 drivers/edac/edac_module.h | 6 +++---
 drivers/edac/wq.c          | 8 ++++----
 3 files changed, 10 insertions(+), 10 deletions(-)

diff --git a/drivers/edac/edac_mc.c b/drivers/edac/edac_mc.c
index fd70caa85574..6feb0809a959 100644
--- a/drivers/edac/edac_mc.c
+++ b/drivers/edac/edac_mc.c
@@ -483,12 +483,12 @@ static void edac_mc_workq_function(struct work_struct *work_req)
 }
 
 /*
- * edac_mc_reset_delay_period(unsigned long value)
+ * edac_mc_reset_delay_period(unsigned long msec)
  *
  *	user space has updated our poll period value, need to
  *	reset our workq delays
  */
-void edac_mc_reset_delay_period(unsigned long value)
+void edac_mc_reset_delay_period(unsigned long msec)
 {
 	struct mem_ctl_info *mci;
 	struct list_head *item;
@@ -499,7 +499,7 @@ void edac_mc_reset_delay_period(unsigned long value)
 		mci = list_entry(item, struct mem_ctl_info, link);
 
 		if (mci->op_state == OP_RUNNING_POLL)
-			edac_mod_work(&mci->work, value);
+			edac_mod_work(&mci->work, msecs_to_jiffies(msec));
 	}
 	mutex_unlock(&mem_ctls_mutex);
 }
diff --git a/drivers/edac/edac_module.h b/drivers/edac/edac_module.h
index eceef5539186..762a331a5708 100644
--- a/drivers/edac/edac_module.h
+++ b/drivers/edac/edac_module.h
@@ -48,12 +48,12 @@ extern void edac_device_remove_sysfs(struct edac_device_ctl_info *edac_dev);
 /* edac core workqueue: single CPU mode */
 int edac_workqueue_setup(void);
 void edac_workqueue_teardown(void);
-bool edac_queue_work(struct delayed_work *work, unsigned long delay);
+bool edac_queue_work(struct delayed_work *work, unsigned long jiffies);
 bool edac_stop_work(struct delayed_work *work);
-bool edac_mod_work(struct delayed_work *work, unsigned long delay);
+bool edac_mod_work(struct delayed_work *work, unsigned long jiffies);
 
 extern void edac_device_reset_delay_period(struct edac_device_ctl_info *edac_dev, unsigned int msec);
-extern void edac_mc_reset_delay_period(unsigned long value);
+extern void edac_mc_reset_delay_period(unsigned long msec);
 
 /*
  * EDAC debugfs functions
diff --git a/drivers/edac/wq.c b/drivers/edac/wq.c
index ad3f516627c5..edeb7bbd3d68 100644
--- a/drivers/edac/wq.c
+++ b/drivers/edac/wq.c
@@ -3,15 +3,15 @@
 
 static struct workqueue_struct *wq;
 
-bool edac_queue_work(struct delayed_work *work, unsigned long delay)
+bool edac_queue_work(struct delayed_work *work, unsigned long jiffies)
 {
-	return queue_delayed_work(wq, work, delay);
+	return queue_delayed_work(wq, work, jiffies);
 }
 EXPORT_SYMBOL_GPL(edac_queue_work);
 
-bool edac_mod_work(struct delayed_work *work, unsigned long delay)
+bool edac_mod_work(struct delayed_work *work, unsigned long jiffies)
 {
-	return mod_delayed_work(wq, work, delay);
+	return mod_delayed_work(wq, work, jiffies);
 }
 EXPORT_SYMBOL_GPL(edac_mod_work);
 

---
base-commit: 4405c18c95d2d0f99f6c581ef0ee8591a1aa6ccd
change-id: 20261119-edac-mc-poll-msec-jiffies-fb7f926f112c

Best regards,
--  
Ahmed Abdelfattah <me@ahmedabdelfattah.dev>

