From: Jerome Mohm <jrmmhm.kernel@eldare.de>
Date: Wed, 28 Oct 2026 19:22:43 +0100
Subject: [PATCH net v2] vsock/virtio: clear vqs[] to avoid a UAF on a
 failed PM restore
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-vsock-restore-uaf-send-v2-1-675aad6da714@eldare.de>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNQQ6CMBBFr0Jm7ZgOhhJdeQ/DorRTqZpCOtBoC
 HcX8AAu38//788gnAILXIoZEucgoY8rlIcCbGfinTG4laFUpSalCLP09omJZewT42Q8CkeH5G1
 9OmtvqHWwjofEPrx38Q0ij9D8QpnaB9txU261Lmyez36faS//e8qEhJUzWvla1ZXSV345k/joG
 JplWb7WmnP00wAAAA==
X-Change-ID: 20261001-vsock-restore-uaf-send-1fc7396fa1bd
To: Stefan Hajnoczi <stefanha@redhat.com>, 
 Stefano Garzarella <sgarzare@redhat.com>, 
 Bobby Eshleman <bobbyeshleman@meta.com>, 
 "Michael S. Tsirkin" <mst@redhat.com>, Jason Wang <jasowangio@gmail.com>, 
 =?utf-8?q?Eugenio_P=C3=A9rez?= <eperezma@redhat.com>, 
 Xuan Zhuo <xuanzhuo@linux.alibaba.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>
Cc: virtualization@lists.linux.dev, kvm@vger.kernel.org, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Jerome Mohm <jrmmhm.kernel@eldare.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793211764; l=7501;
 i=jrmmhm.kernel@eldare.de; s=20260928; h=from:subject:message-id;
 bh=TgNj8sXwA7PXHtGqATFHxwV7EEQCr8JSQsDh7L4876A=;
 b=Zdt4NFAjkbfVtxe5MMNuYELF2gfYAFolbzqG3h/nBprHf9FB16x5aRJgMqVljW/VcO9aa4KHj
 dLnalk+lhNNCGEibK7RilllupwYRQfkpYaxw64b/GamfBC4tUiDf4Wc
X-Developer-Key: i=jrmmhm.kernel@eldare.de; a=ed25519;
 pk=xRCxNXbnNottaHpmvPDAOC9NuMJxqKo24abkehKRVlo=
X-Endpoint-Received: by B4 Relay for jrmmhm.kernel@eldare.de/20260928 with auth_id=1075
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

virtio_vsock_vqs_del() frees the virtqueues via del_vqs() but never
clears vsock->vqs[]. If a later virtio_vsock_restore() fails to
reallocate them (its error path is a bare "goto out" that only unlocks
and returns), the driver is left bound with a dangling vqs[]. The next
virtio_vsock_vqs_del() - on a second freeze or on remove/unbind - then
passes a freed vring_virtqueue to virtqueue_detach_unused_buf(), a slab
use-after-free. KASAN on a guest with a virtio-vsock device on
virtio-pci, after a restore made to fail by fault injection:

  BUG: KASAN: slab-use-after-free in virtqueue_detach_unused_buf
  Read of size 4 at addr ... by task repro
   virtqueue_detach_unused_buf
   virtio_vsock_vqs_del (net/vmw_vsock/virtio_transport.c:785)
   virtio_vsock_remove
   virtio_dev_remove
   ... unbind_store
  Freed by task ...:
   kfree
   vp_del_vqs
   virtio_vsock_freeze          <- the preceding freeze freed the vq
  Allocated by task 1:
   vring_create_virtqueue
   virtio_vsock_vqs_init
   virtio_vsock_probe           <- original allocation at probe

That second virtio_vsock_vqs_del() also repeats del_vqs(), which not
every transport tolerates. virtio-mmio's vm_del_vqs() always ends in
free_irq(), but after the failed vm_find_vqs() the device no longer
holds its IRQ, so on virtio-mmio the second call also warns:

  Trying to free already-free IRQ 51
  WARNING: kernel/irq/manage.c:1894 at free_irq+0x23e/0x840
   vm_del_vqs
   virtio_vsock_vqs_del
   virtio_vsock_remove          (or virtio_vsock_freeze)

virtio-pci's vp_del_vqs() is idempotent, so the PCI case shows only
the use-after-free.

Clear vsock->vqs[] after del_vqs() and when virtio_find_vqs() fails in
virtio_vsock_vqs_init(), and treat an empty vqs[] as "no virtqueues
are live": virtio_vsock_vqs_del() then still resets the device
(virtio_dev_remove() expects a reset device) and purges the send
queue, but skips the detach loops and del_vqs(). find_vqs() cleans up
after itself on failure, so skipping the second del_vqs() leaks
nothing. Clearing the stale pointers follows virtio_blk
commit 0739c2c6a015 ("virtio_blk: NULL out vqs to avoid double free on
failed resume").

The use-after-free was found with the help of an LLM coding assistant
(Anthropic's Claude); the free_irq() warning on virtio-mmio was reported
by the netdev Sashiko AI review of an earlier version of this patch.

Testing: on a private VM with a KASAN fuzz kernel, over virtio-pci and
over virtio-mmio (QEMU microvm). The restore allocation failure was
forced with CONFIG_FAILSLAB steered by the fault-injection stacktrace
filter to the virtio-vsock restore path only; a guest-root program
drives a pm_test=devices freeze/restore cycle (so .restore returns
-ENOMEM) and then unbinds the device, or runs a second freeze/restore
cycle. Without a fix (v7.3-rc5 based) the PCI run reports the
slab-use-after-free above. With only the vqs[] clearing (v1 of this
patch, on net 363c8c79220d) the MMIO runs report the free_irq warning on
remove and on the second freeze. With this patch on the same base,
restore still fails with -ENOMEM on both transports and neither report
appears; the device works again after a second, successful
freeze/restore cycle and after unbind/bind, and a normal freeze/restore
and unbind/bind still leave a working device. A find_vqs() failure after
some virtqueues were set up was not exercised (each restore attempt
failed at its first allocation, before any virtqueue was set up); that
clear is covered by code reading only. The three single-VM tests of
tools/testing/selftests/vsock/vmtest.sh (vm_server_host_client,
vm_client_host_server, vm_loopback; 44 vsock_test cases each) pass on
this tree, as on net; on both kernels the host-side runs skip the SO_INQ
cases (SO_INQ not supported by the host kernel). The ns_* tests of
vmtest.sh were not run (they need root on the host). checkpatch.pl
--strict is clean and the fuzz-config build is warning-free. The
reproducer needs guest root, CONFIG_FAILSLAB with
CONFIG_FAULT_INJECTION_DEBUG_FS and
CONFIG_FAULT_INJECTION_STACKTRACE_FILTER, and CONFIG_HIBERNATION with
CONFIG_PM_DEBUG for pm_test; it is available on request.

Fixes: bd50c5dc182b ("vsock/virtio: add support for device suspend/resume")
Cc: stable@vger.kernel.org
Signed-off-by: Jerome Mohm <jrmmhm.kernel@eldare.de>
---
The use-after-free was found with the help of Anthropic's Claude; the
virtio-mmio warning comes from the netdev Sashiko review.

Changes in v2:
- Skip the detach loops and del_vqs() in virtio_vsock_vqs_del() when no
  virtqueues are live, so the teardown after a failed restore does not
  free virtio-mmio's IRQ a second time (Sashiko review).
- Use an empty vqs[] as the 'no live virtqueues' marker instead of v1's
  per-loop NULL checks, and purge the send queue before the early
  return.
- Commit message: cite only virtio_blk 0739c2c6a015; drop the wrong
  virtio_rtc and virtio_console references (Sashiko review). Drop the
  commit ID from the code comment.
- Tested on virtio-mmio (QEMU microvm) as well as virtio-pci.
- Drop the Assisted-by trailer (removed upstream); tool use is
  disclosed above instead.
- Link to v1: https://patch.msgid.link/20261001-vsock-restore-uaf-send-v1-1-5da60f707506@eldare.de
---
 net/vmw_vsock/virtio_transport.c | 24 +++++++++++++++++++++---
 1 file changed, 21 insertions(+), 3 deletions(-)

diff --git a/net/vmw_vsock/virtio_transport.c b/net/vmw_vsock/virtio_transport.c
index 4f9aa9c4c3aa..bba594b7fc14 100644
--- a/net/vmw_vsock/virtio_transport.c
+++ b/net/vmw_vsock/virtio_transport.c
@@ -714,8 +714,14 @@ static int virtio_vsock_vqs_init(struct virtio_vsock *vsock)
 	atomic_set(&vsock->queued_replies, 0);
 
 	ret = virtio_find_vqs(vdev, VSOCK_VQ_MAX, vsock->vqs, vqs_info, NULL);
-	if (ret < 0)
+	if (ret < 0) {
+		/* On failure virtio_find_vqs() can leave freed virtqueues or
+		 * error pointers in vsock->vqs[]. Clear it: an empty vqs[]
+		 * tells virtio_vsock_vqs_del() that no virtqueues are live.
+		 */
+		memset(vsock->vqs, 0, sizeof(vsock->vqs));
 		return ret;
+	}
 
 	virtio_vsock_update_guest_cid(vsock);
 
@@ -781,6 +787,15 @@ static void virtio_vsock_vqs_del(struct virtio_vsock *vsock)
 	 */
 	virtio_reset_device(vdev);
 
+	virtio_vsock_skb_queue_purge(&vsock->send_pkt_queue);
+
+	/* No virtqueues are live, e.g. after a failed restore: they were
+	 * already deleted, and a second del_vqs() is not safe on every
+	 * transport (virtio-mmio would free its IRQ again).
+	 */
+	if (!vsock->vqs[VSOCK_VQ_RX])
+		return;
+
 	mutex_lock(&vsock->rx_lock);
 	while ((skb = virtqueue_detach_unused_buf(vsock->vqs[VSOCK_VQ_RX])))
 		kfree_skb(skb);
@@ -791,10 +806,13 @@ static void virtio_vsock_vqs_del(struct virtio_vsock *vsock)
 		kfree_skb(skb);
 	mutex_unlock(&vsock->tx_lock);
 
-	virtio_vsock_skb_queue_purge(&vsock->send_pkt_queue);
-
 	/* Delete virtqueues and flush outstanding callbacks if any */
 	vdev->config->del_vqs(vdev);
+
+	/* The virtqueues are freed: clear the stale pointers, so that a
+	 * virtio_vsock_vqs_del() after a failed restore skips them.
+	 */
+	memset(vsock->vqs, 0, sizeof(vsock->vqs));
 }
 
 static int virtio_vsock_probe(struct virtio_device *vdev)

---
base-commit: 363c8c79220d0db4d65dcd570529ddda15067cb5
change-id: 20261001-vsock-restore-uaf-send-1fc7396fa1bd

Best regards,
--  
Jerome Mohm <jrmmhm.kernel@eldare.de>

