From: Isaac Adjei <code@isaacadjei.me>
Date: Thu, 05 Nov 2026 08:16:51 +0000
Subject: [PATCH] gpio: mpfs: reject unsupported interrupt types
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-gpio-mpfs-irq-type-v1-1-cbb2b0b2a807@isaacadjei.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqAIBBA0avIrBtII4muEi1Kx5pFahpRRHdPW
 r7F/w9kSkwZevFAopMzB18gKwFmnfxCyLYYVK20lHWLS+SAW3QZOe143JGQGm061czGWQ0ljIk
 cX/90GN/3AyioTb1kAAAA
X-Change-ID: 20261105-gpio-mpfs-irq-type-e36c823bcfd6
To: Conor Dooley <conor.dooley@microchip.com>, 
 Valentina Fernandez <valentina.fernandezalanis@microchip.com>, 
 Daire McNamara <daire.mcnamara@microchip.com>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-riscv@lists.infradead.org, linux-gpio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, kernel test robot <lkp@intel.com>, 
 Dan Carpenter <error27@gmail.com>, Isaac Adjei <code@isaacadjei.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793866638; l=1787;
 i=code@isaacadjei.me; s=20261105; h=from:subject:message-id;
 bh=RPHB+79SRzi3MO4cqrlIZyGYkUrVv21I2XEOqLhYUno=;
 b=fFDDILoO4M0UxwIpenwFbNGJG0/z4thpkU2owNKbMEFvFJ2+2Fw0TJ7pG2PG/Yd9BnSqRfuuC
 2eygNlMXFfxBi6tBkhb9N+FkxBtISiPq5e7WZCwWSl5xEAZcw7nXG0d
X-Developer-Key: i=code@isaacadjei.me; a=ed25519;
 pk=VhIIXFXv1g0LAdmG85V9QxWkeBc0KGdKUVH/4o0lWco=
X-Endpoint-Received: by B4 Relay for code@isaacadjei.me/20261105 with auth_id=1415
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The switch statement in mpfs_gpio_irq_set_type() does not handle
unsupported interrupt types. For example, IRQ_TYPE_NONE is not listed.

When an unsupported type is passed, interrupt_type remains
uninitialised. Its undefined value is then written to the GPIO control
register. The function still returns 0, making the caller believe the
operation succeeded.

Add a default case to return -EINVAL for unsupported interrupt types.

Smatch reported the following warning:

  drivers/gpio/gpio-mpfs.c:144 mpfs_gpio_irq_set_type() error: uninitialized symbol 'interrupt_type'.

I built the driver with W=1 and got no warnings. I also reran Smatch
and confirmed that the warning was resolved.

This is compile-tested only. I do not have access to PolarFire SoC
hardware for runtime testing.

Fixes: e57b53f0f36a ("gpio: mpfs: Add interrupt support")
Reported-by: kernel test robot <lkp@intel.com>
Reported-by: Dan Carpenter <error27@gmail.com>
Closes: https://lore.kernel.org/r/202411080149.bOpayvf6-lkp@intel.com/
Signed-off-by: Isaac Adjei <code@isaacadjei.me>
---
 drivers/gpio/gpio-mpfs.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/gpio/gpio-mpfs.c b/drivers/gpio/gpio-mpfs.c
index 7f0751d7b..0b7a48e0a 100644
--- a/drivers/gpio/gpio-mpfs.c
+++ b/drivers/gpio/gpio-mpfs.c
@@ -138,6 +138,8 @@ static int mpfs_gpio_irq_set_type(struct irq_data *data, unsigned int type)
 	case IRQ_TYPE_LEVEL_LOW:
 		interrupt_type = MPFS_GPIO_TYPE_INT_LEVEL_LOW;
 		break;
+	default:
+		return -EINVAL;
 	}
 
 	regmap_update_bits(mpfs_gpio->regs, MPFS_GPIO_CTRL(gpio_index),

---
base-commit: 05441d697f7f9a927264f4058cbbc6a03dfcac9d
change-id: 20261105-gpio-mpfs-irq-type-e36c823bcfd6

Best regards,
-- 
Isaac Adjei <code@isaacadjei.me>

