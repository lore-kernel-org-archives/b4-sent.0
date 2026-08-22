From: FAN YE <fy15309206903@gmail.com>
Date: Sat, 22 Aug 2026 16:24:54 +0000
Subject: [PATCH] HSI: cmt_speech: fix lost wakeup in cs_char_read()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260822-cmt-speech-lost-wakeup-v1-1-27aac852bb1a@gmail.com>
X-B4-Tracking: v=1; b=H4sIAFXNiWoC/yXMUQ6CMBCE4auQfXaTpSaNchXjA9RRVhGabkETw
 t2t+vglM/9KhqQwaqqVEhY1ncaCeldR6NvxBtZLMTlxXg7OcXhmtgiEnofJMr/aB+bIe9RHkbL
 wXqicY8JV37/w6fy3zd0dIX9rtG0fXprfQHoAAAA=
X-Change-ID: 20260822-cmt-speech-lost-wakeup-3e1900082660
To: Sebastian Reichel <sre@kernel.org>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787415893; l=3480;
 i=fy15309206903@gmail.com; s=tbnet3; h=from:subject:message-id;
 bh=HHYSwbyjof/va1JoOEQpdo4eqsNpZlQbFHJKLO1qIgc=;
 b=TOE/D6VG8bVhPRaDMIwE796KYPhvnS8GTuJEIXvLM6Nu7LjZ2gqF0z7Ffd45FPfltQ1thx1BA
 sQxJCC5WYFTCItUn/VLyjhw0oAbm2VW2Fwm7XSNeYzkEH3m1EhZM8KZ
X-Developer-Key: i=fy15309206903@gmail.com; a=ed25519;
 pk=6QsQIrI/kruYWIJyCH9ntPMXsHCqF5JtK/DCMtOCzdc=
X-Endpoint-Received: by B4 Relay for fy15309206903@gmail.com/tbnet3 with auth_id=929
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A reader can sleep past an available message in cs_char_read(): the
queue check happens before prepare_to_wait_exclusive() queues the
task, and cs_notify() only wakes tasks already on csdata->wait, so a
message queued in between wakes nobody and the reader waits for
whichever message shows up next. cs_notify() runs from ssi_pio_thread(),
so it can land in that window on SMP, or on a preemptible kernel even
with a single CPU.

Re-check the queues after being queued and skip schedule() if one
already has an entry, mirroring what wait_event() does internally.

Fixes: 7f62fe8a5851 ("HSI: cmt_speech: Add cmt-speech driver")
Assisted-by: Claude:claude-sonnet-5
Signed-off-by: FAN YE <fy15309206903@gmail.com>
---
Reproduced under QEMU/TCG with a diagnostic build. This driver has no
hardware and there is no virtual HSI controller, so the harness hands
cs_hsi_client_probe() a fake hsi_client and calls cs_notify() from an RT
kthread woken while the reader still holds csdata->lock -- the shape of
ssi_pio_thread(), which is what runs msg->complete() on omap_ssi.
waitqueue_active() is read inside cs_notify() just before
wake_up_interruptible(). One CPU throughout:

  arm, CONFIG_PREEMPT
    unpatched  waitqueue empty at the wakeup; the reader then sleeps in
               cs_char_read() on the already queued message and wakes
               only when an unrelated one arrives -- 6.0 s here, which
               is simply when the test sends it
    patched    same lost wakeup, read() returns at once (0-1 ms)
  arm, CONFIG_PREEMPT_VOLUNTARY
    both       waitqueue not empty, so the race cannot form on one CPU:
               without CONFIG_PREEMPTION spin_unlock_bh() is not a
               preemption point and the kthread runs only once the
               reader is already queued; read() returns at once
  x86_64, preempt=full and preempt=lazy
    both       as arm CONFIG_PREEMPT

Rebuilt and re-run from scratch on a second machine, same results.
Built W=1 for arm/omap2plus and x86_64; checkpatch --strict clean.
---
 drivers/hsi/clients/cmt_speech.c | 14 +++++++++++++-
 1 file changed, 13 insertions(+), 1 deletion(-)

diff --git a/drivers/hsi/clients/cmt_speech.c b/drivers/hsi/clients/cmt_speech.c
index 7226677ebde7..5be4a4477c44 100644
--- a/drivers/hsi/clients/cmt_speech.c
+++ b/drivers/hsi/clients/cmt_speech.c
@@ -1132,6 +1132,7 @@ static ssize_t cs_char_read(struct file *file, char __user *buf, size_t count,
 	struct cs_char *csdata = file->private_data;
 	u32 data;
 	ssize_t retval;
+	bool empty;
 
 	if (count < sizeof(data))
 		return -EINVAL;
@@ -1161,7 +1162,18 @@ static ssize_t cs_char_read(struct file *file, char __user *buf, size_t count,
 		}
 		prepare_to_wait_exclusive(&csdata->wait, &wait,
 						TASK_INTERRUPTIBLE);
-		schedule();
+		/*
+		 * Re-check after being queued: cs_notify() may have queued
+		 * an entry and woken csdata->wait in the window between the
+		 * empty check above and prepare_to_wait_exclusive() adding
+		 * us to it.
+		 */
+		spin_lock_bh(&csdata->lock);
+		empty = list_empty(&csdata->chardev_queue) &&
+			list_empty(&csdata->dataind_queue);
+		spin_unlock_bh(&csdata->lock);
+		if (empty)
+			schedule();
 		finish_wait(&csdata->wait, &wait);
 	}
 

---
base-commit: 26260251022fbc2f248a3d747a9b2b961b18d2d8
change-id: 20260822-cmt-speech-lost-wakeup-3e1900082660

Best regards,
--  
FAN YE <fy15309206903@gmail.com>

