From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 13 Jun 2026 17:46:47 -0500
Subject: [PATCH] iio: imu: inv_icm45600: clamp the device-reported FIFO
 sample count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260613-b4-disp-58b984f3-v1-1-352b2f925f58@proton.me>
X-B4-Tracking: v=1; b=H4sIANbdLWoC/x3MQQqAIBBA0avErBvQNNGuEi1Sx5qNhUIE0d2Tl
 m/x/wOVClOFqXug0MWVj9wg+w7CvuaNkGMzDGIwwkiFXmPkeuJovbM6KVRESQgXtFUBWnYWSnz
 /y3l53w/F0hEGYgAAAA==
To: Jonathan Cameron <jic23@kernel.org>, 
 Remi Buisson <remi.buisson@tdk.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781390806; l=3435;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=v9HoACtqsgCt5jGG137Jw9QKYokE8rIehp0YKXfbLsQ=;
 b=71Phw+TgwC3If+2IjJnDpn664vnnU5uqlLYSibalvvYCC/VSOL54m6xH2pxzGtTieNJ96NDKi
 nEpnwrWwVbCB7PwBem+A9DTWH4/MOfzFh3LXHG6VcU0VNau16GQpA0g
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

inv_icm45600_buffer_fifo_read() takes the number of samples to fetch from
the device's FIFO_COUNT register and uses it, unclamped, as the length of a
regmap_noinc_read() into the fixed 8 KiB st->fifo.data buffer:

	fifo_nb = le16_to_cpup(raw_fifo_count);
	...
	if (max > 0 && fifo_nb > max)
		fifo_nb = max;
	st->fifo.count = fifo_nb * packet_size;
	regmap_noinc_read(st->map, INV_ICM45600_REG_FIFO_DATA,
			  st->fifo.data, st->fifo.count);

The only bound on fifo_nb is "max", but the interrupt handler calls
inv_icm45600_buffer_fifo_read(st, 0), so on that path the clamp is
skipped. A malfunctioning or malicious device (a counterfeit or
compromised IMU, or a bus interposer) can then report up to 65535 in
FIFO_COUNT, making fifo_nb * packet_size (16 bytes per packet) as large
as ~1 MiB and overflowing the 8 KiB st->fifo.data heap buffer with
device-controlled data.

Clamp fifo_nb to the buffer capacity (INV_ICM45600_FIFO_SIZE_MAX /
packet_size), mirroring the existing watermark cap in
inv_icm45600_wm_truncate() and the sibling inv_icm42600 driver, which
bounds its FIFO count to the buffer size. The clamp is a no-op for
well-behaved hardware, whose FIFO never exceeds the buffer size.

Fixes: 06674a72cf7a ("iio: imu: inv_icm45600: add buffer support in iio devices")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Reproduced with an in-kernel KASAN litmus mirroring the exact allocation and
the FIFO_COUNT -> regmap_noinc_read() length computation, plus a userspace
AddressSanitizer model for the full magnitude:

  Without this patch (device FIFO_COUNT = 0x208 = 520 packets -> 8320 bytes):
    BUG: KASAN: slab-out-of-bounds ... Write of size 8320
    ... the buggy address belongs to the cache kmalloc-8k of size 8192
    ... located 0 bytes inside of allocated 8192-byte region
  With this patch (count clamped to 8192 bytes): clean, no KASAN report.
  ASan model at the full magnitude (FIFO_COUNT = 0xFFFF -> 1048560 bytes):
    AddressSanitizer: heap-buffer-overflow WRITE of size 1048560,
    0 bytes after the 8192-byte region (reproduces on 64- and 32-bit).

The sibling inv_icm42600 driver bounds its FIFO count to the buffer size on
the same interrupt path (max == 0 -> max_count = sizeof(st->fifo.data)); this
restores the equivalent guard for inv_icm45600.

Reproducer and full logs available on request.
---
 drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c b/drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c
index 2b9ea317385c..0021c3dc0888 100644
--- a/drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c
+++ b/drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c
@@ -422,6 +422,9 @@ int inv_icm45600_buffer_fifo_read(struct inv_icm45600_state *st,
 	if (max > 0 && fifo_nb > max)
 		fifo_nb = max;
 
+	/* Limit to the internal buffer capacity; the count is device-provided. */
+	fifo_nb = min_t(size_t, fifo_nb, INV_ICM45600_FIFO_SIZE_MAX / packet_size);
+
 	/* Try to read all FIFO data in internal buffer. */
 	st->fifo.count = fifo_nb * packet_size;
 	ret = regmap_noinc_read(st->map, INV_ICM45600_REG_FIFO_DATA,

---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260613-b4-disp-58b984f3-3eef009c483c

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

