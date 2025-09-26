From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Fri, 26 Sep 2025 12:12:10 +0530
Subject: [PATCH v2 2/2] dt-bindings: interconnect: qcom: Drop QPIC_CORE IDs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250926-sdx75-icc-v2-2-20d6820e455c@oss.qualcomm.com>
References: <20250926-sdx75-icc-v2-0-20d6820e455c@oss.qualcomm.com>
In-Reply-To: <20250926-sdx75-icc-v2-0-20d6820e455c@oss.qualcomm.com>
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
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1460;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=H39PzgE3sz0Da1E79p3mlCmC8enF7l/7/JpoIn/7roE=;
 b=kA0DAAoBVZ8R5v6RzvUByyZiAGjWNcij4ji5d+OhMrWz2FxnQl6c2qbFTx8lbJJF8CcwRBhjD
 4kBMwQAAQoAHRYhBGelQyqBSMvYpFgnl1WfEeb+kc71BQJo1jXIAAoJEFWfEeb+kc71B90IAJ3O
 NF6hWgKBnE3EgdacmcdNpOSGVehcU8hcZiamdB+PleuTeoN9pL3E+8hGmnsOfXJuGuZbdwLtr+V
 teI4RWa5ME5PBIqvLB0R2e1l/ZB2vwAxv34z5QV/XFLCTT5lVQ/rJDRxprKSoZT6gwLOkG6gH2q
 Gt5dHj3Aik2ILARl2jjCJP8uLUVGIeRp9dQBrsoK0ufZfvKJmcJC4qqlbz04qW6esskry0xA78t
 osi7EffgvUa1YiIF0lCV4MvXBi+5ug4iw1Th2GcAhnGmgdhgDqhYRNoYDt82GIg6FmIVFFMG2Z6
 I22cBZAFIaxY6cm/DBif1Qah/HCsCbQr7lkJ+Rg=
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Raviteja Laggyshetty <quic_rlaggysh@quicinc.com>

As like other SDX targets, SDX75 QPIC BCM resource is also modeled as a
RPMh clock in clk-rpmh driver. However, for SDX75, this resource was also
described as an interconnect node mistakenly.

Hence, drop the QPIC interconnect IDs and let the clients use clk-rpmh
driver to vote for this resource.

Even though this change is an ABI break, it is necessary to avoid
describing the same resource provider in two different drivers, as it may
lead to votes from clients overriding each other.

Fixes: 956329ec7c5e ("dt-bindings: interconnect: Add compatibles for SDX75")
Signed-off-by: Raviteja Laggyshetty <quic_rlaggysh@quicinc.com>
[mani: kept the QUP defines value unchanged]
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 include/dt-bindings/interconnect/qcom,sdx75.h | 2 --
 1 file changed, 2 deletions(-)

diff --git a/include/dt-bindings/interconnect/qcom,sdx75.h b/include/dt-bindings/interconnect/qcom,sdx75.h
index e903f5f3dd8f63b257222b78e8ea41143d3dc86c..0e19ee8f168702a364f4101991ce9a6213da2eea 100644
--- a/include/dt-bindings/interconnect/qcom,sdx75.h
+++ b/include/dt-bindings/interconnect/qcom,sdx75.h
@@ -6,9 +6,7 @@
 #ifndef __DT_BINDINGS_INTERCONNECT_QCOM_SDX75_H
 #define __DT_BINDINGS_INTERCONNECT_QCOM_SDX75_H
 
-#define MASTER_QPIC_CORE		0
 #define MASTER_QUP_CORE_0		1
-#define SLAVE_QPIC_CORE			2
 #define SLAVE_QUP_CORE_0		3
 
 #define MASTER_LLCC			0

-- 
2.48.1

