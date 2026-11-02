From: Roman Vivchar <rva333@protonmail.com>
Date: Mon, 02 Nov 2026 17:22:57 +0200
Subject: [PATCH 2/2] media: pwm-ir-tx: add regulator support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261102-6768-irled-v1-2-c7064f3afed1@protonmail.com>
References: <20261102-6768-irled-v1-0-c7064f3afed1@protonmail.com>
In-Reply-To: <20261102-6768-irled-v1-0-c7064f3afed1@protonmail.com>
To: Sean Young <sean@mess.org>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>
Cc: linux-media@vger.kernel.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793632976; l=2900;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=IhXQr7kOEDLCtAxSwK+rAEvZXOZEWzcPKhKvyEtqCwc=;
 b=WpatHju56LMszkCTB2MstZbQpeJ0+VIeHY9B2ViWmHW6U5PgXxpnUaZMqWki8mQ+rJktM/yHG
 kiF5WtstosQBjLdR5tW0MRdSRMh8JI6qzBVYe2qBvUNca1N7rd0h/wn
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On some boards, the IR LED shares a power rail with other components.
If that rail is turned off, IR transmission can't function properly.

Add optional regulator support to ensure the power supply is enabled when
needed.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 drivers/media/rc/pwm-ir-tx.c | 37 ++++++++++++++++++++++++++++++++++++-
 1 file changed, 36 insertions(+), 1 deletion(-)

diff --git a/drivers/media/rc/pwm-ir-tx.c b/drivers/media/rc/pwm-ir-tx.c
index 047472dc9244..f9c95d034493 100644
--- a/drivers/media/rc/pwm-ir-tx.c
+++ b/drivers/media/rc/pwm-ir-tx.c
@@ -10,6 +10,7 @@
 #include <linux/slab.h>
 #include <linux/of.h>
 #include <linux/platform_device.h>
+#include <linux/regulator/consumer.h>
 #include <linux/hrtimer.h>
 #include <linux/completion.h>
 #include <media/rc-core.h>
@@ -19,6 +20,7 @@
 
 struct pwm_ir {
 	struct pwm_device *pwm;
+	struct regulator *reg;
 	struct hrtimer timer;
 	struct completion tx_done;
 	struct pwm_state *state;
@@ -63,10 +65,16 @@ static int pwm_ir_tx_sleep(struct rc_dev *dev, unsigned int *txbuf,
 	struct pwm_ir *pwm_ir = dev->priv;
 	struct pwm_device *pwm = pwm_ir->pwm;
 	struct pwm_state state;
-	int i;
+	int i, ret;
 	ktime_t edge;
 	long delta;
 
+	if (pwm_ir->reg) {
+		ret = regulator_enable(pwm_ir->reg);
+		if (ret)
+			return ret;
+	}
+
 	pwm_init_state(pwm, &state);
 
 	state.period = DIV_ROUND_CLOSEST(NSEC_PER_SEC, pwm_ir->carrier);
@@ -87,6 +95,12 @@ static int pwm_ir_tx_sleep(struct rc_dev *dev, unsigned int *txbuf,
 	state.enabled = false;
 	pwm_apply_might_sleep(pwm, &state);
 
+	if (pwm_ir->reg) {
+		ret = regulator_disable(pwm_ir->reg);
+		if (ret)
+			return ret;
+	}
+
 	return count;
 }
 
@@ -96,6 +110,7 @@ static int pwm_ir_tx_atomic(struct rc_dev *dev, unsigned int *txbuf,
 	struct pwm_ir *pwm_ir = dev->priv;
 	struct pwm_device *pwm = pwm_ir->pwm;
 	struct pwm_state state;
+	int ret;
 
 	pwm_init_state(pwm, &state);
 
@@ -107,10 +122,22 @@ static int pwm_ir_tx_atomic(struct rc_dev *dev, unsigned int *txbuf,
 	pwm_ir->txbuf_index = 0;
 	pwm_ir->state = &state;
 
+	if (pwm_ir->reg) {
+		ret = regulator_enable(pwm_ir->reg);
+		if (ret)
+			return ret;
+	}
+
 	hrtimer_start(&pwm_ir->timer, 0, HRTIMER_MODE_REL);
 
 	wait_for_completion(&pwm_ir->tx_done);
 
+	if (pwm_ir->reg) {
+		ret = regulator_disable(pwm_ir->reg);
+		if (ret)
+			return ret;
+	}
+
 	return count;
 }
 
@@ -157,6 +184,14 @@ static int pwm_ir_probe(struct platform_device *pdev)
 	if (IS_ERR(pwm_ir->pwm))
 		return PTR_ERR(pwm_ir->pwm);
 
+	pwm_ir->reg = devm_regulator_get_optional(&pdev->dev, "power");
+	if (IS_ERR(pwm_ir->reg)) {
+		if (PTR_ERR(pwm_ir->reg) != -ENODEV)
+			return PTR_ERR(pwm_ir->reg);
+
+		pwm_ir->reg = NULL;
+	}
+
 	pwm_ir->carrier = 38000;
 	pwm_ir->duty_cycle = 50;
 

-- 
2.56.0

