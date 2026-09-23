From: George Moussalem <george.moussalem@outlook.com>
Date: Wed, 23 Sep 2026 16:05:07 +0400
Subject: [PATCH ath-next 01/16] dt-bindings: net: wireless: ath11k: Sort
 compatible names alphabetically
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260923-ipq5018-qcn6122-mpd-v1-1-86729521a75c@outlook.com>
References: <20260923-ipq5018-qcn6122-mpd-v1-0-86729521a75c@outlook.com>
In-Reply-To: <20260923-ipq5018-qcn6122-mpd-v1-0-86729521a75c@outlook.com>
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jeff Johnson <jjohnson@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-wireless@vger.kernel.org, devicetree@vger.kernel.org, 
 ath11k@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Vignesh Viswanathan <vignesh.viswanathan@oss.qualcomm.com>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 linux-arm-msm@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790165117; l=1172;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=8Rc10oeOzKG46Y973OUa46HiYgABQNhQH09OMbqE0/A=;
 b=3+IjZNJc/3kIEHzthob1GBb8swjvmJm3tT2XGZdAeVqB3+1bxIGOUS3jPiFtH7zw2XhSFeb45
 S8mdKrSK7N/DUNla87oYJd+YhC7B6MW3DhOtcsbJ2gvPyGxpPV27ex4
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sort the compatible names in the binding file alphabetically for
legibility and correct ordering.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 Documentation/devicetree/bindings/net/wireless/qcom,ath11k.yaml | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/net/wireless/qcom,ath11k.yaml b/Documentation/devicetree/bindings/net/wireless/qcom,ath11k.yaml
index d4aa56e2f823..a846cd704b19 100644
--- a/Documentation/devicetree/bindings/net/wireless/qcom,ath11k.yaml
+++ b/Documentation/devicetree/bindings/net/wireless/qcom,ath11k.yaml
@@ -17,10 +17,10 @@ description: |
 properties:
   compatible:
     enum:
-      - qcom,ipq8074-wifi
+      - qcom,ipq5018-wifi
       - qcom,ipq6018-wifi
+      - qcom,ipq8074-wifi
       - qcom,wcn6750-wifi
-      - qcom,ipq5018-wifi
 
   reg:
     maxItems: 1
@@ -108,8 +108,8 @@ allOf:
         compatible:
           contains:
             enum:
-              - qcom,ipq8074-wifi
               - qcom,ipq6018-wifi
+              - qcom,ipq8074-wifi
     then:
       properties:
         interrupts:

-- 
2.53.0

