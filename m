From: Manivannan Sadhasivam <mani@kernel.org>
Date: Thu, 21 May 2026 12:36:21 +0000
Subject: [PATCH 2/2] dt-bindings: crypto: qcom,inline-crypto-engine:
 Document Hawi ICE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260521-hawi-crypto-v1-2-9176a3b51bc0@kernel.org>
References: <20260521-hawi-crypto-v1-0-9176a3b51bc0@kernel.org>
In-Reply-To: <20260521-hawi-crypto-v1-0-9176a3b51bc0@kernel.org>
To: Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-crypto@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, mani@kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1027; i=mani@kernel.org;
 h=from:subject:message-id; bh=sc+HfR6j5a3ujVo0ShNKGvCFMa9cPO2/pJqvTuqAxPg=;
 b=kA0DAAoBVZ8R5v6RzvUByyZiAGoO/ESgx71obOBk5uPKjm6jfRRVyXa+Hi1bitbegIFOqTeY6
 okBMwQAAQoAHRYhBGelQyqBSMvYpFgnl1WfEeb+kc71BQJqDvxEAAoJEFWfEeb+kc71tY8IAKJZ
 3OsOA2iGYhsATnDiaNfUMNzQiSnkdScNAuYKzv0ZgWiH0heM2Gi597f5OaF3oQ7ncfOPvzcg3pf
 yR4uDmC/NuCkp7MTxSFdR8NmyXgTNAvXcx5lXBT9F8LzgFVA+igwUNmBST6S4irZXLAsLzMa/CX
 W1eIXmKSTEn4Nr6FNh+r4jGkKO9Vtf9Hd8FBXAZ4XxnYpdq6rfRR1/24kYnwWO72Uzo0jNy5OKm
 FBFGJoJJrnAlgo1idyN0Rrg6NhTXab/dtmvl0LsDUK6TSnknlHXPC4d7S4LDnyslKbwuzUWj71A
 7AuvLCnVX6l1/oBAqTAbd1oKDOO64VJS18BZDrY=
X-Developer-Key: i=mani@kernel.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for mani@kernel.org/default with auth_id=787
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

The Inline Crypto Engine found in Hawi SoC is compatible with the common
baseline IP 'qcom,inline-crypto-engine'. Hence, document the compatible as
such.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 Documentation/devicetree/bindings/crypto/qcom,inline-crypto-engine.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/crypto/qcom,inline-crypto-engine.yaml b/Documentation/devicetree/bindings/crypto/qcom,inline-crypto-engine.yaml
index 876bf90ed96e..2a183b07b03a 100644
--- a/Documentation/devicetree/bindings/crypto/qcom,inline-crypto-engine.yaml
+++ b/Documentation/devicetree/bindings/crypto/qcom,inline-crypto-engine.yaml
@@ -14,6 +14,7 @@ properties:
     items:
       - enum:
           - qcom,eliza-inline-crypto-engine
+          - qcom,hawi-inline-crypto-engine
           - qcom,kaanapali-inline-crypto-engine
           - qcom,milos-inline-crypto-engine
           - qcom,qcs8300-inline-crypto-engine

-- 
2.43.0

