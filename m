From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Thu, 13 Mar 2025 14:19:34 +0000
Subject: [PATCH 17/18] pwm: adp5585: make sure to include mod_devicetable.h
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250313-dev-adp5589-fw-v1-17-20e80d4bd4ea@analog.com>
References: <20250313-dev-adp5589-fw-v1-0-20e80d4bd4ea@analog.com>
In-Reply-To: <20250313-dev-adp5589-fw-v1-0-20e80d4bd4ea@analog.com>
To: linux-gpio@vger.kernel.org, linux-pwm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-input@vger.kernel.org
Cc: Lee Jones <lee@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Liu Ying <victor.liu@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741875562; l=672;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=tqFurroQfEZIIAKBp0UvBVXq9bErS1HNimmEhHkQKV0=;
 b=hfpdLUVm6u/hFamM0DfVIZ4hdcQUAfz3yq26VEMBtbydRqYE8myLuJ5SvqlaRxXxKjvU0KHV+
 bbhXliKvK+0Cwhh4nE1fXqvUwLEn0i2NxZQQLFNdEciZnWpxRD6QBE2
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Explicitly include mod_devicetable.h for struct platform_device_id.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/pwm/pwm-adp5585.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/pwm/pwm-adp5585.c b/drivers/pwm/pwm-adp5585.c
index cc8ac8f9e5669b4ffca06d4117a29f030393f48f..85308257724a338da4d2416c8d01e48e08bd0856 100644
--- a/drivers/pwm/pwm-adp5585.c
+++ b/drivers/pwm/pwm-adp5585.c
@@ -20,6 +20,7 @@
 #include <linux/mfd/adp5585.h>
 #include <linux/minmax.h>
 #include <linux/module.h>
+#include <linux/mod_devicetable.h>
 #include <linux/platform_device.h>
 #include <linux/pwm.h>
 #include <linux/regmap.h>

-- 
2.48.1

