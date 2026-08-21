From: FAN YE <fy15309206903@gmail.com>
Date: Fri, 21 Aug 2026 16:40:41 +0000
Subject: [PATCH] PCI/VGA: Fix lost wakeup when waiting for a VGA resource
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260821-pci-vga-lost-wakeup-v1-1-39dc6a2333c6@gmail.com>
X-B4-Tracking: v=1; b=H4sIAIh/iGoC/yXMSQ6DMAxA0asgr7GUhFG9CmIRUhcMFUQxQyXE3
 Rva5Vv8f4JQYBJ4JCcE2ll4mSN0moAb7NwT8jMajDKlqo1G7xj33uJ7kRUPO9HmMesqVRZ1bnL
 SEEsf6MWf37Vp/5atG8mt9wqu6wuBcIaPdwAAAA==
X-Change-ID: 20260821-pci-vga-lost-wakeup-3b70658424e1
To: linux-pci@vger.kernel.org, Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787330440; l=3519;
 i=fy15309206903@gmail.com; s=tbnet3; h=from:subject:message-id;
 bh=Rrv8GAN0TkTavxf0KIGyHuf9553vMGCJ0Prul4fquuY=;
 b=1v3iU7KRL+w1UPjVQY3sriskWxxUrivf66xlFxS/4VJKeVonSAOMEM6cfTk1prWoeU90MW/qg
 8DXrI67x7cCALTVOmYRZpLfStHf90Vi8Ql6yt+yPQnzRj5EgeN26XS5
X-Developer-Key: i=fy15309206903@gmail.com; a=ed25519;
 pk=6QsQIrI/kruYWIJyCH9ntPMXsHCqF5JtK/DCMtOCzdc=
X-Endpoint-Received: by B4 Relay for fy15309206903@gmail.com/tbnet3 with auth_id=929
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A task waiting in vga_get() can sleep forever even though the conflicting
device has already released the resource.  Once __vga_tryget() reports a
conflict, vga_get() drops vga_lock and only then puts itself on
vga_wait_queue, while __vga_put() wakes that queue while holding vga_lock.
A wakeup landing in between finds the queue empty and is discarded, and as
the conflict is already gone no further wakeup is coming.  Callers passing
interruptible=0, such as the "lock" command of /dev/vga_arbiter, are then
unkillable and keep their lock counts forever.

Queue up before dropping vga_lock, the way prepare_to_wait() publishes a
waiter before the condition is re-tested.  The releasing side needs
vga_lock to reach the wakeup, so it can no longer pass an unqueued waiter.

Fixes: deb2d2ecd43d ("PCI/GPU: implement VGA arbitration on Linux")
Cc: stable@vger.kernel.org
Assisted-by: Claude:claude-opus-5
Signed-off-by: FAN YE <fy15309206903@gmail.com>
---
Reproduced under QEMU on 818bebeb63dd with two VGA devices, the second one
behind a bridge that does not forward VGA so that it owns no legacy resources.
Two /dev/vga_arbiter clients each locking one device wedged the second client
in vga_get(), D state and unkillable, after 8538 rounds, while the conflicting
device already read back locks=none(0:0).  40000 rounds with this patch, none.
---
 drivers/pci/vgaarb.c | 29 +++++++++++++++++------------
 1 file changed, 17 insertions(+), 12 deletions(-)

diff --git a/drivers/pci/vgaarb.c b/drivers/pci/vgaarb.c
index 3de05aee78599..51c7d171c9558 100644
--- a/drivers/pci/vgaarb.c
+++ b/drivers/pci/vgaarb.c
@@ -459,6 +459,23 @@ int vga_get(struct pci_dev *pdev, unsigned int rsrc, int interruptible)
 			break;
 		}
 		conflict = __vga_tryget(vgadev, rsrc);
+		/*
+		 * We have a conflict; we wait until somebody kicks the
+		 * work queue. Currently we have one work queue that we
+		 * kick each time some resources are released, but it would
+		 * be fairly easy to have a per-device one so that we only
+		 * need to attach to the conflicting device.
+		 *
+		 * Queue up before dropping vga_lock: __vga_put() wakes the
+		 * queue while holding it, so a wakeup cannot slip past.
+		 */
+		if (!IS_ERR_OR_NULL(conflict)) {
+			init_waitqueue_entry(&wait, current);
+			add_wait_queue(&vga_wait_queue, &wait);
+			set_current_state(interruptible ?
+					  TASK_INTERRUPTIBLE :
+					  TASK_UNINTERRUPTIBLE);
+		}
 		spin_unlock_irqrestore(&vga_lock, flags);
 		if (IS_ERR(conflict)) {
 			rc = PTR_ERR(conflict);
@@ -467,18 +484,6 @@ int vga_get(struct pci_dev *pdev, unsigned int rsrc, int interruptible)
 		if (conflict == NULL)
 			break;
 
-		/*
-		 * We have a conflict; we wait until somebody kicks the
-		 * work queue. Currently we have one work queue that we
-		 * kick each time some resources are released, but it would
-		 * be fairly easy to have a per-device one so that we only
-		 * need to attach to the conflicting device.
-		 */
-		init_waitqueue_entry(&wait, current);
-		add_wait_queue(&vga_wait_queue, &wait);
-		set_current_state(interruptible ?
-				  TASK_INTERRUPTIBLE :
-				  TASK_UNINTERRUPTIBLE);
 		if (interruptible && signal_pending(current)) {
 			__set_current_state(TASK_RUNNING);
 			remove_wait_queue(&vga_wait_queue, &wait);

---
base-commit: 818bebeb63dd6bf5f4e07e145f6cdbace520a34c
change-id: 20260821-pci-vga-lost-wakeup-3b70658424e1

Best regards,
--  
FAN YE <fy15309206903@gmail.com>

