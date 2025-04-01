From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v2 0/2] Pinctrl: add amlogic a5 pinctrl node
Date: Tue, 01 Apr 2025 10:06:20 +0800
Message-Id: <20250401-a5-pinctrl-v2-0-a136c1058379@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABxK62cC/03MQQqDMBCF4avIrDslJhqrq96juAjTqANqJJHQI
 rl7U+miy//B+w4I1rMN0BUHeBs5sFtzyEsBNJl1tMjP3CCFrIUqb2hq3Hil3c84KNKkjRG2GSA
 fNm8Hfp3Yo889cdidf592LL/rj5HNPxNLFFi1SgpVtVRpdTfL7EamK7kF+pTSB97BAKWmAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1743473181; l=788;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=N7COEdohT/p/ERmnPBTo3f+/HD3+Lg9hkfh8iPLCO6s=;
 b=/Y71x73Ay7L8h/1pL9RFzAr9jHHiKfMAvm5TBYQ+ExyBsiJw/DB6NQztZwR2sv6rXORs5CGwt
 OubXuc7SDE5CuePXh35gvVlaSnQmYqT1UZVqhwBFS5QKKzPURSETDhr
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add A5 pinctrl compatible string and device node.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v2:
- Modify bindings according to Conor's suggestion.
- Link to v1: https://lore.kernel.org/r/20250327-a5-pinctrl-v1-0-49320349c463@amlogic.com

---
Xianwei Zhao (2):
      dt-bindings: pinctl: amlogic,pinctrl-a4: Add compatible string for A5
      dts: arm64: amlogic: add a5 pinctrl node

 .../bindings/pinctrl/amlogic,pinctrl-a4.yaml       |  8 +-
 arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi        | 90 ++++++++++++++++++++++
 2 files changed, 96 insertions(+), 2 deletions(-)
---
base-commit: 79e0ecfc780aaf8c0b6658607f75a661a5f00736
change-id: 20250318-a5-pinctrl-f3c6c6aa0e7f

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

