From: Tin Posavec <tin.posavec04@gmail.com>
Date: Mon, 09 Nov 2026 19:17:52 +0100
Subject: [PATCH v2 3/3] media: ipu-bridge: Add OV9734 sensor config
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-ov9734-ipu6-v2-3-0481b512c4c0@gmail.com>
References: <20261109-ov9734-ipu6-v2-0-0481b512c4c0@gmail.com>
In-Reply-To: <20261109-ov9734-ipu6-v2-0-0481b512c4c0@gmail.com>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Bingbu Cao <bingbu.cao@amd.com>, Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Dan Scally <dan.scally@ideasonboard.com>, Hans de Goede <hansg@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Afonso Figuinha <afonso.figuinha@gmail.com>, 
 Tin Posavec <tin.posavec04@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794248315; l=1249;
 i=tin.posavec04@gmail.com; s=20261109; h=from:subject:message-id;
 bh=eQVHwvgwGlO3Yl06SOqVT2v4rEicQFZdXN3NaM0IeJ0=;
 b=jl97J/ClFpJKUhdnSThRmbsWQkTZp/tPO4uLdMJowA4FEgr5/GeMjFXPpM3kLmV07kne5/cg7
 kmN/AHsRazqCMtRtLVLoRl2ycIordoBXYIf+xu63rOW7Xe2SjqgDQOx
X-Developer-Key: i=tin.posavec04@gmail.com; a=ed25519;
 pk=h4O+VaAXzwd3B9L6H8RltugTkzF65lam1c1ls5knAVg=
X-Endpoint-Received: by B4 Relay for tin.posavec04@gmail.com/20261109 with auth_id=1463
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Omnivision OV9734 (ACPI HID OVTI9734) to the
ipu_supported_sensors[] table, with a single link frequency of 180 MHz,
the only one supported by the ov9734 driver.

The sensor is the RGB camera of the Intel NUC M15 laptop (LAPRC710).
Without this entry ipu-bridge does not create a fwnode graph endpoint
for the sensor, and the camera is not enumerated.

Signed-off-by: Tin Posavec <tin.posavec04@gmail.com>
Tested-by: Afonso Figuinha <afonso.figuinha@gmail.com> # Surface Laptop 1 (IPU3)
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

