From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Tue, 27 May 2025 13:23:28 +0800
Subject: [PATCH v3 1/6] dt-bindings: pinctl: amlogic,pinctrl-a4: Add
 compatible string for S7/S7D/S6
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250527-s6-s7-pinctrl-v3-1-44f6a0451519@amlogic.com>
References: <20250527-s6-s7-pinctrl-v3-0-44f6a0451519@amlogic.com>
In-Reply-To: <20250527-s6-s7-pinctrl-v3-0-44f6a0451519@amlogic.com>
To: Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748323408; l=1098;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=prX14EgQxx+RSrte6iKA/xDeT6QG01a/L3Prb2dIYk4=;
 b=MCVkadAxc+QJWR8KLI+ziAQqDUO8mWkG838u+iFmr/ATnjWWjKDFcHPXR4qxu9ANnEbYFecVo
 6mSMypFlLH4CW+7lda4TvdDv01tO5gtZW0bMLIfy3NgfOvxUtDYvICt
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update dt-binding document for pinctrl of Amlogic S7/S7D/S6.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml          | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml b/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml
index c36b6fe377ad..61a4685f9748 100644
--- a/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml
+++ b/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml
@@ -15,11 +15,18 @@ allOf:
 properties:
   compatible:
     oneOf:
-      - const: amlogic,pinctrl-a4
+      - enum:
+          - amlogic,pinctrl-a4
+          - amlogic,pinctrl-s6
+          - amlogic,pinctrl-s7
       - items:
           - enum:
               - amlogic,pinctrl-a5
           - const: amlogic,pinctrl-a4
+      - items:
+          - enum:
+              - amlogic,pinctrl-s7d
+          - const: amlogic,pinctrl-s7
 
   "#address-cells":
     const: 2

-- 
2.37.1

