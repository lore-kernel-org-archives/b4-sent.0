From: DAI RENJIE <drj19981414013@gmail.com>
Date: Fri, 21 Aug 2026 14:08:17 +0000
Subject: [PATCH] resource: fix lost wakeup when waiting for a muxed region
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260821-b4-resource-muxed-lost-wakeup-v1-1-37eb6473a76c@gmail.com>
X-B4-Tracking: v=1; b=H4sIANBbiGoC/yXMTQ6CMBAG0KuQWTtJWwipXsW4gPZT6w8lHaokh
 LtTdPk2byFBChA6VQslfIKEOBToQ0Xu3g03cPDFZJRplTWa+4YTJObkwO88w/MrysTf7ok8ct1
 6661qoI+ayjEmXMP8+8+XvyX3D7hpT2ldN0wSYSaBAAAA
X-Change-ID: 20260821-b4-resource-muxed-lost-wakeup-36d8d804e191
To: Mark Brown <broonie@kernel.org>, Kees Cook <kees@kernel.org>
Cc: linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787321296; l=2725;
 i=drj19981414013@gmail.com; s=spd1; h=from:subject:message-id;
 bh=6IGzf0b/68Vh04oT4XukuXWAvXccrvWh0iRVSpG8jLE=;
 b=CbjmLHq2ItgsfkRYp7p30gMt8YI3Sofz+R2E2KEHZi34ALtbS1wBlI6fRSYBCIbVtJ7OikN7R
 41lRDlabxh8AQ21oEZ9pGe+uUqWd378FWiDahcp+a3FzgYIHkheFDt5
X-Developer-Key: i=drj19981414013@gmail.com; a=ed25519;
 pk=7WMYfxvtyutHpCdX474fP0ENk3k/rJxmIXpreEoqPIU=
X-Endpoint-Received: by B4 Relay for drj19981414013@gmail.com/spd1 with auth_id=967
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A task waiting for a muxed region can sleep forever in TASK_UNINTERRUPTIBLE
even though the region it waits for is already free.
__request_region_locked() queues itself on muxed_resource_wait and drops
resource_lock before setting TASK_UNINTERRUPTIBLE, while __release_region()
wakes the queue after dropping the same lock.  A wakeup landing in between
finds TASK_RUNNING, does not match TASK_NORMAL and is discarded; callers
hold a muxed region only across a bounded transaction, so no further
release is coming.  The task is unkillable and its caller never returns.

The window is one store wide, but an interrupt is enough to hold the waiter
in it, and the machine this was seen on runs PREEMPT_DYNAMIC in its
voluntary default.  Since v6.11 spd5118 exports the DDR5 sensors of AMD
boards through i2c-piix4, which takes a muxed region per SMBus transaction;
a third of the in-tree users of request_muxed_region() are hwmon drivers,
so reading a world-readable attribute is all an unprivileged user needs to
drive the contention.  The blocked task sleeps holding the i2c adapter bus
lock, and 27 more piled up behind it.

Fix it by setting the task state before dropping resource_lock, as
prepare_to_wait() does: the releasing side needs resource_lock to unlink
the resource, so it cannot reach the wakeup before the state is published.

Fixes: 8b6d043b7ee2 ("resource: shared I/O region support")
Cc: stable@vger.kernel.org
Assisted-by: Claude:claude-opus-5
Signed-off-by: DAI RENJIE <drj19981414013@gmail.com>
---
Reproduced by building a kernel with the two orderings selectable at
runtime and a 2ms delay inside the window.  Switching only that knob, a
two-thread barriered reproducer loses the wakeup 200 times out of 200
before the fix and 0 out of 200 after it; without the delay it goes 20000
times through the wait path and loses none.
---
 kernel/resource.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/kernel/resource.c b/kernel/resource.c
index 3d17e3196a3e..3604b7152808 100644
--- a/kernel/resource.c
+++ b/kernel/resource.c
@@ -1350,8 +1350,8 @@ static int __request_region_locked(struct resource *res, struct resource *parent
 		}
 		if (conflict->flags & flags & IORESOURCE_MUXED) {
 			add_wait_queue(&muxed_resource_wait, &wait);
-			write_unlock(&resource_lock);
 			set_current_state(TASK_UNINTERRUPTIBLE);
+			write_unlock(&resource_lock);
 			schedule();
 			remove_wait_queue(&muxed_resource_wait, &wait);
 			write_lock(&resource_lock);

---
base-commit: 818bebeb63dd6bf5f4e07e145f6cdbace520a34c
change-id: 20260821-b4-resource-muxed-lost-wakeup-36d8d804e191

Best regards,
--  
DAI RENJIE <drj19981414013@gmail.com>

