From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/3] Power: A4: add power domain driver
Date: Tue, 28 May 2024 16:39:27 +0800
Message-Id: <20240528-a4_secpowerdomain-v1-0-2a9d7df9b128@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAECYVWYC/x3MQQqAIBBA0avErBMm06iuEhFmU80iDYUKwrsnL
 d/i/xciBaYIffFCoIsje5dRlQXY3biNBC/ZIFEq1LIVRk2R7OlvCos/DDuhaUbUjWq7GiF3Z6C
 Vn/85jCl9vNEVQmMAAAA=
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jianxin Pan <jianxin.pan@amlogic.com>, Ulf Hansson <ulf.hansson@linaro.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-pm@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716885570; l=885;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=bfGDc5/xHmz//Yt7VOOfRU/PyB095+4Sl6kUXfSweuI=;
 b=zXzrrh7KUaH5eZOcybvVChgnCMLz6xll9cNsTL81pYUzbiwrYghjd8a/+Z1vCUYKHlv6pZ50p
 kY6IenT6z00DVwq3DTG04hEuWYeuz6PWUcz8Sfdvaw16xH2bdz1h3SS
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add power controller driver support for Amlogic A4 SoC.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Xianwei Zhao (3):
      dt-bindings: power: add Amlogic A4 power domains
      pmdomain: amlogic: Add support for A4 power domains controller
      arm64: dts: amlogic: a4: add power domain controller node

 .../bindings/power/amlogic,meson-sec-pwrc.yaml     |  1 +
 arch/arm64/boot/dts/amlogic/amlogic-a4-common.dtsi |  4 ++++
 arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi        |  5 ++++
 drivers/pmdomain/amlogic/meson-secure-pwrc.c       | 28 ++++++++++++++++++++++
 include/dt-bindings/power/amlogic,a4-pwrc.h        | 21 ++++++++++++++++
 5 files changed, 59 insertions(+)
---
base-commit: 456f4f5e6e6d3a2228501068a37ce13fe0b333d4
change-id: 20240528-a4_secpowerdomain-5eb005648930

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

