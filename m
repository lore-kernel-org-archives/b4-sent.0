From: Joseph Telaak <joseph@telaak.dev>
Date: Wed, 04 Nov 2026 02:22:06 -0500
Subject: [PATCH 1/3] dt-bindings: usb: dwc2: Add Siflower SF19A2890
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-sf19a2890-dwc2-v1-1-d959375e26ab@telaak.dev>
References: <20261104-sf19a2890-dwc2-v1-0-d959375e26ab@telaak.dev>
In-Reply-To: <20261104-sf19a2890-dwc2-v1-0-d959375e26ab@telaak.dev>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Minas Harutyunyan <hminas@synopsys.com>
Cc: Chuanhong Guo <gch981213@gmail.com>, linux-usb@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793776930; l=810;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=y6CqO/fqkTYFYGM/WugYCN4cRmBu9+bliuNhbXSwqbQ=;
 b=4a6RgqvjF3gfLx2o9U80bxzb+8Hd5FVq7eSWfhku+r1rTxlvh5KAJ7GOtCvC/fEXYCC6AHRV7
 dhnasCqWMiMDEcRoBcLEwCfsZY2EdsYMZ+6Cy7YUcTpcYWvy8w4K7ET
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Siflower SF19A2890 has a DWC OTG 3.30a controller, with its own
bus burst limit and an OTG interrupt quirk.

Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 Documentation/devicetree/bindings/usb/dwc2.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/usb/dwc2.yaml b/Documentation/devicetree/bindings/usb/dwc2.yaml
index 6c3a10991..8217e84be 100644
--- a/Documentation/devicetree/bindings/usb/dwc2.yaml
+++ b/Documentation/devicetree/bindings/usb/dwc2.yaml
@@ -59,6 +59,7 @@ properties:
       - const: amcc,dwc-otg
       - const: apm,apm82181-dwc-otg
       - const: snps,dwc2
+      - const: siflower,sf19a2890-usb
       - const: sophgo,cv1800b-usb
       - const: st,stm32f4x9-fsotg
       - const: st,stm32f4x9-hsotg

-- 
Git-155)

