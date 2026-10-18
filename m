From: George Neacsu <geocausa@gmail.com>
Date: Sun, 18 Oct 2026 22:20:57 +0100
Subject: [PATCH v2] leds: flash: leds-qcom-flash: Release all V4L2 flash
 devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261018-qcom-flash-v4l2-release-v2-1-8e2297844d9f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNQQ7CIBBFr9LM2jGAtQRX3sN0Qei0TEKLBUM0T
 e8u9gIu38//72+QKTFluDUbJCqcOS4V1KkB5+0yEfJQGZRQnRSyw9XFGcdgs8fSBoWJAtlMaAZ
 xdUYP0rUa6vqZaOT3YX70lT3nV0yf46jIX/rfWSRKFGSUtdqZi9L3abYczrUO/b7vXxkI636+A
 AAA
X-Change-ID: 20261016-qcom-flash-v4l2-release-9d05c97d1c47
To: Lee Jones <lee@kernel.org>, Pavel Machek <pavel@kernel.org>
Cc: linux-leds@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Sashiko AI review <sashiko-bot@kernel.org>, 
 George Neacsu <geocausa@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792358492; l=4486;
 i=geocausa@gmail.com; s=20261015; h=from:subject:message-id;
 bh=ppY/VnlROueCHxcWyyUzVBQ38YxKqQ50DfJqg4W2Kio=;
 b=xB+4jGMcpNcyEpSTCCr38ebdfeTe6g+KZM/6wSQB/v8xU1euMNCqlyws2k07/zULg5tXxIVDC
 4+qd4mMfxsPCxMzyGaf2vzEPLdCW0Jo6BZ0GmuLLsJDsdVd0RSH9ozD
X-Developer-Key: i=geocausa@gmail.com; a=ed25519;
 pk=KyQk/iWbxsikewDBh0SwlHI51RvAqahD3loqmRp9DVI=
X-Endpoint-Received: by B4 Relay for geocausa@gmail.com/20261015 with auth_id=1199
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The probe error path and qcom_flash_led_remove() use leds_count as an
array index before decrementing it. Since leds_count is the number of
registered LEDs, that first access is one entry past the last registered
V4L2 flash device. The loops also stop before index 0, so with a single
LED nothing is released at all.

The V4L2 flash sub-device then stays registered after the driver is
unbound, still pointing at the driver's freed devm memory. On a Surface
Pro 11 (X1E80100, PM8550 flash, IR LED linked to a sensor through
flash-leds), unloading the module and then setting a flash control on
the sub-device triggered UBSAN shift-out-of-bounds reports and a NULL
pointer dereference in regmap_field_update_bits_base(), called from
update_allowed_flash_current().

Release the registered entries from leds_count - 1 down to 0. Initialize
the mutex only after the probe checks that can return directly, destroy
it on the shared failure path, and route a final torch-clamp programming
failure through that cleanup as well.

Fixes: 96a2e242a5dc ("leds: flash: Add driver to support flash LED module in QCOM PMICs")
Cc: stable@vger.kernel.org
Reported-by: Sashiko AI review <sashiko-bot@kernel.org>
Link: https://sashiko.dev/#/patchset/20261016-qcom-flash-v4l2-release-v1-1-0e92aa7c9327@gmail.com?part=1
Assisted-by: Claude:claude-opus-5-5
Assisted-by: ChatGPT:gpt-5.6-sol
Signed-off-by: George Neacsu <geocausa@gmail.com>
---
The V4L2 flash cleanup currently indexes one element past the registered
array and fails to release index 0. Fix the cleanup for both probe failure
and driver removal.

v2 also makes the probe error handling symmetric around the mutex and
routes a late torch-clamp programming failure through the V4L2 cleanup.
---
Changes in v2:
- initialize the mutex after direct-return probe checks and destroy it on
  the shared failure path, addressing the Sashiko review;
- route the final torch-clamp register-write failure through V4L2 cleanup;
- retain the v1 tested cleanup of every registered V4L2 flash device.
- Link to v1: https://lore.kernel.org/r/20261016-qcom-flash-v4l2-release-v1-1-0e92aa7c9327@gmail.com
---
 drivers/leds/flash/leds-qcom-flash.c | 19 +++++++++++++------
 1 file changed, 13 insertions(+), 6 deletions(-)

diff --git a/drivers/leds/flash/leds-qcom-flash.c b/drivers/leds/flash/leds-qcom-flash.c
index b03a683..35646c4 100644
--- a/drivers/leds/flash/leds-qcom-flash.c
+++ b/drivers/leds/flash/leds-qcom-flash.c
@@ -923,7 +923,6 @@ static int qcom_flash_led_probe(struct platform_device *pdev)
 	devm_kfree(dev, regs); /* devm_regmap_field_bulk_alloc() makes copies */
 
 	platform_set_drvdata(pdev, flash_data);
-	mutex_init(&flash_data->lock);
 
 	count = device_get_child_node_count(dev);
 	if (count == 0 || count > flash_data->max_channels) {
@@ -936,6 +935,8 @@ static int qcom_flash_led_probe(struct platform_device *pdev)
 	if (!flash_data->v4l2_flash)
 		return -ENOMEM;
 
+	mutex_init(&flash_data->lock);
+
 	device_for_each_child_node_scoped(dev, child) {
 		led = devm_kzalloc(dev, sizeof(*led), GFP_KERNEL);
 		if (!led) {
@@ -951,10 +952,16 @@ static int qcom_flash_led_probe(struct platform_device *pdev)
 		flash_data->leds_count++;
 	}
 
-	return regmap_field_write(flash_data->r_fields[REG_TORCH_CLAMP], flash_data->torch_clamp);
+	rc = regmap_field_write(flash_data->r_fields[REG_TORCH_CLAMP],
+				flash_data->torch_clamp);
+	if (rc)
+		goto release;
+
+	return 0;
 release:
-	while (flash_data->v4l2_flash[flash_data->leds_count] && flash_data->leds_count)
-		v4l2_flash_release(flash_data->v4l2_flash[flash_data->leds_count--]);
+	while (flash_data->leds_count)
+		v4l2_flash_release(flash_data->v4l2_flash[--flash_data->leds_count]);
+	mutex_destroy(&flash_data->lock);
 	return rc;
 }
 
@@ -962,8 +969,8 @@ static void qcom_flash_led_remove(struct platform_device *pdev)
 {
 	struct qcom_flash_data *flash_data = platform_get_drvdata(pdev);
 
-	while (flash_data->v4l2_flash[flash_data->leds_count] && flash_data->leds_count)
-		v4l2_flash_release(flash_data->v4l2_flash[flash_data->leds_count--]);
+	while (flash_data->leds_count)
+		v4l2_flash_release(flash_data->v4l2_flash[--flash_data->leds_count]);
 
 	mutex_destroy(&flash_data->lock);
 }

---
base-commit: 62f482ff73bf3ae88b0c899115527752cf9cbf13
change-id: 20261016-qcom-flash-v4l2-release-9d05c97d1c47

Best regards,
-- 
George Neacsu <geocausa@gmail.com>

