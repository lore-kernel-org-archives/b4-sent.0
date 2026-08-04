From: Alexandre MINETTE <contact@alex-min.fr>
Subject: [PATCH v5 0/6] Add Samsung Galaxy S4 support
Date: Tue, 04 Aug 2026 08:34:25 +0200
Message-Id: <20260804-mainline-send-v1-sending-v5-0-149dd4372ac8@alex-min.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPGHcWoC/43NTQrCMBAF4KtI1kby26SuvIe4SJOpDmiURIpSe
 nfTbqoUiquZ92C+6UmGhJDJftOTBB1mvMcS9HZD/MXFM1AMJRPBRMWU4PTmMF4xAs0QA+34NDG
 eqbA1+NpCFTwn5fyRoMXXRB9PJV8wP+/pPX3q+Nj+gZaV0cY3zGpjhApwcFd40RvGXZvIyHbim
 zIrlChU8M7V3FjGTLOk5ExpXq9QslAyBOMcF1pquaTUTFVsjVKFstJUtm1axVT4pYZh+ACKFS7
 YowEAAA==
X-Change-ID: 20260421-mainline-send-v1-sending-289ec98e6dc1
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, MyungJoo Ham <myungjoo.ham@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, 
 Guru Das Srinagesh <linux@gurudas.dev>, Linus Walleij <linusw@kernel.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>, Lee Jones <lee@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-gpio@vger.kernel.org, 
 phone-devel@vger.kernel.org, Alexandre MINETTE <contact@alex-min.fr>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785825291; l=4604;
 i=contact@alex-min.fr; s=20260421; h=from:subject:message-id;
 bh=ksLuLP9L61STj7l8Y3f0TRckDPVfvzETJaZ9C8sWxEM=;
 b=9OM7C6h+Ew1HyC361g/ORRwFn3yLQWmpclGWjIv21AbIzAy3MhyJFZHxPSAksilNfuZGBGq3I
 CQk0R/vF+42AR5VnxNPTdJndbL8AwiTvPh14Xd8rh78eEvNm3g4/9Se
X-Developer-Key: i=contact@alex-min.fr; a=ed25519;
 pk=KOCaxY4v16ptaT0uk1FRkuaDF2n1JhmnYwLiqWD76M4=
X-Endpoint-Received: by B4 Relay for contact@alex-min.fr/20260421 with auth_id=743
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add initial mainline support for the Samsung Galaxy S4, codenamed jflte.

This series adds the devicetree binding and board DTS, together with the
small driver and common DTS changes needed to boot the device with working
USB peripheral mode.

Tested on a Samsung Galaxy S4 GT-I9505. This series adds support for
UART, USB peripheral mode with USB networking, the front notification
LED and the physical buttons.

Booting the device also requires an MSM IOMMU master handling fix,
which will be submitted separately.

Signed-off-by: Alexandre MINETTE <contact@alex-min.fr>
---
Changes in v5:
- Added Reviewed-by/Acked-by collected on v4
- Link to v4: https://lore.kernel.org/r/20260609-mainline-send-v1-sending-v4-0-83768fbf404d@alex-min.fr

Changes in v4:
- Rework PM8921 USB ID support by registering the extcon device from the
  parent PMIC driver instead of describing a separate DT child node.
- Add GPIO_OPEN_DRAIN flag to i2c-gpio
- Drop the Reviewed-by tag from the Galaxy S4 DTS patch because its USB
  extcon description changed.
- Drop the MSM IOMMU master lookup fix from this series. It needs a
  broader rework and will be sent separately.
- jflte still needs that follow-up MSM IOMMU fix to boot.
- Link to v3: https://lore.kernel.org/r/20260519-mainline-send-v1-sending-v3-0-3dd7aa125353@alex-min.fr

Changes in v3:
- Clarify that the Galaxy S4 compatible is for the Qualcomm
  APQ8064-based variant, and add Krzysztof's Acked-by.
- Clarify the PM8921 USB ID binding, driver and DTS commit messages to
  describe the PMIC interrupt-controller interface and the lack of a
  known register resource for this interrupt-only path.
- Keep the PM8921 USB ID extcon node non-addressable rather than adding a
  speculative reg value.
- Keep the MUIC and LED buses as i2c-gpio. Testing the corresponding
  GSBI controllers on GT-I9505 made USB fail to enumerate with the MUIC
  on GSBI2, and made LED brightness writes time out with the LED on
  GSBI3.
- Reorder APQ8064 USB clock entries to match the related ci-hdrc binding
  update, using iface, core, fs order.
- Sort the jflte DTB Makefile entry after the LG Nexus 4 entry.
- Link to v2: https://lore.kernel.org/r/20260427-mainline-send-v1-sending-v2-0-dcaa9178007b@alex-min.fr

Changes in v2:
- Keep the APQ8064 compatible list in qcom.yaml alphabetically sorted.
- Clarify the Qualcomm pinctrl commit message and include the failing hog
  lookup trace seen on APQ8064.
- Clarify the MSM IOMMU commit message and include the NULL dereference
  trace seen during IOMMU probe on APQ8064.
- Move the PM8921 USB ID extcon node to the end of the PM8921 child nodes.
- Reorder the jflte DTS nodes and pinctrl properties as requested by
  reviewers.
- Add Reviewed-by/Acked-by tags collected on v1.
- Link to v1: https://lore.kernel.org/r/20260421-mainline-send-v1-sending-v1-0-bcb0857724de@alex-min.fr

To: Bjorn Andersson <andersson@kernel.org>
To: Konrad Dybcio <konradybcio@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Linus Walleij <linusw@kernel.org>
To: Lee Jones <lee@kernel.org>
To: MyungJoo Ham <myungjoo.ham@samsung.com>
To: Chanwoo Choi <cw00.choi@samsung.com>
To: Kees Cook <kees@kernel.org>
To: Tony Luck <tony.luck@intel.com>
To: "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-msm@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-gpio@vger.kernel.org

---
Alexandre MINETTE (6):
      dt-bindings: arm: qcom: Add Samsung Galaxy S4
      pinctrl: qcom: Register functions before enabling pinctrl
      ARM: dts: qcom: apq8064: Fix USB controller clocks
      mfd: qcom-pm8xxx: register PM8921 USB ID extcon
      extcon: qcom-spmi-misc: match PM8xxx USB ID platform device
      ARM: dts: qcom: Add Samsung Galaxy S4

 Documentation/devicetree/bindings/arm/qcom.yaml    |   1 +
 arch/arm/boot/dts/qcom/Makefile                    |   1 +
 .../boot/dts/qcom/qcom-apq8064-samsung-jflte.dts   | 481 +++++++++++++++++++++
 arch/arm/boot/dts/qcom/qcom-apq8064.dtsi           |  18 +-
 drivers/extcon/extcon-qcom-spmi-misc.c             |   7 +
 drivers/mfd/qcom-pm8xxx.c                          |  78 +++-
 drivers/pinctrl/qcom/pinctrl-msm.c                 |  15 +-
 7 files changed, 588 insertions(+), 13 deletions(-)
---
base-commit: 4bf3800382b91c2898d14452cf4332782b3fe80a
change-id: 20260421-mainline-send-v1-sending-289ec98e6dc1

Best regards,
--  
Alexandre MINETTE <contact@alex-min.fr>

