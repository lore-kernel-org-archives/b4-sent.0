From: Rongen Wang <security@nitrohex.com>
Date: Thu, 26 Nov 2026 18:18:33 +0900
Subject: [PATCH v2] ALSA: timer: Protect the slave instance flags with the
 timer lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-alsa-timer-slave-flags-v2-1-8e07a536fea3@nitrohex.com>
X-B4-Tracking: v=1; b=H4sIAGj5B2sC/yXMQQ6CMBBG4auQWTsJbRTUqxgXY/kLYyqaDhITw
 t0tuvwW7y1kyAqjc7VQxqymz7HA7yoKg4w9WLti8rVvnPMNSzLhSR/IbElmcEzSGyMc29MhxNr
 thUr8yoj6+Y0v17/tfbsjTNuN1vULH/pCKHoAAAA=
X-Change-ID: 20261126-alsa-timer-slave-flags-ec8795cf014a
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Rongen Wang <security@nitrohex.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795684819; l=6877;
 i=security@nitrohex.com; s=nitrohex; h=from:subject:message-id;
 bh=yPrdezwwo28a566FRr26Hq6P3SlpjEX7jPV2dsOauKM=;
 b=iak98uCKAJp1x/gG1Q/6LT0ZmT/atU7v6w5UlszLA7fFfM4FRQ+rn8BG2/qyPWwfvSOpOYYBb
 R//hX3dZLRIAHEqm6pUDjMSURl7TLwTpdn+B42l8iHTc4VholkmtpTv
X-Developer-Key: i=security@nitrohex.com; a=ed25519;
 pk=Jk5NuTVJdxr1CTP4RuYaG31zSgsNlyFzVo9sphZTqt0=
X-Endpoint-Received: by B4 Relay for security@nitrohex.com/nitrohex with auth_id=1652
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

snd_timer_start_slave() and snd_timer_stop_slave() set and clear
SNDRV_TIMER_IFLG_RUNNING in timeri->flags while holding only
timeri_lock.  For a slave that is linked to a master, the interrupt
path updates the same word under timer->lock:
snd_timer_process_callbacks() sets SNDRV_TIMER_IFLG_CALLBACK before it
calls the instance callback and clears it afterwards.  Both sides do a
plain read-modify-write, so when they overlap one of the two updates is
lost.

If the set of SNDRV_TIMER_IFLG_CALLBACK is lost,
snd_timer_close_locked() does not wait for the callback that is still
running, the owner frees the instance, and the interrupt path clears
the flag in the freed object:

  BUG: KASAN: slab-use-after-free in snd_timer_process_callbacks+0x269/0x2b0
  Read of size 4 at addr ffff888007e5cc10 by task poc/90
   snd_timer_process_callbacks+0x269/0x2b0
   snd_timer_interrupt+0x7b8/0x1100
   snd_utimer_ioctl+0x7c/0xb0
  Freed by task 91:
   kfree+0x127/0x3b0
   __snd_timer_user_ioctl.isra.0+0xe93/0x28f0

If the clear is lost instead, the flag stays set: the instance gets no
further callbacks, and closing it spins in the drain loop of
snd_timer_close_locked() with register_mutex held, which blocks every
other open and close of an ALSA timer.

Take timer->lock around the whole flag update of a linked slave, as
snd_timer_start1() and snd_timer_stop1() do for master instances.  The
callers hold timeri_lock, so timeri->timer is stable, and the lock
order is the one these functions already use.  A slave that is not
linked to a master cannot be reached from any timer and needs no
additional protection.

Fixes: 1da177e4c3f4 ("Linux-2.6.12-rc2")
Cc: stable@vger.kernel.org
Signed-off-by: Rongen Wang <security@nitrohex.com>
---
Changes in v2:
- Resend only, no code change. v1 was damaged by my mail setup (a line
  break was inserted every 1000 bytes) and did not apply. This version
  goes out through the kernel.org web submission endpoint, and the
  generated mail was checked with git am before sending.
- v1: https://lore.kernel.org/r/20261125192053.5664-1-security@nitrohex.com

The bug was found and this patch drafted with the help of an AI tool;
I reviewed the patch and ran the tests below. The report went privately
to the maintainers and security@kernel.org.

Tested on v7.4-rc3 with KASAN under QEMU TCG (4 vCPUs). Without the
patch the reproducer hits the use-after-free within seconds and the
close hang within a minute. With it, 778621 rounds (userspace-driven
timer) and 1310178 rounds (hrtimer) gave no report and no hang. A
master/slave start, stop, pause, continue and relink test passes with
and without the patch. checkpatch --strict clean, no new W=1 warnings
in sound/core/.

Not covered: snd_timer_user_params() changes the instance flags under
the lock of a timer it looked up earlier, so a slave relinked to
another master in between would be updated under the wrong lock.
Much narrower; not reproduced.

Trees before 100407f548ca ("ALSA: timer: Fix racy timeri->timer
changes with rwlock") need a backport on top of slave_active_lock; one
for 6.18.y and 6.12.y applies cleanly but has not been built or tested.
---
 sound/core/timer.c | 50 +++++++++++++++++++++++++++++++++++++++++++-------
 1 file changed, 43 insertions(+), 7 deletions(-)

diff --git a/sound/core/timer.c b/sound/core/timer.c
index 905176bf694..50e31827d9f 100644
--- a/sound/core/timer.c
+++ b/sound/core/timer.c
@@ -657,9 +657,12 @@ static int snd_timer_start1(struct snd_timer_instance *timeri,
 	return result;
 }
 
-/* start/continue a slave timer */
-static int snd_timer_start_slave(struct snd_timer_instance *timeri,
-				 bool start)
+/*
+ * start/continue a slave timer;
+ * called with timer->lock held when the slave is linked to a master
+ */
+static int __snd_timer_start_slave(struct snd_timer_instance *timeri,
+				   bool start)
 {
 	if (timeri->flags & SNDRV_TIMER_IFLG_DEAD)
 		return -EINVAL;
@@ -667,7 +670,6 @@ static int snd_timer_start_slave(struct snd_timer_instance *timeri,
 		return -EBUSY;
 	timeri->flags |= SNDRV_TIMER_IFLG_RUNNING;
 	if (timeri->master && timeri->timer) {
-		guard(spinlock)(&timeri->timer->lock);
 		list_add_tail(&timeri->active_list,
 			      &timeri->master->slave_active_head);
 		snd_timer_notify1(timeri, start ? SNDRV_TIMER_EVENT_START :
@@ -676,6 +678,27 @@ static int snd_timer_start_slave(struct snd_timer_instance *timeri,
 	return 1; /* delayed start */
 }
 
+/*
+ * start/continue a slave timer
+ *
+ * The flags of a slave linked to a master are updated also from the timer
+ * interrupt (SNDRV_TIMER_IFLG_CALLBACK in snd_timer_process_callbacks())
+ * under timer->lock.  Change them only under the same lock, otherwise one
+ * of the two read-modify-write updates may get lost.  The caller holds
+ * timeri_lock, hence timeri->timer can't change here; an unlinked slave is
+ * not reachable from any timer and needs no further protection.
+ */
+static int snd_timer_start_slave(struct snd_timer_instance *timeri,
+				 bool start)
+{
+	struct snd_timer *timer = timeri->timer;
+
+	if (!timer)
+		return __snd_timer_start_slave(timeri, start);
+	guard(spinlock)(&timer->lock);
+	return __snd_timer_start_slave(timeri, start);
+}
+
 /* stop/pause a master timer */
 static int snd_timer_stop1(struct snd_timer_instance *timeri, bool stop)
 {
@@ -718,15 +741,17 @@ static int snd_timer_stop1(struct snd_timer_instance *timeri, bool stop)
 	return 0;
 }
 
-/* stop/pause a slave timer */
-static int snd_timer_stop_slave(struct snd_timer_instance *timeri, bool stop)
+/*
+ * stop/pause a slave timer;
+ * called with timer->lock held when the slave is linked to a master
+ */
+static int __snd_timer_stop_slave(struct snd_timer_instance *timeri, bool stop)
 {
 	bool running;
 
 	running = timeri->flags & SNDRV_TIMER_IFLG_RUNNING;
 	timeri->flags &= ~SNDRV_TIMER_IFLG_RUNNING;
 	if (timeri->timer) {
-		guard(spinlock)(&timeri->timer->lock);
 		list_del_init(&timeri->ack_list);
 		list_del_init(&timeri->active_list);
 		if (running)
@@ -736,6 +761,17 @@ static int snd_timer_stop_slave(struct snd_timer_instance *timeri, bool stop)
 	return running ? 0 : -EBUSY;
 }
 
+/* stop/pause a slave timer; see snd_timer_start_slave() for the locking */
+static int snd_timer_stop_slave(struct snd_timer_instance *timeri, bool stop)
+{
+	struct snd_timer *timer = timeri->timer;
+
+	if (!timer)
+		return __snd_timer_stop_slave(timeri, stop);
+	guard(spinlock)(&timer->lock);
+	return __snd_timer_stop_slave(timeri, stop);
+}
+
 /*
  *  start the timer instance
  */

---
base-commit: aebb7274476403040d582c61478df8f4a7bf9cd3
change-id: 20261126-alsa-timer-slave-flags-ec8795cf014a

Best regards,
--  
Rongen Wang <security@nitrohex.com>

