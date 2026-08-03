From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH 00/28] arm64: dts: qcom: Fix swapped QMP PHY
 vdda-phy/vdda-pll supplies
Date: Mon, 03 Aug 2026 08:33:58 +0200
Message-Id: <20260803-phy-supply-fix-v1-0-5880630cde3e@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAFY2cGoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDc2ND3YKMSt3i0oKCnErdtMwKXRNTsyRDC0vDJDNzIyWgpoKiVKAw2MD
 oWAi/uDQpKzW5BGSKUm0tAKsWXOZyAAAA
X-Change-ID: 20260731-phy-supply-fix-456b1891b672
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Krzysztof Kozlowski <krzk@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=9943;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=Qj0IeKtdQPuP/QWN5WPVEyMWcztiU3lYzYh4ko/E7rY=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqcDZgzbHr+U9GPiNUjsRpJ8K/ibNY0poMPp0L4
 Oxv4cMr4jqJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCanA2YAAKCRBVnxHm/pHO
 9XxyCACh7qSQXBODjBcXQbHGwtqgY2tV1kjHVF0lOXU6FzoI+0lUdrVbpaJwyVwSCJy/6Kj4Lu6
 WtvE+SuPw223QL5IyJ5dOc1b40B05EXJi9nYaHFs4wc1nIHkO0zFWvFdSiuXm6pqZ9CNZD/tVJm
 urBTe4LC8b4/OpTnR0BdfogydgBaFbFZJYp3QOrB2gWnQZo1ZOEbdPVYOjp60ms+r2QQnXrv+O3
 zhXDu9/5vLAOjOLI57ie/YxsvHwzLD/QffR98T46YtZyq/lxdQCZSzAi+CDjYxdkwhPQ98IwRtN
 XXwEv6+hnQpPfRCXOpgzHs3g2AQAP/xJSFo45H7EefAu/o4k
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The QMP PHY takes two analog supplies, vdda-phy and vdda-pll. By the
hardware design, vdda-phy is the lower voltage rail (~0.8V) and vdda-pll
is the higher voltage rail (~1.2V). This holds for every QMP PHY flavour
(PCIe, UFS, DisplayPort and USB) on a given SoC.

A large number of Qualcomm ARM64 boards have these two supplies swapped
for their USB QMP PHYs, feeding the ~1.2V rail to vdda-phy and the ~0.8V
rail to vdda-pll. One board, sa8155p-adp, has the same swap on its UFS
QMP PHY as well. The PCIe and DisplayPort QMP PHYs on the same SoCs are
wired correctly, which confirms the intended assignment. The PHYs happen
to work with the supplies swapped as there was no ordering requirement and
both supplies get enabled anyway. So this was never noticed and got copied
from board to board.

Fix all of the affected boards, one patch per SoC so that each can be
reviewed and backported independently, at the same time reducing the number
of commits. Only the USB and UFS QMP PHY nodes are touched and the PCIe and
DisplayPort PHYs are left untouched.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Manivannan Sadhasivam (28):
      dt-bindings: phy: qcom: Describe QMP USB and UFS PHY vdda-phy/vdda-pll voltages
      arm64: dts: qcom: sc8280xp-blackrock: Fix swapped USB QMP PHY vdda-phy/vdda-pll supplies
      arm64: dts: qcom: sa8540p: Fix swapped USB QMP PHY vdda-phy/vdda-pll supplies
      arm64: dts: qcom: sdm845: Fix swapped USB QMP PHY vdda-phy/vdda-pll supplies
      arm64: dts: qcom: sdm850: Fix swapped USB QMP PHY vdda-phy/vdda-pll supplies
      arm64: dts: qcom: sm8150: Fix swapped USB QMP PHY vdda-phy/vdda-pll supplies
      arm64: dts: qcom: sm8250: Fix swapped USB QMP PHY vdda-phy/vdda-pll supplies
      arm64: dts: qcom: sm8350: Fix swapped USB QMP PHY vdda-phy/vdda-pll supplies
      arm64: dts: qcom: sm8450: Fix swapped USB QMP PHY vdda-phy/vdda-pll supplies
      arm64: dts: qcom: sm8550: Fix swapped USB QMP PHY vdda-phy/vdda-pll supplies
      arm64: dts: qcom: qcs8550-aim300: Fix swapped USB QMP PHY vdda-phy/vdda-pll supplies
      arm64: dts: qcom: qcm6490: Fix swapped USB QMP PHY vdda-phy/vdda-pll supplies
      arm64: dts: qcom: qcs6490: Fix swapped USB QMP PHY vdda-phy/vdda-pll supplies
      arm64: dts: qcom: sm7225-fairphone-fp4: Fix swapped USB QMP PHY vdda-phy/vdda-pll supplies
      arm64: dts: qcom: sc7180: Fix swapped USB QMP PHY vdda-phy/vdda-pll supplies
      arm64: dts: qcom: sc7280: Fix swapped USB QMP PHY vdda-phy/vdda-pll supplies
      arm64: dts: qcom: sc8180x: Fix swapped USB QMP PHY vdda-phy/vdda-pll supplies
      arm64: dts: qcom: hamoa: Fix swapped USB QMP PHY vdda-phy/vdda-pll supplies
      arm64: dts: qcom: purwa: Fix swapped USB QMP PHY vdda-phy/vdda-pll supplies
      arm64: dts: qcom: sm8650: Fix swapped USB QMP PHY vdda-phy/vdda-pll supplies
      arm64: dts: qcom: sm8750: Fix swapped USB QMP PHY vdda-phy/vdda-pll supplies
      arm64: dts: qcom: sar2130p: Fix swapped USB QMP PHY vdda-phy/vdda-pll supplies
      arm64: dts: qcom: kaanapali: Fix swapped USB QMP PHY vdda-phy/vdda-pll supplies
      arm64: dts: qcom: glymur: Fix swapped USB QMP PHY vdda-phy/vdda-pll supplies
      arm64: dts: qcom: lemans: Fix swapped USB QMP PHY vdda-phy/vdda-pll supplies
      arm64: dts: qcom: eliza-mtp: Fix swapped USB QMP PHY vdda-phy/vdda-pll supplies
      arm64: dts: qcom: sa8155p-adp: Fix swapped USB and UFS QMP PHY vdda-phy/vdda-pll supplies
      arm64: dts: qcom: talos-evk: Fix swapped USB QMP PHY vdda-phy/vdda-pll supplies

 .../bindings/phy/qcom,msm8998-qmp-usb3-phy.yaml      | 10 ++++++++--
 .../bindings/phy/qcom,qcs615-qmp-usb3dp-phy.yaml     | 10 ++++++++--
 .../bindings/phy/qcom,sc8280xp-qmp-ufs-phy.yaml      | 12 +++++++++---
 .../bindings/phy/qcom,sc8280xp-qmp-usb3-uni-phy.yaml | 12 +++++++++---
 .../bindings/phy/qcom,sc8280xp-qmp-usb43dp-phy.yaml  | 10 ++++++++--
 arch/arm64/boot/dts/qcom/eliza-mtp.dts               |  4 ++--
 arch/arm64/boot/dts/qcom/glymur-crd.dts              | 16 ++++++++--------
 arch/arm64/boot/dts/qcom/hamoa-iot-som.dtsi          | 20 ++++++++++----------
 .../qcom/hamoa-lenovo-ideacentre-mini-01q8x10.dts    | 20 ++++++++++----------
 arch/arm64/boot/dts/qcom/kaanapali-mtp.dts           |  4 ++--
 arch/arm64/boot/dts/qcom/kaanapali-qrd.dts           |  4 ++--
 arch/arm64/boot/dts/qcom/lemans-evk.dts              |  4 ++--
 arch/arm64/boot/dts/qcom/lemans-ride-common.dtsi     |  8 ++++----
 arch/arm64/boot/dts/qcom/purwa-iot-som.dtsi          | 20 ++++++++++----------
 arch/arm64/boot/dts/qcom/qcm6490-fairphone-fp5.dts   |  4 ++--
 arch/arm64/boot/dts/qcom/qcm6490-idp.dts             |  4 ++--
 .../arm64/boot/dts/qcom/qcm6490-particle-tachyon.dts |  4 ++--
 arch/arm64/boot/dts/qcom/qcm6490-shift-otter.dts     |  4 ++--
 arch/arm64/boot/dts/qcom/qcs6490-rb3gen2.dts         |  4 ++--
 .../dts/qcom/qcs6490-thundercomm-minipc-g1iot.dts    |  4 ++--
 .../boot/dts/qcom/qcs6490-thundercomm-rubikpi3.dts   |  4 ++--
 arch/arm64/boot/dts/qcom/qcs8550-aim300.dtsi         |  4 ++--
 arch/arm64/boot/dts/qcom/qrb5165-rb5.dts             |  8 ++++----
 arch/arm64/boot/dts/qcom/sa8155p-adp.dts             |  8 ++++----
 arch/arm64/boot/dts/qcom/sa8295p-adp.dts             | 16 ++++++++--------
 arch/arm64/boot/dts/qcom/sa8540p-ride.dts            |  8 ++++----
 arch/arm64/boot/dts/qcom/sar2130p-qar2130p.dts       |  4 ++--
 arch/arm64/boot/dts/qcom/sc7180-acer-aspire1.dts     |  4 ++--
 arch/arm64/boot/dts/qcom/sc7180-ecs-liva-qc710.dts   |  4 ++--
 arch/arm64/boot/dts/qcom/sc7180-idp.dts              |  4 ++--
 arch/arm64/boot/dts/qcom/sc7180-trogdor.dtsi         |  4 ++--
 arch/arm64/boot/dts/qcom/sc7280-idp.dtsi             |  4 ++--
 arch/arm64/boot/dts/qcom/sc7280-qcard.dtsi           |  4 ++--
 arch/arm64/boot/dts/qcom/sc8180x-lenovo-flex-5g.dts  | 16 ++++++++--------
 arch/arm64/boot/dts/qcom/sc8180x-primus.dts          | 16 ++++++++--------
 .../boot/dts/qcom/sc8280xp-microsoft-blackrock.dts   |  8 ++++----
 arch/arm64/boot/dts/qcom/sdm845-db845c.dts           |  8 ++++----
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi   |  4 ++--
 arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi       |  4 ++--
 arch/arm64/boot/dts/qcom/sdm845-mtp.dts              |  8 ++++----
 .../boot/dts/qcom/sdm845-samsung-starqltechn.dts     |  4 ++--
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts    |  4 ++--
 .../dts/qcom/sdm845-xiaomi-beryllium-common.dtsi     |  4 ++--
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-polaris.dts   |  4 ++--
 .../boot/dts/qcom/sdm850-huawei-matebook-e-2019.dts  |  8 ++++----
 arch/arm64/boot/dts/qcom/sdm850-lenovo-yoga-c630.dts |  8 ++++----
 arch/arm64/boot/dts/qcom/sdm850-samsung-w737.dts     |  8 ++++----
 arch/arm64/boot/dts/qcom/sm7225-fairphone-fp4.dts    |  4 ++--
 arch/arm64/boot/dts/qcom/sm8150-hdk.dts              |  8 ++++----
 .../boot/dts/qcom/sm8150-microsoft-surface-duo.dts   |  4 ++--
 arch/arm64/boot/dts/qcom/sm8150-mtp.dts              |  4 ++--
 .../boot/dts/qcom/sm8150-sony-xperia-kumano.dtsi     |  4 ++--
 arch/arm64/boot/dts/qcom/sm8250-hdk.dts              |  8 ++++----
 arch/arm64/boot/dts/qcom/sm8250-mtp.dts              |  8 ++++----
 arch/arm64/boot/dts/qcom/sm8250-sony-xperia-edo.dtsi |  4 ++--
 arch/arm64/boot/dts/qcom/sm8250-xiaomi-pipa.dts      |  4 ++--
 arch/arm64/boot/dts/qcom/sm8350-hdk.dts              |  8 ++++----
 .../boot/dts/qcom/sm8350-microsoft-surface-duo2.dts  |  8 ++++----
 arch/arm64/boot/dts/qcom/sm8350-mtp.dts              |  8 ++++----
 .../boot/dts/qcom/sm8350-sony-xperia-sagami.dtsi     |  4 ++--
 arch/arm64/boot/dts/qcom/sm8450-hdk.dts              |  4 ++--
 arch/arm64/boot/dts/qcom/sm8450-qrd.dts              |  4 ++--
 .../boot/dts/qcom/sm8450-sony-xperia-nagara.dtsi     |  4 ++--
 arch/arm64/boot/dts/qcom/sm8550-hdk.dts              |  4 ++--
 arch/arm64/boot/dts/qcom/sm8550-mtp.dts              |  4 ++--
 arch/arm64/boot/dts/qcom/sm8550-qrd.dts              |  4 ++--
 .../boot/dts/qcom/sm8550-sony-xperia-yodo-pdx234.dts |  4 ++--
 arch/arm64/boot/dts/qcom/sm8650-ayaneo-pocket-s2.dts |  4 ++--
 arch/arm64/boot/dts/qcom/sm8650-hdk.dts              |  4 ++--
 arch/arm64/boot/dts/qcom/sm8650-mtp.dts              |  4 ++--
 arch/arm64/boot/dts/qcom/sm8650-qrd.dts              |  4 ++--
 arch/arm64/boot/dts/qcom/sm8750-mtp.dts              |  4 ++--
 arch/arm64/boot/dts/qcom/sm8750-qrd.dts              |  4 ++--
 arch/arm64/boot/dts/qcom/talos-evk-som.dtsi          |  4 ++--
 arch/arm64/boot/dts/qcom/x1-asus-vivobook-s15.dtsi   | 20 ++++++++++----------
 arch/arm64/boot/dts/qcom/x1-asus-zenbook-a14.dtsi    | 20 ++++++++++----------
 arch/arm64/boot/dts/qcom/x1-crd.dtsi                 | 20 ++++++++++----------
 arch/arm64/boot/dts/qcom/x1-dell-thena.dtsi          | 16 ++++++++--------
 arch/arm64/boot/dts/qcom/x1-hp-omnibook-x14.dtsi     | 12 ++++++------
 arch/arm64/boot/dts/qcom/x1-microsoft-denali.dtsi    |  8 ++++----
 arch/arm64/boot/dts/qcom/x1e001de-devkit.dts         | 20 ++++++++++----------
 .../boot/dts/qcom/x1e78100-lenovo-thinkpad-t14s.dtsi | 20 ++++++++++----------
 .../arm64/boot/dts/qcom/x1e80100-dell-xps13-9345.dts | 16 ++++++++--------
 .../boot/dts/qcom/x1e80100-lenovo-yoga-slim7x.dts    | 12 ++++++------
 .../boot/dts/qcom/x1e80100-medion-sprchrgd-14-s1.dts | 16 ++++++++--------
 .../boot/dts/qcom/x1e80100-microsoft-romulus.dtsi    | 16 ++++++++--------
 arch/arm64/boot/dts/qcom/x1e80100-qcp.dts            | 20 ++++++++++----------
 .../boot/dts/qcom/x1p42100-lenovo-thinkbook-16.dts   | 20 ++++++++++----------
 88 files changed, 378 insertions(+), 348 deletions(-)
---
base-commit: dc59e4fea9d83f03bad6bddf3fa2e52491777482
change-id: 20260731-phy-supply-fix-456b1891b672

Best regards,
--  
மணிவண்ணன் சதாசிவம்

