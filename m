From: David Heidelberg <david@ixit.cz>
Date: Wed, 19 Mar 2025 08:42:47 +0100
Subject: [PATCH v4 2/5] dt-bindings: net: Add generic wireless controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250319-dt-bindings-network-class-v4-2-2329336802b4@ixit.cz>
References: <20250319-dt-bindings-network-class-v4-0-2329336802b4@ixit.cz>
In-Reply-To: <20250319-dt-bindings-network-class-v4-0-2329336802b4@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1188; i=david@ixit.cz;
 h=from:subject:message-id; bh=s4h8B9gNJQ6JIaRS+FZDFjTYjzD5y6gNzE0ffwMuDco=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn2nV/6rsk3oZ7Zyx3BHMSxD/3T7AS4K6Ut8/Ix
 lXZHWCc56KJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ9p1fwAKCRBgAj/E00kg
 crwXEADFNSgiKo48SYtQuekFHAo+4fG9ATvPU7eD5a5aQHSz43A2DGLbx1N0t0m5x+UamLuzAYR
 IMl7W1JI+To73ZgOCDkbdHrt9gOlO7OtyQtcIUENMFEba252GuCIeTbneN3qBnxdB33x5AufHx1
 S70mveR8HrembIKmCEtHpf8+GSNkZ+bD3NzxB945vapzCjoF8uKY0EsUEovQ62pRee+D1k8tQn8
 shug/+iZDVDBrCT7vopf6ENjZPzY+tqqCS+AxHq68frOCCEpro+2vZJEgV47dQ8Glve69kXQ/aD
 DGZ+zh610NGjdnMaJYlAub3CB1AkvwpIAO9ovR55JIZm3wNaZwSMMfLXexOsGZ1C40L2o6DVqXR
 ZNNCGhTGL7wt41wBzlCfSDyQAaWiJY30mpOb9ky6mR91exDXT1jHGLlRkOtPSsEiP+iENDCCgwd
 4FAgcm/1INX6D4ny0yaF0ird6L3ius/ZRotszDiViVYiKOWztVRx3xSBUUBzH6FCfZOtQI6p3+D
 fIfCbd7Le45LQMXKKIh4MWOut9jogpciD+QexzNn+4OtJ+rIhVgCUlRFf2aONo8SS0HzQ5Fj5J6
 usYDTtjvhRDLtmqpDueELxfxaW3TKoYXB5Zn187clI6x3cW8dK7Lg+001d76FLMVG2sMHHtf7qc
 /BGK5UaVHz9dP1Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Wireless controllers share the common properties.

Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../bindings/net/wireless/wireless-controller.yaml | 23 ++++++++++++++++++++++
 1 file changed, 23 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/wireless/wireless-controller.yaml b/Documentation/devicetree/bindings/net/wireless/wireless-controller.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..7379f6c1aa05c15a5bc7b34df6502cc174af9a90
--- /dev/null
+++ b/Documentation/devicetree/bindings/net/wireless/wireless-controller.yaml
@@ -0,0 +1,23 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/net/wireless/wireless-controller.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Wireless Controller Common Properties
+
+maintainers:
+  - Lorenzo Bianconi <lorenzo@kernel.org>
+
+properties:
+  $nodename:
+    pattern: "^wifi(@.*)?$"
+
+allOf:
+  - $ref: ieee80211.yaml#
+  - $ref: /schemas/net/network-class.yaml#
+
+additionalProperties: true
+
+...
+

-- 
2.49.0

