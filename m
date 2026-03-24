From: David Heidelberg <david@ixit.cz>
Date: Tue, 24 Mar 2026 20:40:34 +0100
Subject: [PATCH v8 1/7] dt-bindings: input: syna,rmi4: Document
 syna,rmi4-s3706b
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260324-synaptics-rmi4-v8-1-2168d2df68f5@ixit.cz>
References: <20260324-synaptics-rmi4-v8-0-2168d2df68f5@ixit.cz>
In-Reply-To: <20260324-synaptics-rmi4-v8-0-2168d2df68f5@ixit.cz>
To: Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>, 
 Casey Connolly <casey.connolly@linaro.org>
Cc: David Heidelberg <david@ixit.cz>, linux-input@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Krzysztof Kozlowski <krzk@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1250; i=david@ixit.cz;
 h=from:subject:message-id; bh=sEfAUOYzG1M4zvx/Xv8wME49V12PqhPhJ6Tk21Hc6yo=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpwuiz5xzrEArqFAw1SDTk+XBbdHXOUSvBr9h7/
 xUG9+OoW5SJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCacLoswAKCRBgAj/E00kg
 chtYD/9X46MqQT6R/aqVMflAKUjVnBv+ZV7Yq4B5/B3qd0ceScFj+t8IeLuqQSeYZwH/cNsSZwc
 Joex4ttjsmlvz/5KEwyDRx3wJQb4Ms8QRHTlrxgY4atncDJPI2kWopUwDpnCAdrRvWtYAYbuxSq
 VE8dNM7ISwWAcmqsY29m40mJKW1MyUrUUjFOKxZ9ZjjqtzbIXcpIaytsTnCXDWiGPb4SqXR2vOt
 rhmqZuCAQ4t8+MDnL5fOrvVXD7VBi5/Uv02fe7qkIcNrvKGngH5toerJhN6R1wlKnwUho/g6QT8
 xnGZTx/zPRjPQ6r7IgzLS9INdHg1bq5X9TCSWr1tpGZucmh3cEJa/VfqVpL15iXFgDy19h9qad3
 kl+R4Sp92e3yUpGcEHmoQqje7V6fkl5jlj4T1wGB3qH0/vgN3DZM3agT1J3l/kYU9+oVFNZT0gU
 QMFtdkDFZbC3EiP9ae+rzi9UuMR4Z4KMYMGSsltoAtBS/HOuCYrrXGFyUDJozDk/yDw6Xcm7d0N
 QAZQNssfHEn0xPamkd/62CNa5FOMhBLJ7gV5rLz/XseSR0ZJTLU9boc7UxBy26p6lK7WvhGlVBm
 U8fjvmEB8HSQATpNT2++j8d6jYIQz+eu5MjLMR4Pyn55IviA+Dg+RKSTCHCwJI8txv7nV9Jp4vG
 Lp2AptRLL5DVGag==
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
index 8685ef4481f4a..fb4804ac3544d 100644
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
2.53.0

