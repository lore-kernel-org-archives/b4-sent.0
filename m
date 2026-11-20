From: Seonghyeon Lim <forfortuna@naver.com>
Date: Fri, 20 Nov 2026 15:56:03 +0900
Subject: [PATCH v2 1/2] can: virtio: fix RX/TX stall on interrupt before
 NAPI is enabled
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-virtio-can-ready-v2-1-0defda2af8cb@naver.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795157866; l=1758;
 i=forfortuna@naver.com; s=20261110; h=from:subject:message-id;
 bh=VdaeA38HLLllzuwXwpZQnruRF3RFDA8ms3izgQtOuCM=;
 b=0NmnWet0mChPlkOlfm8eK8hgyrc7mZxkjGIeDIrlHa4xCAz9bNBH/Qbmyj2K/OdCJ+iIhw1WE
 RlNf/UDdoTsDhKerVayRxLL8NuUz+OiZLIXuoBDNE2YfrOZlNIdckPT
X-Developer-Key: i=forfortuna@naver.com; a=ed25519;
 pk=NSzj4ReyzmE01C4q/f+7jqXzWqsN5NwQK5UsSI6ufiE=
X-Endpoint-Received: by B4 Relay for forfortuna@naver.com/20261110 with auth_id=1481
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

virtio_can_open() sends the START command before it enables NAPI. Once
the device has started, an RX or TX interrupt can arrive in between.
The interrupt handler then disables the virtqueue callback and calls
napi_schedule(), which does nothing because NAPI is still disabled.
napi_enable() does not schedule a poll either, and only the poll
function re-enables the callback, so the queue can stall until the
device happens to send another interrupt.

Schedule NAPI once after napi_enable(), as virtio-net does in
virtnet_napi_do_enable(). This processes buffers that are already used
and re-enables the callback.

Fixes: 083082a4e6d8 ("can: virtio: Add virtio CAN driver")
Cc: stable@vger.kernel.org
Signed-off-by: Seonghyeon Lim <forfortuna@naver.com>
---
 drivers/net/can/virtio_can.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/drivers/net/can/virtio_can.c b/drivers/net/can/virtio_can.c
index f67d0bf09681..9055d7e43235 100644
--- a/drivers/net/can/virtio_can.c
+++ b/drivers/net/can/virtio_can.c
@@ -116,6 +116,19 @@ static void virtio_can_napi_enable(struct virtio_can_priv *priv)
 	if (!priv->napi_active) {
 		napi_enable(&priv->napi);
 		napi_enable(&priv->napi_tx);
+
+		/* An interrupt that arrived while NAPI was disabled has
+		 * disabled the virtqueue callback but could not schedule
+		 * NAPI, so no further interrupt may come. Schedule NAPI once
+		 * to process pending buffers and re-enable the callback.
+		 */
+		local_bh_disable();
+		virtqueue_napi_schedule(&priv->napi,
+					priv->vqs[VIRTIO_CAN_QUEUE_RX]);
+		virtqueue_napi_schedule(&priv->napi_tx,
+					priv->vqs[VIRTIO_CAN_QUEUE_TX]);
+		local_bh_enable();
+
 		priv->napi_active = true;
 	}
 }

-- 
2.43.0

