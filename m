From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Thu, 09 Jul 2026 03:30:51 +0000
Subject: [PATCH v2 1/2] dt-bindings: media: meson6-ir: Add Amlogic A9 IR
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260709-a9-ir-v2-1-42c21d7a6ffc@amlogic.com>
References: <20260709-a9-ir-v2-0-42c21d7a6ffc@amlogic.com>
In-Reply-To: <20260709-a9-ir-v2-0-42c21d7a6ffc@amlogic.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783567853; l=1145;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=rmPAoSNSZx5LMEoeF/b4E+Q1f6fRs3+ubaclp6Z1pc8=;
 b=RFXDKk/9e5V0rL7YIoH1aU5mVnHctr+HpC13MtW6h6g2GKfJVmXzRqsXK8xhNIlM3fjV/i6GP
 FGq4facPZpuD82VxqBgua2YqJrDoeDW0d229XZ8SywdSlPokapRvkQ2
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Amlogic A9 IR controller compatible string. The A9 IR
controller shares the same implementation as the Meson S4 IR block,
so add "amlogic,a9-ir" with "amlogic,meson-s4-ir" as the fallback
compatible.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Reviewed-by: Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 Documentation/devicetree/bindings/media/amlogic,meson6-ir.yaml | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/amlogic,meson6-ir.yaml b/Documentation/devicetree/bindings/media/amlogic,meson6-ir.yaml
index 0f95fe8dd9ac..db9387e43eff 100644
--- a/Documentation/devicetree/bindings/media/amlogic,meson6-ir.yaml
+++ b/Documentation/devicetree/bindings/media/amlogic,meson6-ir.yaml
@@ -23,6 +23,10 @@ properties:
       - items:
           - const: amlogic,meson-gx-ir
           - const: amlogic,meson-gxbb-ir
+      - items:
+          - enum:
+              - amlogic,a9-ir
+          - const: amlogic,meson-s4-ir
 
   reg:
     maxItems: 1

-- 
2.52.0

