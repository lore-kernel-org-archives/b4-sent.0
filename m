From: fangez <quic_fangez@quicinc.com>
Date: Mon, 14 Oct 2024 17:47:30 +0800
Subject: [PATCH 4/6] dt-bindings: display/msm: Add QCS615 DSI phy
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241014-add_display_support_for_qcs615-v1-4-4efa191dbdd4@quicinc.com>
References: <20241014-add_display_support_for_qcs615-v1-0-4efa191dbdd4@quicinc.com>
In-Reply-To: <20241014-add_display_support_for_qcs615-v1-0-4efa191dbdd4@quicinc.com>
To: kernel@quicinc.com, quic_lliu6@quicinc.com, quic_fangez@quicinc.com, 
 quic_xiangxuy@quicinc.com
Cc: linux-arm-msm@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728899259; l=797;
 i=quic_fangez@quicinc.com; s=20241014; h=from:subject:message-id;
 bh=TVRusJPDQxCEUvA/8eVnVeHUlVYWDLGQdPs1R0zTVY8=;
 b=PXIRo7x9fBlPQX1VSIFAP6xePngM6Nxh95IBQO2ciMBBXyyjxXc/p336uqXSRVaNYqc+2hEfd
 w8SGc9boqLSDC3WOJ3a/q2xDLUsfBuvc1H24qBY5mi6MbA/BmcMxE3u
X-Developer-Key: i=quic_fangez@quicinc.com; a=ed25519;
 pk=tJv8Cz0npA34ynt53o5GaQfBC0ySFhyb2FGj+V2Use4=
X-Endpoint-Received: by B4 Relay for quic_fangez@quicinc.com/20241014 with auth_id=245
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: lliu6 <quic_lliu6@quicinc.com>

QCS615 platform uses the 14nm DSI PHY driver.

Signed-off-by: lliu6 <quic_lliu6@quicinc.com>
---
 Documentation/devicetree/bindings/display/msm/dsi-phy-14nm.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/display/msm/dsi-phy-14nm.yaml b/Documentation/devicetree/bindings/display/msm/dsi-phy-14nm.yaml
index 52bbe132e6dae57246200757767edcd1c8ec2d77..029606d9e87e3b184bd10bd4a5076d6923d60e9e 100644
--- a/Documentation/devicetree/bindings/display/msm/dsi-phy-14nm.yaml
+++ b/Documentation/devicetree/bindings/display/msm/dsi-phy-14nm.yaml
@@ -20,6 +20,7 @@ properties:
       - qcom,dsi-phy-14nm-660
       - qcom,dsi-phy-14nm-8953
       - qcom,sm6125-dsi-phy-14nm
+      - qcom,qcs615-dsi-phy-14nm
 
   reg:
     items:

-- 
2.25.1

