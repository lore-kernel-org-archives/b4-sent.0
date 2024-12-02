From: Thomas Antoine <t.antoine@uclouvain.be>
Date: Mon, 02 Dec 2024 14:07:16 +0100
Subject: [PATCH 2/4] dt-bindings: power: supply: add max77759-fg flavor and
 don't require nvme address
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241202-b4-gs101_max77759_fg-v1-2-98d2fa7bfe30@uclouvain.be>
References: <20241202-b4-gs101_max77759_fg-v1-0-98d2fa7bfe30@uclouvain.be>
In-Reply-To: <20241202-b4-gs101_max77759_fg-v1-0-98d2fa7bfe30@uclouvain.be>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-samsung-soc@vger.kernel.org, Thomas Antoine <t.antoine@uclouvain.be>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733144859; l=1565;
 i=t.antoine@uclouvain.be; s=20241202; h=from:subject:message-id;
 bh=RTgptgGDXIpNksG2RFyyX00KmvPw//2EuQKYPNbTnPY=;
 b=lCO1iSdVtfEpPAC77nh9P49nbswY9iqm8xcrLTlOoQ/khMbOZuUNCBRNJ2ElFwDs5zIuHMEQL
 lx6XWdp54GpALvXJ3t8KOkKVW/Map6F2UCEye4rZu31wIix5Hm/sjwH
X-Developer-Key: i=t.antoine@uclouvain.be; a=ed25519;
 pk=sw7UYl31W1LTpgWRiX4xIF5x6ok7YWZ6XZnHqy/d3dY=
X-Endpoint-Received: by B4 Relay for t.antoine@uclouvain.be/20241202 with auth_id=289
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As the Maxim max77759 fuel gauge has no non-volatile memory slave address,
make it non-obligatory. Except for this, the max77759 seems to behave the
same as the max1720x.

Signed-off-by: Thomas Antoine <t.antoine@uclouvain.be>
---
 .../devicetree/bindings/power/supply/maxim,max17201.yaml   | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/Documentation/devicetree/bindings/power/supply/maxim,max17201.yaml b/Documentation/devicetree/bindings/power/supply/maxim,max17201.yaml
index fe3dd9bd5585618e45220c51023391a5b21acfd2..417fc2c4a1c1961654bc54ec1ac24602012f3335 100644
--- a/Documentation/devicetree/bindings/power/supply/maxim,max17201.yaml
+++ b/Documentation/devicetree/bindings/power/supply/maxim,max17201.yaml
@@ -16,6 +16,7 @@ properties:
   compatible:
     oneOf:
       - const: maxim,max17201
+      - const: maxim,max77759-fg
       - items:
           - enum:
               - maxim,max17205
@@ -25,11 +26,13 @@ properties:
     items:
       - description: ModelGauge m5 registers
       - description: Nonvolatile registers
+    minItems: 1
 
   reg-names:
     items:
       - const: m5
       - const: nvmem
+    minItems: 1
 
   interrupts:
     maxItems: 1
@@ -56,3 +59,14 @@ examples:
         interrupts = <31 IRQ_TYPE_LEVEL_LOW>;
       };
     };
+  - |
+    i2c {
+      #address-cells = <1>;
+      #size-cells = <0>;
+
+      fuel-gauge@36 {
+        compatible = "maxim,max77759-fg";
+        reg = <0x36>;
+        reg-names = "m5";
+      };
+    };

-- 
2.47.1

