From: Roman Vivchar <rva333@protonmail.com>
Subject: [PATCH 0/2] media: pwm-ir-tx: regulator support
Date: Mon, 02 Nov 2026 17:22:55 +0200
Message-Id: <20261102-6768-irled-v1-0-c7064f3afed1@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ5AMBBA0avIrDVpS9pyFbEoBiOCtIikcXfF8
 i3+D+DREXookwAOT/K0LhEiTaAd7TIgoy4aJJdKCC6Z0sowcjN2rMBMmd5ak1sNMdgc9nR9s6r
 +7Y9mwnZ/D3DfD+eHIGtuAAAA
X-Change-ID: 20261102-6768-irled-9e368faa84a7
To: Sean Young <sean@mess.org>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>
Cc: linux-media@vger.kernel.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793632976; l=909;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=1Yz8iX3gDW/P2tgbVxR2nYPw4xtfogUB2xJ/TKPL5hs=;
 b=113z/dYN4qrLGSqf1+2d6F+mseuCwhk6lycW1Q0C0mqDlihLX8wKsQ//QBiP3qB/evPwZ5yPU
 RjjEdRsZaEWCDoBRX+Y8wYjGwJvuEQkn0cQLB0DkCS1h2h2ErZyN+RO
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds optional power-supply property for PWM IR LED,
because some boards, like Xiaomi Redmi Note 9 phone, have the LED
connected to the eMMC power rail. If the eMMC is powered down, IR LED
can't function.

Patch 1 adds dt-bindings documentation for the power-supply property.
Patch 2 adds regulator management to the driver.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
Roman Vivchar (2):
      dt-bindings: leds: irled: pwm-ir-tx: add power supply support
      media: pwm-ir-tx: add regulator support

 .../devicetree/bindings/leds/irled/pwm-ir-tx.yaml  |  4 +++
 drivers/media/rc/pwm-ir-tx.c                       | 37 +++++++++++++++++++++-
 2 files changed, 40 insertions(+), 1 deletion(-)
---
base-commit: 5e6de6a2b522f659defacb1551d0465ba6ce13cf
change-id: 20261102-6768-irled-9e368faa84a7

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

