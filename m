From: Cristian Cozzolino <cristian_ci@protonmail.com>
Subject: [PATCH 0/3] Add initial device tree for Billion Capture+
Date: Fri, 20 Jun 2025 23:51:38 +0200
Message-Id: <20250620-rimob-initial-devicetree-v1-0-8e667ea21f82@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOrXVWgC/x3MywqDMBBG4VeRWXcgDSihryJd5DKpP9goEymC5
 N0NXZ7Fdy6qopBKr+EilR8qttLj+RgoLr58hJF6kzV2NJM1rPhugVFwwK+cOolyqAgn7yY/hpy
 jC9T5rpJx/tfzu7UbtZER4WoAAAA=
X-Change-ID: 20250620-rimob-initial-devicetree-da86a5bffc8b
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 phone-devel@vger.kernel.org, 
 Cristian Cozzolino <cristian_ci@protonmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750456316; l=1013;
 i=cristian_ci@protonmail.com; s=20250620; h=from:subject:message-id;
 bh=enGQ4aWwrJ6GnlC2/iNO0rknwLb2cAAwftwuvIy8kpA=;
 b=9txIvSHhHEff/6GqSaMoOwr+L9cgzhapHpcRzFbRMjtpQXNqtHkSJOJecH9NswPb+Y57xrruw
 qSws9wi5tJfCTEzhu8K/JLW0WqiGoQM3klV98Gq1RQFD2gbc5CuloTx
X-Developer-Key: i=cristian_ci@protonmail.com; a=ed25519;
 pk=xH5IvIPUNHV1Q8R0/pq2CfuVFR/wTiAyuyi6IwedjZY=
X-Endpoint-Received: by B4 Relay for cristian_ci@protonmail.com/20250620 with auth_id=438
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Billion Capture+ is a handset using the MSM8953 SoC released in 2017
and sold by Flipkart.

Add a device tree with initial support for:

- GPIO keys
- SDHCI (internal and external storage)
- USB Device Mode
- Regulators
- Simple framebuffer

Signed-off-by: Cristian Cozzolino <cristian_ci@protonmail.com>
---
Cristian Cozzolino (3):
      dt-bindings: vendor-prefixes: Add Flipkart
      dt-bindings: arm: qcom: Add Billion Capture+
      arm64: dts: qcom: msm8953: Add device tree for Billion Capture+

 Documentation/devicetree/bindings/arm/qcom.yaml    |   1 +
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 arch/arm64/boot/dts/qcom/Makefile                  |   1 +
 .../arm64/boot/dts/qcom/msm8953-flipkart-rimob.dts | 251 +++++++++++++++++++++
 4 files changed, 255 insertions(+)
---
base-commit: 0ff41df1cb268fc69e703a08a57ee14ae967d0ca
change-id: 20250620-rimob-initial-devicetree-da86a5bffc8b

Best regards,
-- 
Cristian Cozzolino <cristian_ci@protonmail.com>

