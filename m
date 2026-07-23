From: Vincent Jardin <vjardin@free.fr>
Date: Fri, 24 Jul 2026 01:09:13 +0200
Subject: [PATCH 2/2] dpll: zl3073x: add ZL30643 chip support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260724-for-upstream-zl30643-v1-2-ea93ba4d85c8@free.fr>
References: <20260724-for-upstream-zl30643-v1-0-ea93ba4d85c8@free.fr>
In-Reply-To: <20260724-for-upstream-zl30643-v1-0-ea93ba4d85c8@free.fr>
To: Ivan Vecera <ivecera@redhat.com>, 
 Prathosh Satish <Prathosh.Satish@microchip.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Vadim Fedorenko <vadim.fedorenko@linux.dev>, 
 Arkadiusz Kubalewski <arkadiusz.kubalewski@intel.com>, 
 Jiri Pirko <jiri@resnulli.us>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784848154; l=2816;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=84xRUJhokqrnrzbH6D226xN7w2LrlqlOsMReWeo9UCg=;
 b=f4B7n1HweVNsPQ/MWnWgoXfSTv8X6RsNecMjQt0DfwD13i96lxm4t1WjJyyy8JU/L04TKNGcj
 AYnN7oN985OCwW1xpKaOI9raI0oow3AtUZI5mWsCEultiK8ewjlPid8
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Register the Microchip ZL30643 (chip ID 0x0E3B), it is a 3 DPLL channel
of the ZL3073x family.

Once register, for instance, we get:

  devlink dev param set spi/spi0.0 name clock_id value 3733 cmode driverinit
  devlink dev reload spi/spi0.0
  devlink dev param set spi/spi2.1 name clock_id value 3643 cmode driverinit
  devlink dev reload spi/spi2.1

  dpll device show | grep clock-id
    clock-id: 3733
    clock-id: 3733
    clock-id: 3733
    clock-id: 3643
    clock-id: 3643
    clock-id: 3643

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 drivers/dpll/zl3073x/core.c | 1 +
 drivers/dpll/zl3073x/i2c.c  | 2 ++
 drivers/dpll/zl3073x/spi.c  | 2 ++
 3 files changed, 5 insertions(+)

diff --git a/drivers/dpll/zl3073x/core.c b/drivers/dpll/zl3073x/core.c
index 8e6416a4741d..4d07f69efb44 100644
--- a/drivers/dpll/zl3073x/core.c
+++ b/drivers/dpll/zl3073x/core.c
@@ -25,6 +25,7 @@
 
 static const struct zl3073x_chip_info zl3073x_chip_ids[] = {
 	ZL_CHIP_INFO(0x0E30, 2, ZL3073X_FLAG_REF_PHASE_COMP_32),
+	ZL_CHIP_INFO(0x0E3B, 3, ZL3073X_FLAG_REF_PHASE_COMP_32),
 	ZL_CHIP_INFO(0x0E93, 1, ZL3073X_FLAG_REF_PHASE_COMP_32),
 	ZL_CHIP_INFO(0x0E94, 2, ZL3073X_FLAG_REF_PHASE_COMP_32),
 	ZL_CHIP_INFO(0x0E95, 3, ZL3073X_FLAG_REF_PHASE_COMP_32),
diff --git a/drivers/dpll/zl3073x/i2c.c b/drivers/dpll/zl3073x/i2c.c
index 4a23340e29d0..f12c6306a85b 100644
--- a/drivers/dpll/zl3073x/i2c.c
+++ b/drivers/dpll/zl3073x/i2c.c
@@ -26,6 +26,7 @@ static int zl3073x_i2c_probe(struct i2c_client *client)
 }
 
 static const struct i2c_device_id zl3073x_i2c_id[] = {
+	{ .name = "zl30643" },
 	{ .name = "zl30731" },
 	{ .name = "zl30732" },
 	{ .name = "zl30733" },
@@ -36,6 +37,7 @@ static const struct i2c_device_id zl3073x_i2c_id[] = {
 MODULE_DEVICE_TABLE(i2c, zl3073x_i2c_id);
 
 static const struct of_device_id zl3073x_i2c_of_match[] = {
+	{ .compatible = "microchip,zl30643" },
 	{ .compatible = "microchip,zl30731" },
 	{ .compatible = "microchip,zl30732" },
 	{ .compatible = "microchip,zl30733" },
diff --git a/drivers/dpll/zl3073x/spi.c b/drivers/dpll/zl3073x/spi.c
index f024f42b78d0..d56c8d8ecc28 100644
--- a/drivers/dpll/zl3073x/spi.c
+++ b/drivers/dpll/zl3073x/spi.c
@@ -26,6 +26,7 @@ static int zl3073x_spi_probe(struct spi_device *spi)
 }
 
 static const struct spi_device_id zl3073x_spi_id[] = {
+	{ "zl30643" },
 	{ "zl30731" },
 	{ "zl30732" },
 	{ "zl30733" },
@@ -36,6 +37,7 @@ static const struct spi_device_id zl3073x_spi_id[] = {
 MODULE_DEVICE_TABLE(spi, zl3073x_spi_id);
 
 static const struct of_device_id zl3073x_spi_of_match[] = {
+	{ .compatible = "microchip,zl30643" },
 	{ .compatible = "microchip,zl30731" },
 	{ .compatible = "microchip,zl30732" },
 	{ .compatible = "microchip,zl30733" },

-- 
2.43.0

