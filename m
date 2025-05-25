From: George Moussalem <george.moussalem@outlook.com>
Date: Sun, 25 May 2025 21:56:04 +0400
Subject: [PATCH 1/5] dt-bindings: net: qca,ar803x: Add IPQ5018 Internal GE
 PHY support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250525-ipq5018-ge-phy-v1-1-ddab8854e253@outlook.com>
References: <20250525-ipq5018-ge-phy-v1-0-ddab8854e253@outlook.com>
In-Reply-To: <20250525-ipq5018-ge-phy-v1-0-ddab8854e253@outlook.com>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-clk@vger.kernel.org, George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748195765; l=2331;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=ayUL3wYd9rvR/ur2nGKYm+iV8WIysnk8OxJFKcrz/ig=;
 b=Aekb7yvWZ5o9Vu+/YejmG2dcGjSGGiy0sUVTXRtXoAARJBX9e0Yh53Df5khsfiuiuTzfUWXMp
 7UerUABr5A2AgqMJGulb8w/DKe1Rhx1gyp/R1pqYNddLikeBxoT0d9b
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the IPQ5018 Internal Gigabit Ethernet PHY found in the IPQ5018
SoC. Its output pins provide an MDI interface to either an external
switch in a PHY to PHY link scenario or is directly attached to an RJ45
connector.

In a phy to phy architecture, DAC values need to be set to accommodate
for the short cable length. As such, add an optional property to do so.

In addition, the LDO controller found in the IPQ5018 SoC needs to be
enabled to driver low voltages to the CMN Ethernet Block (CMN BLK) which
the GE PHY depends on. The LDO must be enabled in TCSR by writing to a
specific register. So, adding a property that takes a phandle to the
TCSR node and the register offset.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 .../devicetree/bindings/net/qca,ar803x.yaml        | 23 ++++++++++++++++++++++
 1 file changed, 23 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/qca,ar803x.yaml b/Documentation/devicetree/bindings/net/qca,ar803x.yaml
index 3acd09f0da863137f8a05e435a1fd28a536c2acd..a9e94666ff0af107db4f358b144bf8644c6597e8 100644
--- a/Documentation/devicetree/bindings/net/qca,ar803x.yaml
+++ b/Documentation/devicetree/bindings/net/qca,ar803x.yaml
@@ -60,6 +60,29 @@ properties:
     minimum: 1
     maximum: 255
 
+  qca,dac:
+    description:
+      Values for MDAC and EDAC to adjust amplitude, bias current settings,
+      and error detection and correction algorithm. Only set in a PHY to PHY
+      link architecture to accommodate for short cable length.
+    $ref: /schemas/types.yaml#/definitions/uint32-array
+    items:
+      - items:
+          - description: value for MDAC. Expected 0x10, if set
+          - description: value for EDAC. Expected 0x10, if set
+      - maxItems: 1
+
+  qca,eth-ldo-enable:
+    description:
+      Register in TCSR to enable the LDO controller to supply
+      low voltages to the common ethernet block (CMN BLK).
+    $ref: /schemas/types.yaml#/definitions/phandle-array
+    items:
+      - items:
+          - description: phandle of TCSR syscon
+          - description: offset of TCSR register to enable the LDO controller
+      - maxItems: 1
+
   vddio-supply:
     description: |
       RGMII I/O voltage regulator (see regulator/regulator.yaml).

-- 
2.49.0

