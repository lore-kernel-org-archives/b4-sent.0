From: Aaron Kling <webgeek1234@gmail.com>
Date: Fri, 05 Jun 2026 16:49:07 -0500
Subject: [PATCH 1/2] dt-bindings: arm: qcom,ids: Add SoC ID for CQ8725S
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-cq8725s-soc-id-v1-1-bb1ef93de649@gmail.com>
References: <20260605-cq8725s-soc-id-v1-0-bb1ef93de649@gmail.com>
In-Reply-To: <20260605-cq8725s-soc-id-v1-0-bb1ef93de649@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Teguh Sobirin <teguh@sobir.in>, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780696163; l=738;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=6e0Ah17Wf7TzEakhG6V963usIXMZDDnLcXD9K/mhscA=;
 b=vL7rM0Gt1x33pVcnzIMeLv1lkmsDpyuAHNHUsvjaJOx0UQQOe6dtizJp6Yenwl0To1JWv7Mms
 YNfZsCMBiNfCFVoVlaO3LMuRx0JJl0R4h17445yJpcjUO3JthDaBXFR
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Teguh Sobirin <teguh@sobir.in>

Add the ID for the Qualcomm CQ8725S SoC which represents the Pakala
platform.

Signed-off-by: Teguh Sobirin <teguh@sobir.in>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 include/dt-bindings/arm/qcom,ids.h | 1 +
 1 file changed, 1 insertion(+)

diff --git a/include/dt-bindings/arm/qcom,ids.h b/include/dt-bindings/arm/qcom,ids.h
index 1af73c0ad41cd0..b571882d51874f 100644
--- a/include/dt-bindings/arm/qcom,ids.h
+++ b/include/dt-bindings/arm/qcom,ids.h
@@ -299,6 +299,7 @@
 #define QCOM_ID_QCS9075			676
 #define QCOM_ID_QCS615			680
 #define QCOM_ID_SA8797P			690
+#define QCOM_ID_CQ8725S			706
 #define QCOM_ID_CQ7790M			731
 #define QCOM_ID_CQ7790S			732
 #define QCOM_ID_CQ2390M			756

-- 
2.53.0

