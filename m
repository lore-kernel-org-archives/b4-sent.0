From: Jingyi Wang <quic_jingyw@quicinc.com>
Date: Wed, 11 Sep 2024 15:06:36 +0800
Subject: [PATCH v2] dt-bindings: ufs: qcom: Document the QCS8300 UFS
 Controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240911-qcs8300_ufs_binding-v2-1-68bb66d48730@quicinc.com>
X-B4-Tracking: v=1; b=H4sIAHxB4WYC/z2NWw6CMBQFt0LutzW3UEH8ch+GkNIH3ERbaYFoC
 Hu3EuPnTHLmrBBNIBPhkq0QzEKRvEuQHzJQg3S9YaQTQ465wJpzNqp4LhDb2ca2I6fJ9ayrCls
 Kw8v6JCAtn8FYeu3VW5N4oDj58N5PFv61vx6Kf48cTSTvrZ4isYUzZBqNrKXVCrG6jjMpcuqo/
 AOabds+JBLRLrkAAAA=
To: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, Avri Altman <avri.altman@wdc.com>, 
 Bart Van Assche <bvanassche@acm.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Andy Gross <agross@kernel.org>
Cc: quic_tengfan@quicinc.com, linux-arm-msm@vger.kernel.org, 
 linux-scsi@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Xin Liu <quic_liuxin@quicinc.com>, 
 Jingyi Wang <quic_jingyw@quicinc.com>
X-Mailer: b4 0.15-dev-99b12
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726038401; l=1428;
 i=quic_jingyw@quicinc.com; s=20240910; h=from:subject:message-id;
 bh=yZxiS3+OUN2g+UOsDxSlDTpZu7grXBO6hd13xebV2Vc=;
 b=tEpNIxFM4Fihx7NycxEykZz+/y/nbEG4sG+ePY1hbyHCUvvgUSjkOcaoLv8qb7gFudEn9aotG
 f6uP3PUBvpYDRwtjWNJvw2nO0FbmbYFrQoYyvwUMKH7MaBuOJnXN4hi
X-Developer-Key: i=quic_jingyw@quicinc.com; a=ed25519;
 pk=ZRP1KgWMhlXXWlSYLoO7TSfwKgt6ke8hw5xWcSY+wLQ=
X-Endpoint-Received: by B4 Relay for quic_jingyw@quicinc.com/20240910 with auth_id=207
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Xin Liu <quic_liuxin@quicinc.com>

Document the Universal Flash Storage(UFS) Controller on the Qualcomm
QCS8300 Platform.

Signed-off-by: Xin Liu <quic_liuxin@quicinc.com>
Signed-off-by: Jingyi Wang <quic_jingyw@quicinc.com>
---
Changes in v2:
- decoupled from the original series.
- Link to v1: https://lore.kernel.org/r/20240904-qcs8300_initial_dtsi-v1-0-d0ea9afdc007@quicinc.com
---
 Documentation/devicetree/bindings/ufs/qcom,ufs.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/ufs/qcom,ufs.yaml b/Documentation/devicetree/bindings/ufs/qcom,ufs.yaml
index 25a5edeea164..cde334e3206b 100644
--- a/Documentation/devicetree/bindings/ufs/qcom,ufs.yaml
+++ b/Documentation/devicetree/bindings/ufs/qcom,ufs.yaml
@@ -26,6 +26,7 @@ properties:
           - qcom,msm8994-ufshc
           - qcom,msm8996-ufshc
           - qcom,msm8998-ufshc
+          - qcom,qcs8300-ufshc
           - qcom,sa8775p-ufshc
           - qcom,sc7180-ufshc
           - qcom,sc7280-ufshc
@@ -146,6 +147,7 @@ allOf:
           contains:
             enum:
               - qcom,msm8998-ufshc
+              - qcom,qcs8300-ufshc
               - qcom,sa8775p-ufshc
               - qcom,sc7280-ufshc
               - qcom,sc8180x-ufshc

---
base-commit: 100cc857359b5d731407d1038f7e76cd0e871d94
change-id: 20240911-qcs8300_ufs_binding-b73f64e16954

Best regards,
-- 
Jingyi Wang <quic_jingyw@quicinc.com>

