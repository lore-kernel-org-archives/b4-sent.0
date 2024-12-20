From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Fri, 20 Dec 2024 11:37:54 +0100
Subject: [PATCH v2 4/4] gpio: mpc8xxx: Preserve pre-init state of outputs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241220-mpc83xx-misc-v2-4-ff4c17ee5fa4@posteo.net>
References: <20241220-mpc83xx-misc-v2-0-ff4c17ee5fa4@posteo.net>
In-Reply-To: <20241220-mpc83xx-misc-v2-0-ff4c17ee5fa4@posteo.net>
To: Mario Six <mario.six@gdsys.cc>, Tom Rini <trini@konsulko.com>
Cc: Sinan Akman <sinan@writeme.com>, u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734691081; l=2017;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=3OOJ1gFlOUtLdlbIMEpQp2gBYtM4bC2L3oBPBpICZwE=;
 b=CUY4EeyCZnhTAJVh8ZGfJXjBCo4QrmZ9Rk5v4rmy7uFZHR+4L25bpnFsOsYsvyPtXoGXWhsh8
 sVMNiQvUZBaDnRnqEUZ/WJMCGNpUrkZodMS5HEoF+XAOuE16mYkwZQk
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The mpc8xxx_gpio driver contains a workaround for certain chips
where the previously written state of outputs cannot be read back
from the GPIO data (GPDAT) register (MPC8572/MPC8536). This workaround
consists of tracking the state of GPDAT in a "shadow register" (i.e. a
software variable). The shadow register is initialized to zero.

This results in a problem w.r.t. outputs that are configured to a
high (1) state before U-Boot runs, but not touched by U-Boot itself:
Due to the zero-initialization, these GPIOs end up being set to zero,
the first time that any other output is set.

To avoid such issues initialize the GPDAT shadow register to the value
previously held by any outputs, if possible. On MPC8572/MPC8536 this
should make no difference, i.e. the shadow register should be
initialized to zero on these chips.

This patch has been tested on a MPC8314E-based board.

Reviewed-by: Sinan Akman <sinan@writeme.com>
Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---

V2:
- Clarify how the patch has been tested
---
 drivers/gpio/mpc8xxx_gpio.c | 12 +++++++++++-
 1 file changed, 11 insertions(+), 1 deletion(-)

diff --git a/drivers/gpio/mpc8xxx_gpio.c b/drivers/gpio/mpc8xxx_gpio.c
index e9bd38f162c10c76460bc63f93c03a711cb4d38e..709d04017d154ecae1e8d16d7c35ced521157c4d 100644
--- a/drivers/gpio/mpc8xxx_gpio.c
+++ b/drivers/gpio/mpc8xxx_gpio.c
@@ -204,7 +204,17 @@ static int mpc8xxx_gpio_plat_to_priv(struct udevice *dev)
 		return -ENOMEM;
 
 	priv->gpio_count = plat->ngpios;
-	priv->dat_shadow = 0;
+
+	/*
+	 * On platforms that do support reading back output values, we want to
+	 * try preserving them, so that we don't accidentally set unrelated
+	 * GPIOs to zero in mpc8xxx_gpio_set_value.
+	 */
+	if (priv->little_endian)
+		priv->dat_shadow = in_le32(&priv->base->gpdat) & in_le32(&priv->base->gpdir);
+	else
+		priv->dat_shadow = in_be32(&priv->base->gpdat) & in_be32(&priv->base->gpdir);
+
 
 	priv->type = driver_data;
 

-- 
2.45.2

