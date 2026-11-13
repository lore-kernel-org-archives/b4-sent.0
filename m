From: Ishu Brar <patches@brar.si>
Date: Fri, 13 Nov 2026 11:26:36 +0530
Subject: [PATCH v3 3/6] dt-bindings: display/msm: dp-controller: Add SM7250
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-dpu-sm7250-v3-3-30bdec59d204@brar.si>
References: <20261113-dpu-sm7250-v3-0-30bdec59d204@brar.si>
In-Reply-To: <20261113-dpu-sm7250-v3-0-30bdec59d204@brar.si>
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Krishna Manikandan <quic_mkrishn@quicinc.com>, Ishu Brar <patches@brar.si>, 
 Kuogee Hsieh <quic_khsieh@quicinc.com>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794549395; l=963;
 i=patches@brar.si; h=from:subject:message-id;
 bh=AcZp8+cV6TDy361VSXZ9EuoRu2qfcwVDBf4K2rgS/Lg=;
 b=49nL62R2ZVcoSVeaVUn4mObj6aSRGxlORdsPdZDMjTPmVGcEYUcZFnc0f84FgzFxsM0D+zXw7
 juLSrBFAyifCoPiSOYtFrON21pAhV5ctpDDFYkDbS1SqFiMnSZM959U
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SM7250 has a single DisplayPort controller, the same as the one on
SM8250, so add its compatible with the qcom,sm8350-dp fallback.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Ishu Brar <patches@brar.si>
---
 Documentation/devicetree/bindings/display/msm/dp-controller.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/display/msm/dp-controller.yaml b/Documentation/devicetree/bindings/display/msm/dp-controller.yaml
index 094a6383bb77..d535e090ea2e 100644
--- a/Documentation/devicetree/bindings/display/msm/dp-controller.yaml
+++ b/Documentation/devicetree/bindings/display/msm/dp-controller.yaml
@@ -53,6 +53,7 @@ properties:
           - enum:
               - qcom,sar2130p-dp
               - qcom,sm7150-dp
+              - qcom,sm7250-dp
               - qcom,sm8150-dp
               - qcom,sm8250-dp
               - qcom,sm8450-dp

-- 
2.56.1

