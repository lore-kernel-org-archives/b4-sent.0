From: =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
Date: Fri, 12 Jun 2026 09:55:07 +0200
Subject: [PATCH] w1: ds2482: add OF device match table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260612-w1-of-autoload-v1-1-74e8a17626e6@gmail.com>
X-B4-Tracking: v=1; b=H4sIAFq7K2oC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDM0ND3XJD3fw03cTSkvyc/MQUXUPzVAPTpJRkk9TUNCWgpoKi1LTMCrC
 B0bG1tQD0FiSfYAAAAA==
X-Change-ID: 20260611-w1-of-autoload-17e05bdc4eef
To: Krzysztof Kozlowski <krzk@kernel.org>
Cc: Miroslav Ondra <ondra@faster.cz>, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781250913; l=1670;
 i=cleverline1mc@gmail.com; s=20241112; h=from:subject:message-id;
 bh=jvWRlBo9AbXM4WqXvJgafF/YG+Z947PiNrJCAur10yc=;
 b=R86g7VDNgVgiL+LPVPpeaIQsrAgPu1g5WIShBhjc2qvAR4zTlO/VVWNB9lvU0MCWGYqSdbFsC
 6K3E3JK+bTSBXBdqKmsT0PjdBK9IYporRixNHPs2s5mdzsXVRy6iZuk
X-Developer-Key: i=cleverline1mc@gmail.com; a=ed25519;
 pk=EJoEbw03UiRORQuCiEyNA8gH1Q6fIpEWnn/MyaWOWX0=
X-Endpoint-Received: by B4 Relay for cleverline1mc@gmail.com/20241112 with auth_id=275
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an of_device_id table and hook it into the i2c driver so the
ds2482/ds2484 can be matched and auto-probed from Device Tree.

This allows automatic module loading when instantiated via DT.

Signed-off-by: Kryštof Černý <cleverline1mc@gmail.com>
---
The ds2482 driver currently lacks an OF match table, which prevents
automatic driver binding and module autoload when the device is
described via Device Tree using compatible strings defined in the
binding.

Even with a correct "maxim,ds2482" compatible, the driver is not
matched because no of_device_id table is registered.

Add OF match support for ds2482/ds2484 and hook it into the i2c driver
to enable proper Device Tree based probing and autoloading.
---
 drivers/w1/masters/ds2482.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/w1/masters/ds2482.c b/drivers/w1/masters/ds2482.c
index 0069e6f854d7..9e57c6e487d1 100644
--- a/drivers/w1/masters/ds2482.c
+++ b/drivers/w1/masters/ds2482.c
@@ -545,9 +545,17 @@ static const struct i2c_device_id ds2482_id[] = {
 };
 MODULE_DEVICE_TABLE(i2c, ds2482_id);
 
+static const struct of_device_id ds2482_of_match[] = {
+	{ .compatible = "maxim,ds2482", },
+	{ .compatible = "maxim,ds2484", },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, ds2482_of_match);
+
 static struct i2c_driver ds2482_driver = {
 	.driver = {
 		.name	= "ds2482",
+		.of_match_table  = ds2482_of_match,
 	},
 	.probe		= ds2482_probe,
 	.remove		= ds2482_remove,

---
base-commit: 53371dcd31b8899d851a169cc2a432f62baa9d54
change-id: 20260611-w1-of-autoload-17e05bdc4eef

Best regards,
--  
Kryštof Černý <cleverline1mc@gmail.com>

