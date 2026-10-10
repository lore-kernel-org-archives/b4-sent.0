From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 10 Oct 2026 14:42:50 +0200
Subject: [PATCH] button: adc: implement get_code()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-b4-button-adc-get-code-v1-1-843d04f5dfd5@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6DIBBA0auYWTsJWHHRqxgXwIx2ugADaEyId
 y9tl2/xf4XMSTjDs6uQ+JQsMTTovgP/smFjFGqGQQ2TVlqhG9EdpcSAljxuXNBHYlRmWh80GkP
 WQov3xKtcv/G8/J0P92Zfvje47w86ab67egAAAA==
X-Change-ID: 20261010-b4-button-adc-get-code-056f3d455daa
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, David Heidelberg <david@ixit.cz>, 
 Simon Glass <sjg@chromium.org>, Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791636171; l=2505;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=3KI/kvEwA0ViY04Mj8sAkRCRRrffZQyJxYwgsHuQjVY=;
 b=9rqicsTEMwo0Rb6Tmd5GPbW0zmW38NIyC0pELcUW/5gEz+uNvzuCkmhvGmY+TgFYFIYevAbE1
 qH8MU15PuvjCzmt62TxNQC/5gzvKRl/I3qPcVKyPXACNsFpDYTduIb8
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement .get_code in button_adc_ops and add linux_code
to button_adc_priv.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
The keys on PinePhone Pro are not registered as Volume Up and Down
as the keys are not wired to normal GPIO but to ADC and use different
resistors to tell them apart.

However, button_adc_ops never sets .get_code unlike button-gpio. As a result
button_get_code() returns -ENOSYS for ADC buttons.

The patch reads linux,code and returns it from .get_code mirroring button-gpio.
---
 drivers/button/button-adc.c | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/drivers/button/button-adc.c b/drivers/button/button-adc.c
index da7ddf2a857..681f3f7c09a 100644
--- a/drivers/button/button-adc.c
+++ b/drivers/button/button-adc.c
@@ -20,12 +20,14 @@
  * @channel: channel of the ADC device to probe the button state.
  * @min: minimal uV value to consider button as pressed.
  * @max: maximal uV value to consider button as pressed.
+ * @linux_code: linux,code devicetree property for this button, or 0 if unset.
  */
 struct button_adc_priv {
 	struct udevice *adc;
 	int channel;
 	int min;
 	int max;
+	int linux_code;
 };
 
 static enum button_state_t button_adc_get_state(struct udevice *dev)
@@ -49,6 +51,16 @@ static enum button_state_t button_adc_get_state(struct udevice *dev)
 	return (uV >= priv->min && uV < priv->max) ? BUTTON_ON : BUTTON_OFF;
 }
 
+static int button_adc_get_code(struct udevice *dev)
+{
+	struct button_adc_priv *priv = dev_get_priv(dev);
+
+	if (!priv->linux_code)
+		return -ENODATA;
+
+	return priv->linux_code;
+}
+
 static int button_adc_of_to_plat(struct udevice *dev)
 {
 	struct button_uc_plat *uc_plat = dev_get_uclass_plat(dev);
@@ -93,6 +105,8 @@ static int button_adc_of_to_plat(struct udevice *dev)
 	}
 
 	priv->channel = args.args[0];
+	priv->linux_code = ofnode_read_u32_default(dev_ofnode(dev),
+						   "linux,code", 0);
 
 	/*
 	 * Define the voltage range such that the button is only pressed
@@ -138,6 +152,7 @@ static int button_adc_bind(struct udevice *parent)
 
 static const struct button_ops button_adc_ops = {
 	.get_state	= button_adc_get_state,
+	.get_code	= button_adc_get_code,
 };
 
 static const struct udevice_id button_adc_ids[] = {

---
base-commit: ece349ade2973e220f524ce59e59711cc919263f
change-id: 20261010-b4-button-adc-get-code-056f3d455daa

Best regards,
--  
Petr Hodina <petr.hodina@protonmail.com>

