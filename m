From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Thu, 18 Jun 2026 00:46:28 -0500
Subject: [PATCH v3] platform/chrome: sensorhub: bound the EC-reported
 sensor number
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260618-b4-disp-adb3f790-v3-1-3a164ed63cbd@proton.me>
X-B4-Tracking: v=1; b=H4sIADOGM2oC/x3MTQqAIBBA4avErBsw+7OuEi1Mx5qNhQMRSHdPW
 n6L9zIIJSaBucqQ6GbhMxa0dQXusHEnZF8MWulBDY3BrUPPcqH1WxvGSaENjTaOpp56ByW7EgV
 +/uWyvu8HKJG7X2IAAAA=
To: Benson Leung <bleung@chromium.org>, Tzung-Bi Shih <tzungbi@kernel.org>
Cc: chrome-platform@lists.linux.dev, Guenter Roeck <groeck@chromium.org>, 
 Gwendal Grignou <gwendal@chromium.org>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781761587; l=2341;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=kRkQQ2XtenLBQgIAfyc88UeRnsxPWIzaMvsDGjnhD3I=;
 b=oJcZC6eYCe5So+WpqJwGJnz45a8YJVhOj88O65r6GJWx07CRPjNdU8btfNh7r1C08KxpZZgR5
 BP9AaT4x/K0BLmGp5nObPRp632D3j1B0+u4AOUyFklVDXWQbbrH8AFG
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Each EC FIFO event carries an 8-bit sensor number (in->sensor_num).
cros_ec_sensorhub_ring_handler() validates the FIFO event count, the
per-read count and the ring bound, but not the sensor number, which
cros_ec_sensor_ring_process_event() then uses unchecked to index
sensorhub->batch_state[] - allocated with only sensorhub->sensor_num
entries. A sensor number of sensor_num or larger is an out-of-bounds
read and write of batch_state[].

Validate the sensor number in the ring handler, where each event is read
from the EC, and drop a malformed event before it is used.

Fixes: 145d59baff59 ("platform/chrome: cros_ec_sensorhub: Add FIFO support")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
Reviewed-by: Tzung-Bi Shih <tzungbi@kernel.org>
---
v3 (per Tzung-Bi Shih's review):
- Fixes: -> 145d59baff59 ("Add FIFO support") as requested.
- Added Tzung-Bi's Reviewed-by.
- Trimmed the commit message.
No code change from v2 (single bound in the FIFO read loop).

The out-of-bounds write was reproduced under KASAN with an in-kernel test
driving the batch_state[] indexing, plus a 32/64-bit AddressSanitizer
model of the same geometry; reproducer available on request.
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
change-id: 20260618-b4-disp-adb3f790-af128ce95e5c

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

