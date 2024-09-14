From: Kelvin Zhang <kelvin.zhang@amlogic.com>
Date: Sat, 14 Sep 2024 13:48:58 +0800
Subject: [PATCH v2 1/2] dt-bindings: pwm: amlogic: Document C3 PWM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240914-c3-pwm-v2-1-ac1f34c68ac2@amlogic.com>
References: <20240914-c3-pwm-v2-0-ac1f34c68ac2@amlogic.com>
In-Reply-To: <20240914-c3-pwm-v2-0-ac1f34c68ac2@amlogic.com>
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-pwm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, Kelvin Zhang <kelvin.zhang@amlogic.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726293023; l=850;
 i=kelvin.zhang@amlogic.com; s=20240329; h=from:subject:message-id;
 bh=jkkwhfD2HY3XpEmv2fppIWZ7XRYKVWP9wFrzIH5jMmg=;
 b=upG6pfE3Oi/FBjPRU+nkf+zdeEhsAdpdeHrLcqCTpPSv3WhaQKJWpzfP3mOP+jyOCt3o8qCmx
 dTJOXhQwUHNCVliqzt/TpaRX7jy9c+xh7Pn3xQKZ04ZLz3US6JflIHn
X-Developer-Key: i=kelvin.zhang@amlogic.com; a=ed25519;
 pk=pgnle7HTNvnNTcOoGejvtTC7BJT30HUNXfMHRRXSylI=
X-Endpoint-Received: by B4 Relay for kelvin.zhang@amlogic.com/20240329 with auth_id=148
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document amlogic,c3-pwm compatible, which falls back to the meson-s4-pwm
group.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: Kelvin Zhang <kelvin.zhang@amlogic.com>
---
 Documentation/devicetree/bindings/pwm/pwm-amlogic.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/pwm/pwm-amlogic.yaml b/Documentation/devicetree/bindings/pwm/pwm-amlogic.yaml
index e021cf59421a..cc3ebd4deeb6 100644
--- a/Documentation/devicetree/bindings/pwm/pwm-amlogic.yaml
+++ b/Documentation/devicetree/bindings/pwm/pwm-amlogic.yaml
@@ -39,6 +39,7 @@ properties:
           - amlogic,meson-s4-pwm
       - items:
           - enum:
+              - amlogic,c3-pwm
               - amlogic,meson-a1-pwm
           - const: amlogic,meson-s4-pwm
       - items:

-- 
2.37.1

