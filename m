From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Subject: [PATCH v2 0/4] arm64: dts: qcom: msm8976-longcheer-l9360: Add
 initial device tree
Date: Sun, 15 Jun 2025 22:35:02 +0200
Message-Id: <20250615-bqx5plus-v2-0-72b45c84237d@apitzsch.eu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAHYuT2gC/0XMQQ6CMBCF4auQWVvTDkKNK+9hWEAZZBID2IEGJ
 b27lcS4/F9evg2EPJPAJdvAU2DhcUiBhwxcXw93UtymBtRY6NKgap5rMT0WUa1FMqYrztY6SPf
 JU8frTt2q1D3LPPrXLgfzXX9I/keCUVph47A95VbburzWE89vcf2RFqhijB9P0WBxogAAAA==
X-Change-ID: 20250612-bqx5plus-d72e11f5877c
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Marijn Suijten <marijn.suijten@somainline.org>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750019747; l=1306;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=SBC2qdWRPcC2wPKUJVvs1+BF12UOwaCCeZuIbZRDQZg=;
 b=OHSlQmNFjvIRKLd4dGtpIC39Fiza3MjyiAjR8nEKqyJxjjXzYoNLnhhxuEosVwmXYi/LozfHd
 1wDqJ3NJr3CD60afO8lKntyR2bmhTs/sgS5PhM5WTaPz8nINmB8XCFu
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
Changes in v2:
- Add Fixes and R-b tag
- Move sdc2 GPIO definitions into msm8976.dtsi (new patch)
- Remove comments from rmi4 nodes
- Don't touch tz-app memory region. Currently, the bigger size seems
  not necessary.
- Link to v1: https://lore.kernel.org/r/20250613-bqx5plus-v1-0-2bc2d43707a6@apitzsch.eu

---
André Apitzsch (4):
      arm64: dts: qcom: msm8976: Make blsp_dma controlled-remotely
      dt-bindings: arm: qcom: Add MSM8976 BQ Aquaris X5 Plus
      arm64: dts: qcom: msm8976: Add sdc2 GPIOs
      arm64: dts: qcom: msm8976-longcheer-l9360: Add initial device tree

 Documentation/devicetree/bindings/arm/qcom.yaml    |   5 +
 arch/arm64/boot/dts/qcom/Makefile                  |   1 +
 .../boot/dts/qcom/msm8976-longcheer-l9360.dts      | 490 +++++++++++++++++++++
 arch/arm64/boot/dts/qcom/msm8976.dtsi              |  38 ++
 4 files changed, 534 insertions(+)
---
base-commit: 0bb71d301869446810a0b13d3da290bd455d7c78
change-id: 20250612-bqx5plus-d72e11f5877c

Best regards,
-- 
André Apitzsch <git@apitzsch.eu>

