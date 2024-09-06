From: Kelvin Zhang <kelvin.zhang@amlogic.com>
Date: Fri, 06 Sep 2024 20:46:12 +0800
Subject: [PATCH 1/2] dt-bindings: pwm: amlogic: Document C3 PWM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240906-c3-pwm-v1-1-acaf17fad247@amlogic.com>
References: <20240906-c3-pwm-v1-0-acaf17fad247@amlogic.com>
In-Reply-To: <20240906-c3-pwm-v1-0-acaf17fad247@amlogic.com>
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-pwm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, Kelvin Zhang <kelvin.zhang@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725626786; l=856;
 i=kelvin.zhang@amlogic.com; s=20240329; h=from:subject:message-id;
 bh=IKxQCbqCymKpXimBeJjfJfj63RpeX53D3eg20nkQmNk=;
 b=zqPcIqkIxj3orOtAbzHPmrmAGEPra58zMaXLyWATX9mRAm6IjFmYHGUNAd25JsmKjUHvjgUiI
 viXPz7Wg/OPCNrukKifurjyz913UP/iVe3RzlrQOXnIGlSYLC/SNEqZ
X-Developer-Key: i=kelvin.zhang@amlogic.com; a=ed25519;
 pk=pgnle7HTNvnNTcOoGejvtTC7BJT30HUNXfMHRRXSylI=
X-Endpoint-Received: by B4 Relay for kelvin.zhang@amlogic.com/20240329 with auth_id=148
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document amlogic,c3-pwm compatible, which falls back to the meson-s4-pwm
group.

Signed-off-by: Kelvin Zhang <kelvin.zhang@amlogic.com>
---
 Documentation/devicetree/bindings/pwm/pwm-amlogic.yaml | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/pwm/pwm-amlogic.yaml b/Documentation/devicetree/bindings/pwm/pwm-amlogic.yaml
index 1d71d4f8f328..356371164acd 100644
--- a/Documentation/devicetree/bindings/pwm/pwm-amlogic.yaml
+++ b/Documentation/devicetree/bindings/pwm/pwm-amlogic.yaml
@@ -44,6 +44,10 @@ properties:
               - amlogic,meson-axg-pwm-v2
               - amlogic,meson-g12-pwm-v2
           - const: amlogic,meson8-pwm-v2
+      - items:
+          - enum:
+              - amlogic,c3-pwm
+          - const: amlogic,meson-s4-pwm
 
   reg:
     maxItems: 1

-- 
2.37.1

