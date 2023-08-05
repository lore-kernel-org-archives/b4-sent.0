From: Xilin Wu <wuxilin123@gmail.com>
Subject: [PATCH 0/3] Add initial support for Xiaomi Mi 11 Ultra
Date: Sun, 06 Aug 2023 01:03:09 +0800
Message-Id: <20230806-xiaomi-star-v1-0-0c384e8b5737@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAM2AzmQC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI2MDCwMz3YrMxPzcTN3iksQi3VRT4xQLs0TjJFPLVCWgjoKi1LTMCrBp0bG
 1tQDLOwb7XQAAAA==
To: Andy Gross <agross@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <keescook@chromium.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-hardening@vger.kernel.org, 
 Xilin Wu <wuxilin123@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1691254992; l=698;
 i=wuxilin123@gmail.com; s=20230805; h=from:subject:message-id;
 bh=h5eU9XX1o4OOf6S1Raai5CwCugmHSOAJ95Q+DWakPuw=;
 b=OQntiV/U7W7Rd3Y6oKVtP7h9tiC8jZyOIZJXVbI7q66nLcgekYC8dPLbkpz3+elHdgC+e5Emt
 e05ygSe7qp7B1fzegauog7IlNEUxEgdJd564vM4/+wSoYzNbAfBcMbO
X-Developer-Key: i=wuxilin123@gmail.com; a=ed25519;
 pk=OZIrHT2qWm7yEdp5fsVR7GsFx1wxciIii20H06Ud088=
X-Endpoint-Received: by B4 Relay for wuxilin123@gmail.com/20230805 with auth_id=73
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Xilin Wu <wuxilin123@gmail.com>
---
Xilin Wu (3):
      soc: qcom: pmic_glink: enable UCSI for SM8350
      dt-bindings: arm: qcom: Add Xiaomi Mi 11 Ultra
      arm64: dts: qcom: Add device tree for Xiaomi Mi 11 Ultra

 Documentation/devicetree/bindings/arm/qcom.yaml |    1 +
 arch/arm64/boot/dts/qcom/Makefile               |    1 +
 arch/arm64/boot/dts/qcom/sm8350-xiaomi-star.dts | 1251 +++++++++++++++++++++++
 drivers/soc/qcom/pmic_glink.c                   |    1 +
 4 files changed, 1254 insertions(+)
---
base-commit: d2aae0f5a3d5af50b13b13cb452745cd0428ce5e
change-id: 20230806-xiaomi-star-e53d86a3b59e

Best regards,
-- 
Xilin Wu <wuxilin123@gmail.com>

