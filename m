From: Esteban Urrutia <esteuwu@proton.me>
Date: Sun, 02 Aug 2026 02:39:55 -0400
Subject: [PATCH v3] dt-bindings: soc: qcom: qcom,pmic-glink: Add compatible
 string for SM8475
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260802-sm8475-pmic-glink-v3-1-45216e6ec572@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NTQ7CIBQE4KsY1mLg9QfqynsYF5a+tqiFBirRN
 L27UDddGJeTzHwzE49OoyfH3UwcBu21NTFk+x1R/dV0SHUTMwEGJRNQUT/IXBR0HLSi3UObOy0
 EFmVbyQbqjMTd6LDVr9U8X77ZP+sbqilBqdFrP1n3Xk8DT71/fuCUUQXIq1Ioljd4Gp2drDkMS
 JIfYCNk/JcAUQAZxxVIbAG2wrIsH7TT1U8GAQAA
X-Change-ID: 20260729-sm8475-pmic-glink-57e56f98d2b3
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785652809; l=1696;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=tn2xH0fzQ/e6xT6kAD58wd7odc28IuNeh1bh7VNPiEQ=;
 b=e08RXdumGEVucO+Vc+5VdB5GOkbF64uTxGj6Kjc5KWzP2O2qAnY/d2BqgZVdaGIR2/0AN95oE
 pHTp6y+OnwKB1QmhPab8ixfMFDrvd5Yn6HgoNxLbXRGqHvA59zLZrpv
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SM8475 is compatible with SM8450 with respect to pmic-glink support.
Add a compatible string for SM8475 using SM8450 as a fallback.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
This series adds a compatible string for pmic-glink in SM8475 in
dt-bindings using SM8450 as a fallback to provide support for it.
---
Changes in v3:
- Drop patch modifying ucsi_glink (redundant)
  - Use SM8450 compatible as a fallback instead
- Link to v2: https://patch.msgid.link/20260731-sm8475-pmic-glink-v2-0-28c04928ef22@proton.me

Changes in v2:
- Apply suggestions from Krzysztof
- Link to v1: https://patch.msgid.link/20260729-sm8475-pmic-glink-v1-0-c2e1967c04de@proton.me
---
 Documentation/devicetree/bindings/soc/qcom/qcom,pmic-glink.yaml | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/soc/qcom/qcom,pmic-glink.yaml b/Documentation/devicetree/bindings/soc/qcom/qcom,pmic-glink.yaml
index 16ad4f5698fc..d4478d9b3212 100644
--- a/Documentation/devicetree/bindings/soc/qcom/qcom,pmic-glink.yaml
+++ b/Documentation/devicetree/bindings/soc/qcom/qcom,pmic-glink.yaml
@@ -43,6 +43,11 @@ properties:
               - qcom,sm7325-pmic-glink
           - const: qcom,qcm6490-pmic-glink
           - const: qcom,pmic-glink
+      - items:
+          - enum:
+              - qcom,sm8475-pmic-glink
+          - const: qcom,sm8450-pmic-glink
+          - const: qcom,pmic-glink
       - items:
           - enum:
               - qcom,eliza-pmic-glink

---
base-commit: 415606a7be939835db9b0d6b711887586646346d
change-id: 20260729-sm8475-pmic-glink-57e56f98d2b3

Best regards,
--  
Esteban Urrutia <esteuwu@proton.me>

