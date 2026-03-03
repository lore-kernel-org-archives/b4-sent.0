From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Tue, 03 Mar 2026 10:05:24 +0000
Subject: [PATCH] dt-bindings: serial: amlogic,meson-uart: Add compatible
 string for A9
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260303-serial-binding-v1-1-c3df2a8f6fa3@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAGOypmkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDYwNjXZD6xBzdpMy8lMy8dN20FEtDEwsTE3NDczMloKaCotS0zAqwgdG
 xtbUAB4QGzmAAAAA=
X-Change-ID: 20260303-serial-binding-fd9148447176
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772532325; l=1431;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=9mURwWMNKHKPj5DQwkxO2/oc3KhRCoTzoGeBobWkQYM=;
 b=JymmJL57wfD3WRuexnCQrwj4gWarkh2+sQtMISQ+nJ1d184MWywv+CAUTFEJ+63gky+C2/16m
 Q8gP9fwsZgFDGeltyP3ZIJJ6/77WPI0Z0i/jNaphv5N1Ab//xjCNCEa
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Amlogic A9 SoCs uses the same UART controller as S4 SoCs.
There is no need for an extra compatible line in the driver,
but add A9 compatible line for documentation.

Reviewed-by: Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
This patch is from the submission below(patch 2/3).
https://lore.kernel.org/all/20260205-a9-baisc-dts-v1-0-1212b46f95a7@amlogic.com/

It is just sent again separately since it goes via the tty tree
---
 Documentation/devicetree/bindings/serial/amlogic,meson-uart.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/serial/amlogic,meson-uart.yaml b/Documentation/devicetree/bindings/serial/amlogic,meson-uart.yaml
index d8ad1bb6172d..a2702319685d 100644
--- a/Documentation/devicetree/bindings/serial/amlogic,meson-uart.yaml
+++ b/Documentation/devicetree/bindings/serial/amlogic,meson-uart.yaml
@@ -56,6 +56,7 @@ properties:
         items:
           - enum:
               - amlogic,a4-uart
+              - amlogic,a9-uart
               - amlogic,s6-uart
               - amlogic,s7-uart
               - amlogic,s7d-uart

---
base-commit: 6de23f81a5e08be8fbf5e8d7e9febc72a5b5f27f
change-id: 20260303-serial-binding-fd9148447176

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

