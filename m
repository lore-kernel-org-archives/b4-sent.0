From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Wed, 21 May 2025 11:19:57 +0800
Subject: [PATCH v2 3/8] dt-bindings: pinctl: amlogic,pinctrl-a4: Add
 compatible string for S6
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250521-s6-s7-pinctrl-v2-3-0ce5e3728404@amlogic.com>
References: <20250521-s6-s7-pinctrl-v2-0-0ce5e3728404@amlogic.com>
In-Reply-To: <20250521-s6-s7-pinctrl-v2-0-0ce5e3728404@amlogic.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747797595; l=777;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=SGs48wURMjraERop2ENTKoLj76g7oJ3ublU0QekYvzE=;
 b=Qt5nX5BPUxyZHj1gFAIs7uDZ/upCK3i0jkdHqry6mRyIScoOtknKTKFy2qmuUdObrWo4G+b+E
 4/UadHNq18uCcwbXtuXngUoIpK2bJz7DhYfBM/RAYjertkKpB3WUVBV
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update dt-binding document for pinctrl of Amlogic S6 SoC.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml b/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml
index 96a7c5646c13..61a4685f9748 100644
--- a/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml
+++ b/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml
@@ -17,6 +17,7 @@ properties:
     oneOf:
       - enum:
           - amlogic,pinctrl-a4
+          - amlogic,pinctrl-s6
           - amlogic,pinctrl-s7
       - items:
           - enum:

-- 
2.37.1

