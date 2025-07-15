From: David Heidelberg <david@ixit.cz>
Date: Tue, 15 Jul 2025 13:49:00 +0200
Subject: [PATCH RESEND v5 1/7] dt-bindings: input: syna,rmi4: Document
 syna,rmi4-s3706b
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250715-synaptics-rmi4-v5-1-ca255962c122@ixit.cz>
References: <20250715-synaptics-rmi4-v5-0-ca255962c122@ixit.cz>
In-Reply-To: <20250715-synaptics-rmi4-v5-0-ca255962c122@ixit.cz>
To: Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Caleb Connolly <caleb.connolly@linaro.org>, 
 phone-devel@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1304; i=david@ixit.cz;
 h=from:subject:message-id; bh=jlm0TtzM+qwlqfeZi52UxUZv7l7Eivv2BkocqxTGAHc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBodkA0542TUS1GhEXdCACJaU7dwt2BzADN4kt+k
 0XQwmfV/6mJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaHZANAAKCRBgAj/E00kg
 cjmwD/wJ+i9YGl/wWRC/JpI6fnwMtVKc2sBAhlgJ0QwZrjR5Y9aI+RT6TzPQ/RoFrBkLyj+6aIm
 R937UWS4QiTRk0nibiWQa5xMsAW8zbe8sQaYoc6IXRQCni8SuzmKCA/VWvaab57DXvimSbs4o/D
 AQZy+hQ90rRJRRqUdLM3JqC3tH9316wMVlY9Sew7pRi7qjOJJ6eZr+tdCHnIa3yKJZhZ2nYQJS1
 5bRU9LNrmkv1XP3CqXrE3+OItNc+qfC495RKjZ/bC1y/GIcz/hdxktwnyFffUx4C7RPAiSmJ7Wl
 9F1oxbWj1HNbObIChuA493I4QZJySlzNH+7/GlazlooLlc7zEdFSsriZrubPYA+5dDorMK9h0eb
 Z9Qw8rcLT7UBWL1IizDBlVGP4CgIM8iPjmPDLsQMhSxDdcAAlRd2zgj0HGuoF0vi4dCk1iR4P4k
 DfG5IfGyuL0cYttEmvLC8SqmXZzxNtV7aCSIAB/0Qra9qzuMaHhs4Owwv/tIL3eLPrrLatPOOk1
 /JjI1YYDw/+vg7idiB+KviPUA8+95aSUoF9iBEyXIJzJsj3S7d6mB03bAVBqEZFxyhgaQVUZ9kl
 TsJwl1AnkH5ziUVhOnEDUdxo5GvjwB94QZX0kQj08cx+Y+SeKpzyHH5SwZsPW83zLsbA60scNCx
 tEqZjdPcsvnvDlw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Mostly irrelevant for authentic Synaptics touchscreens, but very important
for applying workarounds to cheap TS knockoffs.

These knockoffs work well with the downstream driver, and since the user
has no way to distinguish them, later in this patch set, we introduce
workarounds to ensure they function as well as possible.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/input/syna,rmi4.yaml | 11 ++++++++---
 1 file changed, 8 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/input/syna,rmi4.yaml b/Documentation/devicetree/bindings/input/syna,rmi4.yaml
index b522c8d3ce0db719ff379f2fefbdca79e73d027c..d5d0225e3826fa5a0559cbd99115c505ab113aa0 100644
--- a/Documentation/devicetree/bindings/input/syna,rmi4.yaml
+++ b/Documentation/devicetree/bindings/input/syna,rmi4.yaml
@@ -18,9 +18,14 @@ description: |
 
 properties:
   compatible:
-    enum:
-      - syna,rmi4-i2c
-      - syna,rmi4-spi
+    oneOf:
+      - enum:
+          - syna,rmi4-i2c
+          - syna,rmi4-spi
+      - items:
+          - enum:
+              - syna,rmi4-s3706b  # OnePlus 6/6T
+          - const: syna,rmi4-i2c
 
   reg:
     maxItems: 1

-- 
2.50.0

