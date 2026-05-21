From: Manivannan Sadhasivam <mani@kernel.org>
Subject: [PATCH 0/2] dt-bindings: crypto: Add Qualcomm Hawi crypto support
Date: Thu, 21 May 2026 12:36:19 +0000
Message-Id: <20260521-hawi-crypto-v1-0-9176a3b51bc0@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEP8DmoC/yXMTQqAIBBA4avErBPSKKKrRAvTsaaFhfaLePesl
 t/ivQAeHaGHNgvg8CBPi03geQZqknZERjoZRCHqohKcTfIkpty9bgvjZTMYLWSNqoJUrA4NXd+
 t63/7fZhRbe8CYnwAXxPLB28AAAA=
X-Change-ID: 20260521-hawi-crypto-138bfd2a6ec5
To: Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-crypto@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, mani@kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=691; i=mani@kernel.org;
 h=from:subject:message-id; bh=hTCV6Tywmfns991pR2bgVGuKHYp0MV9vZhRRF16DNuM=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqDvxEy+aGqC5dsRtzhdhhiv61/ks24RXASkfTR
 ka7eKsSbqKJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCag78RAAKCRBVnxHm/pHO
 9SwUB/9+ar1g3oJI9EXFpGPYwFFsr8iJiIfXZ3FVfMRm9Xt1+J4CIhdVjRoWM+tG6L6h8r9QnZx
 GSS8M7xEEZE+yA3vKf6yOv97z9NiH2hWnMuwoKKca4Dt36uKgfc7Pj3XAAmUhaS7RFpQuAqrIlJ
 f+vJ31JZvsWWlRKKFmkLDzQ1WpYN20p/T9isCCCFs5O2C4oTlrwaqAV5Zf/2VtiQTnKAWdu7Zl6
 D3+DblwAfR541UoVVykKt3Jjj2ZRLv8YsxAAb2YrsU3rB+JzAB5Izdc6hjt66zrNBwKUbuR1f81
 7PII99Ck8cLH+BNRKbF0bKswmk4+vez8G3HCyaJxoC0RqcFc
X-Developer-Key: i=mani@kernel.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for mani@kernel.org/default with auth_id=787
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series adds the crypto (ICE, TRNG) dt-binding support for Qualcomm's
upcoming Hawi SoC.

Signed-off-by: Manivannan Sadhasivam <mani@kernel.org>
---
Manivannan Sadhasivam (2):
      dt-bindings: crypto: qcom,prng: Document Hawi TRNG
      dt-bindings: crypto: qcom,inline-crypto-engine: Document Hawi ICE

 Documentation/devicetree/bindings/crypto/qcom,inline-crypto-engine.yaml | 1 +
 Documentation/devicetree/bindings/crypto/qcom,prng.yaml                 | 1 +
 2 files changed, 2 insertions(+)
---
base-commit: 254f49634ee16a731174d2ae34bc50bd5f45e731
change-id: 20260521-hawi-crypto-138bfd2a6ec5

Best regards,
--  
Manivannan Sadhasivam <mani@kernel.org>

