From: Jia Wang <wangjia@ultrarisc.com>
Date: Fri, 15 May 2026 09:17:59 +0800
Subject: [PATCH 3/9] dt-bindings: riscv: Add UltraRISC DP1000 bindings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260515-ultrarisc-pinctrl-v1-3-bf559589ea8a@ultrarisc.com>
References: <20260515-ultrarisc-pinctrl-v1-0-bf559589ea8a@ultrarisc.com>
In-Reply-To: <20260515-ultrarisc-pinctrl-v1-0-bf559589ea8a@ultrarisc.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Samuel Holland <samuel.holland@sifive.com>
Cc: Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 devicetree@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-gpio@vger.kernel.org, 
 Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778807890; l=1778;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=qaBC2cTXnLnD+JIt0DLP1KqvWkTUCFHsUaQu5JTU/dA=;
 b=WjaarwqtmIiEMHOknJXQgaDxZpuJJfoLCE7K7+8MSl1guMQezkfhgQUtrbv5/DmQj7A6v8tJ9
 d+WC3TY9ctLAq4A0b3FJ1jfR0C4XK/KzKYSFEKNzqBXQW77JE2Nf+UF
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add DT binding documentation for the UltraRISC DP1000 SoC.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
 .../devicetree/bindings/riscv/ultrarisc.yaml       | 27 ++++++++++++++++++++++
 MAINTAINERS                                        |  6 +++++
 2 files changed, 33 insertions(+)

diff --git a/Documentation/devicetree/bindings/riscv/ultrarisc.yaml b/Documentation/devicetree/bindings/riscv/ultrarisc.yaml
new file mode 100644
index 000000000000..d4421c2ef945
--- /dev/null
+++ b/Documentation/devicetree/bindings/riscv/ultrarisc.yaml
@@ -0,0 +1,27 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/riscv/ultrarisc.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: UltraRISC SoC-based boards
+
+maintainers:
+  - Jia Wang <wangjia@ultrarisc.com>
+
+description:
+  UltraRISC DP1000 SoC-based boards
+
+properties:
+  $nodename:
+    const: '/'
+  compatible:
+    oneOf:
+      - items:
+          - enum:
+              - rongda,m0
+              - milkv,titan
+          - const: ultrarisc,dp1000
+
+additionalProperties: true
+...
diff --git a/MAINTAINERS b/MAINTAINERS
index b2040011a386..5bf971ff48b2 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -23082,6 +23082,12 @@ F:	include/dt-bindings/power/thead,th1520-power.h
 F:	include/dt-bindings/reset/thead,th1520-reset.h
 F:	include/linux/firmware/thead/thead,th1520-aon.h
 
+RISC-V ULTRARISC SoC SUPPORT
+M:	Jia Wang <wangjia@ultrarisc.com>
+L:	linux-riscv@lists.infradead.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/riscv/ultrarisc.yaml
+
 RNBD BLOCK DRIVERS
 M:	Md. Haris Iqbal <haris.iqbal@ionos.com>
 M:	Jack Wang <jinpu.wang@ionos.com>

-- 
2.34.1

