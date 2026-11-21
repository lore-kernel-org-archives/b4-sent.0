From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v3 00/12] Enable Qualcomm VBUS block on PMI8998 and PM660
Date: Sat, 21 Nov 2026 23:37:54 +0100
Message-Id: <20261121-pmi8998-vbus-v3-0-91ba2e61a877@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/12N0Q6CIBhGX8VxHQ1+NLCr3qN1gYj5t5UOlFnOd
 w+szdXl2b5zvpl469B6csxm4mxAj90jgthlxLT6cbUU68gEGBw4A0n7O6qyVDRUo6cAUgmp87r
 RjESld7bBac2dLx/2Y3WzZkiNtGjRD517rn+Bp903LfhvOnDKaF4rVthCswbkCScc9uZFUjjAp
 nKu/lSIqjBSagkVKKY3dVmWN4OigPnzAAAA
X-Change-ID: 20261027-pmi8998-vbus-227837a4dfa0
To: Abel Vesa <abelvesa@kernel.org>, 
 Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Markus Rathgeb <maggu2810@mailbox.org>, Rob Herring <robh@kernel.org>, 
 Robin Snyders <robin@snyders.xyz>, Sebastian Reichel <sre@kernel.org>, 
 Wesley Cheng <quic_wcheng@quicinc.com>
Cc: Richard Acayan <mailingradian@gmail.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 devicetree@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2961; i=david@ixit.cz;
 h=from:subject:message-id; bh=OImt/nLXL2kIokFM/oPd0DirAEB3/8IPasOrbeEvB2A=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrAh1avifTQxrbPQJE0RvoKnBjQHFeuWxjodvzK
 ZaftvItqoOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawIdWgAKCRBgAj/E00kg
 ciUWEADBJs6O+Q+0LfJhX5AAna/uYamcaAMETjP4OSon5T7LaCQ8nfVwsxINcgfoX22O7Cfc1Sz
 9FKRsgSHjsvp3raIeXLxKsQm0wpdEIvex3wwPbEq/GLIxZAJGyirBW4LkfnBBDCdM41K1SCzVcO
 qK4kZuweel5akob4FaY5tieSe1CPSuzU4L7zh0+px+gCvzCyGHEEfpoqVDrhjUURGcCBz/P2D5o
 l4V1WKS1nojNhIFqkhIPP0Bkbf7omcLICG4R3BYgMoC8QKP6a2hfxdN/PDj28dagGhPN3pBs46x
 14kaed+zpU4UyNvCGEqhFGvEpUnkfgd80/+tfyHN9ny/wi2LILQ/MPooPdcIsmdTlbQvAkFSWcS
 8mzRpQp06iKzIPJirElr9nU61atSgUF5KjK0xYBEoFYsv7pnii5+Mr3GoIZq2UZwznsMPN2mMnv
 +srt4CrgDKjrC3wqrcbGaCzXIyty54o+93oCwPCKCC16BpVXqCC9GyF+zXMeR+E7VGG1KotmU8m
 ao76bmyb/TwXbXCb6Ha5WwB9E66mYxxIHL06OyGiI0JDvQzwF03QnnrbzKwgOHO1Y/of+e6snBU
 r1hT7Srpa7cGsRMhm9EQbbBt+fM/XSGJoPDRmdMBTnWisWOpxqztfXQ3nHWwEMi1oAc+yT+hZfF
 fllyl2cswRiuj1Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Includes basic vbus regulator support for:
 - SHIFT 6MQ
 - Pixel 3 / 3a / 3 XL / 3a XL
 - OnePlus 6 / 6T
 - Xiaomi Poco F1
 - LG G7 / V35

All devices we support using default range 0.5 - 1.5 A in downstream
sources.

Validated by looking for `qcom,otg-cl-ua` and default values when
property is not set in the driver.

This series shouldn't change existing behaviour (except register write
execution order). Without Type-C driver this merely replace the write of
the SMB charger to manually control the OTG block.

As a follow-up with the latest upstreamed Type-C driver, this change
will allow setting USB OTG, thus power devices connected to the phone.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v3:
- Limit OTG current from 3A / 500mA step to the 2A / 250mA step. (Markus)
- s/pm8998/pmi8998/ typo. (Sashiko)
- Reworded commit messages.
- Link to v2: https://patch.msgid.link/20261118-pmi8998-vbus-v2-0-3c77a72b280a@ixit.cz

Changes in v2:
- pmi8998 and pm660 belongs into the different generation than pm8150b.
  Adjust the device-tree, code, and commit msg accordingly. (Konrad)
- Link to v1: https://patch.msgid.link/20261031-pmi8998-vbus-v1-0-4d805e5a0f27@ixit.cz

---
David Heidelberg (12):
      regulator: dt-bindings: qcom,usb-vbus-regulator: Add pmi8998 and pm660
      regulator: qcom_usb_vbus: Fix the MODULE_LICENSE() string
      regulator: qcom_usb_vbus: Add support for pmi8998
      power: supply: qcom_smbx: Stop clearing software control select
      arm64: dts: qcom: pmi8998: Add node for PMIC VBUS booster
      arm64: dts: qcom: pm660: Add node for PMIC VBUS booster
      arm64: dts: qcom: sdm845-google: Enable vbus support
      arm64: dts: qcom: sdm845-oneplus: Enable vbus support
      arm64: dts: qcom: sdm845-shift-axolotl: Enable vbus support
      arm64: dts: qcom: sdm845-lg: Enable vbus support
      arm64: dts: qcom: sdm845-xiaomi-beryllium: Enable vbus support
      arm64: dts: qcom: sdm670-google: Enable vbus support

 .../regulator/qcom,usb-vbus-regulator.yaml         | 56 ++++++++++++++++++++--
 arch/arm64/boot/dts/qcom/pm660.dtsi                |  7 +++
 arch/arm64/boot/dts/qcom/pmi8998.dtsi              |  7 +++
 arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi |  7 +++
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi |  7 +++
 arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi     |  7 +++
 .../arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi |  7 +++
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts  |  7 +++
 .../dts/qcom/sdm845-xiaomi-beryllium-common.dtsi   |  7 +++
 drivers/power/supply/qcom_smbx.c                   | 14 ------
 drivers/regulator/qcom_usb_vbus-regulator.c        | 24 ++++++++--
 11 files changed, 128 insertions(+), 22 deletions(-)
---
base-commit: 909ef7a9a30fa139e69e555e3606680f5cca7726
change-id: 20261027-pmi8998-vbus-227837a4dfa0

Best regards,
--  
David Heidelberg <david@ixit.cz>

