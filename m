From: Esteban Urrutia <esteuwu@proton.me>
Date: Fri, 31 Jul 2026 01:00:08 -0400
Subject: [PATCH v2 1/2] dt-bindings: soc: qcom: qcom,pmic-glink: Add
 compatible string for SM8475
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-sm8475-pmic-glink-v2-1-28c04928ef22@proton.me>
References: <20260731-sm8475-pmic-glink-v2-0-28c04928ef22@proton.me>
In-Reply-To: <20260731-sm8475-pmic-glink-v2-0-28c04928ef22@proton.me>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-usb@vger.kernel.org, 
 phone-devel@vger.kernel.org, Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785474171; l=994;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=qlIsWzTJF0ZNZIPSTD3siW5UjKn8TpIMzi3TfROAv2Y=;
 b=UYFWJnnkVXGsAo09+NrRG9PD+O8CBvH2CbNyQPsxTt9hmxpXbPzIS7hoUVy/TpXcvZ+J2nWsR
 dD/ztt1kkhaB4LKX/YgNF2YomCV+sPmUSgP58KOrwA75uWolF5yZflJ
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Due to a different process design, SM8475 (4 nm) SoC takes things from both
SM8450 (4 LPX) and SM8550 (4 nm) SoCs.
Add a separate compatible string for this SoC to avoid possible confusions.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
 Documentation/devicetree/bindings/soc/qcom/qcom,pmic-glink.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/soc/qcom/qcom,pmic-glink.yaml b/Documentation/devicetree/bindings/soc/qcom/qcom,pmic-glink.yaml
index 16ad4f5698fc..c80c72411381 100644
--- a/Documentation/devicetree/bindings/soc/qcom/qcom,pmic-glink.yaml
+++ b/Documentation/devicetree/bindings/soc/qcom/qcom,pmic-glink.yaml
@@ -30,6 +30,7 @@ properties:
               - qcom,sc8280xp-pmic-glink
               - qcom,sm8350-pmic-glink
               - qcom,sm8450-pmic-glink
+              - qcom,sm8475-pmic-glink
               - qcom,sm8550-pmic-glink
           - const: qcom,pmic-glink
       - items:

-- 
2.55.0

