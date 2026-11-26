From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Thu, 26 Nov 2026 14:39:43 +0100
Subject: [PATCH v2 1/2] dt-bindings: sram: document qcom,sc8180x-imem
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-sc8180x-dts-ipa-v2-1-ad57b1be7c70@gmail.com>
References: <20261126-sc8180x-dts-ipa-v2-0-ad57b1be7c70@gmail.com>
In-Reply-To: <20261126-sc8180x-dts-ipa-v2-0-ad57b1be7c70@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Robert Ijtsma <robertijtsma@gmail.com>, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795700384; l=808;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=nEQ+cGLgYgPSg71wgECg22VaJoVFfq3rn8jYugnx5Uc=;
 b=vzd6mOxpsmnXG8ZyobOX8UTLgHOJrDa++9/EF08MRlgNK/3IxUv1tw5c9oRifO/xljKc5KMVT
 RM8TfTrD3P/D+hUwbGQBoNnk7fjp53r7xaoWkUFagvxAazo6rDczOlj
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the compatible string for the on-chip SRAM (IMEM) region on
Qualcomm SC8180X SoCs under the generic mmio-sram binding.

Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 Documentation/devicetree/bindings/sram/sram.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/sram/sram.yaml b/Documentation/devicetree/bindings/sram/sram.yaml
index 6ee0b14..a6353ab 100644
--- a/Documentation/devicetree/bindings/sram/sram.yaml
+++ b/Documentation/devicetree/bindings/sram/sram.yaml
@@ -42,6 +42,7 @@ properties:
         - qcom,maili-imem
         - qcom,milos-imem
         - qcom,rpm-msg-ram
+        - qcom,sc8180x-imem
         - qcom,shikra-imem
         - rockchip,rk3288-pmu-sram
         - samsung,exynos850-acpm-sram

-- 
2.56.0

