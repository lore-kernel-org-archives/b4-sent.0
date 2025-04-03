From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v3 0/2] Pinctrl: add amlogic a5 pinctrl node
Date: Thu, 03 Apr 2025 16:33:13 +0800
Message-Id: <20250403-a5-pinctrl-v3-0-a8c067e22295@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMpH7mcC/1XMQQqDMBCF4auUrJuSZGLUrnqP0kWYRh1QI4mEF
 vHujVJoXb4H/7ew6AK5yK6nhQWXKJIf84DziWFnx9ZxeubNlFCFAFlxW/CJRpxDzxtAg8Za4cq
 G5WAKrqHXjt0feXcUZx/eu53k9n4ZVf4zSXLBdQ1KgK5RG7jZofct4QX9wDYoqV+shTzEKsdWg
 kEpigrK+hiv6/oBEbPHo+MAAAA=
To: Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1743669198; l=918;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=QgyehMsARveK93ZZL1S0DWD6VKwpD0RfUNcyzEEiVwI=;
 b=wC3pYUawqVLxEBq/uVvbyL6+tKn79Zulf2H4XuvfZ3meWIf0mcSkbL8sDDDGC/t/nsGArhLVW
 COjkuoNlARFCmhaENF1XQ+4ZRl5fa5kaZRVR6OmFAd+EmC1zhfc2qqr
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add A5 pinctrl compatible string and device node.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v3:
- Remain blank line.
- Link to v2: https://lore.kernel.org/r/20250401-a5-pinctrl-v2-0-a136c1058379@amlogic.com

Changes in v2:
- Modify bindings according to Conor's suggestion.
- Link to v1: https://lore.kernel.org/r/20250327-a5-pinctrl-v1-0-49320349c463@amlogic.com

---
Xianwei Zhao (2):
      dt-bindings: pinctl: amlogic,pinctrl-a4: Add compatible string for A5
      dts: arm64: amlogic: add a5 pinctrl node

 .../bindings/pinctrl/amlogic,pinctrl-a4.yaml       |  7 +-
 arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi        | 90 ++++++++++++++++++++++
 2 files changed, 96 insertions(+), 1 deletion(-)
---
base-commit: 79e0ecfc780aaf8c0b6658607f75a661a5f00736
change-id: 20250318-a5-pinctrl-f3c6c6aa0e7f

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

