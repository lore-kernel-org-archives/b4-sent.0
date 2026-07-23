From: Esteban Urrutia <esteuwu@proton.me>
Date: Wed, 22 Jul 2026 22:00:01 -0400
Subject: [PATCH v3 1/2] dt-bindings: phy: qcom,sc8280xp-qmp-usb43dp-phy:
 Add SM8475 QMP PHY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260722-sm8475-bup-usbss-v3-1-0dd5da218ab2@proton.me>
References: <20260722-sm8475-bup-usbss-v3-0-0dd5da218ab2@proton.me>
In-Reply-To: <20260722-sm8475-bup-usbss-v3-0-0dd5da218ab2@proton.me>
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Esteban Urrutia <esteuwu@proton.me>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784772180; l=1082;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=QrONa8UfuM7KhLs1br+f3olNhvY+ormmP5vIHk1Ddjo=;
 b=WUB+DblyoqVWwq+5auyteefmtxPX4XalUUFX+BULQK9wT+A4WphzbvQRd6qxxb7YGMcCKA0lZ
 e8y/3w34TXfATb+9GcbD7vYmBa97GCAN1VRNRWzATBwmMiAOEW7KP7O
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SM8450 init sequence for this PHY varies significantly and can't be used in
SM8475.
Add bindings for the PHY found in this SoC.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
 Documentation/devicetree/bindings/phy/qcom,sc8280xp-qmp-usb43dp-phy.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/phy/qcom,sc8280xp-qmp-usb43dp-phy.yaml b/Documentation/devicetree/bindings/phy/qcom,sc8280xp-qmp-usb43dp-phy.yaml
index 4eff92343ce4..b9d0de25f43c 100644
--- a/Documentation/devicetree/bindings/phy/qcom,sc8280xp-qmp-usb43dp-phy.yaml
+++ b/Documentation/devicetree/bindings/phy/qcom,sc8280xp-qmp-usb43dp-phy.yaml
@@ -37,6 +37,7 @@ properties:
           - qcom,sm8250-qmp-usb3-dp-phy
           - qcom,sm8350-qmp-usb3-dp-phy
           - qcom,sm8450-qmp-usb3-dp-phy
+          - qcom,sm8475-qmp-usb3-dp-phy
           - qcom,sm8550-qmp-usb3-dp-phy
           - qcom,sm8650-qmp-usb3-dp-phy
           - qcom,sm8750-qmp-usb3-dp-phy

-- 
2.55.0

