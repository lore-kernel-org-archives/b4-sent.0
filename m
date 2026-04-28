From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Tue, 28 Apr 2026 08:22:48 +0000
Subject: [PATCH 1/2] dt-bindings: pinctl: amlogic,pinctrl-a4: Add
 compatible string for A9
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260428-a9-pinctrl-v1-1-cd611bb5f52d@amlogic.com>
References: <20260428-a9-pinctrl-v1-0-cd611bb5f52d@amlogic.com>
In-Reply-To: <20260428-a9-pinctrl-v1-0-cd611bb5f52d@amlogic.com>
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777364572; l=786;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=ZCQ9AXusiocY4m+0VEcyvhrnI6BCr+BT62vN2ubdhfE=;
 b=xjCHxc9DgI/cq+g0Uw7BwWKjy/UVmfIvgt2iNeeY93ziednAQAhkzXWGcDmkq8pnrle7LI4pW
 LlOPIaqIjtVAAPz6riUk3JbQz2ujPhAGPzn4COaKfZDnryewWevr14o
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update dt-binding document for pinctrl of Amlogic A9.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml b/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml
index 6ba66c2033b4..b69db1b95345 100644
--- a/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml
+++ b/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml
@@ -17,6 +17,7 @@ properties:
     oneOf:
       - enum:
           - amlogic,pinctrl-a4
+          - amlogic,pinctrl-a9
           - amlogic,pinctrl-s6
           - amlogic,pinctrl-s7
       - items:

-- 
2.52.0

