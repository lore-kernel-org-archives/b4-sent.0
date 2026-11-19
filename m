From: Umer Uddin <umer.uddin@mentallysanemainliners.org>
Date: Thu, 19 Nov 2026 19:49:18 +0000
Subject: [PATCH 2/6] dt-bindings: usb: samsung,exynos-dwc3: Add Exynos7885
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-gta3xllte-usb-battery-v1-2-0cf5f763522e@mentallysanemainliners.org>
References: <20261119-gta3xllte-usb-battery-v1-0-0cf5f763522e@mentallysanemainliners.org>
In-Reply-To: <20261119-gta3xllte-usb-battery-v1-0-0cf5f763522e@mentallysanemainliners.org>
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Marek Szyprowski <m.szyprowski@samsung.com>, 
 Sylwester Nawrocki <s.nawrocki@samsung.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-samsung-soc@vger.kernel.org, 
 Umer Uddin <umer.uddin@mentallysanemainliners.org>, 
 David Virag <virag.david003@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795117759; l=1209;
 i=umer.uddin@mentallysanemainliners.org; s=20261109;
 h=from:subject:message-id; bh=v4DbW6fDalAVYk0Te5ZSWb09z4/f2QgblZnvvRGhkXU=;
 b=jmKfYf+qTlQd9d4FBC5QF2O23tXQdfJDxnNZ6ipXFAqDnWYNWcpSMYyMMu9M2IdQPbhmBkBQq
 wzptHRFlRhwB13miEVgN2al2PTGUYX2ZVzT52IDPbhv8P6+WDAhrLXd
X-Developer-Key: i=umer.uddin@mentallysanemainliners.org; a=ed25519;
 pk=Hsgrt4A72CFTe27AI1AAWlnLsiQrlb4+T+cbrfWDhUA=
X-Endpoint-Received: by B4 Relay for umer.uddin@mentallysanemainliners.org/20261109 with auth_id=1466
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: David Virag <virag.david003@gmail.com>

Exynos7885 SoC has a DWC3 compatible USB controller, so it can reuse the
existing Exynos glue layer. Clocks are the same as on Exynos850.

Signed-off-by: David Virag <virag.david003@gmail.com>
[Umer Uddin: use samsung,exynos850-dwusb3 as fallback compatible instead
of adding a separate match entry to the dwc3-exynos driver]
Signed-off-by: Umer Uddin <umer.uddin@mentallysanemainliners.org>
---
 Documentation/devicetree/bindings/usb/samsung,exynos-dwc3.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/usb/samsung,exynos-dwc3.yaml b/Documentation/devicetree/bindings/usb/samsung,exynos-dwc3.yaml
index 8af0143c3e47..f62e3ed82257 100644
--- a/Documentation/devicetree/bindings/usb/samsung,exynos-dwc3.yaml
+++ b/Documentation/devicetree/bindings/usb/samsung,exynos-dwc3.yaml
@@ -24,6 +24,9 @@ properties:
       - items:
           - const: samsung,exynos8890-dwusb3
           - const: samsung,exynos7-dwusb3
+      - items:
+          - const: samsung,exynos7885-dwusb3
+          - const: samsung,exynos850-dwusb3
       - items:
           - const: samsung,exynos990-dwusb3
           - const: samsung,exynos850-dwusb3

-- 
2.56.1

