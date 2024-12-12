From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Thu, 12 Dec 2024 09:44:06 +0100
Subject: [PATCH net-next v3 1/2] dt-bindings: net: dp83822: Add support for
 GPIO2 clock output
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241212-dp83822-gpio2-clk-out-v3-1-e4af23490f44@liebherr.com>
References: <20241212-dp83822-gpio2-clk-out-v3-0-e4af23490f44@liebherr.com>
In-Reply-To: <20241212-dp83822-gpio2-clk-out-v3-0-e4af23490f44@liebherr.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Davis <afd@ti.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733993055; l=1961;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=oEDI75kHA2vxmaYUN5E6SgqscD6FI8Q9e8nx/xXgh34=;
 b=n8XOiO/Ng/08odC8bibzCb9PWP/hxxT+MhDB/24CxH2F0ml4yUwf2kM8V0Ti3L/ixt+OfqtVa
 rMZxq77zOA3Dth/DIULnOVnDtycq69eSwOMNL8VD/PXkBxFexZ9/kwP
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The GPIO2 pin on the DP83822 can be configured as clock output. Add
binding to support this feature.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 .../devicetree/bindings/net/ti,dp83822.yaml        | 27 ++++++++++++++++++++++
 1 file changed, 27 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/ti,dp83822.yaml b/Documentation/devicetree/bindings/net/ti,dp83822.yaml
index 784866ea392b2083e93d8dc9aaea93b70dc80934..50c24248df266f1950371b950cd9c4d417835f97 100644
--- a/Documentation/devicetree/bindings/net/ti,dp83822.yaml
+++ b/Documentation/devicetree/bindings/net/ti,dp83822.yaml
@@ -96,6 +96,32 @@ properties:
       - master
       - slave
 
+  ti,gpio2-clk-out:
+    description: |
+       DP83822 PHY only.
+       The GPIO2 pin on the DP83822 can be configured as clock output. When
+       omitted, the PHY's default will be left as is.
+
+       - 'mac-if': In MII mode the clock frequency is 25-MHz, in RMII Mode the
+         clock frequency is 50-MHz and in RGMII Mode the clock frequency is
+         25-MHz.
+       - 'xi': XI clock(pass-through clock from XI pin).
+       - 'int-ref': Internal reference clock 25-MHz.
+       - 'rmii-master-mode-ref': RMII master mode reference clock 50-MHz. RMII
+         master mode reference clock is identical to MAC IF clock in RMII master
+         mode.
+       - 'free-running': Free running clock 125-MHz.
+       - 'recovered': Recovered clock is a 125-MHz recovered clock from a
+         connected link partner.
+    $ref: /schemas/types.yaml#/definitions/string
+    enum:
+      - mac-if
+      - xi
+      - int-ref
+      - rmii-master-mode-ref
+      - free-running
+      - recovered
+
 required:
   - reg
 
@@ -110,6 +136,7 @@ examples:
         reg = <0>;
         rx-internal-delay-ps = <1>;
         tx-internal-delay-ps = <1>;
+        ti,gpio2-clk-out = "xi";
       };
     };
 

-- 
2.39.5

