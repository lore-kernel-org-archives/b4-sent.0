From: Dylan Laduranty <dylan.laduranty@mesotic.com>
Date: Fri, 27 Feb 2026 16:45:35 +0100
Subject: [PATCH] pps: clients: pps-gpio: fix echo pin configuration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260227-drivers-pps-clients-fix-echo-pin-setup-v1-1-a5a5f52d7d96@mesotic.com>
X-B4-Tracking: v=1; b=H4sIAB68oWkC/x2NzQqDQAwGX0VybsCuaH9epfRgd7+tgbKGRKUgv
 nuXHgeGmZ0cJnC6NzsZNnGZS4XzqaE4jeUNllSZQhuGNoQLJ5MN5qzqHD+Csjhn+TLiNLNKYce
 yKmf0IXWva38bMtWYGqr1Hz2ex/EDBhw5xHgAAAA=
X-Change-ID: 20260227-drivers-pps-clients-fix-echo-pin-setup-fe52d3b8596f
To: Rodolfo Giometti <giometti@enneenne.com>
Cc: linux-kernel@vger.kernel.org, 
 Dylan Laduranty <dylan.laduranty@mesotic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772207140; l=1541;
 i=dylan.laduranty@mesotic.com; s=20260227; h=from:subject:message-id;
 bh=HiKmeAEhQwBWppTE6qjwAahphv1ZtYdeNMPY+D0ILIA=;
 b=poRC80kTHg5VO4R+2PHD288xVPI7mJaRnkP3y9pYBYTL8ncjq5b0PsUj4knUqGLy4lAeGknLb
 q3uyiUx99X1AL0F5AILlT6slpL70N2Zdbmrv2zM9SPvQkXnRb9u3trt
X-Developer-Key: i=dylan.laduranty@mesotic.com; a=ed25519;
 pk=RCBv1HNO5gjI2XmhIo71IsjzUhWXcocB5Y9jtzWduYo=
X-Endpoint-Received: by B4 Relay for dylan.laduranty@mesotic.com/20260227 with auth_id=652
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch adds PPS_ECHOASSERT and PPS_ECHOCLEAR to pps_default_params
when needed.

The pps_gpio_echo() function will check if these flags are set inside
params.mode to update the echo pin state.

However, these flags need to be set during probe sequence otherwise
pps_gpio_echo() function will never update the pin's state.

Signed-off-by: Dylan Laduranty <dylan.laduranty@mesotic.com>
---
 drivers/pps/clients/pps-gpio.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/pps/clients/pps-gpio.c b/drivers/pps/clients/pps-gpio.c
index 935da68610c701e6d9de53c667237f77438d7107..83ca24118eccfdb9eebe272023ef4980c9d54cf2 100644
--- a/drivers/pps/clients/pps-gpio.c
+++ b/drivers/pps/clients/pps-gpio.c
@@ -200,8 +200,13 @@ static int pps_gpio_probe(struct platform_device *pdev)
 
 	/* register PPS source */
 	pps_default_params = PPS_CAPTUREASSERT | PPS_OFFSETASSERT;
-	if (data->capture_clear)
+	if (data->echo_pin)
+		pps_default_params |= PPS_ECHOASSERT;
+	if (data->capture_clear) {
 		pps_default_params |= PPS_CAPTURECLEAR | PPS_OFFSETCLEAR;
+		if (data->echo_pin)
+			pps_default_params |= PPS_ECHOCLEAR;
+	}
 	data->pps = pps_register_source(&data->info, pps_default_params);
 	if (IS_ERR(data->pps)) {
 		dev_err(dev, "failed to register IRQ %d as PPS source\n",

---
base-commit: 3fa5e5702a82d259897bd7e209469bc06368bf31
change-id: 20260227-drivers-pps-clients-fix-echo-pin-setup-fe52d3b8596f

Best regards,
-- 
Dylan Laduranty <dylan.laduranty@mesotic.com>

