From: Jerome Mohm <jrmmhm.kernel@eldare.de>
Date: Wed, 04 Nov 2026 17:26:43 +0100
Subject: [PATCH net v3] vsock/virtio: clear vqs[] to avoid a UAF on a
 failed PM restore
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-vsock-restore-uaf-send-v3-1-d60d06488b57@eldare.de>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4XNQQ7CIBAF0Ks0sxYD1IK68h7GBYXBooYaaImm6
 d2luOnGuPyTP+9PEDE4jHCsJgiYXHS9z6HeVKA75a9InMkZOOWCUcpIir2+k4Bx6AOSUVkS0Rv
 CrJb1QVjFWgP5+RnQuleBz+BxgMv3GMf2hnpYyKXWucV5l/nESvnfUmKEkcYoQa2ksqHihA+jA
 m4NlpHEVwzf/2R4ZoRslDLCKMl2a2ae5w9qgSuWGgEAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793809603; l=3366;
 i=jrmmhm.kernel@eldare.de; s=20260928; h=from:subject:message-id;
 bh=M5xaSNmFTKxhlPUeiNqMrmM7Ti9uva3s+Lictxc3xSk=;
 b=WiOH3gK7gWMGtImU9UnXdRgEZeOga4gZyBeLDnXYU6u/5UOadx+GaGWSQtbgVTmXTQcBfTXY9
 PGRLQ/f248gDMYpfGRy39AwTlpbiJWq423G3xb7DftydlGoHe0CV4/S
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
early from virtio_vsock_vqs_del() when vqs[] is empty: a second
del_vqs() would free virtio-mmio's IRQ again ("Trying to free
already-free IRQ").

Found with the help of Anthropic's Claude and reproduced on virtio-pci
by failing the restore with failslab; the virtio-mmio IRQ issue was
found by the netdev Sashiko review. With this patch neither report
appears on virtio-pci or virtio-mmio guests, and the vsock vmtest.sh
single-VM tests pass. A find_vqs() failure after some virtqueues were
set up was not exercised.

Fixes: bd50c5dc182b ("vsock/virtio: add support for device suspend/resume")
Cc: stable@vger.kernel.org
Signed-off-by: Jerome Mohm <jrmmhm.kernel@eldare.de>
---
Changes in v3:
- Shorten the commit message (Stefano, Michael).
- Drop the two comments on clearing vqs[] (Bobby) and shorten the
  remaining one.
- Drop the tool note below "---"; it is in the commit message (Stefano).
- Comment changes only; not rebuilt or retested.
- Link to v2: https://patch.msgid.link/20261028-vsock-restore-uaf-send-v2-1-675aad6da714@eldare.de
---
 net/vmw_vsock/virtio_transport.c | 16 +++++++++++++---
 1 file changed, 13 insertions(+), 3 deletions(-)

diff --git a/net/vmw_vsock/virtio_transport.c b/net/vmw_vsock/virtio_transport.c
index 4f9aa9c4c3aa..ffe7cd93463d 100644
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
 
@@ -781,6 +783,14 @@ static void virtio_vsock_vqs_del(struct virtio_vsock *vsock)
 	 */
 	virtio_reset_device(vdev);
 
+	virtio_vsock_skb_queue_purge(&vsock->send_pkt_queue);
+
+	/* After a failed restore no virtqueues are live, and a second
+	 * del_vqs() would free virtio-mmio's IRQ again.
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
base-commit: 363c8c79220d0db4d65dcd570529ddda15067cb5
change-id: 20261001-vsock-restore-uaf-send-1fc7396fa1bd

Best regards,
--  
Jerome Mohm <jrmmhm.kernel@eldare.de>

