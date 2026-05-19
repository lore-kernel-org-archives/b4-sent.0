From: Alexandre MINETTE <contact@alex-min.fr>
Subject: [PATCH v3 0/8] Add Samsung Galaxy S4 support
Date: Tue, 19 May 2026 09:16:30 +0200
Message-Id: <20260519-mainline-send-v1-sending-v3-0-3dd7aa125353@alex-min.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAE4ODGoC/43NwQ6CMAwG4FchPTuzTWTDk+9hPIytQBMYZjMLh
 vDuDk56MZ7a/0/6dYGIgTDCpVggYKJIk8/hdCjA9sZ3yMjlDJLLipdSsNGQH8gji+gdS2Kf5Ds
 mdY221lg5KyCfPwK2NO/07Z5zT/E5hdf+KYmt/QPNK2eNbbg+KyVLh1cz4MxG8sc2wMYm+UmpH
 5TMlLPG1EJpzlXzTa3r+gYEXMf4DQEAAA==
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
 iommu@lists.linux.dev, phone-devel@vger.kernel.org, 
 Alexandre MINETTE <contact@alex-min.fr>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779174999; l=3359;
 i=contact@alex-min.fr; s=20260421; h=from:subject:message-id;
 bh=srxk/ghW3IwsXPEsHcEiUAzCr9Eal81bJ5+97DujtE8=;
 b=g9pYROX+TD6V562E6OiEcSZzW3Qctl2dJZD6VHNRIZtqXXnb+7awsVWSQgOfI+TxMdcXZ40Mw
 IgiGtUf+lTLClZf+kR1WOjL0rpk09OchzKym4OSIylScQNfZM4edNAd
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
 .../boot/dts/qcom/qcom-apq8064-samsung-jflte.dts   | 485 +++++++++++++++++++++
 arch/arm/boot/dts/qcom/qcom-apq8064.dtsi           |  18 +-
 drivers/extcon/extcon-qcom-spmi-misc.c             |   1 +
 drivers/iommu/msm_iommu.c                          |  28 +-
 drivers/pinctrl/qcom/pinctrl-msm.c                 |  15 +-
 9 files changed, 546 insertions(+), 27 deletions(-)
---
base-commit: 4bf3800382b91c2898d14452cf4332782b3fe80a
change-id: 20260421-mainline-send-v1-sending-289ec98e6dc1

Best regards,
-- 
Alexandre MINETTE <contact@alex-min.fr>

