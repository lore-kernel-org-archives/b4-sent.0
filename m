From: Manivannan Sadhasivam <mani@kernel.org>
Date: Thu, 21 May 2026 12:36:20 +0000
Subject: [PATCH 1/2] dt-bindings: crypto: qcom,prng: Document Hawi TRNG
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260521-hawi-crypto-v1-1-9176a3b51bc0@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=907; i=mani@kernel.org;
 h=from:subject:message-id; bh=87Y5FwOjUYP3cLO2wi3+Srs6AfNhdn+1QiIA070LBV8=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqDvxE68+VLP4JD5mfqCBLgToH2WODoY19+n7ZF
 7kcGB/pTMiJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCag78RAAKCRBVnxHm/pHO
 9RlnB/9MKf2X0z1K9DYHIi2kpH2/oYGxzWOrZ02bk9J7GENYUFTZeU6szlFAr9LBEXvwZgUM/Bf
 IaSDf05AFY+k/TzKm3AVkm0G54H87b3ErOltrd2yj4WL4VaZ6qMKkQaYsBViqaB0ogUhafpDhfh
 9MXcGxgHhe5Mas/uKfVgqmnmA+20Xf4wj6PCbLHCuKI0cQVOeZEE63u8UFJ7ExinZbttIDTbHZd
 JiSgYZOdQ3OfW2ls8uAxGCeFYt0BUCerW1etQs/+xHVjYQzsBr5LTY9amwIhuMRVmGKecFVGohi
 T/lkwaXo/ggbfZ55dQ1dtfewty95xnEpy+yZIUV9wR9NF0cx
X-Developer-Key: i=mani@kernel.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for mani@kernel.org/default with auth_id=787
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

Hawi SoC has the True Random Number Generator (TRNG) which is compatible
with the baseline IP "qcom,trng". Hence, document the compatible as such.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 Documentation/devicetree/bindings/crypto/qcom,prng.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/crypto/qcom,prng.yaml b/Documentation/devicetree/bindings/crypto/qcom,prng.yaml
index 41402599e9ab..e5489941e769 100644
--- a/Documentation/devicetree/bindings/crypto/qcom,prng.yaml
+++ b/Documentation/devicetree/bindings/crypto/qcom,prng.yaml
@@ -17,6 +17,7 @@ properties:
           - qcom,prng-ee  # 8996 and later using EE
       - items:
           - enum:
+              - qcom,hawi-trng
               - qcom,ipq5332-trng
               - qcom,ipq5424-trng
               - qcom,ipq9574-trng

-- 
2.43.0

