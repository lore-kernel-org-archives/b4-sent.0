From: Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>
Date: Tue, 13 Jan 2026 15:29:47 +0100
Subject: [PATCH 1/2] pinctrl: mcp23s08: support gpio-line-names
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260113-mcp23s17-multiple-addr-names-v1-1-f14b60f92c82@yoseli.org>
References: <20260113-mcp23s17-multiple-addr-names-v1-0-f14b60f92c82@yoseli.org>
In-Reply-To: <20260113-mcp23s17-multiple-addr-names-v1-0-f14b60f92c82@yoseli.org>
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Himanshu Bhavani <himanshu.bhavani@siliconsignals.io>
Cc: linux-gpio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768314588; l=1684;
 i=jeanmichel.hautbois@yoseli.org; s=20240925; h=from:subject:message-id;
 bh=QFjSY0s5khZXPkC3pGl32aLWJsaAHDlYMLi07GfN99c=;
 b=mUhgWjNV40Q/PX355Gyy729hsSTSUpMGhEeAPChUIFa6DDGqDTW//CI8B4aFHksjn9EkCpP34
 uA3rblN76FJAPryM4srND8rPZYsBxBXX0qlmPG70ISov4lCFAMV1UXW
X-Developer-Key: i=jeanmichel.hautbois@yoseli.org; a=ed25519;
 pk=MsMTVmoV69wLIlSkHlFoACIMVNQFyvJzvsJSQsn/kq4=
X-Endpoint-Received: by B4 Relay for jeanmichel.hautbois@yoseli.org/20240925 with auth_id=570
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MCP23S08/17/18 SPI driver supports multiple chips sharing the same
SPI chip select by using the hardware address pins (A0-A2). Each chip
gets its own gpio_chip instance, but they all share the parent device
tree node.

Without setting gpio_chip.offset, the gpio-line-names property cannot
be used because gpiolib assigns all chips names starting at index 0.
Set offset based on cumulative GPIO count to enable sequential
gpio-line-names in device tree:

    microchip,spi-present-mask = /bits/ 8 <0x03>;  /* chips 0 and 1 */
    gpio-line-names =
        /* Chip 0: 16 names */
        "EXP0_A0", "EXP0_A1", ..., "EXP0_B7",
        /* Chip 1: 16 names */
        "EXP1_A0", "EXP1_A1", ..., "EXP1_B7";

Signed-off-by: Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>
---
 drivers/pinctrl/pinctrl-mcp23s08_spi.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/pinctrl/pinctrl-mcp23s08_spi.c b/drivers/pinctrl/pinctrl-mcp23s08_spi.c
index 54f61c8cb1c0..105efc85c3e7 100644
--- a/drivers/pinctrl/pinctrl-mcp23s08_spi.c
+++ b/drivers/pinctrl/pinctrl-mcp23s08_spi.c
@@ -141,6 +141,7 @@ static int mcp23s08_probe(struct spi_device *spi)
 	unsigned long spi_present_mask;
 	unsigned int ngpio = 0;
 	unsigned int addr;
+	unsigned int line_offset = 0;
 	int chips;
 	int ret;
 	u32 v;
@@ -178,6 +179,9 @@ static int mcp23s08_probe(struct spi_device *spi)
 		if (ret)
 			return ret;
 
+		data->mcp[addr]->chip.offset = line_offset;
+		line_offset += data->mcp[addr]->chip.ngpio;
+
 		data->mcp[addr]->pinctrl_desc.name = devm_kasprintf(dev, GFP_KERNEL,
 								    "mcp23xxx-pinctrl.%d",
 								    addr);

-- 
2.39.5

