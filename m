From: Tin Posavec <tin.posavec04@gmail.com>
Date: Sat, 17 Oct 2026 10:31:59 +0200
Subject: [PATCH 3/3] media: ipu-bridge: Add OV9734 sensor config
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-ov9734-ipu6-v1-3-86eab22ae258@gmail.com>
References: <20261017-ov9734-ipu6-v1-0-86eab22ae258@gmail.com>
In-Reply-To: <20261017-ov9734-ipu6-v1-0-86eab22ae258@gmail.com>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Bingbu Cao <bingbu.cao@amd.com>, Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Dan Scally <dan.scally@ideasonboard.com>, Hans de Goede <hansg@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Tin Posavec <tin.posavec04@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792225933; l=1269;
 i=tin.posavec04@gmail.com; s=20261017; h=from:subject:message-id;
 bh=FwgBHrNJRouDllQ+29L6D3vp6iZpIUXBZhoEI3VmSgY=;
 b=QDrGAg8BUmbwzH+NIyXLqxVnJU2GjUiEKzRoPbbry/m7nZSKEBftvlOD6+8nCekMYhvbnTFjm
 dLYbQjQbfyLCTq5eTqRKoiPXmb3eNu8K6YYsS8XYe5H4uN4v2p7ftmp
X-Developer-Key: i=tin.posavec04@gmail.com; a=ed25519;
 pk=SHQVmXmK88mO08JT/P9vzu9gKd208IICWLSbsX3TmcI=
X-Endpoint-Received: by B4 Relay for tin.posavec04@gmail.com/20261017 with auth_id=1222
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Omnivision OV9734 (ACPI HID OVTI9734) to the
ipu_supported_sensors[] table, with a single link frequency of 180 MHz,
the only one supported by the ov9734 driver.

The sensor is the RGB camera of the Intel NUC M15 laptop (LAPRC710).
Without this entry ipu-bridge does not create a fwnode graph endpoint
for the sensor, and the camera is not enumerated.

Tested on the NUC M15: the sensor binds and streams 1296x734 SGRBG10
at 30 fps.

Assisted-by: LLM
Signed-off-by: Tin Posavec <tin.posavec04@gmail.com>
---
 drivers/media/pci/intel/ipu-bridge.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/media/pci/intel/ipu-bridge.c b/drivers/media/pci/intel/ipu-bridge.c
index 3739c4a2a..4982b77de 100644
--- a/drivers/media/pci/intel/ipu-bridge.c
+++ b/drivers/media/pci/intel/ipu-bridge.c
@@ -120,6 +120,8 @@ static const struct ipu_sensor_config ipu_supported_sensors[] = {
 	IPU_SENSOR_CONFIG("OVTI5693", 1, 419200000),
 	/* Omnivision OV8856 */
 	IPU_SENSOR_CONFIG("OVTI8856", 3, 180000000, 360000000, 720000000),
+	/* Omnivision OV9734 */
+	IPU_SENSOR_CONFIG("OVTI9734", 1, 180000000),
 	/* Sony IMX471 */
 	IPU_SENSOR_CONFIG("SONY471A", 1, 200000000),
 	/* Sony IMX471 (found on Lenovo X1 Carbon G14) */

-- 
2.53.0

