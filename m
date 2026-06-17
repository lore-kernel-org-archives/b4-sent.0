From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Tue, 16 Jun 2026 20:56:15 -0500
Subject: [PATCH v3] iio: accel: fxls8962af: clamp the device-reported FIFO
 sample count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260616-b4-disp-2e8d94cf-v3-1-c4e092eef3a2@proton.me>
X-B4-Tracking: v=1; b=H4sIAL7+MWoC/x3MQQqAIBBA0avErBswLa2uEi3KGWs2FgoRRHdPW
 r7F/w9kTsIZxuqBxJdkOWKBqSvw+xI3RqFi0EpbZRuLa4sk+UTNPQ2tDxhccEoTOWM7KNmZOMj
 9L6f5fT/3yoFuYgAAAA==
To: Jonathan Cameron <jic23@kernel.org>
Cc: linux-kernel@vger.kernel.org, David Lechner <dlechner@baylibre.com>, 
 linux-iio@vger.kernel.org, Sean Nyekjaer <sean@geanix.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781661374; l=3254;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=EYfWdZDOsGfm+jKR7ChwMWskcYwWWhSAnxO/QMWeWw8=;
 b=K9AHdy7tvI85JfpIVDolk41qGKVXg8rHTKKMFmLUVNIqCo+1DKiEV3Hi7gCLahXu/Z7gLgkOp
 Zm1NYspPsY3CnZY+H/s0serk7QH8AKerPap17lARqBjVPjM2ZDmqNfx
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

fxls8962af_fifo_flush() transfers the sample count the device reports in
BUF_STATUS into an on-stack buffer sized for FXLS8962AF_FIFO_LENGTH (32)
samples, but the count is a 6-bit field (0..63) that is only checked for
zero. A device, or an attacker on the I2C/SPI bus, reporting 33..63
overflows the buffer by up to 186 bytes: a stack out-of-bounds write.

Clamp the count to FXLS8962AF_FIFO_LENGTH before the transfer, mirroring
the clamp already applied in fxls8962af_set_watermark(). Conforming
hardware reports at most that many samples and is unaffected.

Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
v3 (Andy [2]): shrink the commit message; the register/byte detail, the
not-for-stable rationale and the introducing commit moved below the cut.
v2 (Jonathan [1], Andy [2]): clamp with min() instead of min_t(u8, ...);
drop Fixes: and Cc: stable -- this hardens against a malformed
device-reported count, not reachable with conforming hardware ("not a fix
and not back port material", Jonathan).

[1] https://lore.kernel.org/all/20260614144337.3b3dab1a@jic23-huawei/
[2] https://lore.kernel.org/all/ai_RF9BG17SZ7Tiz@ashevche-desk.local/
v1: https://lore.kernel.org/all/20260613-b4-disp-22362900-v1-1-c5e49f6af027@proton.me/
v2: https://lore.kernel.org/all/20260615-b4-disp-1a8c7886-v2-1-072a8d1721e9@proton.me/

count = reg & FXLS8962AF_BUF_STATUS_BUF_CNT is GENMASK(5, 0), so 0..63;
fxls8962af_fifo_transfer() then reads count * 3 * sizeof(u16) bytes, so a
count of 33..63 writes up to 378 bytes into the 192-byte buffer (up to 186
past its end), clobbering the stack canary, saved registers and the return
address. The unbounded count has been present since commit 79e3a5bdd9ef
("iio: accel: fxls8962af: add hw buffered sampling"); not marked for stable
as it needs a malicious or defective device, or bus tampering.

This is a different bug from CVE-2025-38485, the use-after-free in the same
function fixed by commit 1fe16dc1a2f5 ("iio: accel: fxls8962af: Fix use
after free in fxls8962af_fifo_flush"): that commit added a synchronize_irq()
and did not bound the FIFO count, so this overflow is still present at
mainline HEAD.

Verified with an in-kernel KASAN litmus (CONFIG_KASAN_STACK=y) and a
userspace ASan model on x86_64 and i386: without the clamp a device
reporting count=63 drives the transfer 186 bytes past the buffer
(stack-out-of-bounds write, both ABIs); with the clamp it is bounded to 32.
Reproducer and full logs available on request.
---
 drivers/iio/accel/fxls8962af-core.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/iio/accel/fxls8962af-core.c b/drivers/iio/accel/fxls8962af-core.c
index 8763e91c63d2..1ecffbf41f64 100644
--- a/drivers/iio/accel/fxls8962af-core.c
+++ b/drivers/iio/accel/fxls8962af-core.c
@@ -970,6 +970,8 @@ static int fxls8962af_fifo_flush(struct iio_dev *indio_dev)
 	if (!count)
 		return 0;
 
+	count = min(count, FXLS8962AF_FIFO_LENGTH);
+
 	data->old_timestamp = data->timestamp;
 	data->timestamp = iio_get_time_ns(indio_dev);
 

---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260616-b4-disp-2e8d94cf-f7f702dd7365

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

