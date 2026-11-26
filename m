From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v13 0/2] i2c: Add driver support Amlogic A9 I2C
Date: Thu, 26 Nov 2026 06:31:16 +0000
Message-Id: <20261126-a9-i2c-v13-0-926e2072cc4f@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADXSB2sC/3XSzU7DMAwH8FeZeqYQ2/nkxHsgDknqbJVYi9qpG
 pr27iTT6IpajnH8y1+xfKlGHloeq9fdpRp4ase27/IB6GlXxYPv9ly3TS5UKFALB1B7V7cYa5T
 SWEZkbanKzcGPXIfBd/FQ2nPLS2nr+Hwq118Dp/Z8C3r/yOdDO5764fuWO0Gp3hNQ/iZMUIs6W
 N+4IHWS3r7542e/b+Nz7I9VeWTCGYJAnCFmKBVT5ARGhbSGtIRuhpShCSRijEIoojWUD5jlDGW
 GyoN2CCpYdmuolpBmqDK0OmETGzCu2fijXsLHcHQZjvcaDCTUaQOabWgKpIyCouSTXEO7gCBma
 DMEdg1qi8nqsIZuCc0M3X2qFK2Tif0agtiWOV3UROyd5xQZxQaFJbUPWrZHW09sXEqStlLxH1r
 2J0VLUREgsP5Lr9frDzN/CEE3AwAA
X-Change-ID: 20260911-a9-i2c-24478e22e683
To: Junyi Zhao <junyi.zhao@amlogic.com>, Andi Shyti <andi.shyti@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Xianwei Zhao <xianwei.zhaol@amlogic.com>
Cc: Junyi Zhao <junyi.zhaol@amlogic.com>, 
 Markus Elfring <Markus.Elfring@web.de>, linux-i2c@vger.kernel.org, 
 linux-amlogic@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795674680; l=4011;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=VG38lz3bQkFtaNsrKv2JR7dmLOKBqQpIx9rJVzY1Afk=;
 b=5sqqu0gv5XNxfbHLSA9rQFtAUzZA9aBqMeEWrU9YM/CmM+PtC2X4g4k0n2X1DRGUVXXTv1DjX
 mk/BHLNpoj9AOe2TPn8aZTGmLn3eEqkGrdungW+oUJ47NjClJ8WhqiT
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a device tree binding and driver for the I2C controller found on the
Amlogic A9 SoC.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v13:
- Fix commit message in the dt-bindings patch ("device tree" -> "Devicetree").
- Clear pending IRQ status before configuring and starting a new I2C transfer.
- Link to v12: https://lore.kernel.org/r/20261118-a9-i2c-v12-0-fc83c53121e6@amlogic.com

Changes in v12:
- Cancel the initialization of local variables "ret".
- Link to v11: https://lore.kernel.org/r/20261118-a9-i2c-v11-0-68a3e79ff43a@amlogic.com

Changes in v11:
- Convert hand-rolled spin_lock_irqsave()/spin_unlock_irqrestore() pairs
  to scoped_guard(), and drop the now unused  "flags" variable.
- Link to v10: https://lore.kernel.org/r/20261117-a9-i2c-v10-0-33ea9aefce20@amlogic.com

Changes in v10:
- Convert hand-rolled spin_lock_irqsave()/spin_unlock_irqrestore() pairs
  to guard().
- Drop unneeded braces around the single-statement early return in the
  IRQ handler.
- Add MODULE_AUTHOR entry for Xianwei Zhao.
- Fix commit message capitalization in the dt-bindings patch
  ("Device Tree" -> "device tree").
- Link to v9: https://lore.kernel.org/r/20261117-a9-i2c-v9-0-7b303c894fea@amlogic.com

Changes in v9:
- Use guard(spinlock) instead of spinlock according to Markus's suggestions, no logic change.
- Link to v8: https://lore.kernel.org/r/20261110-a9-i2c-v8-0-1e9d2682f86b@amlogic.com

Changes in v8:
- Reserve complete(done) into lock, and adjust the code process in irq func.
- Link to v7: https://lore.kernel.org/r/20261104-a9-i2c-v7-0-b31f2b53faf4@amlogic.com

Changes in v7:
- Move complete(done) out of lock, and when state = idle not complete(done) in irq func.
- Link to v6: https://lore.kernel.org/r/20261104-a9-i2c-v6-0-baa6171f26f8@amlogic.com

Changes in v6:
- use xfer instead of master_xfer interface, and when div=8 remain valid.
- Optimized the function.
- Link to v5: https://lore.kernel.org/r/20261103-a9-i2c-v5-0-86f2dcd179d8@amlogic.com

Changes in v5:
- Mask out I2C_FUNC_SMBUS_QUICK and return I2C_FUNC_I2C | (I2C_FUNC_SMBUS_EMUL & ~I2C_FUNC_SMBUS_QUICK).
- Link to v4: https://lore.kernel.org/r/20261102-a9-i2c-v4-0-5a169215b8e9@amlogic.com

Changes in v4:
- Repocess xfer len equal 0 use I2C_AQ_NO_ZERO_LEN, and Optimized the function.
- Disable A9_RX_THRESH_READ/A9_TX_THRESH_WRITE enables of irq when xfer timeout.
- Use guard(spinlock_irqsave) instead for direct call spinlock in xfer timeout process.
- Link to v3: https://lore.kernel.org/r/20261029-a9-i2c-v3-0-7b30ccc00533@amlogic.com

Changes in v3:
- Based on the questions raised by the robot, the data flow was reorganized.
- Some processing was optimized according to Andi's and Markus's suggestions.
- Link to v2: https://lore.kernel.org/r/20261022-a9-i2c-v2-0-45e3cef175bf@amlogic.com

Changes in v2:
- dtbinding: make some minor modifications, suggestted by Conor and robot.
- driver: Make some adjustments, including macro definitions, format adjustments,
          adding quirks, process optimization, and so on. According to Andi and robot's suggestion
- Give up MAINTAINERS file the separate submission, make it together with the driver.
- Link to v1: https://lore.kernel.org/r/20260924-a9-i2c-v1-0-b8ad9b46f4a8@amlogic.com

---
Junyi Zhao (1):
      i2c: amlogic: Add Amlogic A9 I2C controller driver

Xianwei Zhao (1):
      dt-bindings: i2c: add Amlogic A9 I2C controller

 .../devicetree/bindings/i2c/amlogic,a9-i2c.yaml    |  56 +++
 MAINTAINERS                                        |   9 +
 drivers/i2c/busses/Kconfig                         |   8 +
 drivers/i2c/busses/Makefile                        |   1 +
 drivers/i2c/busses/i2c-amlogic-a9.c                | 428 +++++++++++++++++++++
 5 files changed, 502 insertions(+)
---
base-commit: 4cd099f240b0b74101fde32b6e3b15ea6e26714c
change-id: 20260911-a9-i2c-24478e22e683

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

