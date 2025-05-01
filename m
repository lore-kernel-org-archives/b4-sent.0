From: George Moussalem <george.moussalem@outlook.com>
Subject: [PATCH 0/2] Add QPIC SPI NAND support for IPQ5018
Date: Thu, 01 May 2025 13:20:50 +0400
Message-Id: <20250501-ipq5018-spi-qpic-snand-v1-0-31e01fbb606f@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPI8E2gC/x2MQQqAIBAAvxJ7bkEtQ/tKdAjdai9mLkQQ/T3pN
 Mxh5gGhwiQwNg8Uulj4SFV020DYl7QRcqwORhmrrNLI+axwKJnxzBxQ0pIi+t4Plpz3puugxrn
 Qyvc/nub3/QClA3oLaAAAAA==
X-Change-ID: 20250501-ipq5018-spi-qpic-snand-94965e899233
To: Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, sadre Alam <quic_mdalam@quicinc.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-spi@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746091263; l=712;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=sSsvDIDiTu5nOi19ywpZdxlp3ipgkMJ6o2Ryy/qOOTo=;
 b=dPiMz7NRt1koz/E3E/avUsHajxPy09iBfUN43fwRdISRwABYDTJr4dqvb1UlWfJAWwqysI8fx
 hK+kUXl/TWWAyNs74JEmoWmcAILR3YMmZKqKBEFJJ6ySjpizF5uXSbS
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the QPIC SPI NAND controller found in IPQ5018 which is 
the same as the one found in IPQ5018.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
George Moussalem (2):
      dt-bindings: spi: spi-qpic-snand: Add IPQ5018 compatible
      arm64: dts: qcom: ipq5018: Add SPI nand support

 .../bindings/spi/qcom,spi-qpic-snand.yaml          |  8 +++--
 arch/arm64/boot/dts/qcom/ipq5018.dtsi              | 38 ++++++++++++++++++++++
 2 files changed, 44 insertions(+), 2 deletions(-)
---
base-commit: 8a2d53ce3c5f82683ad3df9a9a55822816fe64e7
change-id: 20250501-ipq5018-spi-qpic-snand-94965e899233

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

