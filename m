From: Alexandre MINETTE <contact@alex-min.fr>
Subject: [PATCH 0/8] Add Samsung Galaxy S4 support
Date: Tue, 21 Apr 2026 11:45:06 +0200
Message-Id: <20260421-mainline-send-v1-sending-v1-0-bcb0857724de@alex-min.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACJH52kC/x2MwQqAIBAFfyX23EJKhPUr0SH0ZQu1hUIE0b8nn
 YY5zDyUkQSZhuqhhEuyHFrE1BX5ddYIllCcbGO7prWG91l0EwVnaODL/BSNbF0P3zt0wRsq+Zm
 wyP2vx+l9P3sOLCFqAAAA
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, MyungJoo Ham <myungjoo.ham@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, 
 Guru Das Srinagesh <linux@gurudas.dev>, Linus Walleij <linusw@kernel.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Kees Cook <kees@kernel.org>, Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-gpio@vger.kernel.org, 
 iommu@lists.linux.dev, Alexandre MINETTE <contact@alex-min.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776764711; l=1782;
 i=contact@alex-min.fr; s=20260421; h=from:subject:message-id;
 bh=CHhHEb5sgQt9z+DgNHdyFkJRxxQ8BX3aIo7SXeKph/w=;
 b=iLRPlGSXT3LnuC/vB7tE1btiUBFHxZZnZ+LvfrLycTACCo+OS6a2vvYLdkKQsuG9cOyMxs5+b
 F6NC3gyqJaLCMRltTFLGAw+y/MvfM6X1fnMaIY3YEcAFP7MejT00bI2
X-Developer-Key: i=contact@alex-min.fr; a=ed25519;
 pk=KOCaxY4v16ptaT0uk1FRkuaDF2n1JhmnYwLiqWD76M4=
X-Endpoint-Received: by B4 Relay for contact@alex-min.fr/20260421 with auth_id=743
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add initial mainline support for the Samsung Galaxy S4, codenamed jflte.

This series adds the devicetree binding and board DTS, together with the
small driver and common DTS changes needed to boot the device with working
USB peripheral mode.

Tested on a Samsung Galaxy S4 GT-I9505. With this series the device boots
and supports UART, USB peripheral mode with USB networking, the front
notification LED and the physical buttons.

Signed-off-by: Alexandre MINETTE <contact@alex-min.fr>
---
Alexandre MINETTE (8):
      dt-bindings: arm: qcom: Add Samsung Galaxy S4
      dt-bindings: extcon: qcom,pm8941-misc: Add PM8921 compatible
      pinctrl: qcom: Register functions before enabling pinctrl
      iommu/msm: Look up masters per IOMMU instance
      extcon: qcom-spmi-misc: Add PM8921 compatible
      ARM: dts: qcom: apq8064: Fix USB controller clocks
      ARM: dts: qcom: pm8921: Add USB ID extcon
      ARM: dts: qcom: Add Samsung Galaxy S4

 Documentation/devicetree/bindings/arm/qcom.yaml    |   1 +
 .../bindings/extcon/qcom,pm8941-misc.yaml          |  17 +-
 arch/arm/boot/dts/qcom/Makefile                    |   1 +
 arch/arm/boot/dts/qcom/pm8921.dtsi                 |   7 +
 .../boot/dts/qcom/qcom-apq8064-samsung-jflte.dts   | 484 +++++++++++++++++++++
 arch/arm/boot/dts/qcom/qcom-apq8064.dtsi           |  18 +-
 drivers/extcon/extcon-qcom-spmi-misc.c             |   1 +
 drivers/iommu/msm_iommu.c                          |  28 +-
 drivers/pinctrl/qcom/pinctrl-msm.c                 |  15 +-
 9 files changed, 545 insertions(+), 27 deletions(-)
---
base-commit: b4e07588e743c989499ca24d49e752c074924a9a
change-id: 20260421-mainline-send-v1-sending-289ec98e6dc1

Best regards,
-- 
Alexandre MINETTE <contact@alex-min.fr>

