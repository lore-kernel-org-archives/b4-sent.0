From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Mon, 15 Jun 2026 15:43:17 -0500
Subject: [PATCH v2] iio: accel: bmc150: clamp the device-reported FIFO
 frame count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260615-b4-disp-ef4f7a59-v2-1-af5e980bcdd7@proton.me>
X-B4-Tracking: v=1; b=H4sIAORjMGoC/x3MQQqAIBBA0avErBswS8uuEi2mHGs2FgoRRHdPW
 r7F/w9kTsIZxuqBxJdkOWKBritYd4obo/hi0EpbZRuDS4de8okcutCTcdgqGpyzREY7KNmZOMj
 9L6f5fT8b2nTZYgAAAA==
To: Jonathan Cameron <jic23@kernel.org>
Cc: Andy Shevchenko <andy@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, linux-kernel@vger.kernel.org, 
 linux-iio@vger.kernel.org, =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781556196; l=3276;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=E/bT4EkVn+3iqP2XSaNpCV/pBBTqGy2zQ21wB6ceRL4=;
 b=PXWkrkqYThMHD3rxqBUcbkAjG9XFvr/XtEHGnLGpaM6Rl8UniD1G4+hYuGQvmXh5B1lWL8K7z
 9qyuqeCpzzNCP7N6DkgCr/ntZiTPcLbb9fV3aTwTdbmmD3I//M3J+vG
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
v2: use min() instead of min_t(u8, ...) per Jonathan Cameron's review [1].
    count is u8 and BMC150_ACCEL_FIFO_LENGTH is 32, so min() does the
    comparison as int and the clamped result (<= 32) fits back in count;
    builds clean under make W=1.

[1] https://lore.kernel.org/all/20260614141146.697dde04@jic23-huawei/
v1: https://lore.kernel.org/all/20260613-b4-disp-24d6b15f-v1-1-f5c3fe7294fc@proton.me/

Reachable on every FIFO flush (watermark IRQ or the sysfs buffer-disable
an in-kernel KASAN litmus (CONFIG_KASAN_STACK=y) and a userspace ASan model
on x86_64 and i386: without the clamp, a device reporting 127 frames drives
bmc150_accel_fifo_transfer() past the 192-byte on-stack buffer (stack
out-of-bounds write); with the clamp it is bounded to 32. Reproducer and
full logs available on request.

path: bmc150_accel_fifo_flush -> __bmc150_accel_fifo_flush). Verified with
---
 drivers/iio/accel/bmc150-accel-core.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/iio/accel/bmc150-accel-core.c b/drivers/iio/accel/bmc150-accel-core.c
index 2398eb7e12cd..24152be18cb4 100644
--- a/drivers/iio/accel/bmc150-accel-core.c
+++ b/drivers/iio/accel/bmc150-accel-core.c
@@ -991,6 +991,8 @@ static int __bmc150_accel_fifo_flush(struct iio_dev *indio_dev,
 	if (samples && count > samples)
 		count = samples;
 
+	count = min(count, BMC150_ACCEL_FIFO_LENGTH);
+
 	ret = bmc150_accel_fifo_transfer(data, (u8 *)buffer, count);
 	if (ret)
 		return ret;

---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260615-b4-disp-ef4f7a59-30a8996aa529

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

