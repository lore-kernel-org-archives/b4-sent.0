From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Fri, 05 Sep 2025 10:39:40 +0800
Subject: [PATCH] dt-bindings: power: keep alphabetical order
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250905-pm-fix-order-v1-1-3596e03d66e6@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAGtNumgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDSwNT3YJc3bTMCt38opTUIl3TRDPLpDQTM0MjE3MloJaColSgJNi46Nj
 aWgA2dWuCXgAAAA==
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jianxin Pan <jianxin.pan@amlogic.com>, Ulf Hansson <ulf.hansson@linaro.org>, 
 "hongyu.chen1" <hongyu.chen1@amlogic.com>
Cc: Conor Dooley <conor.dooley@microchip.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757039980; l=1166;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=v+dUEzn1Vq7pqlYwSYypI3RmFlt816zF2fbTkSK6CaI=;
 b=0NIo6ncVhxzcSBYsUPwwNstjwwmTebpSb7P86Z3fS5sMjjo8uiUE2k4Q2oiWF1Ym+XQVj4maz
 rorfr+gR0aNBFnqYjT9M3EUghIpXGKaFqKI+kHsytLqcqv892pudIQQ
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Keep the order of compatible property for amlogic sec power.

Fixes: 9428fff44f0c ("dt-bindings: power: add Amlogic S6 S7 S7D power domains")
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Keep alphabetical order.
---
 Documentation/devicetree/bindings/power/amlogic,meson-sec-pwrc.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/power/amlogic,meson-sec-pwrc.yaml b/Documentation/devicetree/bindings/power/amlogic,meson-sec-pwrc.yaml
index 12b71688dd34..7b843e9f51c7 100644
--- a/Documentation/devicetree/bindings/power/amlogic,meson-sec-pwrc.yaml
+++ b/Documentation/devicetree/bindings/power/amlogic,meson-sec-pwrc.yaml
@@ -23,10 +23,10 @@ properties:
       - amlogic,a4-pwrc
       - amlogic,a5-pwrc
       - amlogic,c3-pwrc
-      - amlogic,t7-pwrc
       - amlogic,s6-pwrc
       - amlogic,s7-pwrc
       - amlogic,s7d-pwrc
+      - amlogic,t7-pwrc
 
   "#power-domain-cells":
     const: 1

---
base-commit: b283b70967c0553b66e924f40e1c35b68fa8a1f7
change-id: 20250905-pm-fix-order-5a69bf461247

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

