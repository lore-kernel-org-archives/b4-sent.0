From: Aaron Kling <webgeek1234@gmail.com>
Date: Tue, 23 Sep 2025 12:05:28 -0500
Subject: [PATCH v4 2/9] dt-bindings: memory: tegra210: emc: Document OPP
 table and interconnect
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250923-t210-actmon-v4-2-442d1eb6377c@gmail.com>
References: <20250923-t210-actmon-v4-0-442d1eb6377c@gmail.com>
In-Reply-To: <20250923-t210-actmon-v4-0-442d1eb6377c@gmail.com>
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 MyungJoo Ham <myungjoo.ham@samsung.com>, 
 Kyungmin Park <kyungmin.park@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, Dmitry Osipenko <digetx@gmail.com>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-pm@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758647133; l=1483;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=fxGzLjsrwN+Xeyvc5NaaaQzuBIaA9YsbdpmmFPCmyp0=;
 b=hsOiaV/M2VIhcGeveysR5AylGa8wKtzkvFzMsLB0LmWqQ9yElaof7IxTy7UypEi4KSFa6j5QG
 bMn3IHN0avfD2gIfvZ2Bc6q8xOdm4mm20/s7uq0xIGMVQOlNVMsEE03
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These are needed for dynamic frequency scaling of the EMC controller.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 .../bindings/memory-controllers/nvidia,tegra210-emc.yaml      | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/Documentation/devicetree/bindings/memory-controllers/nvidia,tegra210-emc.yaml b/Documentation/devicetree/bindings/memory-controllers/nvidia,tegra210-emc.yaml
index bc8477e7ab193b7880bb681037985f3fccebf02f..4e4fb4acd7f9d376379a19b5f8e0256baaed5697 100644
--- a/Documentation/devicetree/bindings/memory-controllers/nvidia,tegra210-emc.yaml
+++ b/Documentation/devicetree/bindings/memory-controllers/nvidia,tegra210-emc.yaml
@@ -33,6 +33,9 @@ properties:
     items:
       - description: EMC general interrupt
 
+  "#interconnect-cells":
+    const: 0
+
   memory-region:
     maxItems: 1
     description:
@@ -44,6 +47,11 @@ properties:
     description:
       phandle of the memory controller node
 
+  operating-points-v2:
+    description:
+      Should contain freqs and voltages and opp-supported-hw property, which
+      is a bitfield indicating SoC speedo ID mask.
+
 required:
   - compatible
   - reg
@@ -79,4 +87,7 @@ examples:
         interrupts = <GIC_SPI 78 IRQ_TYPE_LEVEL_HIGH>;
         memory-region = <&emc_table>;
         nvidia,memory-controller = <&mc>;
+        operating-points-v2 = <&dvfs_opp_table>;
+
+        #interconnect-cells = <0>;
     };

-- 
2.51.0

