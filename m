From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Wed, 17 Jun 2026 00:42:27 -0500
Subject: [PATCH v2] platform/chrome: sensorhub: bound the EC-reported
 sensor number
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260617-b4-disp-4e176cdc-v2-1-160f9ffa463e@proton.me>
X-B4-Tracking: v=1; b=H4sIAMIzMmoC/x3MTQqAIBBA4avErBvwD8OuEi1Mp5pNiUIE4t2Tl
 t/ivQqFMlOBeaiQ6eHC99WhxgHC6a+DkGM3KKGssHLCzWDkktCQnGyIAZ3UmoLZyCkPPUuZdn7
 /5bK29gGzF8q0YgAAAA==
To: Benson Leung <bleung@chromium.org>, Tzung-Bi Shih <tzungbi@kernel.org>
Cc: chrome-platform@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Guenter Roeck <groeck@chromium.org>, Gwendal Grignou <gwendal@chromium.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781674946; l=4373;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=+D/PnruFsIeMzAqKfIW8Z1wCZ7XJX8si17RTg+XTyfE=;
 b=FOIOYxrBhzBEcf6CNQrhn1ohxz4y0fQUvz08G2DOPZLYTLxzdw9keG1oTtHFysVAPkX0yJ1Ob
 MIoskgSuBWeCG3k79OZPdOBqA3SsbLPKFN34dddN4AZHQRt8X2ewUoy
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Each EC FIFO event carries a sensor number (in->sensor_num, an 8-bit
value). cros_ec_sensorhub_ring_handler() validates the FIFO event count,
the per-read count and the ring bound, but not the per-event sensor
number. cros_ec_sensor_ring_process_event() then uses it unchecked to
index sensorhub->batch_state[], which is allocated with only
sensorhub->sensor_num entries, so a sensor number of sensor_num or larger
is an out-of-bounds read and write of batch_state[] - in the ODR and
FLUSH paths and, via cros_ec_sensor_ring_check_for_past_timestamp(), as
an out-of-bounds read that is fed back into the event timestamp.

Validate the sensor number in the ring handler, where each event is read
from the EC, and drop a malformed event before it is used. This is the
bound cros_sensorhub_send_sample() already applies on the push path,
hoisted to the point where the EC data enters the kernel so it also
covers the batch_state[] indexing in cros_ec_sensor_ring_process_event()
and sensor_mask |= BIT(in->sensor_num) in the handler.

Fixes: 93fe48a58590 ("platform/chrome: cros_ec_sensorhub: Add median filter")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
v2 (per Tzung-Bi Shih's review):
- Move the check from cros_ec_sensor_ring_process_event() into the FIFO
  read loop of cros_ec_sensorhub_ring_handler(), so the sensor number is
  validated where each event is read from the EC. This is the source
  Tzung-Bi pointed to and it covers every later use of the sensor number.
- Shorten the comment.
- Left the existing cros_sensorhub_send_sample() bound in place. With the
  handler check it can no longer fire, so it is now redundant; I can drop
  it as a separate cleanup patch if preferred.
- Kept Fixes: 93fe48a58590. batch_state[] and every unchecked
  batch_state[in->sensor_num]/[sensor_id] access (and sensor_mask |=
  BIT(in->sensor_num)) were introduced by the median-filter commit; at
  145d59baff59 ("Add FIFO support") there is no batch_state[] and the only
  ring-path use of the sensor number, cros_sensorhub_send_sample() ->
  push_data[], was already bounded. Both commits are in v5.7-rc1, so the
  stable backport range is unchanged either way; happy to switch to
  145d59baff59 if you prefer.

I reproduced the out-of-bounds access with an in-kernel test that drives
the batch_state[] indexing verbatim under KASAN (CONFIG_KASAN=y), plus a
userspace AddressSanitizer model of the same geometry on both 32- and
64-bit. batch_state is devm_kcalloc(sensor_num, 40 bytes); the EC FIFO
sensor number is an 8-bit field, so it can index up to 255 - roughly
9.8 KB past the end of a typical (handful-of-sensors) allocation.

  - In-kernel (7.1.0-rc5 + KASAN): an event with sensor_num just past the
    allocation tripped a slab-out-of-bounds Write in the ODR-flag path
    (batch_state[n].last_len = 0); the patched arm and an in-bounds
    control arm completed cleanly with no KASAN report.
  - ASan model (-m32 and -m64): a sensor number of 200/255 produced a
    heap-buffer-overflow WRITE 8000/10200 bytes past the alloc on both
    ABIs; the patched arm and the in-bounds arm were clean.

Reproducer (kernel module + ASan model) available on request.
---
 drivers/platform/chrome/cros_ec_sensorhub_ring.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/platform/chrome/cros_ec_sensorhub_ring.c b/drivers/platform/chrome/cros_ec_sensorhub_ring.c
index a10579144c34..64e9615ed6f4 100644
--- a/drivers/platform/chrome/cros_ec_sensorhub_ring.c
+++ b/drivers/platform/chrome/cros_ec_sensorhub_ring.c
@@ -890,6 +890,14 @@ static void cros_ec_sensorhub_ring_handler(struct cros_ec_sensorhub *sensorhub)
 
 		for (in = sensorhub->resp->fifo_read.data, j = 0;
 		     j < number_data; j++, in++) {
+			/* Skip event if sensor_num from EC is out of bounds. */
+			if (in->sensor_num >= sensorhub->sensor_num) {
+				dev_warn_ratelimited(sensorhub->dev,
+						     "Invalid sensor number %u from EC\n",
+						     in->sensor_num);
+				continue;
+			}
+
 			if (cros_ec_sensor_ring_process_event(
 						sensorhub, fifo_info,
 						fifo_timestamp,

---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260617-b4-disp-4e176cdc-9133ec4be92a

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

