From: Roman Vivchar <rva333@protonmail.com>
Subject: [PATCH v3 0/2] backlight: add ktd3137 support
Date: Tue, 17 Nov 2026 19:40:57 +0200
Message-Id: <20261117-6768-ktd3137-v3-0-b4fd957e3b00@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XNTQ7CIBCG4asY1mL4aWlx5T2MC6BTi9rSABJN0
 7tL68ZoXL7JN89MKIC3ENB+MyEPyQbrhhx8u0GmU8MZsG1yI0aYoJQwLCpR42tsOOUVLsDIkoi
 61UKhfDJ6aO1j5Y6nd4e7voCJi7EsOhui88/1X6LL7g+dKCZYl7poJeGmFHAYvYtu6JW97Yzr0
 eIn9iFQ8iWwLMhCClNSaEEVP8I8zy+sGjsXAQEAAA==
X-Change-ID: 20261102-6768-ktd3137-4ec95068fb6a
To: Lee Jones <lee@kernel.org>, Daniel Thompson <danielt@kernel.org>, 
 Jingoo Han <jingoohan1@gmail.com>, Pavel Machek <pavel@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Helge Deller <deller@gmx.de>
Cc: dri-devel@lists.freedesktop.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-fbdev@vger.kernel.org, Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794937267; l=1886;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=FSVxmo57BknMiKWx0HlL7rvM1SWImH1ToEyr5Lg5KGA=;
 b=6xP59/Y/AqYpXNqfijQP8uk+tItfqsnD/vfknkIo3xT6XvOWTesQ/9sLKcMSIUDVjHwFf5zuP
 CVa7id8j4z9C+ndMYh7N5W4ZntdP/oHZI02bEPzdMo6rJGO3juJZXtN
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds support for Kinetic KTD3137 backlight IC. It
supports linear brightness range from 0 to 2047.

While the chip supports PWM and MSB modes, they weren't included, since
MSB mode supports only 8-bit brightness range, and PWM is not enabled on
this board. I have checked other Xiaomi vendor kernels, and their
configuration appear to be the same as on my board. I'm not aware if any
device uses PWM mode with this chip.

This series was developed and tested on the Xiaomi Redmi Note 9 board.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
Changes in v3:
- dt-bindings: bring back vin-supply (Krzysztof)
- Driver:
    - Move enable_gpio from the struct to local variable
    - Use .name for i2c match (Sashiko)
- Link to v2: https://patch.msgid.link/20261110-6768-ktd3137-v2-0-9496c51efea4@protonmail.com

Changes in v2:
- dt-bindings: drop vin-supply from required list (Daniel)
- Driver:
    - Drop val variable in ktd3137_init() (Daniel)
    - Replace KTD3137_DEFAULT_BRIGHTNESS with KTD3137_MAX_BRIGHTNESS (Daniel)
    - Drop gpiod_set_value_cansleep() in ktd3137_remove() (Daniel)
- Link to v1: https://patch.msgid.link/20261102-6768-ktd3137-v1-0-b5b4f903c56e@protonmail.com

---
Roman Vivchar (2):
      dt-bindings: leds: backlight: add Kinetic KTD3137
      backlight: add ktd3137 support

 .../bindings/leds/backlight/kinetic,ktd3137.yaml   |  64 +++++
 MAINTAINERS                                        |   6 +
 drivers/video/backlight/Kconfig                    |  11 +
 drivers/video/backlight/Makefile                   |   1 +
 drivers/video/backlight/ktd3137.c                  | 257 +++++++++++++++++++++
 5 files changed, 339 insertions(+)
---
base-commit: 5e6de6a2b522f659defacb1551d0465ba6ce13cf
change-id: 20261102-6768-ktd3137-4ec95068fb6a

Best regards,
--  
rva3 <rva333@protonmail.com>

