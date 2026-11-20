From: Seonghyeon Lim <forfortuna@naver.com>
Date: Fri, 20 Nov 2026 15:56:04 +0900
Subject: [PATCH v2 2/2] can: virtio: fix virtqueue use before DRIVER_OK
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-virtio-can-ready-v2-2-0defda2af8cb@naver.com>
References: <20261120-virtio-can-ready-v2-0-0defda2af8cb@naver.com>
In-Reply-To: <20261120-virtio-can-ready-v2-0-0defda2af8cb@naver.com>
To: Harald Mommer <harald.mommer@oss.qualcomm.com>, 
 Matias Ezequiel Vara Larsen <mvaralar@redhat.com>, 
 Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, 
 Mikhail Golubev-Ciuchea <mikhail.golubev-ciuchea@oss.qualcomm.com>, 
 Francesco Valla <francesco@valla.it>, "Michael S. Tsirkin" <mst@redhat.com>
Cc: virtualization@lists.linux.dev, linux-can@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jason Wang <jasowangio@gmail.com>, 
 stable@vger.kernel.org, Seonghyeon Lim <forfortuna@naver.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795157866; l=2078;
 i=forfortuna@naver.com; s=20261110; h=from:subject:message-id;
 bh=wIY55Nih6Exr0WUhi1Tyc3EiQfNI6qtLKhOXoT4e7Vs=;
 b=iNTmLb2IWMi8elzzOk5J87idYxXeiL/HJlLHubu6TkFR6PvPZZ2EtrbwqEf2/9Hg+tlrRCNfC
 kqvNbXf4G3DCr+iziYwoMCePuJlXRkNMSecgnlwE05WyIN+Fch2rUMB
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
resume:

  task:kworker/u4:5 state:D
  Workqueue: async async_run_entry_fn
  Call Trace:
   __wait_for_common
   virtio_can_send_ctrl_msg
   virtio_can_open
   virtio_can_restore
   virtio_device_restore_priv
   dpm_run_callback
   device_resume

In probe, an ndo_open() right after register_candev() can likewise
send the START message before DRIVER_OK.

Call virtio_device_ready() before the first virtqueue use in both
probe and restore, as virtio-net does. Config change callbacks are
still deferred by the virtio core until probe or restore returns, and
virtqueue callbacks that arrive before NAPI is enabled are handled in
virtio_can_napi_enable().

Fixes: 083082a4e6d8 ("can: virtio: Add virtio CAN driver")
Cc: stable@vger.kernel.org
Signed-off-by: Seonghyeon Lim <forfortuna@naver.com>
---
 drivers/net/can/virtio_can.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/net/can/virtio_can.c b/drivers/net/can/virtio_can.c
index 9055d7e43235..549e8d789d74 100644
--- a/drivers/net/can/virtio_can.c
+++ b/drivers/net/can/virtio_can.c
@@ -925,6 +925,9 @@ static int virtio_can_probe(struct virtio_device *vdev)
 		err = -ENOMEM;
 		goto on_failure;
 	}
+
+	virtio_device_ready(vdev);
+
 	virtio_can_populate_rx_vq(vdev);
 
 	err = register_virtio_can_dev(dev);
@@ -979,6 +982,9 @@ static int __maybe_unused virtio_can_restore(struct virtio_device *vdev)
 		virtio_can_del_vq(vdev);
 		return -ENOMEM;
 	}
+
+	virtio_device_ready(vdev);
+
 	virtio_can_populate_rx_vq(vdev);
 
 	if (netif_running(ndev)) {

-- 
2.43.0

