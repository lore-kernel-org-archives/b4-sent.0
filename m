From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Thu, 24 Apr 2025 16:43:17 +0800
Subject: [PATCH] dt-bindings: serial: amlogic,meson-uart: Add compatible
 string for S6/S7/S7D
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250424-uart-binding-v1-1-eb0f6d97a654@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAKT5CWgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDEyNj3dLEohLdpMy8lMy8dF0Dc2MTY6OkZBMLAxMloJaCotS0zAqwcdG
 xtbUAPfJZZV4AAAA=
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745484197; l=1533;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=3DWwMa+7PjWV5QLyMZHNnOjU4vTv3C9jBSh+V9Rd7Tc=;
 b=Cb+so7K1Vu9uCfUtZiKOmxmz+Rqy5dDfuSxj7i+QuK/vA1royFFeEHl+Gmww/XaVucyPTJ1jc
 PwTh+xUr8OZCFNmRPfd/IIlGjdZ6HaPruf8ONbvi7L6kW1aevm3Kt6+
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Amlogic S6/S7/7D SoCs uses the same UART controller as S4 SoCs and G12A.
There is no need for an extra compatible line in the driver, but
add S6/S7/S7D compatible line for documentation.

Acked-by: Rob Herring (Arm) <robh@kernel.org>
Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
This patch has been reviewed in the submission below(patch 4/7).
https://lore.kernel.org/all/20250317-s6-s7-basic-v1-0-d653384e41f3@amlogic.com/

It is just sent again separately since it goes via the tty tree

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 Documentation/devicetree/bindings/serial/amlogic,meson-uart.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/serial/amlogic,meson-uart.yaml b/Documentation/devicetree/bindings/serial/amlogic,meson-uart.yaml
index 0565fb7649c5..d8ad1bb6172d 100644
--- a/Documentation/devicetree/bindings/serial/amlogic,meson-uart.yaml
+++ b/Documentation/devicetree/bindings/serial/amlogic,meson-uart.yaml
@@ -56,6 +56,9 @@ properties:
         items:
           - enum:
               - amlogic,a4-uart
+              - amlogic,s6-uart
+              - amlogic,s7-uart
+              - amlogic,s7d-uart
               - amlogic,t7-uart
           - const: amlogic,meson-s4-uart
 

---
base-commit: 8f5f9fc2ee8cd65fa0e8062885d4ffa0688fe7c6
change-id: 20250423-uart-binding-073432bc4804

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

