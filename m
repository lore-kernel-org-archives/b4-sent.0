From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Tue, 16 Jun 2026 20:56:51 -0500
Subject: [PATCH v3] iio: accel: bmc150: clamp the device-reported FIFO
 frame count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260616-b4-disp-9546bfb4-v3-1-5acc59a06636@proton.me>
X-B4-Tracking: v=1; b=H4sIAOL+MWoC/x3MQQqAIBBA0avErBNMc6CuEi1Mx5pNiQMRhHdPW
 r7F/y8IFSaBuXuh0M3C19lg+w7C4c+dFMdmMNqgxgHVNqrIktXkRtxSkzcYnEvWUgrQslwo8fM
 vl7XWDwIpZBliAAAA
To: Jonathan Cameron <jic23@kernel.org>
Cc: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781661410; l=3194;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=pmJWBQpt24Fy41JehEcTsvmC6VykaNqWCyEqfXHULzw=;
 b=vqMn4SiapVb2QLSypCbL9iOUozRq9BlH2+V3VO4wM50fho0SOWfM3jZeiQsM+RNgj5dB7NBAf
 VuNkVeK+LVLDfBgG6BEXavySPA1zzD5ZD/BHFHbF5HumOhV6o/RjHIS
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__bmc150_accel_fifo_flush() transfers the frame count the device reports
in FIFO_STATUS into an on-stack buffer sized for BMC150_ACCEL_FIFO_LENGTH
(32) samples, but the count is masked to 7 bits (0..127) and the optional
caller budget does not bound the flush-all path. A device, or an attacker
on the I2C/SPI bus, reporting up to 127 frames overflows the buffer by up
to 570 bytes: a stack out-of-bounds write.

Clamp the count to BMC150_ACCEL_FIFO_LENGTH before the transfer, mirroring
the clamp already applied in bmc150_accel_set_watermark(). Conforming
hardware reports at most that many frames and is unaffected.

Fixes: 3bbec9773389 ("iio: bmc150_accel: add support for hardware fifo")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
v3 (Andy [2], [3]): shrink the commit message and move the register/byte
detail below the cut; fold the caller budget and the clamp into min3()/min()
per Andy [3] (no functional change; make W=1 clean).
v2 (Jonathan [1]): clamp with min() instead of min_t(u8, ...).

[1] https://lore.kernel.org/all/20260614141146.697dde04@jic23-huawei/
[2] https://lore.kernel.org/all/ajEMUChqvxGzSLl_@ashevche-desk.local/
[3] https://lore.kernel.org/all/ajELw0x5DiyMuFYZ@ashevche-desk.local/
v1: https://lore.kernel.org/all/20260613-b4-disp-24d6b15f-v1-1-f5c3fe7294fc@proton.me/
v2: https://lore.kernel.org/all/20260615-b4-disp-ef4f7a59-v2-1-af5e980bcdd7@proton.me/

count = val & 0x7F is 0..127; the only other limit is the optional caller
budget, which does not constrain the flush-all path (samples == 0).
bmc150_accel_fifo_transfer() reads count * 6 bytes, so a count of up to 127
writes up to 762 bytes into the 192-byte buffer (up to 570 past its end),
clobbering the stack canary, saved registers and the return address.

Reachable on every FIFO flush (watermark IRQ or the sysfs buffer-disable
path). Verified with an in-kernel KASAN litmus (CONFIG_KASAN_STACK=y) and a
userspace ASan model on x86_64 and i386: without the clamp a device
reporting 127 frames drives the transfer past the 192-byte buffer (stack
out-of-bounds write, both ABIs); with the clamp it is bounded to 32.
Reproducer and full logs available on request.
---
 drivers/iio/accel/bmc150-accel-core.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/accel/bmc150-accel-core.c b/drivers/iio/accel/bmc150-accel-core.c
index 2398eb7e12cd..ecaa4782d847 100644
--- a/drivers/iio/accel/bmc150-accel-core.c
+++ b/drivers/iio/accel/bmc150-accel-core.c
@@ -988,8 +988,10 @@ static int __bmc150_accel_fifo_flush(struct iio_dev *indio_dev,
 	do_div(sample_period, count);
 	tstamp = data->timestamp - (count - 1) * sample_period;
 
-	if (samples && count > samples)
-		count = samples;
+	if (samples)
+		count = min3(count, samples, BMC150_ACCEL_FIFO_LENGTH);
+	else
+		count = min(count, BMC150_ACCEL_FIFO_LENGTH);
 
 	ret = bmc150_accel_fifo_transfer(data, (u8 *)buffer, count);
 	if (ret)

---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260616-b4-disp-9546bfb4-a26c55f33efc

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

