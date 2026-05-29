From: Alexis Bouzigues <BouziguesAlexis@JohnDeere.com>
Date: Fri, 29 May 2026 09:28:14 -0500
Subject: [PATCH] i2c: virtio: mark device ready before registering the
 adapter
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260529-virtio-i2c-driver-ok-v1-1-ecf2504f6a56@JohnDeere.com>
X-B4-Tracking: v=1; b=H4sIAH2iGWoC/x3MQQqDMBBG4avIrB3QaZTGq4iLkoztT8HIRIIg3
 r2hy2/x3kVZDZppai4yLchIW0XfNhQ+r+2tjFhN0snYDeK5wA4khgSOhqLG6ct+dM4F0eHhn1T
 T3XTF+d/Oy33/ABQZNFdmAAAA
To: Viresh Kumar <viresh.kumar@linaro.org>, 
 Andi Shyti <andi.shyti@kernel.org>
Cc: linux-i2c@vger.kernel.org, virtualization@lists.linux.dev, 
 linux-kernel@vger.kernel.org, 
 Alexis Bouzigues <BouziguesAlexis@JohnDeere.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780064893; l=1298;
 i=BouziguesAlexis@JohnDeere.com; s=20260527; h=from:subject:message-id;
 bh=iPwimaClnP4+pM+SMSAbPbbHxIEK/XLSHtxDtApz4AY=;
 b=eToR/52uFUF29AE4RN1+uvqSOsg3sZ2bMRNc1c29cCgA5nCagFpEEoIkP0QMJovGBAwjUJQeS
 oMRbCXyXn2GA7QEhvCEG3Sea87kyPPzWzbuJFXhdqGPnqma3u/p2TJD
X-Developer-Key: i=BouziguesAlexis@JohnDeere.com; a=ed25519;
 pk=5KJ7ArL00x5flpPhi9zRLC2p88V1rZXDQ5SXhpRvTDk=
X-Endpoint-Received: by B4 Relay for BouziguesAlexis@JohnDeere.com/20260527 with auth_id=797
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

virtio_i2c_probe() synchronously probes child i2c drivers on the bus,
but peripherals may use the bus at probe for tasks like reading a chip
id. The vhost-user-i2c backend stalls at such probes unless DRIVER_OK
is already set before the virtqueue is first kicked.

Set DRIVER_OK explicitly before i2c_add_adapter(), as done for the
same reason in commit f5866db64f34 ("virtio_console: enable VQs
early") and commit 71e4b8bf0482 ("virtio_rpmsg: set DRIVER_OK before
using device").

Signed-off-by: Alexis Bouzigues <BouziguesAlexis@JohnDeere.com>
---
 drivers/i2c/busses/i2c-virtio.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/i2c/busses/i2c-virtio.c b/drivers/i2c/busses/i2c-virtio.c
index 7b0b0bff8000..5da6fef92bec 100644
--- a/drivers/i2c/busses/i2c-virtio.c
+++ b/drivers/i2c/busses/i2c-virtio.c
@@ -222,6 +222,8 @@ static int virtio_i2c_probe(struct virtio_device *vdev)
 	 */
 	ACPI_COMPANION_SET(&vi->adap.dev, ACPI_COMPANION(vdev->dev.parent));
 
+	virtio_device_ready(vdev);
+
 	ret = i2c_add_adapter(&vi->adap);
 	if (ret)
 		virtio_i2c_del_vqs(vdev);

---
base-commit: 7fd2df204f342fc17d1a0bfcd474b24232fb0f32
change-id: 20260529-virtio-i2c-driver-ok-96444c2e5398

Best regards,
-- 
Alexis Bouzigues <BouziguesAlexis@JohnDeere.com>

