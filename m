From: Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>
Subject: [PATCH 0/2] pinctrl: mcp23s08: Enable gpio-line-names for
 multi-chip configurations
Date: Tue, 13 Jan 2026 15:29:46 +0100
Message-Id: <20260113-mcp23s17-multiple-addr-names-v1-0-f14b60f92c82@yoseli.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANpWZmkC/yXMwQrCMAwA0F8ZORtY0qHor4iHro0aWWtpNhHG/
 t2qx3d5K5hUFYNTt0KVl5o+cwPtOgh3n2+CGpuBe973RIwpFHZGB0zLNGuZBH2MFbNPYjiwoyF
 E73g8QitKlau+f/358rct40PC/D1h2z7D/Q9VgAAAAA==
X-Change-ID: 20260112-mcp23s17-multiple-addr-names-42314cda32b9
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Himanshu Bhavani <himanshu.bhavani@siliconsignals.io>
Cc: linux-gpio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768314588; l=1719;
 i=jeanmichel.hautbois@yoseli.org; s=20240925; h=from:subject:message-id;
 bh=06Yl975+vnTWDTbPJXQ82WwbzE0P4Eyw/LDsEzrePRY=;
 b=1/HWneVKW6gV+ahQYeOezXywv6G3CSjoZ1lg4NnL5HHkiseUKQgW0jOTczZO5kHetRxCRRt7l
 h9wkVYcAhslD6iQCtwWw4Fdn9CLlWFRksF6apC15Bo3lsQ1K+qBVZ1t
X-Developer-Key: i=jeanmichel.hautbois@yoseli.org; a=ed25519;
 pk=MsMTVmoV69wLIlSkHlFoACIMVNQFyvJzvsJSQsn/kq4=
X-Endpoint-Received: by B4 Relay for jeanmichel.hautbois@yoseli.org/20240925 with auth_id=570
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MCP23S08/17/18 SPI driver supports multiple GPIO expander chips
sharing the same SPI chip select via hardware address pins (A0-A2).
However, the gpio-line-names device tree property could not be used in
these configurations because all gpio_chip instances tried to use names
starting at index 0.

This series enables gpio-line-names support by setting gpio_chip.offset
for each chip based on cumulative GPIO count.

Example device tree usage:
    gpio@0 {
        compatible = "microchip,mcp23s17";
        microchip,spi-present-mask = /bits/ 8 <0x03>;  /* chips 0 and 1 */
        gpio-line-names =
            /* Chip 0: 16 names */
            "EXP0_A0", "EXP0_A1", ..., "EXP0_B7",
            /* Chip 1: 16 names */
            "EXP1_A0", "EXP1_A1", ..., "EXP1_B7";
    };

Patch 1 implements the driver change (9 lines added).
Patch 2 adds documentation with a complete example.

Testing:
- Verified on AM64x hardware with 2 MCP23S17 chips at addresses 1 and 2
- Confirmed gpio-line-names appear correctly in gpioinfo output
- Each chip's 16 GPIOs receive the correct sequential names

Signed-off-by: Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>
---
Jean-Michel Hautbois (2):
      pinctrl: mcp23s08: support gpio-line-names
      dt-bindings: pinctrl: mcp23s08: Add multi-chip example

 .../bindings/pinctrl/microchip,mcp23s08.yaml       | 33 ++++++++++++++++++++++
 drivers/pinctrl/pinctrl-mcp23s08_spi.c             |  4 +++
 2 files changed, 37 insertions(+)
---
base-commit: 0f61b1860cc3f52aef9036d7235ed1f017632193
change-id: 20260112-mcp23s17-multiple-addr-names-42314cda32b9

Best regards,
--  
Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>

