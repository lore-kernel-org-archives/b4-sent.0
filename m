From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v2 00/12] Enable Qualcomm VBUS block on PMI8998 and PM660
Date: Wed, 18 Nov 2026 18:25:33 +0100
Message-Id: <20261118-pmi8998-vbus-v2-0-3c77a72b280a@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/1WNQQ6CMBBFr0JmbU07gC2svIdhUWCQMRFICw1Ku
 LuAbly+5P33F/DkmDzk0QKOAnvuuw3wFEHV2u5OguuNASVelEQthiebLDMilJMXiNrE2iZ1YyV
 sk8FRw/ORuxVf9lP5oGrcG7vRsh979zr+gtq9XzpW/+mghBRJbWRKqZUN6ivPPJ6rNxTrun4Ad
 ym4LrgAAAA=
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2810; i=david@ixit.cz;
 h=from:subject:message-id; bh=G+aoOXMCv1vOvaJcGLQ/ejfn57oi1myVgmlFlR994S8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq/d+WZrBYerqOCRo5K3vHy14SqZ4dyO8XnD90e
 cqzIB93wsqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCav3flgAKCRBgAj/E00kg
 corCD/4qkSFiE/InAscyogqdEzdsfvAxDPp7cp2kQltHmN3seuhtUFOTHW1fUxPjhsxRhJ2lpta
 a2TM/U8dkZAD8oIa41tTEluDqsggNIBqOEvSYeTR1NBjbYLHat3rV6W6ibd3UnXRmacMap0sWWr
 kcqEvNuJqRLe226Z4qoDV5MwPD1ZYedRA1dG+tTRSs6FuUq6CJJjlq42wGYtby09N95TuJPatvQ
 lO/ueS2p5OcpKRF+Oke6gzfRQ6RGvysB37fGNxMvQBrOUMm83sJEpx7W/pXo+dTSwYXF2bd7xwn
 pMc41kU7Kk1Hyq2SMwZgg+Ba/f7qjgVzLnYNzYuVuyQ7zUPfa2cqazlStYo2r5pODeGGBbx1fVf
 MzNWBgUxYDtX7ICHXZLD8iLJl1QdMFK8t/Gbiu4Vc3MXOAW0OV/U5aoBfvHs1bPpHNexduaYELZ
 pT8i95PkGeILkhFYemceUs16iswlgW9iFiDMh86TW6WF7A69jamzuDpE+tOcHUm9ZDZ2bOGNwID
 v8Onm9hXgy76MuX+wAtCHSAbgKB13wHAhTTEMIl3SPuYVNWhEk2Ig3F1pEDdtwo05LPKnrmU1n6
 CQxFdr2D/nN5bopswUeBTrBEHbo/XHMldk4nMNP83nEtPQA8NsYZobIIltnlsbBiQqmNWj/ExK5
 hASOvFvPpyHgRRw==
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
Changes in v2:
- pmi8998 and pm660 belongs into the different generation than pm8150b.
  Adjust the device-tree, code, and commit msg accordingly. (Konrad)
- Link to v1: https://patch.msgid.link/20261031-pmi8998-vbus-v1-0-4d805e5a0f27@ixit.cz

---
David Heidelberg (12):
      regulator: qcom_usb_vbus: Fix the MODULE_LICENSE() string
      regulator: qcom_usb_vbus: Add support for pmi8998
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

 .../bindings/regulator/qcom,usb-vbus-regulator.yaml        |  5 +++++
 arch/arm64/boot/dts/qcom/pm660.dtsi                        |  7 +++++++
 arch/arm64/boot/dts/qcom/pmi8998.dtsi                      |  7 +++++++
 arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi         |  7 +++++++
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi         |  7 +++++++
 arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi             |  7 +++++++
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi        |  7 +++++++
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts          |  7 +++++++
 .../boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi      |  8 +++++++-
 drivers/power/supply/qcom_smbx.c                           | 14 --------------
 drivers/regulator/qcom_usb_vbus-regulator.c                | 14 +++++++++++++-
 11 files changed, 74 insertions(+), 16 deletions(-)
---
base-commit: aaa2f954c21b205a0bcd0961e5b2be4e82e58455
change-id: 20261027-pmi8998-vbus-227837a4dfa0

Best regards,
--  
David Heidelberg <david@ixit.cz>

