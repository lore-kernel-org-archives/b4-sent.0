From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v4 0/4] Add GPIO interrupt support for Amlogic A4 and A5
 SoCs
Date: Fri, 07 Mar 2025 16:49:21 +0800
Message-Id: <20250307-irqchip-gpio-a4-a5-v4-0-d03a9424151b@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABGzymcC/23NwW6DMAzG8VdBOS+T48SM7bT3qHYIxoCltWFhQ
 p0q3r2BSzeN4/+T/PPNzJJVZvNW3UyWRWdNlxLhqTI8xssgVrvSBgGDQ+et5i8edbLDpMnGYCP
 ZBpggukA1B1MOpyy9Xnf09FF61Pk75Z/9x+K2deMI0L0ecYuzYD03EkKUgF3/Hs+faVB+5nQ2G
 7jgLwTrQwQLwkStAwJuif4j/oF4oEPEF8SJ8At4wl7iX2Rd1zvpttjbQAEAAA==
To: Thomas Gleixner <tglx@linutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Heiner Kallweit <hkallweit1@gmail.com>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741337362; l=1730;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=MqtpD5D8ho7ZkuHg72dZuTrsPAosUYbPrhtFmWLF0Xo=;
 b=jf2kjl2+fTJLAmql/JkT3VEHpbqntitDldAJPUz8QyCqBKYCjLRpFruPnhKEmVBw/RGfgz/SO
 wgJC8IuFyvcDp1wUcSQe8szaZvVptqOy7GprHofvxVqwwE/1tW7l5SH
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch adds GPIO interrupt support for Amlogic A4 and A5 SoCs

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v4:
- Make minor changes for bindings as Conor and Rob suggest.
- Format adjustment of source code according to Thomas's suggestion.
- Link to v3: https://lore.kernel.org/r/20250305-irqchip-gpio-a4-a5-v3-0-1eec70352fea@amlogic.com

Changes in v3:
- Fix warning when run 'make ARCH=arm64 dtbs_check'.
- Fix warning when run 'make ARCH=arm64 Image W=1'.
- Rebase file amlogic-a4.dtsi.
- Link to v2: https://lore.kernel.org/r/20250226-irqchip-gpio-a4-a5-v2-0-c55b1050cb55@amlogic.com

Changes in v2:
- Use if/then instead of direct modification minimum value for property 'amlogic,channel-interrupts'.
- Add register offsets to the parameter structure to reduce definition of a function.
- Link to v1: https://lore.kernel.org/r/20250219-irqchip-gpio-a4-a5-v1-0-3c8e44ae42df@amlogic.com

---
Xianwei Zhao (4):
      dt-bindings: interrupt-controller: Add support for Amlogic A4 and A5 SoCs
      irqchip: Add support for Amlogic A4 and A5 SoCs
      arm64: dts: Add gpio_intc node for Amlogic A4 SoCs
      arm64: dts: Add gpio_intc node for Amlogic A5 SoCs

 .../amlogic,meson-gpio-intc.yaml                   | 19 ++++++++-
 arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi        | 19 +++++++++
 arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi        | 12 ++++++
 drivers/irqchip/irq-meson-gpio.c                   | 45 +++++++++++++++++-----
 4 files changed, 85 insertions(+), 10 deletions(-)
---
base-commit: 73e4ffb27bb8a093d557bb2dac1a271474cca99c
change-id: 20241213-irqchip-gpio-a4-a5-80c50a1456c4

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

