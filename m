From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Subject: [PATCH 0/2] usb: typec: add Rohm BM92TXX Type-C / PD controller
 driver
Date: Sun, 10 May 2026 23:08:53 +0700
Message-Id: <20260510-bm92t-v1-0-dff3c9d22426@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDU0MD3aRcS6MSXWNzi0RDy2RjY8tUYyWg2oKi1LTMCrA50bEQfnFpUlZ
 qcglIs1JtLQBYUa82aQAAAA==
X-Change-ID: 20260510-bm92t-378a19c339e3
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, CTCaer <ctcaer@gmail.com>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-usb@vger.kernel.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 Alexandre Hamamdjian <azkali.limited@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778429339; l=1198;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=wfHMaPVrKZ/CnHd2SjBdGDvMgPBPVKrMvAzVQG74mw4=;
 b=REsPFHgjcoHND/C70+ey/FApHgnxXCkQO4GaIsf4qjx7zf5Ah/DseTUQfjvUrhp8TxB1assci
 RFHuC6TxolQCm5SE1mpimcRyihDWI2KeGk0zx98PSSTDldp4yndSpRb
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds initial support for the Rohm Semiconductor BM92TXX
family of USB Type-C and Power Delivery controllers.

This chipset is found on Nintendo Switch hardware, where it handles
charger and dock USB-C / PD negotiation, DisplayPort alternate-mode
entry through the dock and VBUS / VCONN control.

Further patches will follow to wire the driver up on Nintendo Switch
device trees and to address review feedback.

Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
---
Alexandre Hamamdjian (1):
      dt-bindings: usb: add Rohm BM92TXX Type-C controller

CTCaer (1):
      usb: typec: bm92txx: add Rohm BM92TXX support

 .../devicetree/bindings/usb/rohm,bm92t.yaml        |  128 +
 MAINTAINERS                                        |    8 +
 drivers/usb/typec/Kconfig                          |   11 +
 drivers/usb/typec/Makefile                         |    1 +
 drivers/usb/typec/bm92txx.c                        | 2634 ++++++++++++++++++++
 5 files changed, 2782 insertions(+)
---
base-commit: e98d21c170b01ddef366f023bbfcf6b31509fa83
change-id: 20260510-bm92t-378a19c339e3

Best regards,
--  
Alexandre Hamamdjian <azkali.limited@gmail.com>

