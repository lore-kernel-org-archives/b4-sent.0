From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Wed, 16 Apr 2025 19:14:48 +0200
Subject: [PATCH net-next v3 2/4] dt-bindings: net: dp83822: add constraints
 for mac-termination-ohms
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250416-dp83822-mac-impedance-v3-2-028ac426cddb@liebherr.com>
References: <20250416-dp83822-mac-impedance-v3-0-028ac426cddb@liebherr.com>
In-Reply-To: <20250416-dp83822-mac-impedance-v3-0-028ac426cddb@liebherr.com>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, Andrew Davis <afd@ti.com>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744823698; l=1043;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=7BGE9tLp93J171J2FMQIe9ov/36XBFIFpQ/JiCi+QRk=;
 b=4I4GSYv9VJSa6JnkgkwdunnyRsu48D4YMC+tlSYhLrhhWW74kjNAHiycTFCavsjRpRaeOnR81
 QtWOY7xs/R8Cl1wSiciNSdgVaQVE5QmmgS3xVlZadhaULjNuf8AhPC+
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Property mac-termination-ohms is defined in ethernet-phy.yaml. Add allowed
values for the property.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 Documentation/devicetree/bindings/net/ti,dp83822.yaml | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/ti,dp83822.yaml b/Documentation/devicetree/bindings/net/ti,dp83822.yaml
index 50c24248df266f1950371b950cd9c4d417835f97..28a0bddb9af940e79a7a768a35ef588e28ec5bd4 100644
--- a/Documentation/devicetree/bindings/net/ti,dp83822.yaml
+++ b/Documentation/devicetree/bindings/net/ti,dp83822.yaml
@@ -122,6 +122,9 @@ properties:
       - free-running
       - recovered
 
+  mac-termination-ohms:
+    enum: [43, 44, 46, 48, 50, 53, 55, 58, 61, 65, 69, 73, 78, 84, 91, 99]
+
 required:
   - reg
 
@@ -137,6 +140,7 @@ examples:
         rx-internal-delay-ps = <1>;
         tx-internal-delay-ps = <1>;
         ti,gpio2-clk-out = "xi";
+        mac-termination-ohms = <43>;
       };
     };
 

-- 
2.39.5

