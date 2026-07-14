From: Esteban Urrutia <esteuwu@proton.me>
Date: Tue, 14 Jul 2026 02:36:42 -0400
Subject: [PATCH 4/6] dt-bindings: phy: qcom,sc8280xp-qmp-usb43dp-phy: Add
 SM8475 QMP PHY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260714-sm8475-bup-v1-4-b2871be2b4ec@proton.me>
References: <20260714-sm8475-bup-v1-0-b2871be2b4ec@proton.me>
In-Reply-To: <20260714-sm8475-bup-v1-0-b2871be2b4ec@proton.me>
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784011013; l=1034;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=PFP6IUISjVGd8cu9nI1mb8qZCo6FrND8DguB7XWFWvU=;
 b=Knlwubmm3cj+tjfc+xBpN8HYB1V46nzV6q3q+6JzCvyRUeRuUxRW9y10afVId2G8FiX1ImDZ6
 KipU2bPxOM6CpEpyjm4CljVsDSfrZV8o0mJIHoVfVGhl+VcTHijG28d
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SM8450 init sequence for this PHY varies significantly and can't be used in
SM8475.
Add proper init sequence and bindings for the PHY found in this SoC.

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

