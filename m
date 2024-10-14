From: fangez <quic_fangez@quicinc.com>
Date: Mon, 14 Oct 2024 17:47:32 +0800
Subject: [PATCH 6/6] dt-bindings: display/msm: dsi-controller-main:
 Document QCS615
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241014-add_display_support_for_qcs615-v1-6-4efa191dbdd4@quicinc.com>
References: <20241014-add_display_support_for_qcs615-v1-0-4efa191dbdd4@quicinc.com>
In-Reply-To: <20241014-add_display_support_for_qcs615-v1-0-4efa191dbdd4@quicinc.com>
To: kernel@quicinc.com, quic_lliu6@quicinc.com, quic_fangez@quicinc.com, 
 quic_xiangxuy@quicinc.com
Cc: linux-arm-msm@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728899260; l=941;
 i=quic_fangez@quicinc.com; s=20241014; h=from:subject:message-id;
 bh=QzSZ/Ct5mHITxFIkGSeEs5PMumalxJtc+YuO5VAUQ7g=;
 b=iWvhASurjdF1/1luSnheYQptvyFB9TxLx0geZPd6BRJpPrdfEBsfgUZMIczWyB6R6/C3KIY9Z
 VpYYGu7jodvDT+7SGmNZUXchYzcgoj5wXbB0kvqbb8JX5JIeO+YCSXd
X-Developer-Key: i=quic_fangez@quicinc.com; a=ed25519;
 pk=tJv8Cz0npA34ynt53o5GaQfBC0ySFhyb2FGj+V2Use4=
X-Endpoint-Received: by B4 Relay for quic_fangez@quicinc.com/20241014 with auth_id=245
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: lliu6 <quic_lliu6@quicinc.com>

Document general compatibility of the DSI controller on QCS615.

Signed-off-by: lliu6 <quic_lliu6@quicinc.com>
---
 Documentation/devicetree/bindings/display/msm/dsi-controller-main.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/display/msm/dsi-controller-main.yaml b/Documentation/devicetree/bindings/display/msm/dsi-controller-main.yaml
index b0fd96b76ed1376e429a6168df7e7aaa7aeff2d3..4142c753d1c4c4797e3a3f5317c02f8c863cdd12 100644
--- a/Documentation/devicetree/bindings/display/msm/dsi-controller-main.yaml
+++ b/Documentation/devicetree/bindings/display/msm/dsi-controller-main.yaml
@@ -39,6 +39,7 @@ properties:
               - qcom,sm8450-dsi-ctrl
               - qcom,sm8550-dsi-ctrl
               - qcom,sm8650-dsi-ctrl
+              - qcom,qcs615-dsi-ctrl
           - const: qcom,mdss-dsi-ctrl
       - enum:
           - qcom,dsi-ctrl-6g-qcm2290

-- 
2.25.1

