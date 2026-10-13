From: Petr Hodina <petr.hodina@protonmail.com>
Date: Tue, 13 Oct 2026 18:13:23 +0200
Subject: [PATCH v2] button: adc: implement get_code()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-b4-button-adc-get-code-v2-1-72a1352d5965@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNQQ6DIBBFr2JYdxpQME1XvYdxgcygNFUMoGljv
 HvRHqDLl7z//sYiBUeR3YuNBVpddH7KUF4KZgY99QQOM7OSl7XggkMnoVtS8hNoNNBTAuORgKv
 aViiVQq1ZHs+BrHuf4ab9cVy6J5l01A5jcDH58DmfV3F4f09WAQJuskIurUKL6jEHn61Ru9fV+
 JG1+75/AfA7oXnTAAAA
X-Change-ID: 20261010-b4-button-adc-get-code-056f3d455daa
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, David Heidelberg <david@ixit.cz>, 
 Simon Glass <sjg@chromium.org>, Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791908037; l=3672;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=9JePnEKjXiJ/W2mAz2OuQbRVLmFiWrSIiKO5Q6MgnM0=;
 b=8Ei60eMDseMoth/TDkrO13G6fAyI+8z74Nm81uT7Tm1lR6tktBMC0CtC0Bydw15TWpNDD+xaH
 N+rhn3GNc3xBaH2dUKUSqLSrMcmm7oaBDzXXQTFi6zEpChv3z6qqdyT
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement .get_code in button_adc_ops and add linux_code
to button_adc_priv.

The consumer in this case is the PinePhone Pro platform with the
volume up and down keys for selection in bootmenu.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
The keys on PinePhone Pro are not registered as Volume Up and Down
as the keys are not wired to normal GPIO but to ADC and use different
resistors to tell them apart.

However, button_adc_ops never sets .get_code unlike button-gpio. As a result
button_get_code() returns -ENOSYS for ADC buttons.

The patch reads linux,code and returns it from .get_code mirroring button-gpio.
---
Changes in v2:
- extended the sandbox test for KEY_F3/F4/F5 in 'test/dm/button.c'
- switched to dev_read_u32_default() instead of ofnode_read_u32_default()
- the commit message now lists the PinePhone Pro as consumer
- Link to v1: https://patch.msgid.link/20261010-b4-button-adc-get-code-v1-1-843d04f5dfd5@protonmail.com
---
 drivers/button/button-adc.c | 14 ++++++++++++++
 test/dm/button.c            |  3 +++
 2 files changed, 17 insertions(+)

diff --git a/drivers/button/button-adc.c b/drivers/button/button-adc.c
index da7ddf2a857..2f33d36238a 100644
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
@@ -93,6 +105,7 @@ static int button_adc_of_to_plat(struct udevice *dev)
 	}
 
 	priv->channel = args.args[0];
+	priv->linux_code = dev_read_u32_default(dev, "linux,code", 0);
 
 	/*
 	 * Define the voltage range such that the button is only pressed
@@ -138,6 +151,7 @@ static int button_adc_bind(struct udevice *parent)
 
 static const struct button_ops button_adc_ops = {
 	.get_state	= button_adc_get_state,
+	.get_code	= button_adc_get_code,
 };
 
 static const struct udevice_id button_adc_ids[] = {
diff --git a/test/dm/button.c b/test/dm/button.c
index f05f4ca27ce..59431c8eb2b 100644
--- a/test/dm/button.c
+++ b/test/dm/button.c
@@ -123,10 +123,13 @@ static int dm_test_button_keys_adc(struct unit_test_state *uts)
 	 */
 	ut_assertok(button_get_by_label("button3", &dev));
 	ut_asserteq(BUTTON_OFF, button_get_state(dev));
+	ut_asserteq(KEY_F3, button_get_code(dev));
 	ut_assertok(button_get_by_label("button4", &dev));
 	ut_asserteq(BUTTON_OFF, button_get_state(dev));
+	ut_asserteq(KEY_F4, button_get_code(dev));
 	ut_assertok(button_get_by_label("button5", &dev));
 	ut_asserteq(BUTTON_ON, button_get_state(dev));
+	ut_asserteq(KEY_F5, button_get_code(dev));
 
 	return 0;
 }

---
base-commit: ece349ade2973e220f524ce59e59711cc919263f
change-id: 20261010-b4-button-adc-get-code-056f3d455daa

Best regards,
--  
Petr Hodina <petr.hodina@protonmail.com>

