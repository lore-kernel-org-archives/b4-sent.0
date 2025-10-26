From: Sven Peter <sven@kernel.org>
Date: Sun, 26 Oct 2025 12:21:36 +0000
Subject: [PATCH usb-next] usb: dwc3: apple: Only support a single reset
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251026-b4-dwc3-apple-reset-array-fix-v1-1-ccdbacd63f78@kernel.org>
X-B4-Tracking: v=1; b=H4sIAE8S/mgC/x3MwQrCMAyA4VcZORtY6xzoq4iHtIkakFqSTSdj7
 77i8fsP/woupuJw6VYw+ajruzSEQwf5SeUhqNwMsY+n0MeIaUD+5iNSrS9BE5cJyYx+eNcFaQy
 Z4zkxhxHao5q0/P9fYfaERZYJbtu2A+uoLQR5AAAA
X-Change-ID: 20251022-b4-dwc3-apple-reset-array-fix-a61cd29bdd16
To: Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4079; i=sven@kernel.org;
 h=from:subject:message-id; bh=GXuFAtgP+oHMIwv1faVRiehyLAz3rr8xYHnrw+m3qak=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8Y/oczj+5zfLeI4+Srj5LntiU/C5kyIN8tijz08dwpPo
 /fJPW97OkpZGMQ4GGTFFFm277c3ffLwjeDSTZfew8xhZQIZwsDFKQATeb+V4Q9X33uZNcet++6y
 fNy4Xd/3zs3K5ODcbb3i8/jVGU68DOBmZHi73a7h0vMvfZyFhxc+/ZWo/6i06uZ3VQ/XnakbNkl
 cusEBAA==
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As pointed out by Philipp, Apple's dwc3 controller only uses a single
reset line and there's thus no need to use reset controller array
functions. The only functional change here is replacing
devm_reset_control_array_get_exclusive with
devm_reset_control_get_exclusive. The rest are only cosmetic changes
to replace "resets" with "reset".

Reported-by: Philipp Zabel <p.zabel@pengutronix.de>
Closes: https://lore.kernel.org/asahi/47112ace39ea096242e68659d67a401e931abf3a.camel@pengutronix.de/
Fixes: 0ec946d32ef7 ("usb: dwc3: Add Apple Silicon DWC3 glue layer driver")
Signed-off-by: Sven Peter <sven@kernel.org>
---
I was planning to submit a v3 with this fixed but didn't find the time
before v2 was picked up.
---
 drivers/usb/dwc3/dwc3-apple.c | 28 ++++++++++++++--------------
 1 file changed, 14 insertions(+), 14 deletions(-)

diff --git a/drivers/usb/dwc3/dwc3-apple.c b/drivers/usb/dwc3/dwc3-apple.c
index 6e41bd0e34f461b0c3db9b8a646116458ff816b6..cc47cad232e397ac4498b09165dfdb5bd215ded7 100644
--- a/drivers/usb/dwc3/dwc3-apple.c
+++ b/drivers/usb/dwc3/dwc3-apple.c
@@ -81,7 +81,7 @@ enum dwc3_apple_state {
  * @dev: Pointer to the device structure
  * @mmio_resource: Resource to be passed to dwc3_core_probe
  * @apple_regs: Apple-specific DWC3 registers
- * @resets: Reset control
+ * @reset: Reset control
  * @role_sw: USB role switch
  * @lock: Mutex for synchronizing access
  * @state: Current state of the controller, see documentation for the enum for details
@@ -93,7 +93,7 @@ struct dwc3_apple {
 	struct resource *mmio_resource;
 	void __iomem *apple_regs;
 
-	struct reset_control *resets;
+	struct reset_control *reset;
 	struct usb_role_switch *role_sw;
 
 	struct mutex lock;
@@ -237,9 +237,9 @@ static int dwc3_apple_init(struct dwc3_apple *appledwc, enum dwc3_apple_state st
 
 	lockdep_assert_held(&appledwc->lock);
 
-	ret = reset_control_deassert(appledwc->resets);
+	ret = reset_control_deassert(appledwc->reset);
 	if (ret) {
-		dev_err(appledwc->dev, "Failed to deassert resets, err=%d\n", ret);
+		dev_err(appledwc->dev, "Failed to deassert reset, err=%d\n", ret);
 		return ret;
 	}
 
@@ -288,9 +288,9 @@ static int dwc3_apple_init(struct dwc3_apple *appledwc, enum dwc3_apple_state st
 core_exit:
 	dwc3_core_exit(&appledwc->dwc);
 reset_assert:
-	ret_reset = reset_control_assert(appledwc->resets);
+	ret_reset = reset_control_assert(appledwc->reset);
 	if (ret_reset)
-		dev_warn(appledwc->dev, "Failed to assert resets, err=%d\n", ret_reset);
+		dev_warn(appledwc->dev, "Failed to assert reset, err=%d\n", ret_reset);
 
 	return ret;
 }
@@ -323,9 +323,9 @@ static int dwc3_apple_exit(struct dwc3_apple *appledwc)
 	dwc3_core_exit(&appledwc->dwc);
 	appledwc->state = DWC3_APPLE_NO_CABLE;
 
-	ret = reset_control_assert(appledwc->resets);
+	ret = reset_control_assert(appledwc->reset);
 	if (ret) {
-		dev_err(appledwc->dev, "Failed to assert resets, err=%d\n", ret);
+		dev_err(appledwc->dev, "Failed to assert reset, err=%d\n", ret);
 		return ret;
 	}
 
@@ -411,14 +411,14 @@ static int dwc3_apple_probe(struct platform_device *pdev)
 	appledwc->dev = &pdev->dev;
 	mutex_init(&appledwc->lock);
 
-	appledwc->resets = devm_reset_control_array_get_exclusive(dev);
-	if (IS_ERR(appledwc->resets))
-		return dev_err_probe(&pdev->dev, PTR_ERR(appledwc->resets),
-				     "Failed to get resets\n");
+	appledwc->reset = devm_reset_control_get_exclusive(dev, NULL);
+	if (IS_ERR(appledwc->reset))
+		return dev_err_probe(&pdev->dev, PTR_ERR(appledwc->reset),
+				     "Failed to get reset control\n");
 
-	ret = reset_control_assert(appledwc->resets);
+	ret = reset_control_assert(appledwc->reset);
 	if (ret) {
-		dev_err(&pdev->dev, "Failed to assert resets, err=%d\n", ret);
+		dev_err(&pdev->dev, "Failed to assert reset, err=%d\n", ret);
 		return ret;
 	}
 

---
base-commit: be83d83664e9f6fa035e96fb9187f9e7898659e4
change-id: 20251022-b4-dwc3-apple-reset-array-fix-a61cd29bdd16

Best regards,
-- 
Sven Peter <sven@kernel.org>

