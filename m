From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Mon, 22 Jun 2026 03:55:13 -0500
Subject: [PATCH v4] iio: imu: inv_icm45600: clamp the device-reported FIFO
 sample count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260622-b4-disp-ca8d55df-v4-1-e306208ecbb0@proton.me>
X-B4-Tracking: v=1; b=H4sIAHD4OGoC/x3MPQqAMAxA4atIZgMaTf25ijhoGzVLlRZEkN7d4
 vgN770QJahEGIsXgtwa9fQZbVmAPRa/C6rLBqrIVIYI1xadxgvt0jtmt6FpBivMTcc1Qc6uIJs
 +/3KaU/oAByG122IAAAA=
To: Jonathan Cameron <jic23@kernel.org>, 
 Remi Buisson <remi.buisson@tdk.com>
Cc: David Lechner <dlechner@baylibre.com>, linux-kernel@vger.kernel.org, 
 linux-iio@vger.kernel.org, =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782118512; l=4600;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=xe1uIrNY7gVIBxa290oSlcAmIpUHYZrdadGSkjhELaI=;
 b=QQ5eQ4tI9Yqb3Hr8bVElRTvXB2EBhkg7jiFFTXerEl3cTtmmQFsc6E2y+R6StNHelF0GXigIX
 s1RuWB0EEAZCzQT0tCmqjU2c6+OHTT/nu1v9bJ0DTQQJpbD2BB9t4YL
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

inv_icm45600_buffer_fifo_read() uses the FIFO_COUNT the device reports,
unclamped, as the length of a regmap_noinc_read() into the fixed
INV_ICM45600_FIFO_SIZE_MAX (8 KiB) st->fifo.data buffer. The only bound is
the caller's "max", which the interrupt path skips (it passes 0). A device,
or an attacker on the bus, reporting up to 65535 makes the read as large as
~1 MiB: a heap out-of-bounds write of device-controlled data.

Clamp st->fifo.count to the buffer capacity before the read, and allocate
the buffer with the same INV_ICM45600_FIFO_SIZE_MAX define, so the bound
and the allocation reference one constant. The clamp is a no-op for
conforming hardware.

Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
v4 (Jonathan [3]): clamp the byte count directly --
    st->fifo.count = min(fifo_nb * packet_size, INV_ICM45600_FIFO_SIZE_MAX) --
    rather than dividing then multiplying by packet_size. fifo_nb is unused
    after this point (the read, the one-by-one fallback and the decode loop all
    bound on st->fifo.count), so clamping the byte count is sufficient. Also
    allocate st->fifo.data with INV_ICM45600_FIFO_SIZE_MAX in _core.c (was a
    bare 8192) so the allocation and the clamp reference one define.
v3 (Andy [2]): shrink the commit message; register/byte detail below the cut.
v2 (Jonathan [1]): use min() instead of min_t(size_t, ...); drop the backport
    tags -- hardening against a malformed device-reported count, not reachable
    with conforming hardware.

[1] https://lore.kernel.org/all/20260614144557.196a5c4c@jic23-huawei/
[2] https://lore.kernel.org/all/ajEMfH-_76M1OBqE@ashevche-desk.local/
[3] https://lore.kernel.org/all/20260621190804.04894168@jic23-huawei/
v1: https://lore.kernel.org/all/20260613-b4-disp-58b984f3-v1-1-352b2f925f58@proton.me/
v2: https://lore.kernel.org/all/20260615-b4-disp-feb19207-v2-1-2d36f1e5fc54@proton.me/
v3: https://lore.kernel.org/all/20260616-b4-disp-76e3f743-v3-1-c20930aaf1cb@proton.me/

fifo_nb = le16_to_cpup(raw_fifo_count) is 0..65535; the interrupt handler calls
inv_icm45600_buffer_fifo_read(st, 0), so the "max" clamp is skipped, and
fifo_nb * packet_size (16 bytes per packet) reaches ~1 MiB into the 8 KiB
buffer. Present since 06674a72cf7a ("iio: imu: inv_icm45600: add buffer support
in iio devices"); not marked for stable as it needs a malicious or defective
device, or bus tampering.

Reproduced with an in-kernel KASAN litmus and a userspace ASan model: without
the clamp a FIFO_COUNT of 0x208 (520 packets -> 8320 bytes) gives a
slab-out-of-bounds write past the 8192-byte region, and 0xFFFF (1048560 bytes)
reproduces under ASan on x86_64 and i386; with the clamp the read is bounded to
the buffer. Reproducer and full logs available on request.
---
 drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c | 7 +++++--
 drivers/iio/imu/inv_icm45600/inv_icm45600_core.c   | 2 +-
 2 files changed, 6 insertions(+), 3 deletions(-)

diff --git a/drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c b/drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c
index 2b9ea317385c..42111c543d3c 100644
--- a/drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c
+++ b/drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c
@@ -422,8 +422,11 @@ int inv_icm45600_buffer_fifo_read(struct inv_icm45600_state *st,
 	if (max > 0 && fifo_nb > max)
 		fifo_nb = max;
 
-	/* Try to read all FIFO data in internal buffer. */
-	st->fifo.count = fifo_nb * packet_size;
+	/*
+	 * Read all FIFO data into the internal buffer, clamping the
+	 * device-reported count to the buffer capacity.
+	 */
+	st->fifo.count = min(fifo_nb * packet_size, INV_ICM45600_FIFO_SIZE_MAX);
 	ret = regmap_noinc_read(st->map, INV_ICM45600_REG_FIFO_DATA,
 				st->fifo.data, st->fifo.count);
 	if (ret == -ENOTSUPP || ret == -EFBIG) {
diff --git a/drivers/iio/imu/inv_icm45600/inv_icm45600_core.c b/drivers/iio/imu/inv_icm45600/inv_icm45600_core.c
index d49053161a65..c1d7aa7e950d 100644
--- a/drivers/iio/imu/inv_icm45600/inv_icm45600_core.c
+++ b/drivers/iio/imu/inv_icm45600/inv_icm45600_core.c
@@ -716,7 +716,7 @@ int inv_icm45600_core_probe(struct regmap *regmap, const struct inv_icm45600_chi
 
 	dev_set_drvdata(dev, st);
 
-	st->fifo.data = devm_kzalloc(dev, 8192, GFP_KERNEL);
+	st->fifo.data = devm_kzalloc(dev, INV_ICM45600_FIFO_SIZE_MAX, GFP_KERNEL);
 	if (!st->fifo.data)
 		return -ENOMEM;
 

---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260622-b4-disp-ca8d55df-639ce5537512

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

