From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Subject: [PATCH 0/4] arm64: dts: qcom: x1p42100-lenovo-thinkbook-16: dt
 definition for Thinkbook 16
Date: Thu, 15 May 2025 22:38:54 +0200
Message-Id: <20250515-tb16-dt-v1-0-dc5846a25c48@oldschoolsolutions.biz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAN5QJmgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDU0ND3ZIkQzPdlBLdVAuTZBNj4xQL8yRDJaDqgqLUtMwKsEnRsbW1ACk
 vhLtZAAAA
X-Change-ID: 20250511-tb16-dt-e84c433d87b1
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Johan Hovold <johan+linaro@kernel.org>, 
 Aleksandrs Vinarskis <alex.vinarskis@gmail.com>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747341542; l=3438;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=0QBcmZ0wC7RDVtQZp8NKM02wZRMB5QN8hObcMC0OIF8=;
 b=Kqz7IEXkK/WWWXjx2z8vOWnf7jPhaam2wwa6g7OwSuFTNqpDSN9zzZAge9aA9Tb8SEObQqZvk
 FlziGZd5NlcAwTKd7o8LOwUyeWeP1F+AlUWHZqxMS5g4Dwo7Rwc1Pl4
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Device tree for the Lenovo Thinkbook 16 G7 QOY

The Laptop is a Snapdragon X1 / X1 Plus (Purwa) based device [1].

Supported features:

- USB type-c and type-a ports
- Keyboard
- Touchpad (all that are described in the dsdt)
- Touchscreen (described in the dsdt, no known SKUss)
- Display including PWM backlight control
- PCIe devices
- nvme
- SDHC card reader
- ath12k WCN7850 Wifi and Bluetooth
- ADSP and CDSP
- GPIO keys (Lid switch)
- Sound via internal speakers / DMIC / USB / headphone jack
- DP Altmode with 2 lanes (as all of these still do)
- Integrated fingerprint reader (FPC)
- Integrated UVC camera

Not supported yet:

- HDMI port.
- EC and some fn hotkeys.

Limited support yet:

- SDHC card reader is based on the on-chip sdhc_2 controller, but the driver from
the Snapdragon Dev Kit is only a partial match. It can do normal slow sd cards,
but not the faster ones.

- The Purwa SoC has 8 compute cores and a different GPU (X1-45, apparently A730).
The GPU is not yet supported. Graphics is only software rendered.
The SoC has 2 instead of 3 thermal sensor banks. I have disabled all sensors on
the 3rd bank to get rid of dmesg errors. Many of these sensor nodes have a place
on the remaining 2 banks, but I don't know which. So the thermal management is
clearly incomplete, but the firmware monitoring the chip does a power off before
overheating (not experienced yet). For the Thinkbook, it has a pretty decent fan
that can develop some air flow, so maybe this has prevented the emergency cutoff.
As a result of these unknowns, I had to modify x1e80100.dtsi and x1p42100.dtsi to
delete the non-existend nodes.

This work was done without any schematics or non-public knowledge of the device.
So, it is based on the existing x1 device trees, dsdt analysis, using HWInfo
ARM64, and pure guesswork. It has been confirmed, however, that the device really
has 4 NXP PTN3222 eUSB2 repeaters, one of which doesn't have a reset GPIO (eusb5
@43).

I have brought up the Thinkbook over the last 4 months since the x1p42100-crd 
patches were available. The laptop is very usable now, and quite solid as a dev/
test platform. GPU support would be nice, though :) 

Big thanks to Alexandrs Vinarkis for helping (and sort of persisting) on the 
fingerprint, camera and HDMI issues. 

[1]: https://psref.lenovo.com/syspool/Sys/PDF/ThinkBook/ThinkBook_16_G7_QOY/ThinkBook_16_G7_QOY_Spec.pdf

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
Jens Glathe (4):
      dt-bindings: arm: qcom: Add Lenovo Thinkbook 16
      firmware: qcom: scm: Allow QSEECOM on Lenovo Thinkbook 16
      arm64: dts: qcom: x1p42100: add Lenovo ThinkBook 16 G7 QOY
      arm64: dts: qcom: x1p42100-lenovo-thinkbook-16: dt definition for Thinkbook 16

 Documentation/devicetree/bindings/arm/qcom.yaml    |    2 +
 arch/arm64/boot/dts/qcom/Makefile                  |    3 +
 arch/arm64/boot/dts/qcom/x1e80100.dtsi             |   30 +-
 .../boot/dts/qcom/x1p42100-lenovo-thinkbook-16.dts | 1654 ++++++++++++++++++++
 arch/arm64/boot/dts/qcom/x1p42100.dtsi             |   16 +
 drivers/firmware/qcom/qcom_scm.c                   |    1 +
 6 files changed, 1691 insertions(+), 15 deletions(-)
---
base-commit: bdd609656ff5573db9ba1d26496a528bdd297cf2
change-id: 20250511-tb16-dt-e84c433d87b1

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

