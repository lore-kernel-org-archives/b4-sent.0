From: Seonghyeon Lim <forfortuna@naver.com>
Subject: [PATCH v2 0/2] can: virtio: fix NAPI stall and virtqueue use
 before DRIVER_OK
Date: Fri, 20 Nov 2026 15:56:02 +0900
Message-Id: <20261120-virtio-can-ready-v2-0-0defda2af8cb@naver.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAALv/2oC/32NwQrCMBBEf0X27EoSaime/A/pIU02dgUT2dRgK
 f1303p3bg9m3iyQSZgyXA4LCBXOnGIFczyAG228E7KvDEaZVtdgYZk4obMRhayfsTs7CiGo1nY
 N1NlLKPBnV976H+f38CA3bZ6tMXKeksz7Z9Fb74++aNSohsZ7ZZQNarhGW0hOLj2hX9f1C7bTZ
 8XCAAAA
X-Change-ID: 20261111-virtio-can-ready-85cefff06a84
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795157866; l=1990;
 i=forfortuna@naver.com; s=20261110; h=from:subject:message-id;
 bh=7UHNUXHJc6SuRgb037ZK+F81kJ4BMtFKgcLw6ppT8Iw=;
 b=3Q0gUda1kTefGJ42u+omhUSG5N2sIBN/ExfcRfS/TewBnuFYwV25TljYIRqMwqwe22X7twi7U
 txOLek6KmiZD2QbBypeEgxrwEDsB7WNDUchgVqdSlbDJBPUd1ybvXL0
X-Developer-Key: i=forfortuna@naver.com; a=ed25519;
 pk=NSzj4ReyzmE01C4q/f+7jqXzWqsN5NwQK5UsSI6ufiE=
X-Endpoint-Received: by B4 Relay for forfortuna@naver.com/20261110 with auth_id=1481
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes two issues in the virtio CAN driver.

Patch 1 fixes an RX/TX stall when an interrupt arrives after the START
command but before NAPI is enabled in virtio_can_open().

Patch 2 calls virtio_device_ready() before the first virtqueue use in
probe and restore. Without it, resume hangs if the interface was up.

Patch 1 goes first: without patch 2, restore hangs waiting for the
START reply before it reaches that window, so patch 2 alone would
expose the stall.

The interrupt handlers could also use virtqueue_napi_schedule() like
virtio-net does. I left that for a follow-up cleanup.

Tested with QEMU 8.2 and vhost-device-can:
- With the interface up, suspend/resume (pm_test=devices) hangs
  without patch 2 and completes with the series.
- With a temporary delay before napi_enable() and continuous traffic,
  RX interrupts arrive while NAPI is disabled and napi_schedule_prep()
  fails. With patch 1, NAPI is scheduled right after napi_enable() and
  the RX poll runs without waiting for another interrupt.
  vhost-device-can keeps sending interrupts, which hides the stall
  without patch 1.
- RX traffic and repeated down/up work. No lockdep warnings.

---
Changes in v2:
- Add patch 1 for the NAPI stall reported by sashiko-bot. With patch 2
  the restore path can reach it (Michael's question about callbacks
  after virtio_device_ready()).
- Patch 2: describe the callbacks, add the hung task trace and
  Cc: stable.
- Link to v1: https://patch.msgid.link/20261111-virtio-can-ready-v1-1-0b4dd020af0b@naver.com

---
Seonghyeon Lim (2):
      can: virtio: fix RX/TX stall on interrupt before NAPI is enabled
      can: virtio: fix virtqueue use before DRIVER_OK

 drivers/net/can/virtio_can.c | 19 +++++++++++++++++++
 1 file changed, 19 insertions(+)
---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261111-virtio-can-ready-85cefff06a84

Best regards,
--  
Seonghyeon Lim <forfortuna@naver.com>

