From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v2 0/8] Add support for Amlogic S7/S7D/S6 pinctrl
Date: Wed, 21 May 2025 11:19:54 +0800
Message-Id: <20250521-s6-s7-pinctrl-v2-0-0ce5e3728404@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFtGLWgC/3WMyw6CMBBFf4XM2jG0PERW/odhUdsBJoGWtKTRk
 P67lb3Lc3PPOSCQZwrQFwd4ihzY2QzyUoCelZ0I2WQGWcqmbESNocVww42t3v2CahT0MqrrVE2
 Qnc3TyO+z9xwyzxx25z9nPorf+q8UBZZY3U3VdlqZfHmodXET66t2KwwppS+CZbg7rAAAAA==
To: Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747797595; l=2128;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=FilmMjWVjeFbgPQ1/VIsUxcruvgzblwEpDc5cmgZlVY=;
 b=U1eTjmPOftcb7iYltC3UH46ARev+gM0/KW5ZTeoQ/qiPrvdj/r6c6PBMe9+aR35Bzk4OhXzRq
 JEx4RuXCa7cAoIPVyO0iXifLoJGKdUy2fFud6Pfi8GnF6FyuVYtWSRE
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In some Amlogic SoCs, to save register space or due to some
abnormal arrangements, two sets of pins share one mux register.
A group starting from pin0 is the main pin group, which acquires
the register address through DTS and has management permissions,
but the register bit offset is undetermined.
Another GPIO group as a subordinate group. Some pins mux use share
register and bit offset from bit0 . But this group do not have
register management permissions.

In SoC S7 and S7D, GPIOX(16~19) mux share with GPIOCC mux register.

In SoC S6, GPIOX(16~19) mux share with GPIOCC mux register, and GPIOD(6)
mux share with GPIOF mux register.

Add S7/S7D/S6 pinctrl compatible string and device node.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v2:
- Add a unit address for pinctrl node.
- Use pointer instead of flexible array to solve the problem tested by kernel test robot.
- Link to v1: https://lore.kernel.org/r/20250514-s6-s7-pinctrl-v1-0-39d368cad250@amlogic.com

---
Xianwei Zhao (8):
      dt-bindings: pinctl: amlogic,pinctrl-a4: Add compatible string for S7
      dt-bindings: pinctl: amlogic,pinctrl-a4: Add compatible string for S7D
      dt-bindings: pinctl: amlogic,pinctrl-a4: Add compatible string for S6
      pinctrl: meson: a4: remove special data processing
      pinctrl: meson: support amlogic S6/S7/S7D SoC
      dts: arm64: amlogic: add S7 pinctrl node
      dts: arm64: amlogic: add S7D pinctrl node
      dts: arm64: amlogic: add S6 pinctrl node

 .../bindings/pinctrl/amlogic,pinctrl-a4.yaml       |   9 +-
 arch/arm64/boot/dts/amlogic/amlogic-s6.dtsi        |  97 +++++++++++++++++
 arch/arm64/boot/dts/amlogic/amlogic-s7.dtsi        |  81 ++++++++++++++
 arch/arm64/boot/dts/amlogic/amlogic-s7d.dtsi       |  90 ++++++++++++++++
 drivers/pinctrl/meson/pinctrl-amlogic-a4.c         | 118 ++++++++++++++++-----
 5 files changed, 370 insertions(+), 25 deletions(-)
---
base-commit: aa94665adc28f3fdc3de2979ac1e98bae961d6ca
change-id: 20250514-s6-s7-pinctrl-af1ebda88a4e

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

