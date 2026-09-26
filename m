From: David Heidelberg <david@ixit.cz>
Subject: [PATCH RFC 00/12] Qualcomm Type-C support for 1st generation
Date: Sat, 26 Sep 2026 14:40:19 +0200
Message-Id: <20260926-typec-v1-0-31adc19f32c6@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDSyMj3ZLKgtRkXbNkE4vUNPPEZIskAyWg2oKi1LTMCrA50UpBbs5KsRD
 B4tKkrNTkEpAJSrW1AJSvOV1uAAAA
X-Change-ID: 20260922-typec-6c48ef7ac8b0
To: Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Lee Jones <lee@kernel.org>, Stephen Boyd <sboyd@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, mfd@lists.linux.dev, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2898; i=david@ixit.cz;
 h=from:subject:message-id; bh=xjTU+sbFxgAggl/vVSj98MM476PDRp/Fsy3fzVYTSv4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqt709jwyJHrD6CfhHDqzowkW+fwNwrlSwXtg0O
 hYU/0A3JkCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCare9PQAKCRBgAj/E00kg
 cl9lD/4rcGeu0us3gr1ySqw8KNKrs54/QxPwlFkuGnScpOzRvoBmGlwhjSVxHUwzVuwPv++lOnV
 DOeQAip+sSE/2iDz2vIxpyvOYyvPsS1UgjV2abr+yLO8O5Frn3fyxCrsq1wQS1TIaxyo1SeFWGN
 9Iw4cuQf9Pr9NXOh0cPePkSrOOaxbX/10hk8WdDIFBPCzWtyMsiZIAsy0q+hLLrW2CAqysCKhOO
 zscZNGtbrE1NQgRbO+B77YB3kiEDSPQ+XbISdkXD45ini1gbyOVJ26nzqC7GGTEcQetcfD3GR6A
 b5t0P63Yv6oZ0mYhIH+WhR/EaOQX/1LtAmDsLm0X7MlkokZ1RTH1fugGSysaZHjKQ32VGEu3Zvr
 QVXUWoR/pAe+IctupGWu2SY2WJ1li8kCRngBe0P10hvnjMvYZuwYgPs2aMWg278r7TbeK7L6+RV
 gB36AQ63GzbJPeZhUEonjiTCzEduK+mdOaoCdiqBQjC6nK0CvAIjoy/hdobzK+yUAbuCJKLPxMy
 9kDVzAx82d7tHT8iHz9EHaKXx+ey3x17qZPkveT284VkIYH4UORftQdKaUJkrUBUFTm/DXpxpXN
 n5LsdTfDuwhFZJdZBixrJ8zud0OaBRKcNh5C2nNL2U+ANSqrt7BwVfMsQEVzXIbWGQ09Pj6WP3r
 ta6K+o3Dom9rdtA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds basic USB Type-C support for 1st gen devices, covering
configurations that do not require VBUS power (e.g. devices using
externally powered docks).

VBUS support will be added in a follow-up series after this one is merged.
Supporting VBUS will likely require refactoring parts of the SMBX charger
support, which is why it is not included here.

Tested with an externally powered dock station:

 - Pixel 3 / 3 XL
 - SHIFT 6mq
 - OnePlus 6

Tested with an additional, not-yet-included VBUS patch for non-powered
devices:

 - Xiaomi Redmi Note 7
 - Xiaomi Mi Pad 4

Credits to everyone who has contributed to Type-C enablement before:

 Casey Connolly
 Zachary Dry — LLM generation and testing
 Max Furman — LLM generation and testing

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Alexey Minnekhanov (1):
      arm64: dts: qcom: pm660: Add USB Type-C port controller node

David Heidelberg (11):
      usb: typec: tcpm: qcom: Release the connector fwnode reference
      dt-bindings: usb: qcom,pmic-typec: Update example with vbus-supply
      dt-bindings: usb: Add Qualcomm 1st-gen PMIC Type-C
      usb: typec: qcom: Make PMIC port probe selectable
      usb: typec: qcom: Make typec_port accept also different structure
      usb: typec: qcom: Add gen1 Type-C port support
      arm64: dts: qcom: pmi8998: Add USB Type-C port controller node
      arm64: dts: qcom: sdm670-google-common: Enable USB Type-C port controller
      arm64: dts: qcom: sdm845-google-common: Enable USB Type-C port controller
      arm64: dts: qcom: sdm845-oneplus-common: Enable USB Type-C port controller
      arm64: dts: qcom: sdm845-shift-axolotl: Enable USB Type-C port controller

 .../devicetree/bindings/mfd/qcom,spmi-pmic.yaml    |   4 +-
 .../bindings/usb/qcom,pmic-typec-gen1.yaml         | 130 +++++
 .../devicetree/bindings/usb/qcom,pmic-typec.yaml   |   3 +-
 arch/arm64/boot/dts/qcom/pm660.dtsi                |  27 +
 arch/arm64/boot/dts/qcom/pmi8998.dtsi              |  27 +
 arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi |  51 +-
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi |  59 +-
 .../arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi |  48 +-
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts  |  62 ++-
 drivers/usb/typec/tcpm/qcom/Makefile               |   1 +
 drivers/usb/typec/tcpm/qcom/qcom_pmic_typec.c      |  20 +-
 drivers/usb/typec/tcpm/qcom/qcom_pmic_typec.h      |   2 +-
 drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_port.c |   2 +
 .../typec/tcpm/qcom/qcom_pmic_typec_port_gen1.c    | 605 +++++++++++++++++++++
 .../typec/tcpm/qcom/qcom_pmic_typec_port_gen1.h    |  15 +
 15 files changed, 1045 insertions(+), 11 deletions(-)
---
base-commit: 7079a12d7506b07fb53b54a664bfad5fa9b16d70
change-id: 20260922-typec-6c48ef7ac8b0

Best regards,
--  
David Heidelberg <david@ixit.cz>

