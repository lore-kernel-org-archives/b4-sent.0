From: David Heidelberg <david@ixit.cz>
Date: Tue, 18 Mar 2025 20:56:45 +0100
Subject: [PATCH v3 2/5] dt-bindings: net: Add generic wireless controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250318-dt-bindings-network-class-v3-2-4d8d04ddfb61@ixit.cz>
References: <20250318-dt-bindings-network-class-v3-0-4d8d04ddfb61@ixit.cz>
In-Reply-To: <20250318-dt-bindings-network-class-v3-0-4d8d04ddfb61@ixit.cz>
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
 Konrad Dybcio <konradybcio@kernel.org>, Andy Gross <agross@kernel.org>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-wireless@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Janne Grunau <j@jannau.net>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1138; i=david@ixit.cz;
 h=from:subject:message-id; bh=P3wxtxq+fD4LWVRBZ1MpaWJgE1IIo4CuIxn7yG+ZET0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn2c/+2Izef9m3kj/hpAUM3U5cGidvjC+W0Vt2D
 fwwdoXVqJGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ9nP/gAKCRBgAj/E00kg
 cgbvD/4xduajTZBRFlLvfYA2TDr5D6etA3CjLCwejbi5IHfaMb+e7iyJFcqgn9kmvgmfmQKFDmh
 6jVcmN3/PnX0B2uaY0Iwy83/MxSp0RZnkmkIhg07Y0H1sHWIkJIjkegw6OUpaOmsSEcRaOjDw/J
 ODUY7ddiwIryzizg3reyHVx7zrr7UQIxhQhLnQ48bchp2ZZXdpsQB+wXaHOxAyJ58B5Q8qbndgA
 V3dIKt8YBYYM/Q2uBi7dtwJqgc0gtiRU22mgFS84m5zzWO7f+P9ZpVUCY0xufD3S69nNRXIpfsK
 KMLvjJgK5Afiyjbp8BeWD46wKgRaSt2AckKoyjRwrlLtfXR7ELY0DLg4YJO5i7lf7vZgv4Zpmhq
 AorV6Z0g85Ac66o979xe0VlWZWfmnYDln14Qxj1CVT44Ms0S57ghFqbCTh8lijbIk9aNcd+6Vbs
 YmCy8YVGvgnofDxTNOCE6WNBj0R8AA4cpdZnlYeA76MNvBc1qyrOVHvsZYZl3LUf0rR93e0FZ/X
 ViVwrr+3CJeFUa2hlCj69Lj5o4Xt1XRoeLQsmUrXSzvrNOnwloMvEr//0RhVQmIE1wLJ9NGFcVj
 TiuIzCXNpL4Ebt2+JYbdDkyBHzX6ph2/9jkcAiGN+shX0UwProNDkv4z3Y9YPVOIrY9/wkQCFfb
 vlJJC/Y2yKS8t7w==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Wireless controllers share the common properties.

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

