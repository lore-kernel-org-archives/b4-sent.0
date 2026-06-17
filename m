From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Tue, 16 Jun 2026 20:57:28 -0500
Subject: [PATCH v3] iio: imu: inv_icm45600: clamp the device-reported FIFO
 sample count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260616-b4-disp-76e3f743-v3-1-c20930aaf1cb@proton.me>
X-B4-Tracking: v=1; b=H4sIAAf/MWoC/x3MQQqAIBBA0avErBsolbG6SrSoHGs2JQoRiHdPW
 r7F/xkSR+EEU5Mh8iNJ7qtCtw3s53odjOKqQXWKOuoJN4NOUkBLrL01GsfBKbNbppUN1CxE9vL
 +y3kp5QPHnSCzYgAAAA==
To: Remi Buisson <remi.buisson@tdk.com>, 
 Jonathan Cameron <jic23@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781661447; l=3241;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=eW5J0QMRckFzzjMN390KcVFdu6pXodW5o1qjHfegiwM=;
 b=nPV0rM9j+MBsRn3+QL/trmgMPBHPJv6rucTuasakqBRJadcJdkMtaz2/yv1WVv3vov1JyhF6e
 uL01fON7sjyDCn3w+UI8O7LWlOZ/7ig95hQd9cIhuqAECrEw+1bBxMb
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

inv_icm45600_buffer_fifo_read() uses the FIFO_COUNT the device reports,
unclamped, as the length of a regmap_noinc_read() into the fixed 8 KiB
st->fifo.data buffer. The only bound is the caller's "max", which the
interrupt path skips (it passes 0). A device, or an attacker on the bus,
reporting up to 65535 makes the read as large as ~1 MiB: a heap
out-of-bounds write of device-controlled data.

Clamp fifo_nb to the buffer capacity (INV_ICM45600_FIFO_SIZE_MAX /
packet_size) before the read, mirroring the watermark cap in
inv_icm45600_wm_truncate() and the sibling inv_icm42600 driver. The clamp
is a no-op for conforming hardware.

Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
v3 (Andy [2]): shrink the commit message; the register/byte detail, the
not-for-stable rationale and the introducing commit moved below the cut.
v2 (Jonathan [1]): use min() instead of min_t(size_t, ...), and drop the
backport tags -- this is hardening against a malformed device-reported
count, not reachable with conforming hardware ("nice to have hardening",
Jonathan).

[1] https://lore.kernel.org/all/20260614144557.196a5c4c@jic23-huawei/
[2] https://lore.kernel.org/all/ajEMfH-_76M1OBqE@ashevche-desk.local/
v1: https://lore.kernel.org/all/20260613-b4-disp-58b984f3-v1-1-352b2f925f58@proton.me/
v2: https://lore.kernel.org/all/20260615-b4-disp-feb19207-v2-1-2d36f1e5fc54@proton.me/

fifo_nb = le16_to_cpup(raw_fifo_count) is 0..65535; the interrupt handler
calls inv_icm45600_buffer_fifo_read(st, 0), so the "max" clamp is skipped,
and fifo_nb * packet_size (16 bytes per packet) reaches ~1 MiB into the
8 KiB st->fifo.data buffer. Present since 06674a72cf7a ("iio: imu:
inv_icm45600: add buffer support in iio devices"); not marked for stable as
it needs a malicious or defective device, or bus tampering.

Reproduced with an in-kernel KASAN litmus and a userspace ASan model:
without the clamp a FIFO_COUNT of 0x208 (520 packets -> 8320 bytes) gives a
slab-out-of-bounds write past the 8192-byte region, and the full magnitude
(0xFFFF -> 1048560 bytes) reproduces under ASan on x86_64 and i386; with the
clamp the read is bounded to the buffer. Reproducer and full logs available
on request.
---
 drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c b/drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c
index 2b9ea317385c..5cde42f70c2e 100644
--- a/drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c
+++ b/drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c
@@ -422,6 +422,9 @@ int inv_icm45600_buffer_fifo_read(struct inv_icm45600_state *st,
 	if (max > 0 && fifo_nb > max)
 		fifo_nb = max;
 
+	/* Limit to the internal buffer capacity; the count is device-provided. */
+	fifo_nb = min(fifo_nb, INV_ICM45600_FIFO_SIZE_MAX / packet_size);
+
 	/* Try to read all FIFO data in internal buffer. */
 	st->fifo.count = fifo_nb * packet_size;
 	ret = regmap_noinc_read(st->map, INV_ICM45600_REG_FIFO_DATA,

---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260616-b4-disp-76e3f743-98d24c7e6ae4

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

