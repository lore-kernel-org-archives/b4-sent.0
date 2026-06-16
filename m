From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Mon, 15 Jun 2026 23:46:34 -0500
Subject: [PATCH] platform/chrome: sensorhub: bound the EC-reported sensor
 number
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260615-b4-disp-42d17651-v1-1-fe599bb972f4@proton.me>
X-B4-Tracking: v=1; b=H4sIACnVMGoC/x3MQQqAIBBA0avErBtQsxG6SrSwnGo2JgoRSHdPW
 r7F/xUKZ+ECU1ch8y1Frtig+w6208eDUUIzGGVIkR5xtRikJLQmaEejxkA87OQcKW+hZSnzLs+
 /nJf3/QDc3r64YgAAAA==
To: Tzung-Bi Shih <tzungbi@kernel.org>, Benson Leung <bleung@chromium.org>
Cc: Gwendal Grignou <gwendal@chromium.org>, chrome-platform@lists.linux.dev, 
 Guenter Roeck <groeck@chromium.org>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781585193; l=3746;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=8SrA15YJrZtNHL8+1PqoW54xiLZumanmBmpsTVz+v0s=;
 b=CdLfdDXQNhI8VmZ3p6cKWXt2n7C6j36ikhmenIjuZ4z9oxgt2hHywakPWYjElJgQRi9Whp2MB
 I50M2v841jjC+iYn33MXpyhwovWC2GvknVGafV+eC8xoLCq09RUS7Vs
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cros_ec_sensor_ring_process_event() takes the sensor number from each
EC FIFO event (in->sensor_num, an 8-bit value) and uses it unchecked to
index sensorhub->batch_state[], which is allocated with only
sensorhub->sensor_num entries (the EC-reported sensor count).
cros_ec_sensorhub_ring_handler() validates the FIFO event count and the
ring bound, but not the per-event sensor number, so a value of
sensor_num or larger results in an out-of-bounds read and write of the
batch_state array - directly here and, via
cros_ec_sensor_ring_check_for_past_timestamp(), as an out-of-bounds read
that is fed back into the event timestamp.

The push path cros_sensorhub_send_sample() already rejects a sensor
number that is not smaller than sensor_num; apply the same check in the
ring processing path and drop the malformed event.

Fixes: 93fe48a58590 ("platform/chrome: cros_ec_sensorhub: Add median filter")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
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

The fix is the same bound cros_sensorhub_send_sample() already applies,
moved to the per-event chokepoint so it also covers the timestamp-spread
read path. A malicious, malfunctioning or counterfeit EC (or an attacker
interposing on the AP<->EC bus) is the source; this is a hardening of the
kernel's trust in the EC FIFO, in the spirit of the existing check.

Reproducer (kernel module + ASan model) available on request.
---
 drivers/platform/chrome/cros_ec_sensorhub_ring.c | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/drivers/platform/chrome/cros_ec_sensorhub_ring.c b/drivers/platform/chrome/cros_ec_sensorhub_ring.c
index a10579144c34..a06609bca57b 100644
--- a/drivers/platform/chrome/cros_ec_sensorhub_ring.c
+++ b/drivers/platform/chrome/cros_ec_sensorhub_ring.c
@@ -436,6 +436,20 @@ cros_ec_sensor_ring_process_event(struct cros_ec_sensorhub *sensorhub,
 	const s64 now = cros_ec_get_time_ns();
 	int axis, async_flags;
 
+	/*
+	 * The sensor number is reported by the EC and is used unchecked below
+	 * to index sensorhub->batch_state[], which is only sensor_num entries
+	 * long. Reject an out-of-range value, as cros_sensorhub_send_sample()
+	 * already does, so a malformed FIFO event cannot drive an out-of-bounds
+	 * access.
+	 */
+	if (in->sensor_num >= sensorhub->sensor_num) {
+		dev_warn_ratelimited(sensorhub->dev,
+				     "Invalid sensor number %u from EC\n",
+				     in->sensor_num);
+		return false;
+	}
+
 	/* Do not populate the filter based on asynchronous events. */
 	async_flags = in->flags &
 		(MOTIONSENSE_SENSOR_FLAG_ODR | MOTIONSENSE_SENSOR_FLAG_FLUSH);

---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260615-b4-disp-42d17651-d6e3f67760a4

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

