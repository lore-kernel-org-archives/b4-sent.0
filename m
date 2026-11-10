From: Seonghyeon Lim <forfortuna@naver.com>
Date: Wed, 11 Nov 2026 02:11:13 +0900
Subject: [PATCH] can: virtio: fix virtqueue use before DRIVER_OK
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-virtio-can-ready-v1-1-0b4dd020af0b@naver.com>
X-B4-Tracking: v=1; b=H4sIADBQ82oC/yXMQQ5AMBCF4avIrE1SgjSuIhZVU8aiZIoQcXfF2
 32L918QSJgC1MkFQjsHnn1EliZgR+MHQu6jIVd5lcXhzrLyjNZ4FDL9ibq05JxTldEFxNsi5Pj
 4kk37O2zdRHZ9O3DfD8XMF5F0AAAA
X-Change-ID: 20261111-virtio-can-ready-85cefff06a84
To: Harald Mommer <harald.mommer@oss.qualcomm.com>, 
 Matias Ezequiel Vara Larsen <mvaralar@redhat.com>, 
 Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, 
 Mikhail Golubev-Ciuchea <mikhail.golubev-ciuchea@oss.qualcomm.com>, 
 Francesco Valla <francesco@valla.it>, "Michael S. Tsirkin" <mst@redhat.com>
Cc: virtualization@lists.linux.dev, linux-can@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jason Wang <jasowangio@gmail.com>, 
 Seonghyeon Lim <forfortuna@naver.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794330677; l=1943;
 i=forfortuna@naver.com; s=20261110; h=from:subject:message-id;
 bh=MJAobe4rPXYioFnUfp9+XUMNTxBij8wL6gfGu1JqKaQ=;
 b=E1tjMRm3+lNVL2OwfvqZKG7Q0qtbt8SWyZ1IIFGIkPNrZN1rDFwRWWcxA8zCPaJbUwq2c0pta
 au/rzScbiSpAZ3U57rYO8ZM0v+Qsd863Ysb4r0+HahDb4KjqAiFl424
X-Developer-Key: i=forfortuna@naver.com; a=ed25519;
 pk=NSzj4ReyzmE01C4q/f+7jqXzWqsN5NwQK5UsSI6ufiE=
X-Endpoint-Received: by B4 Relay for forfortuna@naver.com/20261110 with auth_id=1481
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

virtio_can_probe() and virtio_can_restore() fill the RX virtqueue and
kick it before the device is set DRIVER_OK. The virtio specification
does not allow the driver to notify the device before DRIVER_OK.

In restore, if the interface was up, virtio_can_open() then sends a
START control message and waits for the reply. DRIVER_OK is only set
by the virtio core after restore returns, so the device may never
handle the request and the wait never completes, which hangs system
resume. In probe, an ndo_open() right after register_candev() can
likewise send the START message before DRIVER_OK.

Call virtio_device_ready() before the first virtqueue use in both
probe and restore, as virtio-net does.

Fixes: 083082a4e6d8 ("can: virtio: Add virtio CAN driver")
Signed-off-by: Seonghyeon Lim <forfortuna@naver.com>
---
Tested with QEMU 8.2 + vhost-device-can: with the CAN interface up,
suspend/resume (pm_test=devices) hangs without this patch and
completes with it. No new lockdep warnings.
---
 drivers/net/can/virtio_can.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/net/can/virtio_can.c b/drivers/net/can/virtio_can.c
index f67d0bf09681..ae35a00b784b 100644
--- a/drivers/net/can/virtio_can.c
+++ b/drivers/net/can/virtio_can.c
@@ -912,6 +912,9 @@ static int virtio_can_probe(struct virtio_device *vdev)
 		err = -ENOMEM;
 		goto on_failure;
 	}
+
+	virtio_device_ready(vdev);
+
 	virtio_can_populate_rx_vq(vdev);
 
 	err = register_virtio_can_dev(dev);
@@ -966,6 +969,9 @@ static int __maybe_unused virtio_can_restore(struct virtio_device *vdev)
 		virtio_can_del_vq(vdev);
 		return -ENOMEM;
 	}
+
+	virtio_device_ready(vdev);
+
 	virtio_can_populate_rx_vq(vdev);
 
 	if (netif_running(ndev)) {

---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261111-virtio-can-ready-85cefff06a84

Best regards,
--  
Seonghyeon Lim <forfortuna@naver.com>

