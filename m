From: David Heidelberg <david@ixit.cz>
Date: Sat, 23 May 2026 11:45:34 +0200
Subject: [PATCH v2 1/2] dt-bindings: input: syna,rmi4: Document
 syna,rmi4-s3706b
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260523-synaptics-rmi4-dt-v2-1-0645122babdc@ixit.cz>
References: <20260523-synaptics-rmi4-dt-v2-0-0645122babdc@ixit.cz>
In-Reply-To: <20260523-synaptics-rmi4-dt-v2-0-0645122babdc@ixit.cz>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Krzysztof Kozlowski <krzk@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1546; i=david@ixit.cz;
 h=from:subject:message-id; bh=0q+JIIsIzsebe835sf4TIR/9lu8nbddLJDq/K03juvc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqEXc/BdW8VHYyGBhmXrqsBIYZ6AHtA/jYbsEId
 Bhl3OBhrMiJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCahF3PwAKCRBgAj/E00kg
 cij0D/9yltRG0psQbXfzevFnU+3syLSl+yA++BRC7ab1DzK6eCt6hCM2iRhDXKExsVub/Z+1Gt1
 WTVUU7xdFr6GlLps03hz+oOVQ/a3C2+2Q7G2EByAfL+HcSrYOmACnZOLW8va9998/ZFBBomqEH6
 udbD5bGzROYOYkwI8cXvGouIYU7W4c2GhLznOKELC+0qOGIZau7wXxOL6OSZf3s30k6Q2rAHabW
 3yeIZ9BldW+HiN44Ym7stvdjw7O9ICiwN9Z71/Xh0V7C6310QIAPT6roDal+rJ1LmnRyimG0NTE
 n99EfjbCLq9oX2Nx8YqqlRvNpYfwEZYIcOVLlPwoig+A8wr3jZsY7fwqtqmmMlQg7qddppffg5r
 Xg3bHJszoZ0iaR/+7YKbvcIitIb5uf7caUAvLk4Qs0fBTr89KJ+nL4+GgLodhJpurJU+41w6MdR
 bR2rhZrn9yLMp5XmXoXoroFtekCml3o7dBo+5wPPp+MJ349KM2JzVMEoflxToGQEN9LH8ZXoQA+
 kScG6CA7yXupZjFNuJYy/UsFBe3jIEP/qrdhtKyIPVmDzKXGJIzdjyqCyYtounpz+UlAWZ50Lqa
 W6WmRcruhHw5qqTEnbojLi0FG8ZuOBVKn95SqLjLxykeMDJSFSqBXU5Mk2Lc7+5Og7BgarS1p7y
 col9cX5brln3dEA==
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
@@ -13,19 +13,24 @@ maintainers:
 
 description: |
   The Synaptics RMI4 (Register Mapped Interface 4) core is able to support RMI4
   devices using different transports (I2C, SPI) and different functions (e.g.
   Function 1, 2D sensors using Function 11 or 12).
 
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
 
   '#address-cells':
     const: 1
 
   '#size-cells':

-- 
2.53.0

