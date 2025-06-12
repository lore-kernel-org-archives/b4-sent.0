From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Subject: [PATCH 0/3] arm64: dts: qcom: msm8976-longcheer-l9360: Add initial
 device tree
Date: Fri, 13 Jun 2025 00:37:17 +0200
Message-Id: <20250613-bqx5plus-v1-0-2bc2d43707a6@apitzsch.eu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAJ1WS2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDM0Mj3aTCCtOCnNJi3RRzo1RDwzRTC3PzZCWg8oKi1LTMCrBR0bG1tQB
 7QwS5WgAAAA==
X-Change-ID: 20250612-bqx5plus-d72e11f5877c
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749767846; l=936;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=GQ+Xtv/R4Cazn0jTLW14AKKOtVPMuLFroC6FY7/Wwwc=;
 b=BtpIaq4MHJ8rHJvyS2zi/RJdzpn0Y5hUwKIBUabE0oANdzbtLtlnAFfyhN8FV0nA/zsmrtwIJ
 mFDzJBdJFIMAItGto0WhQsmWZW+wMJfVb/cUtTWU1Eqz/JYjUrcoT6l
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This dts adds support for BQ Aquaris X5 Plus (Longcheer L9360) released
in 2016.

Add a device tree with initial support for:

- GPIO keys
- NFC
- SDHCI
- Status LED
- Touchscreen

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
André Apitzsch (3):
      arm64: dts: qcom: msm8976: Make blsp_dma controlled-remotely
      dt-bindings: arm: qcom: Add MSM8976 BQ Aquaris X5 Plus
      arm64: dts: qcom: msm8976-longcheer-l9360: Add initial device tree

 Documentation/devicetree/bindings/arm/qcom.yaml    |   5 +
 arch/arm64/boot/dts/qcom/Makefile                  |   1 +
 .../boot/dts/qcom/msm8976-longcheer-l9360.dts      | 532 +++++++++++++++++++++
 arch/arm64/boot/dts/qcom/msm8976.dtsi              |   2 +
 4 files changed, 540 insertions(+)
---
base-commit: 0bb71d301869446810a0b13d3da290bd455d7c78
change-id: 20250612-bqx5plus-d72e11f5877c

Best regards,
-- 
André Apitzsch <git@apitzsch.eu>

