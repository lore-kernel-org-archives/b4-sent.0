From: Esteban Urrutia <esteuwu@proton.me>
Date: Wed, 29 Jul 2026 15:48:24 -0400
Subject: [PATCH 1/2] dt-bindings: soc: qcom: qcom,pmic-glink: Add
 compatible string for SM8475
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260729-sm8475-pmic-glink-v1-1-c2e1967c04de@proton.me>
References: <20260729-sm8475-pmic-glink-v1-0-c2e1967c04de@proton.me>
In-Reply-To: <20260729-sm8475-pmic-glink-v1-0-c2e1967c04de@proton.me>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785354535; l=839;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=0RkYfT7rea1utUnMdAEKOGzdpJNp1iGdKhG5L3zAaz0=;
 b=nG9XgR+swDbx10GNYeE0rqt6DsG1HzIXuQw3qvkJLB/hoDC23FkoZxQHaoZ4W5jtDj376FVBf
 rxsybq70HEVDtf/9G4aq4bSuu6G+CuFTsVhUj5q+z3LgJPTMPTLm5bk
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatible string for pmic-glink.

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

