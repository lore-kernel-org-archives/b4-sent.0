From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/2] sdm845: Use definitions and deduplicate
Date: Thu, 31 Jul 2025 23:02:42 +0200
Message-Id: <20250731-sdm845-msmid-v1-0-98489ece786e@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPLZi2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDc2ND3eKUXAsTU93c4tzMFF2TJAMLC3NDcyOLlGQloJaCotS0zAqwcdG
 xtbUACLOyUl4AAAA=
X-Change-ID: 20250731-sdm845-msmid-4b08871728dc
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1000; i=david@ixit.cz;
 h=from:subject:message-id; bh=fbQDmYKLPvl6sslhUGqA6kC7+83TEDi0PeX9KJSShBo=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBoi9nzXl11gx7oYPrvGzQcQ8kKVM8PnZr6gJMqA
 VEl1iLFoHqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaIvZ8wAKCRBgAj/E00kg
 cibED/9Ib1BhZ+rTZS8HWHGqGuYx1V/SGkJpv71VUqIg5vFMEtSZ9D0YxucCiDP6lm39V4JT7QL
 LfqA0lcuMM2RnPKPue3w1waTDYY/oiAPLOxyJ5+djGKr5ncD8LUEaEmm2yJ/1iWNvD7Ut1eQaSA
 X7s5ub+Qe9lQEjkXSNgcurS7skPNiNzvPUBOJwiwwm4dXrpQ5cOJO8stI11X7JvGbtRu3wmS6Em
 V6gkDj1XO54Tfz4Mwjb2nJzMnfnrj+LZt/2SD9BwG2c4tmiNOBoKuKOnLJJmVKfeOyU6jVPCsfY
 DTJxDl7rJegKRXuwrc39Uu9dnF0Rxs1tkZCVrWzw4prVRH6D4n+w3TlXkheBDkVoxzyuhg5azjt
 vAOPjs0Mk/7xqW7Sv+58gdy8Z5hpD1ncH0R0MMdmACRvNNmXV7w/7c1sjLzFM1pz1K9b+BV0K0O
 bFpsiRRfWuRdXRI70sYvIDjzaKH76mmvr9Bj3MIT29GcwM8AgS46PlA8a2eKw4hBtlMOHrp7kle
 TeRguR+g8zxM05OUWcA/ypYI/fodCUkkiaRmDFmuHz/J/6HOn2gCmpekxFNdYZxpGpeCubMAh1x
 +pMcXKxWi04pfzQo7e/J6wBplGCEjfF1XKRbbsycZe8jfM4+M8l4P17jSuA+T3fjXm2jxCzNG16
 wdT/L9/bXtoR59A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Small cleanup.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (2):
      arm64: dts: qcom: sdm845*: Use definition for msm-id
      arm64: dts: qcom: sdm845-oneplus: Deduplicate shared entries

 arch/arm64/boot/dts/qcom/sdm845-db845c.dts                   | 2 +-
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi          | 3 +++
 arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts        | 2 --
 arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts           | 2 --
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts            | 2 +-
 arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi        | 2 +-
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi | 2 +-
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-polaris.dts           | 2 +-
 8 files changed, 8 insertions(+), 9 deletions(-)
---
base-commit: 84b92a499e7eca54ba1df6f6c6e01766025943f1
change-id: 20250731-sdm845-msmid-4b08871728dc

Best regards,
-- 
David Heidelberg <david@ixit.cz>

