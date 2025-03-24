From: David Heidelberg <david@ixit.cz>
Date: Mon, 24 Mar 2025 18:41:38 +0100
Subject: [PATCH v5 1/5] dt-bindings: net: Add network-class schema for
 mac-address properties
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250324-dt-bindings-network-class-v5-1-f5c3fe00e8f0@ixit.cz>
References: <20250324-dt-bindings-network-class-v5-0-f5c3fe00e8f0@ixit.cz>
In-Reply-To: <20250324-dt-bindings-network-class-v5-0-f5c3fe00e8f0@ixit.cz>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Mailing List <devicetree-spec-u79uwXL29TY76Z2rM5mHXA@public.gmane.org>, 
 Johannes Berg <johannes@sipsolutions.net>, 
 Lorenzo Bianconi <lorenzo@kernel.org>, van Spriel <arend@broadcom.com>, 
 =?utf-8?q?J=C3=A9r=C3=B4me_Pouiller?= <jerome.pouiller@silabs.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Andy Gross <agross@kernel.org>, 
 Mailing List <devicetree-spec@vger.kernel.org>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-wireless@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Janne Grunau <j@jannau.net>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4573; i=david@ixit.cz;
 h=from:subject:message-id; bh=V386ZXz4Pz6PLuOWcjq3RT0zmANmJc+rqbdyU0TJU1U=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn4ZlTwoSCsbScF+KycWcny0ivxTVp6Egzb4wg7
 bYY6nhykaSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ+GZUwAKCRBgAj/E00kg
 cgR8D/9QLJYcwGDZGiOAdOlcdhhqd5wyMmokorCUDR0Q1BIcge/5RIkZsVkB0Qy2fTOaRYPICaw
 eeHv6II7gXA3bs5pacKIC6p2M9Ap/BPur+XszKGj9+XAbomIJIaAPFrs2/r7iaLzEtPfs16dveF
 MVgzcOTCYYFjaW3QfQiygHoqCKccT44bgybylNZfwB9+tWA5BCQDIw71yCSrf3YXZWNU3M83uGI
 iekkoy8+8NICTWLC2krD0VoRdh73eApXQ5ppJMZZejyAAWfDrXQNsc2Q72n/idS0nfLj66XsVzd
 lxdHA+ZBUJCdptYvus1NM3ZIOTHMfL4SZLNN0vo0ADOqQygf6aPddRF5N9uOH2J+gPaEesHtFQe
 L0IVvq1LKYwkC5LeEPYRYoMFgltu/cry0rk9KekxmbdSEG9PgdquxcMdRiTN8QXTHrBxqD8xce2
 1kACGAQigM3mzd5xdfvXgf8IcXFvPsDGlhzvjYX0psgZ5DSjExxMze2Vr7jj04jEyFQzzyb2byr
 pXFsvzeB0DW4d1Tv8Z7ANWRlXikHbc1TndMUrY6qINf5/9evPZEmvbn+hC53Ww6MliU8rDfeY7z
 Si0Ob8UsKfJ4OULsx9wjIFFzmn+YA2+yEmj0/JNYja+7XpMy4lxzVoUndIASBJSSqfGpILKYWQl
 H5XiQ4H8c1jC9+A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Janne Grunau <j@jannau.net>

The ethernet-controller schema specifies "mac-address" and
"local-mac-address" but other network devices such as wireless network
adapters use mac addresses as well.
The Devicetree Specification, Release v0.3 specifies in section 4.3.1
a generic "Network Class Binding" with "address-bits", "mac-address",
"local-mac-address" and "max-frame-size". This schema specifies the
"address-bits" property and moves the remaining properties over from
the ethernet-controller.yaml schema.

The "max-frame-size" property is used to describe the maximal payload
size despite its name. Keep the description from ethernet-controller
specifying this property as MTU. The contradictory description in the
Devicetree Specification is ignored.

Signed-off-by: Janne Grunau <j@jannau.net>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../bindings/net/ethernet-controller.yaml          | 25 +-----------
 .../devicetree/bindings/net/network-class.yaml     | 46 ++++++++++++++++++++++
 2 files changed, 47 insertions(+), 24 deletions(-)

diff --git a/Documentation/devicetree/bindings/net/ethernet-controller.yaml b/Documentation/devicetree/bindings/net/ethernet-controller.yaml
index 45819b2358002bc75e876eddb4b2ca18017c04bd..c91b41b83d1dc1294e99ec72c7cdcc16550cb33e 100644
--- a/Documentation/devicetree/bindings/net/ethernet-controller.yaml
+++ b/Documentation/devicetree/bindings/net/ethernet-controller.yaml
@@ -16,30 +16,6 @@ properties:
   label:
     description: Human readable label on a port of a box.
 
-  local-mac-address:
-    description:
-      Specifies the MAC address that was assigned to the network device.
-    $ref: /schemas/types.yaml#/definitions/uint8-array
-    minItems: 6
-    maxItems: 6
-
-  mac-address:
-    description:
-      Specifies the MAC address that was last used by the boot
-      program; should be used in cases where the MAC address assigned
-      to the device by the boot program is different from the
-      local-mac-address property.
-    $ref: /schemas/types.yaml#/definitions/uint8-array
-    minItems: 6
-    maxItems: 6
-
-  max-frame-size:
-    $ref: /schemas/types.yaml#/definitions/uint32
-    description:
-      Maximum transfer unit (IEEE defined MTU), rather than the
-      maximum frame size (there\'s contradiction in the Devicetree
-      Specification).
-
   max-speed:
     $ref: /schemas/types.yaml#/definitions/uint32
     description:
@@ -262,6 +238,7 @@ dependencies:
   pcs-handle-names: [pcs-handle]
 
 allOf:
+  - $ref: /schemas/net/network-class.yaml#
   - if:
       properties:
         phy-mode:
diff --git a/Documentation/devicetree/bindings/net/network-class.yaml b/Documentation/devicetree/bindings/net/network-class.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..06461fb92eb8452cea685160b7a29ee9c0493f7e
--- /dev/null
+++ b/Documentation/devicetree/bindings/net/network-class.yaml
@@ -0,0 +1,46 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/net/network-class.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Network Class Common Properties
+
+maintainers:
+  - Devicetree Specification Mailing List <devicetree-spec@vger.kernel.org>
+
+properties:
+  address-bits:
+    description:
+      Specifies number of address bits required to address the device
+      described by this node, e.g. size of the MAC address.
+    default: 48
+    const: 48
+
+  local-mac-address:
+    description:
+      Specifies MAC address that was assigned to the network device described by
+      the node containing this property.
+    $ref: /schemas/types.yaml#/definitions/uint8-array
+    minItems: 6
+    maxItems: 6
+
+  mac-address:
+    description:
+      Specifies the MAC address that was last used by the boot program. This
+      property should be used in cases where the MAC address assigned to the
+      device by the boot program is different from the
+      local-mac-address property. This property shall be used only if the value
+      differs from local-mac-address property value.
+    $ref: /schemas/types.yaml#/definitions/uint8-array
+    minItems: 6
+    maxItems: 6
+
+  max-frame-size:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description:
+      Maximum transfer unit (IEEE defined MTU), rather than the
+      maximum frame size (there\'s contradiction in the Devicetree
+      Specification).
+
+additionalProperties: true

-- 
2.49.0

