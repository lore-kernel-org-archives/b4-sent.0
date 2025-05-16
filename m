From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Subject: [PATCH v2 0/4] arm64: dts: qcom: Add Lenovo ThinkBook 16 device
 tree
Date: Fri, 16 May 2025 08:42:58 +0200
Message-Id: <20250516-tb16-dt-v2-0-7c4996d58ed6@oldschoolsolutions.biz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHPeJmgC/z3OQQ7CIBCF4as0sxYDFCpx1XuYLlpAmaQphkGiN
 r272ESX/8vky6xAPqEnODcrJF+QMC415KEBG8bl5hm62iC51FwLwfIkOuYy80ZZ1bbOnCYB9fq
 e/BWfu3QZagekHNNrh4v4rj9D/40iGGfOaqO6UWqrTB9nRzbEOFOcH7n+QscJ3zBs2/YByc0g4
 asAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747377794; l=3679;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=crk7T9TgJJOj15aeet5D1OzFLT/UJZ/nMDtEOQxcfrA=;
 b=ptIeoewaSB84haEEznVzckiH5nV+u8xHvjEjUowNHk3BfevC4TKgwuVcGtvevUu9TmDZMYXoW
 TDzZIIH78dNDtAzfFYt7ClIFZMx+D6dZ0i1f/VqiXzA/XTEV2SV6RMq
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
Changes in v2:
- removed nodes that gave DTC compile errors (pm8010_thermal, edp0_hpd_active)
- amended qcom.yaml
- shortened the commit titles to fit 75 chars
- Link to v1: https://lore.kernel.org/r/20250515-tb16-dt-v1-0-dc5846a25c48@oldschoolsolutions.biz

---
Jens Glathe (4):
      dt-bindings: arm: qcom: Add Lenovo TB16 support
      firmware: qcom: scm: Allow QSEECOM on Lenovo Thinkbook 16
      arm64: dts: qcom: x1p42100: Add Lenovo ThinkBook 16 G7 QOY
      arm64: dts: qcom: Add Lenovo ThinkBook 16 device tree

 Documentation/devicetree/bindings/arm/qcom.yaml    |    1 +
 arch/arm64/boot/dts/qcom/Makefile                  |    3 +
 arch/arm64/boot/dts/qcom/x1e80100.dtsi             |   30 +-
 .../boot/dts/qcom/x1p42100-lenovo-thinkbook-16.dts | 1649 ++++++++++++++++++++
 arch/arm64/boot/dts/qcom/x1p42100.dtsi             |   16 +
 drivers/firmware/qcom/qcom_scm.c                   |    1 +
 6 files changed, 1685 insertions(+), 15 deletions(-)
---
base-commit: 484803582c77061b470ac64a634f25f89715be3f
change-id: 20250511-tb16-dt-e84c433d87b1

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

