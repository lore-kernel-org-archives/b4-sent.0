From: Cunhao Lu <1579567540@qq.com>
Date: Fri, 23 Oct 2026 22:14:59 +0800
Subject: [PATCH v2 1/2] dt-bindings: power: rockchip: Add RK3572 power
 domains
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-add-board-ok3572-c-pmdomain-v2-1-79ddd42e92c1@qq.com>
References: <20261023-add-board-ok3572-c-pmdomain-v2-0-79ddd42e92c1@qq.com>
In-Reply-To: <20261023-add-board-ok3572-c-pmdomain-v2-0-79ddd42e92c1@qq.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Elaine Zhang <zhangqing@rock-chips.com>, Ulf Hansson <ulfh@kernel.org>
Cc: Cunhao Lu <1579567540@qq.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 Finley Xiao <finley.xiao@rock-chips.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792764905; l=2755;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=yMzCyaLHegkny0sbJwdEkUgADvLcEUSeHq007zGMJrY=;
 b=EbHuNCF42mOSnEIz5wEWNmwrzBUeQ1RCs5I9Xb+Y+gFqCI1taFvla7Kv74MSVxE9Vv+TSNyst
 QS3B9QedJzCBCikkEdR4q5IPsBcPDaHNXdYTx1IsGtL5BC6Z+OEt50L
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Finley Xiao <finley.xiao@rock-chips.com>

Define the RK3572 power-domain IDs. The driver uses the system GRF to
check firewall readiness after powering on a domain.

Signed-off-by: Finley Xiao <finley.xiao@rock-chips.com>

- Added the rockchip,grf property.
- Made the phandle required only for RK3572.

Signed-off-by: Cunhao Lu <1579567540@qq.com>
---
 .../bindings/power/rockchip,power-controller.yaml  | 17 ++++++++++++
 .../power/rockchip,rk3572-power-controller.h       | 30 ++++++++++++++++++++++
 2 files changed, 47 insertions(+)

diff --git a/Documentation/devicetree/bindings/power/rockchip,power-controller.yaml b/Documentation/devicetree/bindings/power/rockchip,power-controller.yaml
index b41db576f95d..f8afb0fabe80 100644
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
+    description: System GRF with firewall readiness status.
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

