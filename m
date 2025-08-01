From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v2 0/2] sdm845: Use definitions and deduplicate
Date: Fri, 01 Aug 2025 10:21:38 +0200
Message-Id: <20250801-sdm845-msmid-v2-0-9f44d125ee44@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABJ5jGgC/3XMQQ7CIBCF4as0sxYDSGXqynuYLhRGOwvaBhpSb
 bi72L3L/yXv2yBRZEpwaTaIlDnxNNbQhwbccB9fJNjXBi11K+1JieQDmlaEFNgL85CIVlmN3kG
 9zJGevO7cra89cFqm+N71rH7rHygrIUWHBjtyZPFMV155OboP9KWUL3uzLwSmAAAA
X-Change-ID: 20250731-sdm845-msmid-4b08871728dc
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1145; i=david@ixit.cz;
 h=from:subject:message-id; bh=cbKMaeNFnC7Uv8CxN51Vo7VVhMeUMuTAk7cQCsUiu9g=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBojHkSBWvNXNdLcMUpN8bt8KueWCleQmK/GcdTZ
 AlZM4DI2COJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaIx5EgAKCRBgAj/E00kg
 cqNrD/4hy2MAe4IilwbDSw1HeXkm2bI8unrs3isoiJmmVRVohN0QVFHgKno1CJZAi1AXBwVVNAT
 LOMVtL6EvdmTOh+fwmEv88bBcbQhsevS0AJ9i+FgCPmV0WluT2anXH0ouuW3dLMiceMrhLfxbKW
 COdP6fTALRJRog+G4dIvN9lgdSsLGdjs1cDmZnxFO6sZdUmLES8K1n2eMUS7Up3HbGmHUykgxh8
 9fYnEMEj3REFY/mKQMPmjUUn9yOrSGPjttHRm6yEt844yNIKdbbkfc8DzB79/F6joNM4WCux61o
 f3o/mPGda/XALNqb/SYX+4GvwLQ71JwsRA9c2k/cvlriwx8ExRU7MdPMS2IE5q16UhQr0bXAyOF
 LwQSpcqf/PmRl5/8LLDtrgIpHmFJxkR/jzfC9Yk6kly/kIVKBa+5UGN71Mn5A3GftKUpJ0DpGXH
 FY6W0l+xFgjlBOW+b6WPN01vzdOhuHmpeA4yVeM/Dr4m/PGng6/+SP9H+zm+50fimr3WDjWXgkf
 0oflYoKUssidXxQqxxbJ126sv2c7k4KjsHmjUE0ZT0SV8CVDLIzk/1UBX/+8qNQbzMJdVs8k1Rg
 6cSsO2i1O3CCXF7e999mynmI71HFdjE8gRGYFNZcyrPUPJhs7KSA/9gxcEuK2o09POMY3SCmUtQ
 Rgcz+kfLUVwXuGQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Small cleanup.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v2:
- Added missing include.
- Link to v1: https://lore.kernel.org/r/20250731-sdm845-msmid-v1-0-98489ece786e@ixit.cz

---
David Heidelberg (2):
      arm64: dts: qcom: sdm845*: Use definition for msm-id
      arm64: dts: qcom: sdm845-oneplus: Deduplicate shared entries

 arch/arm64/boot/dts/qcom/sdm845-db845c.dts                   | 3 ++-
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi          | 4 ++++
 arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts        | 2 --
 arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts           | 2 --
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts            | 3 ++-
 arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi        | 3 ++-
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi | 3 ++-
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-polaris.dts           | 3 ++-
 8 files changed, 14 insertions(+), 9 deletions(-)
---
base-commit: 84b92a499e7eca54ba1df6f6c6e01766025943f1
change-id: 20250731-sdm845-msmid-4b08871728dc

Best regards,
-- 
David Heidelberg <david@ixit.cz>

