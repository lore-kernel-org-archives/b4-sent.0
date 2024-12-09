From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Mon, 09 Dec 2024 11:46:15 +0100
Subject: [PATCH] power: supply: gpio-charger: Fix set charge current limits
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241209-fix-charge-current-limit-v1-1-760d9b8f2af3@liebherr.com>
X-B4-Tracking: v=1; b=H4sIAHbKVmcC/x2MQQqAMAwEvyI5G7BFD/oV8VBrqgGtkqoI0r8bP
 A6zsy8kEqYEXfGC0M2J96hgygL84uJMyJMy2MrWxlYtBn5QjajxlwjFE1fe+ETXUDOOLkzBGND
 8ENLtf90POX+owkMkagAAAA==
X-Change-ID: 20241209-fix-charge-current-limit-a5e5bbafdf11
To: Sebastian Reichel <sre@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>
Cc: Sebastian Reichel <sebastian.reichel@collabora.com>, 
 linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Dimitri Fedrau <dimitri.fedrau@liebherr.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733741199; l=1471;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=JMP/YPv48CKxY8k+OHWu1fWQP76Gr1cU/J9kXPrJcps=;
 b=BYybNBmEiGJm6J9m12P59VausTgYIExWvufe6VUrPuap1Hx5eJ7OG9YSOmiA/l0w0NPXVI/EY
 ZT1wKRPwS8uAgh5NI+K3CIJdEfSKOsTWHGLMq+HhoSwguHe5ryQ6IC7
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix set charge current limits for devices which allow to set the lowest
charge current limit to be greater zero. If requested charge current limit
is below lowest limit, the index equals current_limit_map_size which leads
to accessing memory beyond allocated memory.

Fixes: be2919d8355e ("power: supply: gpio-charger: add charge-current-limit feature")
Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 drivers/power/supply/gpio-charger.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/power/supply/gpio-charger.c b/drivers/power/supply/gpio-charger.c
index 68212b39785beabfe5536a18fa15bc249f7b1eea..6139f736ecbe4ffc74848797a72095f4cadf3b62 100644
--- a/drivers/power/supply/gpio-charger.c
+++ b/drivers/power/supply/gpio-charger.c
@@ -67,6 +67,14 @@ static int set_charge_current_limit(struct gpio_charger *gpio_charger, int val)
 		if (gpio_charger->current_limit_map[i].limit_ua <= val)
 			break;
 	}
+
+	/*
+	 * If a valid charge current limit isn't found, default to smallest
+	 * current limitation for safety reasons.
+	 */
+	if (i >= gpio_charger->current_limit_map_size)
+		i = gpio_charger->current_limit_map_size - 1;
+
 	mapping = gpio_charger->current_limit_map[i];
 
 	for (i = 0; i < ndescs; i++) {

---
base-commit: 88e4a7dc04b7828315292eb3acaa466c9c123d8b
change-id: 20241209-fix-charge-current-limit-a5e5bbafdf11

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

