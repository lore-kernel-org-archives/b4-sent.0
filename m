From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Subject: [PATCH v2 0/3] usb: typec: add Rohm BM92TXX Type-C / PD controller
 driver
Date: Mon, 11 May 2026 01:32:08 +0700
Message-Id: <20260511-bm92t-v2-0-2145e4f4386b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/12NQQ6CMBBFr0JmbU07VbSuvIdhAe0UxlgwLTYaw
 t0F3Ll8yfvvT5AoMiW4FBNEypx46BfAXQG2q/uWBLuFASWW8qikaILBUejTuVbGam1Iw+I+I3l
 +b51b9eP0au5kx3W8Gh2ncYif7Sir1ftvZiWkcN5raxziActrG2p+7O0QoJrn+Qs/7YNLrAAAA
 A==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778437929; l=1928;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=zhf2v3Fxq81QYgVX0wuET1y38n//e4jTE1V3yZEXPG4=;
 b=kFodGNoh7i42PTlga1DXS3gjvphT79mvS9m5p75ugk5y5GXgzHHPClLOLam0RuCgVuBM4mAy3
 RklHpfzsM9ZCgNPfH+x+UBZgY2pCo409RZsHT3zcVQoyy0j5C6DFK3R
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
Changes in v2:
- dt-bindings: usb: rohm,bm92t: fix properties type
- Link to v1: https://patch.msgid.link/20260510-bm92t-v1-0-dff3c9d22426@gmail.com

To: Heikki Krogerus <heikki.krogerus@linux.intel.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
To: CTCaer <ctcaer@gmail.com>
To: Alexandre Hamamdjian <azkali.limited@gmail.com>
To: Linus Walleij <linusw@kernel.org>
To: Bartosz Golaszewski <brgl@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org
Cc: linux-usb@vger.kernel.org
Cc: linux-gpio@vger.kernel.org
Cc: devicetree@vger.kernel.org

---
Alexandre Hamamdjian (2):
      dt-bindings: usb: add Rohm BM92TXX Type-C controller
      dt-bindings: usb: fix properties type

CTCaer (1):
      usb: typec: bm92txx: add Rohm BM92TXX support

 .../devicetree/bindings/usb/rohm,bm92t.yaml        |  132 +
 MAINTAINERS                                        |    8 +
 drivers/usb/typec/Kconfig                          |   11 +
 drivers/usb/typec/Makefile                         |    1 +
 drivers/usb/typec/bm92txx.c                        | 2634 ++++++++++++++++++++
 5 files changed, 2786 insertions(+)
---
base-commit: e98d21c170b01ddef366f023bbfcf6b31509fa83
change-id: 20260510-bm92t-378a19c339e3

Best regards,
--  
Alexandre Hamamdjian <azkali.limited@gmail.com>

