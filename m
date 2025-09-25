From: David Heidelberg <david@ixit.cz>
Date: Thu, 25 Sep 2025 11:12:47 +0200
Subject: [PATCH 1/8] dt-bindings: panel: Add Samsung S6E3FC2X01 DDIC with
 panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250925-s6e3fc2x01-v1-1-9293016768f7@ixit.cz>
References: <20250925-s6e3fc2x01-v1-0-9293016768f7@ixit.cz>
In-Reply-To: <20250925-s6e3fc2x01-v1-0-9293016768f7@ixit.cz>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jessica.zhang@oss.qualcomm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3067; i=david@ixit.cz;
 h=from:subject:message-id; bh=by2IGpA/fsa5PiFT1mv+v/aflwQh7WSaQNPfojdHElg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo1QeR+mlmL+bnq7ElGz14J3/TRkaprI+netvoi
 23C/zWCjC+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaNUHkQAKCRBgAj/E00kg
 csaaEACxthclv0uC7nHPbJTuuDMbxo477Q3pBNgq9UeKlfJxnifMjV/QBn8c17OD/6TmRSrWeVa
 lVG77qDcbBhsANHaC3lIBkNzUdFv/0PzefnZy6sJyFIHYrY0tPikpRJsqN0M8y82Y8UG+sx9XRk
 oBklVH2ltuELmsTd3AI2rALJ9yuB8qKxENSZ2gCPujn4RNtMI96bJPK9oWXeGut0hbD1PP/s/UM
 2iPaP3gTa9tBQK5pl08kkF+chYq0JymV/Gtl4itPPJQQawoYBdmelP7/DF0mxad+nkXVNS9Qu0E
 JMMTyGIaWwCyEMm7Yoc0ycuigimwLjjlwbjd5diKE52cFLAfFcxRRwLGXUMDRl9dyZ5G0uDZMzA
 ohxWYZedBZGldRUSv69o8V17CqeiKDitz5dbQc7Q/Eg2noODzwlFm1VVbFcRfjjaT+mUwLDtkRI
 sz4ttTa0szO1CXMNojAPCuxyWquLpV+BM93BwAJq87tifjT5Y5O4WTfdinqfHrvzsYtDopyXmdM
 3XON2wONMdckCNM6bn3rBPhdjhQSG0Yf1n+FqzAyEUH8a/sJcA79HRPXEze5Hl9lStf8REhNyMl
 DX5YUX2GP27zgEVS8ixKsCW/iZ3uyptjwGMCazCj3UAiijgL63m+qWzLRq4iX5SsGWeE7pt3Nmu
 T+LNSDT3s0+ySoA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Basic description for S6E3FC2X01 DDIC with attached panel AMS641RW.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../bindings/display/panel/samsung,s6e3fc2x01.yaml | 77 ++++++++++++++++++++++
 MAINTAINERS                                        |  5 ++
 2 files changed, 82 insertions(+)

diff --git a/Documentation/devicetree/bindings/display/panel/samsung,s6e3fc2x01.yaml b/Documentation/devicetree/bindings/display/panel/samsung,s6e3fc2x01.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..489b6b52effe1e627ff5ef5891729c175ad71685
--- /dev/null
+++ b/Documentation/devicetree/bindings/display/panel/samsung,s6e3fc2x01.yaml
@@ -0,0 +1,77 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/display/panel/samsung,s6e3fc2x01.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Samsung S6E3FC2X01 AMOLED DDIC
+
+description: The S6E3FC2X01 is display driver IC with connected panel.
+
+maintainers:
+  - David Heidelberg <david@ixit.cz>
+
+allOf:
+  - $ref: panel-common.yaml#
+
+properties:
+  compatible:
+    const: samsung,s6e3fc2x01-ams641rw
+
+  reg:
+    maxItems: 1
+
+  reset-gpios: true
+
+  port: true
+
+  vddio-supply:
+    description: VDD regulator
+
+  vci-supply:
+    description: VCI regulator
+
+  poc-supply:
+    description: POC regulator
+
+required:
+  - compatible
+  - reset-gpios
+  - vddio-supply
+  - vci-supply
+  - poc-supply
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+
+    dsi {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        panel@0 {
+            compatible = "samsung,s6e3fc2x01-ams641rw";
+            reg = <0>;
+
+            vddio-supply = <&vreg_l14a_1p88>;
+            vci-supply = <&s2dos05_buck1>;
+            poc-supply = <&s2dos05_ldo1>;
+
+            te-gpios = <&tlmm 10 GPIO_ACTIVE_HIGH>;
+            reset-gpios = <&tlmm 6 GPIO_ACTIVE_HIGH>;
+
+            pinctrl-names = "default", "sleep";
+            pinctrl-0 = <&sde_dsi_active &sde_te_active_sleep>;
+            pinctrl-1 = <&sde_dsi_suspend &sde_te_active_sleep>;
+
+            port {
+                panel_in: endpoint {
+                    remote-endpoint = <&mdss_dsi0_out>;
+                };
+            };
+        };
+    };
+
+...
diff --git a/MAINTAINERS b/MAINTAINERS
index 9955f2a87f292000fae6d5a71ae7744ceadfed05..961f472e52039932e3208f7c0eb9aa0412b7f44b 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -8054,6 +8054,11 @@ S:	Maintained
 F:	Documentation/devicetree/bindings/display/panel/samsung,s6d7aa0.yaml
 F:	drivers/gpu/drm/panel/panel-samsung-s6d7aa0.c
 
+DRM DRIVER FOR SAMSUNG S6E3FC2X01 DDIC
+M:	David Heidelberg <david@ixit.cz>
+S:	Maintained
+F:	Documentation/devicetree/bindings/display/panel/samsung,s6e3fc2x01.yaml
+
 DRM DRIVER FOR SAMSUNG S6E3HA8 PANELS
 M:	Dzmitry Sankouski <dsankouski@gmail.com>
 S:	Maintained

-- 
2.51.0

