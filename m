From: David Heidelberg <david@ixit.cz>
Date: Wed, 19 Mar 2025 08:42:49 +0100
Subject: [PATCH v4 4/5] dt-bindings: wireless: silabs,wfx: Use
 wireless-controller.yaml
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250319-dt-bindings-network-class-v4-4-2329336802b4@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1294; i=david@ixit.cz;
 h=from:subject:message-id; bh=l57H1RfHi2nyRkEMHSpfv1DPteDzmkI0cH0ZxcD39cU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn2nV/GJXqP46+RluuNNyMAQKN75PZKl4HCTx7x
 wSys6q/NTaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ9p1fwAKCRBgAj/E00kg
 clWMD/0fWsWzN0SOl0+waxtXKViVHMwA9Gx4s7s80akUelEhYGg3J6k9IjJRD5dZuA7ob/mPhCw
 5awtfV37JzaaGzG/2/NpO2ce0NFK8EzZ08UATgh3DIocukcOaGA9ma8KI8ZYCK41K2QMh2n3eEa
 Ft+0IsXVu+DbVqLHZjq10lsTqjB8o4hL6TI+M3vSbPtr5WkajIwE/6YR06eI9Z5Ie4e46kGLJda
 GVEgTeW1fCtYj9QJRbtFRJlMUhQZChWZFP1lan2tDTIqvSdd1Sv5ApIXaHlh2JnF3/Fvg013D+c
 9WYHyT82B4PmMl4U3ZEW64+KemjRhf1MjIBPc/vj2JYEzagLETQ3rm5LMOaP5ZjlX27eSzaA6Dz
 Yg2ZIjONDWzp159N6AEYlXQL4oZLH34k9bm5k7UwumWwFDXQlDgcBvHwgWEeEunb0Zu6Z7x88oJ
 yaurc3PGvCwLcXRuVcc7bbmDzubWN1zY4vGIlDDFzZrCucQjdeYYI8QV9QErFpRNQZovLuA0L++
 IVhy88Cqwpy8mjlNlkl3PTYW0jmpdRUASqTCQv/BspwsPnNIHrZOAygUdYMUHAJBOTY5bY1/ksU
 KoSxQrF+bEfwJY6w2hRkg3HBLwQzPGmi1qOWEsXz8mNvSiteozBapvOWUOxd/tROsj+1ZnJbtjO
 gD5+G9Met9QwmQw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Janne Grunau <j@jannau.net>

Instead listing local-mac-address and mac-address properties, reference
wireless-controller.yaml schema. The schema brings in constraints for the
property checked during `make dtbs_check`.

Signed-off-by: Janne Grunau <j@jannau.net>
Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/net/wireless/silabs,wfx.yaml | 5 +----
 1 file changed, 1 insertion(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/net/wireless/silabs,wfx.yaml b/Documentation/devicetree/bindings/net/wireless/silabs,wfx.yaml
index 84e5659e50ef3125b5063fbebcaf1d2b2bdb7398..6c0888ae4c4e172edf2a5f6249cb8aed5ed11681 100644
--- a/Documentation/devicetree/bindings/net/wireless/silabs,wfx.yaml
+++ b/Documentation/devicetree/bindings/net/wireless/silabs,wfx.yaml
@@ -71,15 +71,12 @@ properties:
       "Platform Data Set" in Silabs jargon). Default depends of "compatible"
       string. For "silabs,wf200", the default is 'wf200.pds'.
 
-  local-mac-address: true
-
-  mac-address: true
-
 required:
   - compatible
   - reg
 
 allOf:
+  - $ref: /schemas/net/wireless/wireless-controller.yaml#
   - $ref: /schemas/spi/spi-peripheral-props.yaml#
 
 unevaluatedProperties: false

-- 
2.49.0

