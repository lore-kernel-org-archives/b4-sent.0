From: Joseph Telaak <joseph@telaak.dev>
Date: Mon, 09 Nov 2026 14:03:42 -0500
Subject: [PATCH v2 06/11] dt-bindings: leds: kinetic,ktd202x: Add Etek
 ET6326
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-ktd202x-et6326-v2-6-56e97c226658@telaak.dev>
References: <20261109-ktd202x-et6326-v2-0-56e97c226658@telaak.dev>
In-Reply-To: <20261109-ktd202x-et6326-v2-0-56e97c226658@telaak.dev>
To: Lee Jones <lee@kernel.org>, Pavel Machek <pavel@kernel.org>, 
 Griffin Kroah-Hartman <griffin@kroah.com>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: linux-leds@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hardening@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-doc@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794251062; l=1688;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=hIvFiNaElM5DM1f0GSci39p2JZ0LoYvSxCvTlBftLaU=;
 b=lUjuN8U4Q5GU35310ZlXoMPNWT2zClb0iQY/QCBSyeAe8abYvpxs9cJYgn2FDsyOsiJAmE1Yj
 kVmh2yZhhlmAaI5cfY4Bzdh/6fZpO67chvFzMtoSbzQd+RqswrnYOkx
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Etek ET6326 is a 3 channel LED driver with the register map, the I2C
address and the current steps of the KTD2026. It only differs in the
flash period, which is (Reg1 + 1) * 128 ms instead of 256 ms + Reg1 *
128 ms, so a KTD2026 driver runs it with blink periods that are 128 ms
off. Document it with the KTD2026 as fallback.

The ET6326 drives the status LED of the GL.iNet GL-SFT1200 (Opal).

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 .../devicetree/bindings/leds/kinetic,ktd202x.yaml         | 15 ++++++++++++---
 1 file changed, 12 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/leds/kinetic,ktd202x.yaml b/Documentation/devicetree/bindings/leds/kinetic,ktd202x.yaml
index 832c030a5acf..b13c71721853 100644
--- a/Documentation/devicetree/bindings/leds/kinetic,ktd202x.yaml
+++ b/Documentation/devicetree/bindings/leds/kinetic,ktd202x.yaml
@@ -15,11 +15,20 @@ description: |
   The data sheet can be found at:
     https://www.kinet-ic.com/uploads/KTD2026-7-04h.pdf
 
+  The Etek ET6326 is a 3 channel variant that is register compatible with
+  the KTD2026, but encodes the flash period differently. Its data sheet can
+  be found at:
+    https://www.etekmicro.com/wp-content/uploads/datasheets/ET6326_datasheet.pdf
+
 properties:
   compatible:
-    enum:
-      - kinetic,ktd2026
-      - kinetic,ktd2027
+    oneOf:
+      - enum:
+          - kinetic,ktd2026
+          - kinetic,ktd2027
+      - items:
+          - const: etekmicro,et6326
+          - const: kinetic,ktd2026
 
   reg:
     maxItems: 1

-- 
Git-155)

