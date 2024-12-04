From: Nikolaos Pasaloukos <nikolaos.pasaloukos@blaize.com>
Date: Wed, 04 Dec 2024 16:05:25 +0000
Subject: [PATCH v5 2/6] dt-bindings: arm: blaize: Add Blaize BLZP1600 SoC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241204-blaize-blzp1600_init_board_support-v5-2-b642bcc49307@blaize.com>
References: <20241204-blaize-blzp1600_init_board_support-v5-0-b642bcc49307@blaize.com>
In-Reply-To: <20241204-blaize-blzp1600_init_board_support-v5-0-b642bcc49307@blaize.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 James Cowgill <james.cowgill@blaize.com>, 
 Matt Redfearn <matt.redfearn@blaize.com>, 
 Neil Jones <neil.jones@blaize.com>, 
 Niko Pasaloukos <nikolaos.pasaloukos@blaize.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Arnd Bergmann <arnd@arndb.de>, Olof Johansson <olof@lixom.net>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, soc@lists.linux.dev, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733328392; l=2168;
 i=nikolaos.pasaloukos@blaize.com; s=20241111; h=from:subject:message-id;
 bh=nZrtoLEBx9eSJm+LA7iUVDlX7hTZ20Riw/HSYwpf1yo=;
 b=X+HoK8cBDfO3U5Zsc18jHTANKsInOutc6BStS8FgN09ozvbyIvQsF4cWbAHf1H0/ys2VyGzZs
 MEqNXCeh3ECCUh+oeImi+YskXlmmc61MBXXt0Mcx7A0fCfy40+y9ShU
X-Developer-Key: i=nikolaos.pasaloukos@blaize.com; a=ed25519;
 pk=gGEjGCXdSuvCJPIiu0p0UeiPcW5LC710Z6KGN/dzo3g=
X-Endpoint-Received: by B4 Relay for nikolaos.pasaloukos@blaize.com/20241111 with auth_id=274
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree bindings for the Blaize BLZP1600 CB2 development
board (carrier board). This board integrates a Blaize BLZP1600
SoM (System on Module) which is based on the Blaize BLZP1600 SoC.

The Blaize BLZP1600 SoC integrates a dual core ARM Cortex A53
cluster and a Blaize Graph Streaming Processor for AI and ML
workloads, plus a suite of connectivity and other peripherals.

Signed-off-by: Nikolaos Pasaloukos <nikolaos.pasaloukos@blaize.com>
Reviewed-by: Matt Redfearn <matt.redfearn@blaize.com>
Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
---
 Documentation/devicetree/bindings/arm/blaize.yaml | 40 +++++++++++++++++++++++
 1 file changed, 40 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/blaize.yaml b/Documentation/devicetree/bindings/arm/blaize.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..af39e2756407baacee3030f6909cf2aa7dc5776c
--- /dev/null
+++ b/Documentation/devicetree/bindings/arm/blaize.yaml
@@ -0,0 +1,40 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/arm/blaize.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Blaize Platforms
+
+maintainers:
+  - James Cowgill <james.cowgill@blaize.com>
+  - Matt Redfearn <matt.redfearn@blaize.com>
+  - Neil Jones <neil.jones@blaize.com>
+  - Nikolaos Pasaloukos <nikolaos.pasaloukos@blaize.com>
+
+description: |
+  Blaize Platforms using SoCs designed by Blaize Inc.
+
+  The products based on the BLZP1600 SoC:
+
+  - BLZP1600-SoM: SoM (System on Module)
+  - BLZP1600-CB2: Development board CB2 based on BLZP1600-SoM
+
+  BLZP1600 SoC integrates a dual core ARM Cortex A53 cluster
+  and a Blaize Graph Streaming Processor for AI and ML workloads,
+  plus a suite of connectivity and other peripherals.
+
+properties:
+  $nodename:
+    const: '/'
+  compatible:
+    oneOf:
+      - description: Blaize BLZP1600 based boards
+        items:
+          - enum:
+              - blaize,blzp1600-cb2
+          - const: blaize,blzp1600
+
+additionalProperties: true
+
+...

-- 
2.43.0

