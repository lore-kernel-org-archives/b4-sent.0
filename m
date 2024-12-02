From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Subject: [PATCH v3 0/3] arm64: dts: qcom: x1e80100-hp-x14: dt for HP
 Omnibook X Laptop 14
Date: Mon, 02 Dec 2024 20:41:28 +0100
Message-Id: <20241202-hp-omnibook-x14-v3-0-0fcd96483723@oldschoolsolutions.biz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGgNTmcC/3XOwQ6CMAyA4VchOzuzlQHBk+9hPLCxuUWkZMMFJ
 by7g3gwIR7/Jv3amQTtnQ7klM3E6+iCwz5FfsiIsk1/09S1qQkwEJzzktqB4qN3EvFOJy5ozYq
 8No2qeNGStDV4bdy0iZdrauvCiP61HYh8nX4tEDsrcsqoFlCCYVAI05yxa4OyiF3A7jmm38JRu
 jdZ4Qg/WM72GCSsAoBKqlJKI/5iy7J8AN/wCEAIAQAA
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kalle Valo <kvalo@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733168490; l=3638;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=rNGn5lYsz515JXXPpEUswF6PhdUyNi1X5qQjQ2VMzQk=;
 b=q6EiZmR19/dO+ECqSEVIl03r794vd63LL70/3v3eyh3klS1GlTQmYtsF3aRlp8btfXVaopraW
 ZbEUTQrUfX+DTRw2/qQbUouiTnLyigTeSxgTHfPEXZaslydCLYt7ysy
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce device tree for the HP Omnibook X Laptop 14-fe0750ng
(hp-omnibook-x14). It is a Laptop based on the Qualcomm Snapdragon
X Elite SoC. There seem to be other SKUs, some with Wifi-7 (WCN7850)
instead of Wifi-6E (WCN6855). This dt explicitly supports WCN6855,
I haven't found a good way yet to describe both.
    
PDF link: https://www8.hp.com/h20195/V2/GetPDF.aspx/c08989140

Supported features:
    
- Keyboard (no function keys though)
- Display (IPS 2240x1400, 300nits)
- PWM brightness control (works via brightnessctl)
- Touchpad
- Touchscreen
- PCIe ports (pcie4, pcie6a)
- USB type-c, type-a
- WCN6855 Wifi-6E
- WCN6855 Bluetooth
- ADSP and CDSP
- X1 GPU
- GPIO Keys (Lid switch)
- Audio definition (works via USB)
- prepared for DP Altmode

Bringup work has started with the Asus Vivobook S15 as initial template,
worked from there by comparing and copying from the CRD, QCP, 
Yoga Slim 7, Thinkpad T14s. Special thanks to all the people that helped
on #aarch64-laptops [1] with comments and suggestions.
I tested on my laptop, mostly. Since the dt is also in Ubuntu-Concept X1E
[2] there is also test exposure there, with some feedback.

For WiFi to work you need a board file matching the board string [3]. By 
experiment and pure guess I found the already existing calibration for
HP_G8_LANCIA_14 to be quite nice, it gives 866MB/s link speed here. A 
patch proposal [5] has been sent.

For this patchset to work you also need patch [4] in the tree,
otherwise uart14 for BT will be mising.

[1] https://oftc.irclog.whitequark.org/aarch64-laptops
[2] https://discourse.ubuntu.com/t/ubuntu-24-10-concept-snapdragon-x-elite/48800
[3] "bus=pci,vendor=17cb,device=1103,subsystem-vendor=105b,subsystem-device=e108,qmi-chip-id=2,qmi-board-id=255"
[4] https://lore.kernel.org/all/20241007-x1e80100-pwrseq-qcp-v1-0-f7166510ab17@linaro.org/
[5] https://lore.kernel.org/all/f6693075-60ea-4fed-8453-9e124e94203b@oldschoolsolutions.biz/

To: Bjorn Andersson <andersson@kernel.org>
To: Konrad Dybcio <konradybcio@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Kalle Valo <kvalo@kernel.org>
Cc: linux-arm-msm@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>

Changes in v3:
- removed patch for the BOE panel from the set, already merged
  c1bae6802ee9 drm/panel-edp: Add unknown BOE panel for HP Omnibook X14
- added link to the WiFi board file patch
- Link to v2: https://lore.kernel.org/r/20241130-hp-omnibook-x14-v2-0-72227bc6bbf4@oldschoolsolutions.biz

Changes in v2:
- amended usb_mp_dwc3 definition to reference both phys that are used,
  as suggested by Krishna Kurapati
- Link to v1: https://lore.kernel.org/r/20241124-hp-omnibook-x14-v1-0-e4262f0254fa@oldschoolsolutions.biz

---
Jens Glathe (3):
      dt-bindings: arm: qcom: Add HP Omnibook X 14
      firmware: qcom: scm: Allow QSEECOM for HP Omnibook X14
      arm64: dts: qcom: x1e80100-hp-x14: dt for HP Omnibook X Laptop 14

 Documentation/devicetree/bindings/arm/qcom.yaml    |    1 +
 arch/arm64/boot/dts/qcom/Makefile                  |    1 +
 .../boot/dts/qcom/x1e80100-hp-omnibook-x14.dts     | 1693 ++++++++++++++++++++
 drivers/firmware/qcom/qcom_scm.c                   |    1 +
 4 files changed, 1696 insertions(+)
---
base-commit: 02d920be494a5f953319e7589d23a8ba3f00ce05
change-id: 20241116-hp-omnibook-x14-90539fac715d

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

