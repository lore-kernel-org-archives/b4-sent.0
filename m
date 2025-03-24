From: David Heidelberg <david@ixit.cz>
Date: Mon, 24 Mar 2025 18:41:39 +0100
Subject: [PATCH v5 2/5] dt-bindings: net: Add generic wireless controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250324-dt-bindings-network-class-v5-2-f5c3fe00e8f0@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1188; i=david@ixit.cz;
 h=from:subject:message-id; bh=s4h8B9gNJQ6JIaRS+FZDFjTYjzD5y6gNzE0ffwMuDco=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn4ZlUkO2OTp2AzhwK0TqhMqWIaIvFxzYIv7hU4
 sC1q5W8JXGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ+GZVAAKCRBgAj/E00kg
 ctX+EACIls3D2cw/sYf6yNpFF7jMddNcznl3sRLq0U1Gq9Qpqn/AgYTzBJXrYWOyGxwhoO3hegV
 XZIj25cuIt6LQglWdRSdQ+sF0s1ta/419YsW2ACTqCWRfh8YZvXVLeiCGB3JcsgDW9usnOSR1Rq
 AGAYg0uegeuRC9Sx2XL+ydP3Y8BhmVdRTvy3Axxl0E4WjS++hCsAnukU0Ju3RJo9Q4Qc5iQAu2I
 hKvmzxRxF22/do9WKRea5LFe8/5P+nc23dvqF253VsOELmU/6v93iE7dYDluB2oyQnxvxWeNWLA
 s8He4wM7PDJOeysx19z6LJ5WqFfu1XVq66U1KHOsxoJed7Lm2humQSmQdVXccwjoHfy/vpZR0Zg
 qLCqTJPrsOrfTnzeXzpCp9HCJjQnZQpbJkOdLVuE0cjaSpS6dejVpWDdGZS6GueJAy3wV61jvBQ
 VYMX3QHRMJCVVN/z3N1NxMLjFzlhzu/+iX9jTlctE6gvB1TUD/0ILv+ainKo6XrHQahwh9hQzoB
 lQa+apHVJhkaaILysbh3KHnsqjvojDCOqT4UTyJJRJ3JEYXrFlZ+IO9Yieyi45/ZPjnCKALZUUe
 QSU12CiBMB+QJdBXtETwNFowKfPLsuRti24UbsIjbhFPKd7ljtNqgpdcDATIJJUTGfk6EwwIxye
 EJtNFGT07HwaRFg==
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

