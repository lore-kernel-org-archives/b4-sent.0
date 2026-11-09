From: Jerome Mohm <jrmmhm.kernel@eldare.de>
Date: Mon, 09 Nov 2026 20:39:24 +0100
Subject: [PATCH net v4] vsock/virtio: clear vqs[] to avoid a UAF on a
 failed PM restore
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-vsock-restore-uaf-send-v4-1-1df8dfb5d5de@eldare.de>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4XNQW6DMBAF0KtEXsfVjAGbZNV7RFkYZty4iaCyw
 UqEuHsNXRRFirL8oz/vTyJy8BzFcTeJwMlH33c5lPudaC+2+2LpKWehQGkEQJli315l4Dj0geV
 onYzckUTXmuKgncWGRH7+Cez8fYVPouNBnP+OcWy+uR0Wcqld/OI81vmEa/ndUkKJsiKrwRkwF
 ehPvpEN/EG8jiS1YVT9klGZ0aayljRZg+UzU/wzCOVLpsgMaSDQZV03ldky8zz/AjpYukFhAQA
 A
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794253170; l=4147;
 i=jrmmhm.kernel@eldare.de; s=20260928; h=from:subject:message-id;
 bh=5YFXaOW8KllonSsjF6SOnB8HkwciO73pZwsUjT72k8E=;
 b=o5Ui0yGmlrlsv7s3vDR3Ic3XgYduWqet+IqPcVhgBKc2puHQzgL+jxfeHT/pgfs6jWrU82E9J
 /7KX0+ab2xgBwU5CsrABnE3TPB51T8iCBoYthWQ/phU9iNUse8McHiX
X-Developer-Key: i=jrmmhm.kernel@eldare.de; a=ed25519;
 pk=xRCxNXbnNottaHpmvPDAOC9NuMJxqKo24abkehKRVlo=
X-Endpoint-Received: by B4 Relay for jrmmhm.kernel@eldare.de/20260928 with auth_id=1075
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

virtio_vsock_vqs_del() frees the virtqueues but leaves vsock->vqs[]
pointing at them. If virtio_vsock_restore() then fails, the driver
stays bound with a dangling vqs[], and the next freeze or unbind
passes a freed virtqueue to virtqueue_detach_unused_buf():

  BUG: KASAN: slab-use-after-free in virtqueue_detach_unused_buf
   virtio_vsock_vqs_del (net/vmw_vsock/virtio_transport.c:785)
   virtio_vsock_remove
  Freed by task ...:
   vp_del_vqs
   virtio_vsock_freeze

Clear vqs[] after del_vqs() and when virtio_find_vqs() fails. Return
early from virtio_vsock_vqs_del() when vqs[] is empty: the detach
loops would pass NULL to virtqueue_detach_unused_buf(), and a second
del_vqs() would free virtio-mmio's IRQ again, which only WARNs in
free_irq() ("Trying to free already-free IRQ").

Found with the help of Anthropic's Claude and reproduced on virtio-pci
and virtio-mmio by failing the restore with failslab, without other
kernel changes; the virtio-mmio WARN was found by the netdev Sashiko
review and reproduced with v1 of this patch. With this patch neither
report appears on virtio-pci or virtio-mmio guests, and the vsock
vmtest.sh single-VM tests pass. A find_vqs() failure after some
virtqueues were set up was not exercised.

Fixes: bd50c5dc182b ("vsock/virtio: add support for device suspend/resume")
Cc: stable@vger.kernel.org
Signed-off-by: Jerome Mohm <jrmmhm.kernel@eldare.de>
---
Changes in v4:
- Say why the early return is needed: the detach loops would pass NULL
  to virtqueue_detach_unused_buf() (answering Stefano).
- Say in the message and the comment that freeing virtio-mmio's IRQ
  again only WARNs (Stefano).
- Move the send queue purge before virtio_reset_device() (Stefano).
- Message: the use-after-free also reproduces on virtio-mmio.
- Rebase onto current net; rebuilt and retested on virtio-pci and
  virtio-mmio, and the vmtest.sh single-VM tests rerun on this version.
  The moved purge ran with an empty send queue only; the ns_* tests of
  vmtest.sh were not run (they need root on the host). The reproducers
  are available on request.
- Link to v3: https://patch.msgid.link/20261104-vsock-restore-uaf-send-v3-1-d60d06488b57@eldare.de
---
 net/vmw_vsock/virtio_transport.c | 16 +++++++++++++---
 1 file changed, 13 insertions(+), 3 deletions(-)

diff --git a/net/vmw_vsock/virtio_transport.c b/net/vmw_vsock/virtio_transport.c
index 4f9aa9c4c3aa..cf63bc99f3cc 100644
--- a/net/vmw_vsock/virtio_transport.c
+++ b/net/vmw_vsock/virtio_transport.c
@@ -714,8 +714,10 @@ static int virtio_vsock_vqs_init(struct virtio_vsock *vsock)
 	atomic_set(&vsock->queued_replies, 0);
 
 	ret = virtio_find_vqs(vdev, VSOCK_VQ_MAX, vsock->vqs, vqs_info, NULL);
-	if (ret < 0)
+	if (ret < 0) {
+		memset(vsock->vqs, 0, sizeof(vsock->vqs));
 		return ret;
+	}
 
 	virtio_vsock_update_guest_cid(vsock);
 
@@ -776,11 +778,19 @@ static void virtio_vsock_vqs_del(struct virtio_vsock *vsock)
 	vsock->event_run = false;
 	mutex_unlock(&vsock->event_lock);
 
+	virtio_vsock_skb_queue_purge(&vsock->send_pkt_queue);
+
 	/* Flush all device writes and interrupts, device will not use any
 	 * more buffers.
 	 */
 	virtio_reset_device(vdev);
 
+	/* After a failed restore no virtqueues are live, and a second
+	 * del_vqs() would free virtio-mmio's IRQ again (a WARN in free_irq()).
+	 */
+	if (!vsock->vqs[VSOCK_VQ_RX])
+		return;
+
 	mutex_lock(&vsock->rx_lock);
 	while ((skb = virtqueue_detach_unused_buf(vsock->vqs[VSOCK_VQ_RX])))
 		kfree_skb(skb);
@@ -791,10 +801,10 @@ static void virtio_vsock_vqs_del(struct virtio_vsock *vsock)
 		kfree_skb(skb);
 	mutex_unlock(&vsock->tx_lock);
 
-	virtio_vsock_skb_queue_purge(&vsock->send_pkt_queue);
-
 	/* Delete virtqueues and flush outstanding callbacks if any */
 	vdev->config->del_vqs(vdev);
+
+	memset(vsock->vqs, 0, sizeof(vsock->vqs));
 }
 
 static int virtio_vsock_probe(struct virtio_device *vdev)

---
base-commit: 1d5e2c57e9ffc134e14b3f837c8d7c53b508bd22
change-id: 20261001-vsock-restore-uaf-send-1fc7396fa1bd

Best regards,
--  
Jerome Mohm <jrmmhm.kernel@eldare.de>

