From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v2 0/2] interconnect: qcom: sdx75: Drop QP0 interconnect
 and BCM nodes
Date: Fri, 26 Sep 2025 12:12:08 +0530
Message-Id: <20250926-sdx75-icc-v2-0-20d6820e455c@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAME11mgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHQUlJIzE
 vPSU3UzU4B8JSMDI1MDSyMz3eKUCnNT3czkZF0z82QjgyTjlFQLk0QloPqCotS0zAqwWdGxtbU
 A34DkpVsAAAA=
X-Change-ID: 20250926-sdx75-icc-67c20b3de84a
To: Georgi Djakov <djakov@kernel.org>, 
 Rohit Agarwal <quic_rohiagar@quicinc.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 devicetree@vger.kernel.org, Manivannan Sadhasivam <mani@kernel.org>, 
 Raviteja Laggyshetty <quic_rlaggysh@quicinc.com>, 
 Lakshmi Sowjanya D <quic_laksd@quicinc.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2092;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=w50rQbsUwHAX7rQjt1NnSquIVsSXVF6HpsxQbh+X4Zo=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBo1jXImIUMosVMEtE4ghqPdD1MJv1QPBohfPPr7
 jcaWqgcHH+JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaNY1yAAKCRBVnxHm/pHO
 9frcB/9Zc7MG+v8da1LYI1ZK1cOzGIBzmucX9iVFdcve/fQzbHEVk+Xq1Xuwi0WQZCcMB5HIfRv
 G0vwDGCkPB46Krt3X35JtJ6b7aiC4i+CGwWSQkFpuuzq9TZNyBT7Tw4EKIAEoLKjXeYQxaS+oLT
 Rw0Hu4Us1HOHpiiXrDAZguzfrQLgcta8Ck2Jnl1vI6ggK1mO6ffU3rUPsxthIvP+Dv0AX4Fpzc4
 nc7xJaLYWRTEOAMqaJHuP0NEf6934HaF5SG0481sz8cLPEUFzpgXA7R/PM0DjScLm7vrUmkm4HR
 uofBSBwY/gYOOAqxCwz7l43Iy4TaKB3YLAFy3ldMViMv0shN
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series drops the QPIC interconnect and BCM nodes for the SDX75 SoC. The
reason is that this QPIC BCM resource is already defined as a RPMh clock in
clk-rpmh driver as like other SDX SoCs. So it is wrong to describe the same
resource in two different providers.

Also, without this series, the NAND driver fails to probe on SDX75 as the
interconnect sync state disables the QPIC nodes as there were no clients voting
for this ICC resource. However, the NAND driver had already voted for this BCM
resource through the clk-rpmh driver. Since both votes come from Linux, RPMh was
unable to distinguish between these two and ends up disabling the resource
during sync state.

Cc: linux-arm-msm@vger.kernel.org
Cc: linux-pm@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Cc: devicetree@vger.kernel.org
Cc: Manivannan Sadhasivam <mani@kernel.org>
Cc: Raviteja Laggyshetty <quic_rlaggysh@quicinc.com>
Cc: Lakshmi Sowjanya D <quic_laksd@quicinc.com>
To: Georgi Djakov <djakov@kernel.org>
To: Konrad Dybcio <konradybcio@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

Changes in v2:

- Taken over the series from Raviteja
- Reordered the patches to avoid breaking build
- Improved the patch descriptions and kept the values for other defines
  unchanged

---
Raviteja Laggyshetty (2):
      interconnect: qcom: sdx75: Drop QPIC interconnect and BCM nodes
      dt-bindings: interconnect: qcom: Drop QPIC_CORE IDs

 drivers/interconnect/qcom/sdx75.c             | 26 --------------------------
 drivers/interconnect/qcom/sdx75.h             |  2 --
 include/dt-bindings/interconnect/qcom,sdx75.h |  2 --
 3 files changed, 30 deletions(-)
---
base-commit: 8f5ae30d69d7543eee0d70083daf4de8fe15d585
change-id: 20250926-sdx75-icc-67c20b3de84a

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

