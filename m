From: Cunhao Lu <1579567540@qq.com>
Date: Wed, 04 Nov 2026 16:56:03 +0800
Subject: [PATCH v4 1/2] dt-bindings: power: rockchip: Add RK3572 power
 domains
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-add-board-ok3572-c-pmdomain-v4-1-15cf8b5a6e59@qq.com>
References: <20261104-add-board-ok3572-c-pmdomain-v4-0-15cf8b5a6e59@qq.com>
In-Reply-To: <20261104-add-board-ok3572-c-pmdomain-v4-0-15cf8b5a6e59@qq.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Elaine Zhang <zhangqing@rock-chips.com>, Ulf Hansson <ulfh@kernel.org>
Cc: Cunhao Lu <1579567540@qq.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 Finley Xiao <finley.xiao@rock-chips.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793782666; l=2834;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=oyvMUU7R4CjKJ/p4yd/DxcdPfUMgGd3L5BZrnlpZr8A=;
 b=QJ1uWl+F7GBiGoGGJ+woFdBVjA8OLhcGVy1YEOIXpoJqX/+/qBrkXK6SqOvk0bgcpYc8HWZHY
 0xT8khOcz40B93eyVSzKyNNqLh007MZTtht5ngy3HAw9FuuZPoli+1X
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Finley Xiao <finley.xiao@rock-chips.com>

Describe the RK3572 power controller and define its 14 power-domain IDs.
Require the system GRF phandle used to check firmware shift-ready status.

Signed-off-by: Finley Xiao <finley.xiao@rock-chips.com>
Signed-off-by: Cunhao Lu <1579567540@qq.com>
Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
---
Changes in v4:
- Describe the system GRF register as firmware shift-ready status.
---
 .../bindings/power/rockchip,power-controller.yaml  | 17 ++++++++++++
 .../power/rockchip,rk3572-power-controller.h       | 30 ++++++++++++++++++++++
 2 files changed, 47 insertions(+)

diff --git a/Documentation/devicetree/bindings/power/rockchip,power-controller.yaml b/Documentation/devicetree/bindings/power/rockchip,power-controller.yaml
index b41db576f95d..fbf3e0ab4cd9 100644
--- a/Documentation/devicetree/bindings/power/rockchip,power-controller.yaml
+++ b/Documentation/devicetree/bindings/power/rockchip,power-controller.yaml
@@ -43,6 +43,7 @@ properties:
       - rockchip,rk3528-power-controller
       - rockchip,rk3562-power-controller
       - rockchip,rk3568-power-controller
+      - rockchip,rk3572-power-controller
       - rockchip,rk3576-power-controller
       - rockchip,rk3588-power-controller
       - rockchip,rv1126-power-controller
@@ -57,6 +58,22 @@ properties:
   "#size-cells":
     const: 0
 
+  rockchip,grf:
+    $ref: /schemas/types.yaml#/definitions/phandle
+    description: System GRF with firmware shift-ready status.
+
+allOf:
+  - if:
+      properties:
+        compatible:
+          const: rockchip,rk3572-power-controller
+    then:
+      required:
+        - rockchip,grf
+    else:
+      properties:
+        rockchip,grf: false
+
 required:
   - compatible
   - "#power-domain-cells"
diff --git a/include/dt-bindings/power/rockchip,rk3572-power-controller.h b/include/dt-bindings/power/rockchip,rk3572-power-controller.h
new file mode 100644
index 000000000000..c2316fa859df
--- /dev/null
+++ b/include/dt-bindings/power/rockchip,rk3572-power-controller.h
@@ -0,0 +1,30 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */
+/*
+ * Copyright (c) 2026 Rockchip Electronics Co., Ltd.
+ * Author: Finley Xiao <finley.xiao@rock-chips.com>
+ */
+
+#ifndef __DT_BINDINGS_POWER_RK3572_POWER_CONTROLLER_H__
+#define __DT_BINDINGS_POWER_RK3572_POWER_CONTROLLER_H__
+
+/* VD_NPU */
+#define RK3572_PD_NPU		0
+
+/* VD_GPU */
+#define RK3572_PD_GPU		1
+
+/* VD_LOGIC */
+#define RK3572_PD_NVM0		2
+#define RK3572_PD_NVM1		3
+#define RK3572_PD_DSMC		4
+#define RK3572_PD_PHP		5
+#define RK3572_PD_AUDIO		6
+#define RK3572_PD_IMG		7
+#define RK3572_PD_VDEC		8
+#define RK3572_PD_VI		9
+#define RK3572_PD_VENC		10
+#define RK3572_PD_VO		11
+#define RK3572_PD_VOP		12
+#define RK3572_PD_VOP_PRE	13
+
+#endif

-- 
2.34.1

