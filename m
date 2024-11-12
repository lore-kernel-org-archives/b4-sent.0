From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Tue, 12 Nov 2024 18:26:55 +0800
Subject: [PATCH v5 1/5] dt-bindings: pinctrl: modify gpio-cells property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241112-a4_pinctrl-v5-1-3460ce10c480@amlogic.com>
References: <20241112-a4_pinctrl-v5-0-3460ce10c480@amlogic.com>
In-Reply-To: <20241112-a4_pinctrl-v5-0-3460ce10c480@amlogic.com>
To: Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731407219; l=972;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=vZqjjnCO3zwPWuTy0qDsSgOCsxCV7fM7PewSW3T9rgc=;
 b=vcZvhifPHORlWOS0LP5dmR4xmjVZApG64++PFcGo9B8LlLDz+aPXv1CK9UdzrxNjozCr6v3/S
 tMKjBWTbJL1BDcc3W6TDDy84l6vUVuKboaEkrAnonuxhKjQFb/yba6X
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Extend the value range of #gpio-cells property, including [2, 3],
to compatible with Amlogic A4 SoC and later chips's pinctrl module.
The early GPIO parameter number is 2, and the later GPIO parameter
number is 3.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../devicetree/bindings/pinctrl/amlogic,meson-pinctrl-common.yaml       | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/pinctrl/amlogic,meson-pinctrl-common.yaml b/Documentation/devicetree/bindings/pinctrl/amlogic,meson-pinctrl-common.yaml
index e707c222a07f..6b53577dea59 100644
--- a/Documentation/devicetree/bindings/pinctrl/amlogic,meson-pinctrl-common.yaml
+++ b/Documentation/devicetree/bindings/pinctrl/amlogic,meson-pinctrl-common.yaml
@@ -36,7 +36,7 @@ $defs:
       gpio-controller: true
 
       "#gpio-cells":
-        const: 2
+        enum: [2, 3]
 
       gpio-ranges:
         maxItems: 1

-- 
2.37.1

