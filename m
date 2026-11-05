From: Demeter Barna <me@fromdisposition.org>
Date: Thu, 05 Nov 2026 13:30:01 +0000
Subject: [PATCH 2/5] dt-bindings: nvmem: qfprom: Add SM8350 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-b4-sm8350-gpu-v1-2-a7175cdd6512@fromdisposition.org>
References: <20261105-b4-sm8350-gpu-v1-0-a7175cdd6512@fromdisposition.org>
In-Reply-To: <20261105-b4-sm8350-gpu-v1-0-a7175cdd6512@fromdisposition.org>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Srinivas Kandagatla <srini@kernel.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, Sean Paul <sean@poorly.run>, 
 Akhil P Oommen <akhilpo@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, Demeter Barna <me@fromdisposition.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793885419; l=868;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=Oob8rDXOYjlZ+LgrNVXCvcO5Bli00goKm8+tcwj7nKI=;
 b=7DrcJnoUp88KALon2mZV8imuZBCEzgeqXXg1X5V/967WhbLJrepAfg6A+iP3D/WykSnUVCFMb
 vufPNefnw5dDuKFEoIfAeLrYrW1jc1E2OzSi+2rp2ZrlEJ08MipKbgb
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the SM8350 QFPROM. It needs its own compatible because some of
its regions cannot be read, and the driver has to know which.

Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
 Documentation/devicetree/bindings/nvmem/qcom,qfprom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/nvmem/qcom,qfprom.yaml b/Documentation/devicetree/bindings/nvmem/qcom,qfprom.yaml
index 566304ed4..f1aacc8c0 100644
--- a/Documentation/devicetree/bindings/nvmem/qcom,qfprom.yaml
+++ b/Documentation/devicetree/bindings/nvmem/qcom,qfprom.yaml
@@ -60,6 +60,7 @@ properties:
           - qcom,sm6375-qfprom
           - qcom,sm8150-qfprom
           - qcom,sm8250-qfprom
+          - qcom,sm8350-qfprom
           - qcom,sm8450-qfprom
           - qcom,sm8550-qfprom
           - qcom,sm8650-qfprom

-- 
2.53.0

