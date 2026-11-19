From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH v6 0/2] gpio: Add Cortina Systems CS75xx GPIO driver
Date: Thu, 19 Nov 2026 18:09:07 +0300
Message-Id: <20261119-cs75xx-gpio-v6-0-37aeda0aaedd@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/1WNQQ6DIBQFr2JYlwYsoHbVezRdIHyVpooBS2yMd
 y/oRpeTvJm3IA/OgEf3bEEOgvHGDhHEJUOqk0ML2OjIKCe5oIRyrHzB5xm3o7EYNJG3AoBJUaJ
 ojA4aM2+152tn/63foKaUSIvO+Mm633YXWNrtZUrFqRwYJljqksiKMaiEeLS9NJ+rsj1K5cCPb
 nV2eXRLTVmT17WgrD6667r+AUyfBGv0AAAA
X-Change-ID: 20261015-cs75xx-gpio-ed0a37ee4a68
To: Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Fil Dunsky <filipp.dunsky@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795100967; l=5049;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=EhUV4m3x5pqIox2QkeCyQxEVHdvQ1jHoNLjoIGNZ+IM=;
 b=94pauLRG9uL56SEoTCkAmBgHzcSmy8uKOHr8hKWTKkjibpQfNexqAlzhITdtBDoYEScHgog9z
 Px6RgrSKNSqCTy6J733wq9UskzxJar5h2vIAcwePP/Xp8QxljKDzMYV
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Cortina Systems CS75xx ("Goldengate G2") SoCs have five banks of 32
GPIO lines, each bank with its own interrupt. This series adds the
binding and a driver based on gpio-mmio; level and edge triggers are
supported, both edges are emulated by flipping the polarity.

Each pin is either a GPIO line or belongs to a peripheral (NAND,
Ethernet, UART, I2C, ...). That choice is made in the global control
block, which is not part of the GPIO controller: as discussed on v1 [1],
the driver does not touch the pin mux and leaves it as the boot loader
set it up, until there is a pin controller driver for that block.
Testing the reset button on the Securifi Almond+ requires selecting
GPIO37 in the global pin mux before gpio-keys is probed; the current
boot path does not provide that setup. The tests used a separate,
board-specific setup step. The GPIO driver does not program the mux.

The driver used to be part of a series with the interrupt controller,
I2C and watchdog drivers and the device tree changes. That series is now
split per subsystem. The driver depends on OF and the generic MMIO GPIO
and IRQ infrastructure, with no dependency on the platform series [2],
which is under review separately. The device tree nodes will follow with
the other CS75xx dts changes once the platform is merged.

There is no public documentation; the register layout comes from the GPL
vendor kernels. Tested on a Securifi Almond+ (CS7542): the reset button
(GPIO 37) works as an active-low gpio-keys input, and the SX8650
touchscreen uses a level-triggered GPIO interrupt.

[1] https://lore.kernel.org/all/20261012-dreamlike-hazily-19bb60326f0a@spud/
[2] https://lore.kernel.org/all/20261114-b4-cs75xx-v7-0-8f17f38821b4@gmail.com/

---
Changes in v6:
- replace the dependency on ARCH_CORTINA_ACCESS || COMPILE_TEST with OF,
  so the GPIO series can be merged independently of the platform series
  (Bartosz); HAS_IOMEM is inherited from the MMIO GPIO driver menu
- build built-in and modular on ARM and x86-64 with COMPILE_TEST=n,
  without the platform series; the driver code is unchanged
- Link to v5: https://patch.msgid.link/20261119-cs75xx-gpio-v5-0-8d14f2bb614b@gmail.com

Changes in v5:
- explain that ARCH_CORTINA_ACCESS is introduced by the platform series;
  COMPILE_TEST allows building this driver without that series
- correct the pin mux setup required for testing the Almond+ reset button
- clear the interrupt status after changing the trigger type, so that
  unmasking an edge interrupt does not fire a stale event (sashiko-bot)
- collect Reviewed-by tags; Linus, I kept yours over the one-line change
  above
- Link to v4: https://patch.msgid.link/20261116-cs75xx-gpio-v4-0-ad80a944e966@gmail.com

Changes in v4:
- rebase on v7.4-rc1
- split out of "Cortina Systems CS75xx: interrupt controller, GPIO, I2C
  and TWD watchdog" so that each driver can go through its own tree; no
  longer based on the platform series
- the pin mux registers are not part of the GPIO controller (Conor): the
  binding has a single reg entry and the driver no longer switches the
  pin mux when a line is requested
  (Rob, your Reviewed-by on v3 is not carried because of this change)
- switch a line to input for an interrupt only when it is not requested;
  flip the polarity of a both-edges line after the ack, so that an edge
  in between is not lost (sashiko-bot)
- drop the gpio_chip owner, gpiolib sets it; sort the Makefile entry
- Link to v3: https://patch.msgid.link/20261013-b4-cs75xx-s2-v3-0-181bb0d23f4c@gmail.com

Changes in v3:
- rebase on v6 of the platform series
- Link to v2: https://patch.msgid.link/20261013-b4-cs75xx-s2-v2-0-94f8c0a90cda@gmail.com

Changes in v2:
- rebase on v5 of the platform series
- do not include <linux/mod_devicetable.h> (Uwe)
- update the both-edges mask only for a valid trigger type and test it
  under the lock in the interrupt handler; refuse more than 32 lines
  (sashiko-bot)
- Link to v1: https://patch.msgid.link/20261012-b4-cs75xx-s2-v1-0-8a7641b7b79c@gmail.com

To: Linus Walleij <linusw@kernel.org>
To: Bartosz Golaszewski <brgl@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
Cc: linux-gpio@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-arm-kernel@lists.infradead.org

---
Fil Dunsky (2):
      dt-bindings: gpio: Add Cortina Systems CS7542 GPIO controller
      gpio: Add Cortina Systems CS75xx GPIO driver

 .../bindings/gpio/cortina,cs7542-gpio.yaml         |  65 +++++
 drivers/gpio/Kconfig                               |  12 +
 drivers/gpio/Makefile                              |   1 +
 drivers/gpio/gpio-cs75xx.c                         | 283 +++++++++++++++++++++
 4 files changed, 361 insertions(+)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261015-cs75xx-gpio-ed0a37ee4a68

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

