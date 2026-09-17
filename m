From: 0xSmash0th <0xSmash0th@gmail.com>
Date: Thu, 17 Sep 2026 17:20:24 -0400
Subject: [PATCH] firmware: tegra: ivc: back off when a peer stalls the
 handshake
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260917-ivc-resync-backoff-v1-1-dd41ef3a1390@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqAIBBA0avErBuwIM2uEi10GmsILBSiiO6et
 HyL/x/InIQzDNUDiU/JsseCpq6AVhcXRpmLoVWtVrYxKCdh4nxHQu9o20NAb3TfacteEUEJj8R
 Brn86Tu/7AazuO8VkAAAA
X-Change-ID: 20260917-ivc-resync-backoff-b768569eb0cc
To: Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 0xSmash0th <0xSmash0th@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789680034; l=13677;
 i=0xSmash0th@gmail.com; s=20260917; h=from:subject:message-id;
 bh=xI23HGnd1O7JPgGTS/M47lGy5+o/8IZV4S5U1Ah6NHw=;
 b=GM9OUxc05mtbQd3pbhl3RcsXMbSB7uqdjcegbRRk+L+IrGaBBaCj7H1rcOuczia/9STMK+0RK
 NxOYCWLMOcDAYEhkzzRwlqmVoxEM9vpJVxxtx5e6NAJAJNNsKRh/JiQ
X-Developer-Key: i=0xSmash0th@gmail.com; a=ed25519;
 pk=zVeoR0UBzAAUPJSb7skqhhRlouyNu+2xwsW4ThiH5YU=
X-Endpoint-Received: by B4 Relay for 0xSmash0th@gmail.com/20260917 with auth_id=1034
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

An untrusted peer can wedge a channel for ever: park its state word on
SYNC and stop touching the ring.  No path in tegra_ivc_notified() can
change the victim's rx word, so rx_state stays SYNC and the loop is
absorbing rather than slow -- pass 7,651,085 is indistinguishable from
pass 1.  Each pass rewrites the ACK already in tx.state, re-zeroes both
counters, rings the doorbell and returns -EAGAIN.

The only in-tree caller, tegra186_bpmp_channel_reset(), retries on that
with no timeout, no iteration cap and no cpu_relax(), on both the probe
and the resume path, so the victim burns a core at roughly 1.5M
iterations per second for as long as the peer stays quiet.

A peer is a service, not a VM: one untrusted guest can hold a channel to
each of a rack of service partitions, and nothing here makes wedging the
tenth harder than the first.

This is not a new class of concern for ivc.c.  tegra_ivc_empty() already
carries an over-full check "to prevent denial of service attacks", and
calls that condition "an invalid case caused by a potentially malicious
peer".  That defence covers the counters; the handshake has none.

Apply geometric backoff to calls that make no progress, modelled on
xen_irq_lateeoi_locked(): a saturating count, a doubling delay, a hard
cap, and a reset the moment the peer moves.  Progress is detected by
reading tx.state back rather than by tracking which branch ran, so the
states from which no branch can escape are covered too.  The wait is a
bounded busy-wait by default because tegra_bpmp_transfer_atomic() reaches
this with interrupts disabled, and it uses local_clock() because the
resume path can run with timekeeping suspended.

This is a floor, not a fix.  The return value is unchanged, the caller
still retries for ever and probe or resume still never completes -- the
spin just stops costing what other channels have to share.  Bounding the
loop belongs in the caller.

Assisted-by: LLM
Signed-off-by: 0xSmash0th <0xSmash0th@gmail.com>
---
Precedent
---------
ivc.c already models a hostile peer.  tegra_ivc_empty() carries an
over-full check "to prevent denial of service attacks", and calls the
condition "an invalid case caused by a potentially malicious peer".  That
defence covers the counters; the handshake has none.  This closes the
second path, not a new class of concern.

The handshake has never been revisited: since 2016, every patch to ivc.c
has been the import itself or a tree-wide sweep.

Scope
-----
A peer is a service on one channel, not a VM: DRIVE OS is one untrusted
Linux guest with a channel to each of about ten service partitions.  One
hostile peer wedges one channel, and nothing makes wedging the tenth
harder than the first.

Whether x services down becomes the SoC down, I cannot show.  That needs
the spinning partitions to share cores rather than being pinned apart by
the PCT, and the hypervisor to enforce no per-partition CPU budget.  I
have no Tegra hardware and have not looked at the hypervisor -- treat the
SoC-wide version as something to check, not a claim made here.

Measurements
------------
Keying the test on the first branch -- where the doorbell amplification
lives -- would cover only a third of the reachable cases.  Over 30 inputs
that stall the loop:

    looping endpoint                  n    before        after
    rx=SYNC, tx=ACK   (branch A)      9   ~7,700,000      50-64
    rx=SYNC, tx=SYNC  (enters A)      2   ~7,700,000         65
    tx=SYNC, rx=EST   (empty else)   15    8,387,013      63-64
    tx=SYNC, rx=OTHER (empty else)    3    7,648,606         64
    tx=OTHER, rx=EST  (no escape)     1    8,244,347         64

Two thirds are the do-nothing else at the end of the chain, which emits no
doorbell at all -- silent, and so easier to miss.  The last row is an
out-of-enum tx.state from which no branch can escape.

Why only a floor
----------------
xen-netback puts five layers between a hostile frontend and the host that
IVC has none of: a thread per peer, a blocking wait, stall detection that
parks and recovers, a per-peer quota, and a fatal way to declare one peer
dead.  Backoff is the floor under those, not a substitute.

The two tunables and two counters are documented at their declarations in
ivc.h.  Nothing in the tree sets or reads them yet.

Testing
-------
Exercised under LKL with a userspace fuzzer driving ivc.c directly; the
numbers above are from those runs.

arm64 defconfig builds clean to vmlinux and Image under W=1 with TEGRA_IVC,
TEGRA_BPMP and the 186/194/234/264 SoC options on.  ivc.o also builds clean
for 32-bit ARM and pulls in no 64-bit division helper.  Not run on Tegra
hardware.

Tool assistance
---------------
AI tooling was used throughout -- audit, fuzzing setup, patch and changelog
-- but never fully automated; every step was hand-checked.  The Assisted-by
trailer is on the patch.
---
 drivers/firmware/tegra/ivc.c | 132 +++++++++++++++++++++++++++++++++++++++++++
 include/soc/tegra/ivc.h      |  44 +++++++++++++++
 2 files changed, 176 insertions(+)

diff --git a/drivers/firmware/tegra/ivc.c b/drivers/firmware/tegra/ivc.c
index 8c9aff9804c0..2b7d7a240aa6 100644
--- a/drivers/firmware/tegra/ivc.c
+++ b/drivers/firmware/tegra/ivc.c
@@ -3,6 +3,12 @@
  * Copyright (c) 2014-2016, NVIDIA CORPORATION.  All rights reserved.
  */
 
+#include <linux/delay.h>
+#include <linux/math64.h>
+#include <linux/minmax.h>
+#include <linux/sched/clock.h>
+#include <linux/time64.h>
+
 #include <soc/tegra/ivc.h>
 
 #define TEGRA_IVC_ALIGN 64
@@ -395,10 +401,111 @@ int tegra_ivc_write_advance(struct tegra_ivc *ivc)
 }
 EXPORT_SYMBOL(tegra_ivc_write_advance);
 
+/*
+ * A peer that moves to the SYNC state and then stops responding leaves this
+ * end with nothing to do. Each call to tegra_ivc_notified() repeats the same
+ * work, changes no state and returns -EAGAIN again, and the only in-tree
+ * caller retries in a loop with no timeout and no iteration limit. The result
+ * is a doorbell and several shared memory writes per iteration, for as long as
+ * the peer stays silent.
+ *
+ * Delay the call instead of skipping the work. Each call still does everything
+ * it did before, so the behaviour a caller sees is unchanged apart from how
+ * long the call takes. The delay doubles on each fruitless call, up to
+ * TEGRA_IVC_RESYNC_MAX_NS, which reduces the doorbell rate, the memory traffic
+ * and the CPU time together.
+ *
+ * A call counts as fruitless if it did not change this end's own state and is
+ * about to return -EAGAIN. That covers every case where a peer can stall the
+ * handshake, including the states from which no branch below can make
+ * progress, without naming any of them.
+ *
+ * The loop itself is not bounded by this. The channel really is not ready, so
+ * the return value does not change and a caller that retries forever still
+ * does. Only the cost of retrying falls.
+ */
+#define TEGRA_IVC_RESYNC_MIN_NS		(10 * NSEC_PER_USEC)
+#define TEGRA_IVC_RESYNC_MAX_NS		(100 * NSEC_PER_MSEC)
+#define TEGRA_IVC_RESYNC_MAX_SHIFT	16
+#define TEGRA_IVC_RESYNC_THRESHOLD	1
+
+/*
+ * resync_count stops increasing at U8_MAX, so a threshold near that value
+ * would leave no room for the delay to grow and the backoff would never take
+ * effect. Clamp the threshold so that a larger value always means a longer
+ * grace period, and leave TEGRA_IVC_RESYNC_DISABLED as the only way to turn
+ * the backoff off.
+ */
+#define TEGRA_IVC_RESYNC_THRESHOLD_MAX	32
+
+static void tegra_ivc_resync_restart(struct tegra_ivc *ivc)
+{
+	ivc->resync_count = 0;
+}
+
+static void tegra_ivc_resync_wait(struct tegra_ivc *ivc)
+{
+	unsigned int threshold = ivc->resync_threshold;
+	unsigned int shift;
+	u64 deadline;
+	u64 delay;
+
+	if (threshold == TEGRA_IVC_RESYNC_DISABLED)
+		return;
+
+	if (!threshold)
+		threshold = TEGRA_IVC_RESYNC_THRESHOLD;
+	else if (threshold > TEGRA_IVC_RESYNC_THRESHOLD_MAX)
+		threshold = TEGRA_IVC_RESYNC_THRESHOLD_MAX;
+
+	ivc->resync_events++;
+
+	if (ivc->resync_count != U8_MAX)
+		ivc->resync_count++;
+
+	/*
+	 * A small number of fruitless calls is normal while a peer catches
+	 * up, so they are not delayed. Still yield to any sibling thread,
+	 * because the caller is likely to be spinning.
+	 */
+	if (ivc->resync_count <= threshold) {
+		cpu_relax();
+		return;
+	}
+
+	shift = ivc->resync_count - 1 - threshold;
+	if (shift >= TEGRA_IVC_RESYNC_MAX_SHIFT)
+		delay = TEGRA_IVC_RESYNC_MAX_NS;
+	else
+		delay = min_t(u64, TEGRA_IVC_RESYNC_MIN_NS << shift,
+			      TEGRA_IVC_RESYNC_MAX_NS);
+
+	ivc->resync_delayed_ns += delay;
+
+	if (ivc->resync_can_sleep) {
+		might_sleep();
+		fsleep(div_u64(delay, NSEC_PER_USEC));
+		return;
+	}
+
+	/*
+	 * This can be reached while the device is suspended, where
+	 * timekeeping may also be suspended and ktime_get() would warn and
+	 * return a clock that is not advancing. local_clock() remains valid
+	 * there, and tegra_bpmp_wait_request_channel_free() busy-waits the
+	 * same way for the same reason.
+	 */
+	deadline = local_clock() + delay;
+	while (local_clock() < deadline)
+		cpu_relax();
+}
+
 void tegra_ivc_reset(struct tegra_ivc *ivc)
 {
 	unsigned int offset = offsetof(struct tegra_ivc_header, tx.count);
 
+	tegra_ivc_resync_restart(ivc);
+
 	tegra_ivc_header_write_field(&ivc->tx.map, tx.state, TEGRA_IVC_STATE_SYNC);
 	tegra_ivc_flush(ivc, ivc->tx.phys + offset);
 	ivc->notify(ivc, ivc->notify_data);
@@ -546,6 +653,17 @@ int tegra_ivc_notified(struct tegra_ivc *ivc)
 		 */
 	}
 
+	/*
+	 * Read the state back to find out whether any of the branches above
+	 * changed it, rather than tracking which branch ran. A peer that is
+	 * making progress moves us along and resets the backoff; a peer that
+	 * has stopped leaves the value sampled at the top of this function.
+	 */
+	if (tegra_ivc_header_read_field(&ivc->tx.map, tx.state) != tx_state)
+		tegra_ivc_resync_restart(ivc);
+	else if (tx_state != TEGRA_IVC_STATE_ESTABLISHED)
+		tegra_ivc_resync_wait(ivc);
+
 	if (tx_state != TEGRA_IVC_STATE_ESTABLISHED)
 		return -EAGAIN;
 
@@ -702,6 +820,20 @@ int tegra_ivc_init(struct tegra_ivc *ivc, struct device *peer, const struct iosy
 	ivc->tx.position = 0;
 	ivc->rx.position = 0;
 
+	/*
+	 * This function assigns the fields it uses and does not zero the
+	 * structure, so clear the backoff state explicitly. A caller that
+	 * passes an uninitialised structure would otherwise inherit a random
+	 * resync_can_sleep and could end up sleeping in atomic context. Both
+	 * of the caller-settable fields are cleared here, so they have to be
+	 * set after this function returns.
+	 */
+	ivc->resync_can_sleep = false;
+	ivc->resync_threshold = 0;
+	ivc->resync_count = 0;
+	ivc->resync_events = 0;
+	ivc->resync_delayed_ns = 0;
+
 	return 0;
 }
 EXPORT_SYMBOL(tegra_ivc_init);
diff --git a/include/soc/tegra/ivc.h b/include/soc/tegra/ivc.h
index be45d5f5adea..548512e3113f 100644
--- a/include/soc/tegra/ivc.h
+++ b/include/soc/tegra/ivc.h
@@ -7,12 +7,20 @@
 #define __TEGRA_IVC_H
 
 #include <linux/device.h>
+#include <linux/limits.h>
 #include <linux/dma-mapping.h>
 #include <linux/iosys-map.h>
 #include <linux/types.h>
 
 struct tegra_ivc_header;
 
+/*
+ * Store this in tegra_ivc.resync_threshold to turn the re-synchronisation
+ * backoff off. tegra_ivc_notified() then behaves as it did before the backoff
+ * was added, and the counters below stay at zero.
+ */
+#define TEGRA_IVC_RESYNC_DISABLED	U8_MAX
+
 struct tegra_ivc {
 	struct device *peer;
 
@@ -27,6 +35,42 @@ struct tegra_ivc {
 
 	unsigned int num_frames;
 	size_t frame_size;
+
+	/*
+	 * Backoff applied when a peer stops responding and calls to
+	 * tegra_ivc_notified() stop making progress. The call is delayed
+	 * rather than skipped, so the work it does is unchanged and only the
+	 * rate at which a retrying caller can repeat it falls. See the comment
+	 * above TEGRA_IVC_RESYNC_MIN_NS in ivc.c.
+	 *
+	 * @resync_can_sleep: set only if every call site of
+	 * tegra_ivc_notified() is allowed to sleep. When false, which is the
+	 * default, the delay is a bounded busy-wait that is safe in any
+	 * context. Do not set it just because the common path can sleep, as
+	 * tegra_bpmp_transfer_atomic() reaches this code with interrupts
+	 * disabled.
+	 *
+	 * @resync_threshold: how many calls that make no progress are allowed
+	 * through before the delay begins. Zero selects a default. Values
+	 * above TEGRA_IVC_RESYNC_THRESHOLD_MAX are clamped, so a larger value
+	 * always means a longer grace period and never disables the backoff.
+	 *
+	 * Both of the above are cleared by tegra_ivc_init(), so set them after
+	 * calling it.
+	 *
+	 * @resync_count: how many calls in a row have made no progress. Reset
+	 * whenever the state changes and by tegra_ivc_reset(). Internal.
+	 *
+	 * @resync_events: how many calls have made no progress in total.
+	 * @resync_delayed_ns: how long this channel has spent delayed, in
+	 * nanoseconds. Both are for diagnostics, are only cleared by
+	 * tegra_ivc_init(), and are not used elsewhere in the kernel.
+	 */
+	bool resync_can_sleep;
+	u8 resync_threshold;
+	u8 resync_count;
+	u32 resync_events;
+	u64 resync_delayed_ns;
 };
 
 /**

---
base-commit: dc9c9c4fcb88a5660259dcef93c1ef5acd767189
change-id: 20260917-ivc-resync-backoff-b768569eb0cc

Best regards,
-- 
0xSmash0th <0xSmash0th@gmail.com>

