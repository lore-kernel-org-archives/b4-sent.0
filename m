From: Xiangxu Yin <xiangxu.yin@oss.qualcomm.com>
Date: Fri, 24 Oct 2025 13:21:02 +0800
Subject: [PATCH v6 2/4] dt-bindings: display: msm: sm6150-mdss: Fix example
 indentation and OPP values
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251024-add-displayport-support-to-qcs615-devicetree-v6-2-c4316975dd0e@oss.qualcomm.com>
References: <20251024-add-displayport-support-to-qcs615-devicetree-v6-0-c4316975dd0e@oss.qualcomm.com>
In-Reply-To: <20251024-add-displayport-support-to-qcs615-devicetree-v6-0-c4316975dd0e@oss.qualcomm.com>
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, fange.zhang@oss.qualcomm.com, 
 yongxing.mou@oss.qualcomm.com, li.liu@oss.qualcomm.com, 
 Xiangxu Yin <xiangxu.yin@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761283306; l=2505;
 i=xiangxu.yin@oss.qualcomm.com; s=20241125; h=from:subject:message-id;
 bh=y4mnUq7LzHW10KKLH+nf6gjJ/MAmcz9UJ+dZcgRQN14=;
 b=V8T8jDE+c94oJdOpBld3BxRonpp4Qd0Aetpd/l6CzM6eWyAtECrf+BD7QYbBlamxhUxhpgx5E
 5n8Yb8K0TjPD4KRXfcbMH+WJd6O7HoGKhFbCywGZXDu7n/96rgNNWi1
X-Developer-Key: i=xiangxu.yin@oss.qualcomm.com; a=ed25519;
 pk=F1TwipJzpywfbt3n/RPi4l/A4AVF+QC89XzCHgZYaOc=
X-Endpoint-Received: by B4 Relay for xiangxu.yin@oss.qualcomm.com/20241125 with auth_id=542
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- Adjusted indentation and added missing blank lines in the example.
- Corrected OPP clock values to match actual DTS configuration.

Signed-off-by: Xiangxu Yin <xiangxu.yin@oss.qualcomm.com>
---
 .../bindings/display/msm/qcom,sm6150-mdss.yaml     | 32 ++++++++++++----------
 1 file changed, 17 insertions(+), 15 deletions(-)

diff --git a/Documentation/devicetree/bindings/display/msm/qcom,sm6150-mdss.yaml b/Documentation/devicetree/bindings/display/msm/qcom,sm6150-mdss.yaml
index ba0dea2edea98cee0826cf38b3f33361666e004a..80183df71cd9288f652dc42afeae101e8edcbe65 100644
--- a/Documentation/devicetree/bindings/display/msm/qcom,sm6150-mdss.yaml
+++ b/Documentation/devicetree/bindings/display/msm/qcom,sm6150-mdss.yaml
@@ -140,35 +140,37 @@ examples:
                 #size-cells = <0>;
 
                 port@0 {
-                  reg = <0>;
-                  dpu_intf0_out: endpoint {
-                  };
+                    reg = <0>;
+
+                    dpu_intf0_out: endpoint {
+                    };
                 };
 
                 port@1 {
-                  reg = <1>;
-                  dpu_intf1_out: endpoint {
-                      remote-endpoint = <&mdss_dsi0_in>;
-                  };
+                    reg = <1>;
+
+                    dpu_intf1_out: endpoint {
+                        remote-endpoint = <&mdss_dsi0_in>;
+                    };
                 };
             };
 
             mdp_opp_table: opp-table {
                 compatible = "operating-points-v2";
 
-                opp-19200000 {
-                  opp-hz = /bits/ 64 <19200000>;
-                  required-opps = <&rpmhpd_opp_low_svs>;
+                opp-192000000 {
+                    opp-hz = /bits/ 64 <192000000>;
+                    required-opps = <&rpmhpd_opp_low_svs>;
                 };
 
-                opp-25600000 {
-                  opp-hz = /bits/ 64 <25600000>;
-                  required-opps = <&rpmhpd_opp_svs>;
+                opp-256000000 {
+                    opp-hz = /bits/ 64 <256000000>;
+                    required-opps = <&rpmhpd_opp_svs>;
                 };
 
                 opp-307200000 {
-                  opp-hz = /bits/ 64 <307200000>;
-                  required-opps = <&rpmhpd_opp_nom>;
+                    opp-hz = /bits/ 64 <307200000>;
+                    required-opps = <&rpmhpd_opp_nom>;
                 };
             };
         };

-- 
2.34.1

