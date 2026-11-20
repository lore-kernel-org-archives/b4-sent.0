From: Joseph Telaak <joseph@telaak.dev>
Date: Fri, 20 Nov 2026 15:31:06 -0500
Subject: [PATCH v3 1/3] dt-bindings: usb: dwc2: Add Siflower SF19A2890
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-sf19a2890-dwc2-v3-1-de377bd408a0@telaak.dev>
References: <20261120-sf19a2890-dwc2-v3-0-de377bd408a0@telaak.dev>
In-Reply-To: <20261120-sf19a2890-dwc2-v3-0-de377bd408a0@telaak.dev>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>
Cc: Chuanhong Guo <gch981213@gmail.com>, linux-mips@vger.kernel.org, 
 linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Conor Dooley <conor.dooley@microchip.com>, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795206676; l=864;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=w+QiNRAN39ZqxwzT8eL/SeZFAxcNqrljvHT4hVUBrPc=;
 b=+aanc8SFiEJySAcjYFTPjNa/h7pkwT4ilDA6rSZ97oWc4EJ1W2leT/yP94vOE2SajMrcmbtrA
 9DkBL5QMdRGAu2XkHpWWSnDHcXthaUKOn+L3zICXhcZb8m/eV1AOGKb
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Siflower SF19A2890 has a DWC OTG 3.30a controller, with its own
bus burst limit and an OTG interrupt quirk.

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 Documentation/devicetree/bindings/usb/dwc2.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/usb/dwc2.yaml b/Documentation/devicetree/bindings/usb/dwc2.yaml
index 6c3a10991b8b..3b4763f476ea 100644
--- a/Documentation/devicetree/bindings/usb/dwc2.yaml
+++ b/Documentation/devicetree/bindings/usb/dwc2.yaml
@@ -58,6 +58,7 @@ properties:
           - const: snps,dwc2
       - const: amcc,dwc-otg
       - const: apm,apm82181-dwc-otg
+      - const: siflower,sf19a2890-usb
       - const: snps,dwc2
       - const: sophgo,cv1800b-usb
       - const: st,stm32f4x9-fsotg

-- 
Git-155)

