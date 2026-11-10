From: Roman Vivchar <rva333@protonmail.com>
Subject: [PATCH v2 0/2] backlight: add ktd3137 support
Date: Tue, 10 Nov 2026 21:38:50 +0200
Message-Id: <20261110-6768-ktd3137-v2-0-9496c51efea4@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNyw6CMBBFf4XM2pq2QHms/A/DgpZBRqUlbSUaw
 r8LuHZ5knPPXSCgJwxQJwt4nCmQsxvIUwJmaO0NGXUbg+RSCcElU4Uq2SN2qUgLlqGpcq7KXqs
 Wtsnksaf3kbs2Pw4vfUcT98ZuDBSi85/jbxa79yc9C8aZznXWVzw1ucLL5F10dmzpeTZuhGZd1
 y9qvTASvwAAAA==
X-Change-ID: 20261102-6768-ktd3137-4ec95068fb6a
To: Lee Jones <lee@kernel.org>, Daniel Thompson <danielt@kernel.org>, 
 Jingoo Han <jingoohan1@gmail.com>, Pavel Machek <pavel@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Helge Deller <deller@gmx.de>
Cc: dri-devel@lists.freedesktop.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-fbdev@vger.kernel.org, Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794339538; l=1622;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=nVPDdJ3JnMVhs+SAbohUAkjVRUMXwv9zoHcS2AawkNI=;
 b=bt3HNbSrpPuheTayuYlq2Bjl/f+0v/HSyi6bV881yJEQ55J9Qa9EJ5lTTnU/OmIrmANGS0Ek/
 FmVRC16rKV6Ca6NaUYkguZj44iskIzDsrFCT4jHZx5m4HLzVYZBhpAM
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

 .../bindings/leds/backlight/kinetic,ktd3137.yaml   |  63 +++++
 MAINTAINERS                                        |   6 +
 drivers/video/backlight/Kconfig                    |  11 +
 drivers/video/backlight/Makefile                   |   1 +
 drivers/video/backlight/ktd3137.c                  | 258 +++++++++++++++++++++
 5 files changed, 339 insertions(+)
---
base-commit: 5e6de6a2b522f659defacb1551d0465ba6ce13cf
change-id: 20261102-6768-ktd3137-4ec95068fb6a

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

