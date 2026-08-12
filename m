From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Wed, 12 Aug 2026 10:22:12 +0000
Subject: [PATCH] pinctrl: meson: sync some modify from A4
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260812-sync_a4-v1-1-b7279c26e2bc@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAFNJfGoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDC0Mj3eLKvOT4RBNdA0PDxFQjg7Q0Y8NkJaDqgqLUtMwKsEnRsbW1ADs
 3+W5ZAAAA
X-Change-ID: 20260812-sync_a4-011ae20ff31c
To: Linus Walleij <linusw@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-gpio@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786530133; l=1591;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=e/6sQWJ1ygoCKacBsI4pbgOSo29ZSl5fN1COhUhv2b0=;
 b=+npSTpTZcyUHwNQKfVQMSVMkn7ZL/7EmlBUcCciWqI0ADTvpgZxjGNIPFljysn5gww3Skd8T9
 qvIhywPAjIADP8eZEf03v8d3ZxXYnHfIBxR600Yn+YSA1nkayfJfNlj
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Set the drive strength before enabling the output to avoid enabling
the output with an unintended drive strength.

Also return the actual output enable state from
PIN_CONFIG_OUTPUT_ENABLE instead of always reporting it as enabled.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Sync some fixes from  A4.
---
 drivers/pinctrl/meson/pinctrl-meson.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/pinctrl/meson/pinctrl-meson.c b/drivers/pinctrl/meson/pinctrl-meson.c
index 4507dc8b5563..1eea3e9d1cb2 100644
--- a/drivers/pinctrl/meson/pinctrl-meson.c
+++ b/drivers/pinctrl/meson/pinctrl-meson.c
@@ -252,11 +252,11 @@ static int meson_pinconf_set_output_drive(struct meson_pinctrl *pc,
 {
 	int ret;
 
-	ret = meson_pinconf_set_output(pc, pin, true);
+	ret = meson_pinconf_set_drive(pc, pin, high);
 	if (ret)
 		return ret;
 
-	return meson_pinconf_set_drive(pc, pin, high);
+	return meson_pinconf_set_output(pc, pin, true);
 }
 
 static int meson_pinconf_disable_bias(struct meson_pinctrl *pc,
@@ -498,9 +498,9 @@ static int meson_pinconf_get(struct pinctrl_dev *pcdev, unsigned int pin,
 		break;
 	case PIN_CONFIG_OUTPUT_ENABLE:
 		ret = meson_pinconf_get_output(pc, pin);
-		if (ret <= 0)
+		if (ret < 0)
 			return -EINVAL;
-		arg = 1;
+		arg = ret;
 		break;
 	case PIN_CONFIG_LEVEL:
 		ret = meson_pinconf_get_output(pc, pin);

---
base-commit: 761af93c9f1a100b8d9f71aa744b8f9abbbbbfb2
change-id: 20260812-sync_a4-011ae20ff31c

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

