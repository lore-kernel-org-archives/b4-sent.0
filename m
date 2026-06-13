From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 13 Jun 2026 02:18:39 -0500
Subject: [PATCH] iio: accel: bmc150: clamp the device-reported FIFO frame
 count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260613-b4-disp-24d6b15f-v1-1-f5c3fe7294fc@proton.me>
X-B4-Tracking: v=1; b=H4sIAE4ELWoC/x3MTQqAIBBA4avErBtwzOznKtEidazZVChEEN09a
 fkt3nsgcxLOMFYPJL4ky7EXUF2B35Z9ZZRQDFppqyw16AwGySdqE6yjNuKgojJ9t3gyBCU7E0e
 5/+U0v+8HSXP1QWIAAAA=
To: Jonathan Cameron <jic23@kernel.org>
Cc: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Lechner <dlechner@baylibre.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781335118; l=2375;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=BlBnpxJiHdoVhKcQyHWqtLmOf+xPJntNmXmoR7QP7Mo=;
 b=K4toF6bP8tRu8uvSDwLphnxmaFs6rz+guUa8/XJfl6KSharoVchFhd8IZwRrQt/3kpuJmEztN
 zNNC8j/YxtTDesRP86U93k4oaBuSJ59+38Ph6KOfQR4KRYzlhrC7klJ
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__bmc150_accel_fifo_flush() copies the number of samples the device
reports in its hardware FIFO into an on-stack buffer

	u16 buffer[BMC150_ACCEL_FIFO_LENGTH * 3];

which is sized for at most BMC150_ACCEL_FIFO_LENGTH (32) samples. The
frame count is read from the FIFO_STATUS register and only masked to its
7 valid bits:

	count = val & 0x7F;

so it can be 0..127. The only other limit applied to it is the optional
caller-supplied sample budget:

	if (samples && count > samples)
		count = samples;

which does not constrain count on the flush-all path (samples == 0), and
leaves it well above 32 whenever samples is larger. count samples are
then transferred into buffer[]:

	bmc150_accel_fifo_transfer(data, (u8 *)buffer, count);

bmc150_accel_fifo_transfer() reads count * 6 bytes through regmap, so a
malfunctioning, malicious or counterfeit accelerometer (or an attacker
tampering with the I2C/SPI bus) that reports up to 127 frames writes up
to 762 bytes into the 192-byte buffer: a stack out-of-bounds write of up
to 570 bytes that clobbers the stack canary, saved registers and the
return address.

Clamp count to BMC150_ACCEL_FIFO_LENGTH, the number of samples buffer[]
is sized for, before the transfer, mirroring the watermark clamp already
done in bmc150_accel_set_watermark(). A well-formed flush reports at most
BMC150_ACCEL_FIFO_LENGTH frames, so legitimate devices are unaffected.

Fixes: 3bbec9773389 ("iio: bmc150_accel: add support for hardware fifo")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 drivers/iio/accel/bmc150-accel-core.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/iio/accel/bmc150-accel-core.c b/drivers/iio/accel/bmc150-accel-core.c
index 2398eb7e12cd..dc8a6285cf3d 100644
--- a/drivers/iio/accel/bmc150-accel-core.c
+++ b/drivers/iio/accel/bmc150-accel-core.c
@@ -991,6 +991,8 @@ static int __bmc150_accel_fifo_flush(struct iio_dev *indio_dev,
 	if (samples && count > samples)
 		count = samples;
 
+	count = min_t(u8, count, BMC150_ACCEL_FIFO_LENGTH);
+
 	ret = bmc150_accel_fifo_transfer(data, (u8 *)buffer, count);
 	if (ret)
 		return ret;

---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260613-b4-disp-24d6b15f-90f0487ac141

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

