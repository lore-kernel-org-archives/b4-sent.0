From: David Heidelberg <david@ixit.cz>
Date: Thu, 13 Nov 2025 17:30:57 +0100
Subject: [PATCH v6 1/7] dt-bindings: input: syna,rmi4: Document
 syna,rmi4-s3706b
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251113-synaptics-rmi4-v6-1-d9836afab801@ixit.cz>
References: <20251113-synaptics-rmi4-v6-0-d9836afab801@ixit.cz>
In-Reply-To: <20251113-synaptics-rmi4-v6-0-d9836afab801@ixit.cz>
To: Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Casey Connolly <casey.connolly@linaro.org>, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Krzysztof Kozlowski <krzk@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1250; i=david@ixit.cz;
 h=from:subject:message-id; bh=rwhOCivbUtBWH/U4u1pSZSbkJP3diksC8GrYstkJ/kY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpFgfJgCxB6SQi0xX/lkiQ5kGvuMriLATNx2Ns9
 QscwJ08Ne+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRYHyQAKCRBgAj/E00kg
 ctZhD/9d44CoZsa81vrG2ivCjGlQHv07MqgyoatoEJfcpFVJX4cV1PGQsver1FIxFEaHZth9+D2
 zVgBhZt2aOmpEGyjyh8zwMq+jgm20qL5CxrURRG2NU464ZKxIzyPrNLng+K/tELMxgYdetaBFXx
 6wL97x6zgb2iPFVIIBCceuXWoLe1w8gBktSF6EM4xXxvCwF0ZWbWsQajS0cNO8CSKiT/4oDVegc
 tyCATT/4v0xWTYccky22IPfH85TtlmxuwlE9OhM/je2Ql51DEqvu9lXumRSUssXGP78siZNhNEe
 wgr7202+5aTGCRq0W6AvQMq46K+oGcNj+GiFKMHz9qiAKnDHydvsl+I1QW2N0oZbYWjrQx1Uedn
 ZWjxFtvb5qRb32+IbGh2XOkXOpMj4wch6HIX1AWPknsLuJANzWrSaVsh1YK2llZOAmrI+FNsbVn
 rQUMJ93I7IRBMmtkeLIl/15lLL6f71f5mbX3marfMadlIlItO4SSpmcIfcQ+e0ft3IEfX6RLFfR
 0PdG3K4HULDm/VV+7Al9KXesZA0b63DvaL6Y/bpYzlydE8Nx20PVtRYXm+MRxfIPTKTmyJfEy1A
 4oa56CbHwbzT/+3H+VsyOuOyCBCSRAXC2t0SEpqwCRiGlU29KO1CSwF/JoZZfOUXQQaJRU7b1X4
 +Xl451tqRjgqxhg==
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
index f369385ffaf02..e0e006c9c9ee4 100644
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
2.51.0

