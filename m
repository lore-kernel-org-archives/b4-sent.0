From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Thu, 26 Nov 2026 15:10:16 +0100
Subject: [PATCH v2 1/3] dt-bindings: sram: Document qcom,sc8180x-imem
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-sc8180x-dts-ipa-v2-1-e919ed1643c1@gmail.com>
References: <20261126-sc8180x-dts-ipa-v2-0-e919ed1643c1@gmail.com>
In-Reply-To: <20261126-sc8180x-dts-ipa-v2-0-e919ed1643c1@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795702215; l=802;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=dn2iumU+xZu7jFHoKhppBtYJi14Aa8xqhGV0sQfQ17o=;
 b=JgZSLCIu/wgp+eO5Rymz0a+sERXGKGyZ0a/5fhgNVDfcU8E0gnjbvKzNLRMMebjenfqLupMPw
 GBwonaX9RQvChn9jL5ftMNwkbibHNlyjJkLEA3YnQNLuU/GXe291n7n
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatible for the Qualcomm SC8180X SoC IMEM region.

Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 Documentation/devicetree/bindings/sram/sram.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/sram/sram.yaml b/Documentation/devicetree/bindings/sram/sram.yaml
index b09a70b3d57652f79a4ae813cfac2ca677ecffbb..f12dcb1d1e2fa5414fba8a9304893e2c6b6af319 100644
--- a/Documentation/devicetree/bindings/sram/sram.yaml
+++ b/Documentation/devicetree/bindings/sram/sram.yaml
@@ -44,6 +44,7 @@ properties:
         - qcom,maili-imem
         - qcom,milos-imem
         - qcom,rpm-msg-ram
+        - qcom,sc8180x-imem
         - qcom,shikra-imem
         - rockchip,rk3288-pmu-sram
         - samsung,exynos850-acpm-sram

-- 
2.47.3

