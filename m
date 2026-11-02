From: Roman Vivchar <rva333@protonmail.com>
Subject: [PATCH 0/2] backlight: add ktd3137 support
Date: Mon, 02 Nov 2026 21:58:47 +0200
Message-Id: <20261102-6768-ktd3137-v1-0-b5b4f903c56e@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ5AMBBA4avIrDVpi/FzFbGgBkOCtIhE3F2x/
 BbvXeDIMjkoggssHex4mT1UGIAZ6rknwa03aKlRKakFppiJaWsjFaUiJpMnErOuwRp8slrq+Px
 2ZfXb7c1IZnsfcN8PWFwMyXAAAAA=
X-Change-ID: 20261102-6768-ktd3137-4ec95068fb6a
To: Lee Jones <lee@kernel.org>, Daniel Thompson <danielt@kernel.org>, 
 Jingoo Han <jingoohan1@gmail.com>, Pavel Machek <pavel@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Helge Deller <deller@gmx.de>
Cc: dri-devel@lists.freedesktop.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-fbdev@vger.kernel.org, Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793649528; l=1234;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=/mr61SqES4OjMu/nXS3z130f9tijC/yFjMxrAicySaA=;
 b=eOg774+CURNnDRRZWvxeH/ftUyYBMEG9OfIE/+kbBKDMtOdgJ7K7fvLw7iuJ8mEBo5eG3ZBM2
 XBAVbD8lPw2Cz19HqzYDCUkYfPTQt9XVioP5vvNwB6oypOePywXgGJo
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
Roman Vivchar (2):
      dt-bindings: leds: backlight: add Kinetic KTD3137
      backlight: add ktd3137 support

 .../bindings/leds/backlight/kinetic,ktd3137.yaml   |  64 +++++
 MAINTAINERS                                        |   6 +
 drivers/video/backlight/Kconfig                    |  11 +
 drivers/video/backlight/Makefile                   |   1 +
 drivers/video/backlight/ktd3137.c                  | 262 +++++++++++++++++++++
 5 files changed, 344 insertions(+)
---
base-commit: 5e6de6a2b522f659defacb1551d0465ba6ce13cf
change-id: 20261102-6768-ktd3137-4ec95068fb6a

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

