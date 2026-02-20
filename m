From: Radu Sabau <radu.sabau@analog.com>
Date: Fri, 20 Feb 2026 16:16:41 +0200
Subject: [PATCH v2] iio: imu: adis: Fix NULL pointer dereference in
 adis_init
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260220-adis-fix-v2-1-4cc24a261306@analog.com>
X-B4-Tracking: v=1; b=H4sIAMhsmGkC/22MQQrCMBAAv1L27EqyqK2e/If0sKSbdkETSSQoJ
 X839uxxhmFWyJJUMly6FZIUzRpDA9p14BYOs6BOjYEMnQyRQZ40o9c32r53bA7mOA0MLX8maXp
 b3cbGi+ZXTJ/tXOzP/pkUixbPnq1xTgZL/sqB73Heu/iAsdb6BXwUTcKhAAAA
X-Change-ID: 20260220-adis-fix-177ca0405d8a
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Nuno Sa <nuno.sa@analog.com>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Robert Budai <robert.budai@analog.com>, 
 Antoniu Miclaus <antoniu.miclaus@analog.com>, 
 Ramona Gradinariu <ramona.gradinariu@analog.com>
Cc: Jonathan Cameron <Jonathan.Cameron@huawei.com>, 
 linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Radu Sabau <radu.sabau@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771597002; l=3393;
 i=radu.sabau@analog.com; s=20260220; h=from:subject:message-id;
 bh=j7cynfRXNkYO1RlmBQEKsd6iLn8cQ9DPq0pFxeWKoVc=;
 b=VZwmslO2FNTnjjbSNylbaZMamDujGeJcM7vTTCrv93vtTDh2f2PDkF24gUuH9mf5cp5j8oZug
 RfnQeyM6zEFDTYHZTs8zb/UwENY9MqkXp4arbRbdNnqzsOU9XGEDLji
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=lDPQHgn9jTdt0vo58Na9lLxLaE2mb330if71Cn+EvFU=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20260220 with auth_id=642
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The adis_init() function dereferences adis->ops to check if the
individual function pointers (write, read, reset) are NULL, but does
not first check if adis->ops itself is NULL.

Drivers like adis16480, adis16490, adis16545 and others do not set
custom ops and rely on adis_init() assigning the defaults. Since struct
adis is zero-initialized by devm_iio_device_alloc(), adis->ops is NULL
when adis_init() is called, causing a NULL pointer dereference:

    Unable to handle kernel NULL pointer dereference at virtual address 0000000000000000
    pc : adis_init+0xc0/0x118
    Call trace:
     adis_init+0xc0/0x118
     adis16480_probe+0xe0/0x670

Fix this by checking if adis->ops is NULL before dereferencing it,
falling through to assign the default ops in that case.

Fixes: 3b29bcee8f6f ("iio: imu: adis: Add custom ops struct")
Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
adis_init() dereferences adis->ops to validate its function pointers
  before checking whether adis->ops itself is NULL. Drivers that rely on
  the default ops (adis16480, adis16490, adis16545, among others) never
  set adis->ops prior to calling adis_init(), so the field is NULL due to
  zero-initialisation by devm_iio_device_alloc(). The result is a kernel
  crash on probe:

      Unable to handle kernel NULL pointer dereference at virtual address 0000000000000000
      Hardware name: Raspberry Pi 5 Model B Rev 1.0 (DT)
      pc : adis_init+0xc0/0x118
      lr : adis_init+0x50/0x118
      Call trace:
       adis_init+0xc0/0x118
       adis16480_probe+0xe0/0x670
       spi_probe+0x8c/0xf8
       really_probe+0xc4/0x2b0

  The bug was introduced in 3b29bcee8f6f ("iio: imu: adis: Add custom ops struct")
  which added the ops validation logic without a prior NULL check
  on the pointer itself.

  The fix is a one-line addition of !adis->ops to the condition, so that
  a NULL ops pointer is treated the same as an ops struct with all-NULL
  function pointers, both falling through to the default ops assignment.
  The validation path for partially-populated custom ops structs is
  unchanged.

  Tested on Raspberry Pi 5 with adis16545-3 connected over SPI. Without
  the fix the kernel crashes at adis_init+0xc0. With the fix the driver
  probes successfully and the device is accessible via the IIO subsystem.
---
Changes in v2:
- put stack trace in a single line in the commit body
- split long line if in multiple statements and removed the redundant ones
- use correct git hash for fixes tag
- Link to v1: https://lore.kernel.org/r/20260220-adis-fix-v1-1-9fa10cce812f@analog.com
---
 drivers/iio/imu/adis.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/imu/adis.c b/drivers/iio/imu/adis.c
index d160147cce0b..a2bc1d14ed91 100644
--- a/drivers/iio/imu/adis.c
+++ b/drivers/iio/imu/adis.c
@@ -526,7 +526,7 @@ int adis_init(struct adis *adis, struct iio_dev *indio_dev,
 
 	adis->spi = spi;
 	adis->data = data;
-	if (!adis->ops->write && !adis->ops->read && !adis->ops->reset)
+	if (!adis->ops)
 		adis->ops = &adis_default_ops;
 	else if (!adis->ops->write || !adis->ops->read || !adis->ops->reset)
 		return -EINVAL;

---
base-commit: 8bf22c33e7a172fbc72464f4cc484d23a6b412ba
change-id: 20260220-adis-fix-177ca0405d8a

Best regards,
-- 
Radu Sabau <radu.sabau@analog.com>

