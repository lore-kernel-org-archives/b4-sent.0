From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Mon, 15 Jun 2026 15:57:38 -0500
Subject: [PATCH v2] iio: accel: fxls8962af: clamp the device-reported FIFO
 sample count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260615-b4-disp-1a8c7886-v2-1-0f0a2c48d840@proton.me>
X-B4-Tracking: v=1; b=H4sIAEFnMGoC/x3MQQqAIBBA0avErBvQodS6SrSwnGo2FgoRhHdPW
 r7F/y9kTsIZxuaFxLdkOWMFtQ2sh487o4RqIEVGGd3j0mGQfKH2brXOGVSWvAvakuYBanYl3uT
 5l9Ncygfc0ZhtYgAAAA==
To: Jonathan Cameron <jic23@kernel.org>
Cc: linux-kernel@vger.kernel.org, Sean Nyekjaer <sean@geanix.com>, 
 Andy Shevchenko <andy@kernel.org>, linux-iio@vger.kernel.org, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781557057; l=4141;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=7n2Pt8AECslmDb9tBXp70RdCBntCY6xu0S7mqDS1qaA=;
 b=IRdbfJp45D6RJ0tiSTa45mChcYuEsL67Acdh1+e/hhTVEFr1BkA2VuDwg/COanucRNN15t3/o
 jEyDaMDILvnCMXRTCkf5zm40EoPINupG0P5mU/hEstVwVL+HI8gt4jr
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

fxls8962af_fifo_flush() copies the number of samples the device reports
in its hardware FIFO into an on-stack buffer

	u16 buffer[FXLS8962AF_FIFO_LENGTH * 3];

which is sized for at most FXLS8962AF_FIFO_LENGTH (32) samples. The count
is read from the BUF_STATUS register and masked with a 6-bit field:

	count = reg & FXLS8962AF_BUF_STATUS_BUF_CNT;

where FXLS8962AF_BUF_STATUS_BUF_CNT is GENMASK(5, 0), so count can be
0..63 - nearly double the 32-deep FIFO the buffer is sized for. The only
check applied to it is the zero test; unlike the bmc150 flush there is no
caller-supplied bound at all. count samples are then transferred into
buffer[]:

	fxls8962af_fifo_transfer(data, buffer, count);

fxls8962af_fifo_transfer() reads count * 3 * sizeof(u16) = count * 6
bytes through regmap, so a malfunctioning, malicious or counterfeit
accelerometer (or an attacker tampering with the I2C/SPI bus) that
reports a count of 33..63 writes up to 63 * 6 = 378 bytes into the
192-byte buffer: a stack out-of-bounds write of up to 186 bytes that
clobbers the stack canary, saved registers and the return address.

Clamp count to FXLS8962AF_FIFO_LENGTH, the number of samples buffer[] is
sized for, before the transfer, mirroring the watermark clamp already
done in fxls8962af_set_watermark(). A well-formed flush reports at most
FXLS8962AF_FIFO_LENGTH samples, so legitimate devices are unaffected.

This hardens the flush against a malformed device-reported count; it is
not reachable with conforming hardware (it requires a malicious or
defective device, or bus tampering), so it is not marked for stable. The
unbounded count has been present since hardware-FIFO support was added in
commit 79e3a5bdd9ef ("iio: accel: fxls8962af: add hw buffered sampling").

Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
v2 (review [1] Jonathan Cameron, [2] Andy Shevchenko):
- use min() instead of min_t(u8, ...) (count is u8, FXLS8962AF_FIFO_LENGTH
  is 32, so min() compares as int and the result <= 32 fits count; builds
  clean under make W=1).
- drop Fixes: and Cc: stable -- this is hardening against a malformed
  device-reported count, not a fix reachable with conforming hardware, per
  Jonathan ("not a fix and not back port material"). The introducing
  commit is now noted in the commit message instead.

[1] https://lore.kernel.org/all/20260614144337.3b3dab1a@jic23-huawei/
[2] https://lore.kernel.org/all/ai_RF9BG17SZ7Tiz@ashevche-desk.local/
v1: https://lore.kernel.org/all/20260613-b4-disp-22362900-v1-1-c5e49f6af027@proton.me/

This is a different bug from CVE-2025-38485, the use-after-free in the same
function fixed by commit 1fe16dc1a2f5 ("iio: accel: fxls8962af: Fix use
after free in fxls8962af_fifo_flush"): that commit added a
synchronize_irq() in fxls8962af_buffer_predisable and did not bound the
FIFO sample count, so this stack overflow is still present at mainline HEAD.

Verified with an in-kernel KASAN litmus (CONFIG_KASAN_STACK=y) and a
userspace ASan model on x86_64 and i386: without the clamp, a device
reporting count=36 drives fxls8962af_fifo_transfer() past the 192-byte
on-stack buffer (stack-out-of-bounds Write of size 216); count=63 (a
378-byte write, 186 bytes past the buffer) reproduces under ASan on both
ABIs; with the clamp the transfer is bounded to 32. Reproducer and full
logs available on request.
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
change-id: 20260615-b4-disp-1a8c7886-072a8d1721e9

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

