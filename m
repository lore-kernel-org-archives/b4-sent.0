From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 00/11] Enable Qualcomm VBUS block on PMI8998 and PM660
Date: Sat, 31 Oct 2026 16:04:57 +0100
Message-Id: <20261031-pmi8998-vbus-v1-0-4d805e5a0f27@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAyNz3YLcTAtLSwvdsqTSYl0jI3MLY/NEk5S0RAMloJaCotS0zAqwcdG
 xEH5xaVJWanIJyAyl2loAC6LVK3AAAAA=
X-Change-ID: 20261027-pmi8998-vbus-227837a4dfa0
To: Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Robin Snyders <robin@snyders.xyz>, Liam Girdwood <lgirdwood@gmail.com>, 
 Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Wesley Cheng <quic_wcheng@quicinc.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Sebastian Reichel <sre@kernel.org>
Cc: Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 linux-pm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2484; i=david@ixit.cz;
 h=from:subject:message-id; bh=QQTUMzJbcnskHluf3ZL3QNJlfDwcPnf44W0frCsxGxM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq5gOuRG6OIDtxI8rAcGvhRdIxcCWngaL+/WZFI
 CdLu+FYCNuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCauYDrgAKCRBgAj/E00kg
 crk9D/90HtW5E6+cyVh6rw4Iek3eaVQP76zsks5ArdVIuVL3D6DB6lLWVkCG8d1gr0V2iKCphOq
 RfI8MH4K0Fv+cWgWQU/lhd5LqOLZy7N5Od+p+U2jHVA9Hj3cQ8XuxXsNNX9G5MImU9vcsSMkd1F
 ELM36G2WmADaj8+wbq/gJuTd3rU4IuPcqhw9zdT302Otu+Wz2T/RU1xGfCExnYevLCvmwm6HaJ2
 ZUsBz2743Xrf0/V6VNE2rizwHx0SxBOXgjK7IQbPxIMpFiPpJcQs1eVgkboMLms5UOYEv8+1S6p
 izULFYgLKdOMA+3+0KqLEqDFNWED9ZxNArKoJSccse/XMzTC4hNLciJXo6kCVFlOLQC2BN4UMTr
 uzYDNvz1D8w5PA9vJ7SbS0ywg45ME4jydPx1k5HBW3TxxnXjavNUYIzOYU9BNoauuuk5rb8pben
 C5u6CLFyoFOECUoqr7J1r7NWpaYghd556nZytkPhbMs1cx+SufIPbghTcRSIgR2GfwrnPB4B/qv
 a8pwy7de+4HvF/O00XD14M4u0UB5O85Yeki2XfNSwbTWjvJZL+WKkuabs3t5IMg1bRGfR7aakn8
 rg/H5wQJzJ1VIi9tVDNwZrkavd8c8cjtS4wfB6h8dXn1DFyF93TkSHrNcZfuciWpNUsmoH+VPvU
 gNloHtrPXsb7DRw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Includes basic vbus regulator support for:
 - SHIFT 6MQ
 - Pixel 3 / 3a / 3 XL / 3a XL
 - OnePlus 6 / 6T
 - Xiaomi Poco F1
 - LG G7 / V40

All devices downstream sources using default range 0.5 - 1.5 A.

Validated by looking for `qcom,otg-cl-ua` and default values when
property is not set in the driver.

This series shouldn't change existing behaviour (except register write
execution order). Without Type-C driver this merely replace the write of
the SMB charger to manually control the OTG block.

As a follow-up with the latest upstreamed Type-C driver, this change
will allow setting USB OTG, thus power devices connected to the phone.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (11):
      regulator: qcom_usb_vbus: Fix the MODULE_LICENSE() string
      power: supply: qcom_smbx: Do not interfere with vbus driver
      dt-bindings: regulator: qcom,usb-vbus-regulator: Add pmi8998 and pm660
      arm64: dts: qcom: pmi8998: Add node for PMIC VBUS booster
      arm64: dts: qcom: pm660: Add node for PMIC VBUS booster
      arm64: dts: qcom: sdm845-google: Enable vbus support
      arm64: dts: qcom: sdm845-oneplus: Enable vbus support
      arm64: dts: qcom: sdm845-shift-axolotl: Enable vbus support
      arm64: dts: qcom: sdm845-lg: Enable vbus support
      arm64: dts: qcom: sdm845-xiaomi-beryllium: Enable vbus support
      arm64: dts: qcom: sdm670-google: Enable vbus support

 .../bindings/regulator/qcom,usb-vbus-regulator.yaml        |  2 ++
 arch/arm64/boot/dts/qcom/pm660.dtsi                        |  7 +++++++
 arch/arm64/boot/dts/qcom/pmi8998.dtsi                      |  7 +++++++
 arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi         |  7 +++++++
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi         |  7 +++++++
 arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi             |  7 +++++++
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi        |  7 +++++++
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts          |  7 +++++++
 .../boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi      |  8 +++++++-
 drivers/power/supply/qcom_smbx.c                           | 14 --------------
 drivers/regulator/qcom_usb_vbus-regulator.c                |  2 +-
 11 files changed, 59 insertions(+), 16 deletions(-)
---
base-commit: 151a134a4e6ec66f69db8750c66006f5207f7a9d
change-id: 20261027-pmi8998-vbus-227837a4dfa0

Best regards,
--  
David Heidelberg <david@ixit.cz>

