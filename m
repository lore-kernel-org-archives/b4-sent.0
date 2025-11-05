From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Wed, 05 Nov 2025 17:45:32 +0800
Subject: [PATCH 1/5] dt-bindings: interrupt-controller: Add support for
 Amlogic S6 S7 and S7D SoCs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251105-irqchip-gpio-s6-s7-s7d-v1-1-b4d1fe4781c1@amlogic.com>
References: <20251105-irqchip-gpio-s6-s7-s7d-v1-0-b4d1fe4781c1@amlogic.com>
In-Reply-To: <20251105-irqchip-gpio-s6-s7-s7d-v1-0-b4d1fe4781c1@amlogic.com>
To: Thomas Gleixner <tglx@linutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Heiner Kallweit <hkallweit1@gmail.com>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762336003; l=1048;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=P95W9L3DXzWgmu3DvSM7acqbbjZPHAZ7SEai9ZgGXgQ=;
 b=doXrU4qLxxUcLZ0b6f1xAhEm7WtM6bSso8PEa2qebHzTzMiW3Kg8zad34VDAJ8Dwf/WOBVLNL
 /JIc9w2Zx37Dryj3gC3Fn+cEr/2OybhlhCA12VvedXLC4n5i9UeThmB
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update dt-binding document for GPIO interrupt controller
of Amlogic S6 S7 and S7D SoCs.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../bindings/interrupt-controller/amlogic,meson-gpio-intc.yaml         | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/interrupt-controller/amlogic,meson-gpio-intc.yaml b/Documentation/devicetree/bindings/interrupt-controller/amlogic,meson-gpio-intc.yaml
index 3d60d9e9e208..d0fad930de9d 100644
--- a/Documentation/devicetree/bindings/interrupt-controller/amlogic,meson-gpio-intc.yaml
+++ b/Documentation/devicetree/bindings/interrupt-controller/amlogic,meson-gpio-intc.yaml
@@ -39,6 +39,9 @@ properties:
               - amlogic,a4-gpio-ao-intc
               - amlogic,a5-gpio-intc
               - amlogic,c3-gpio-intc
+              - amlogic,s6-gpio-intc
+              - amlogic,s7-gpio-intc
+              - amlogic,s7d-gpio-intc
               - amlogic,t7-gpio-intc
           - const: amlogic,meson-gpio-intc
 

-- 
2.37.1

