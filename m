From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH 0/3] usb: ehci-generic: setup a bulk of phy when possible
Date: Thu, 01 Feb 2024 21:16:07 +0800
Message-Id: <20240201-ehci-v1-0-bb506cb0f64d@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJeZu2UC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDIwND3dSM5Exds2TjxETzFEtzS2MjJaDSgqLUtMwKsDHRsbW1AGJ0p4p
 WAAAA
To: Tom Rini <trini@konsulko.com>, Simon Glass <sjg@chromium.org>, 
 Marek Vasut <marex@denx.de>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706793368; l=837;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=QMfwBw1MGvgmX+baE1mQW7yqLnFCwlhOHl1tI9+cRFg=;
 b=AcptH8CJIHYl6WPhhwqTXaRNTKyPseQaeOnOYgZ81rpcLuozTj6WD/+UYkZahlWe5zhqP4iiD
 1ePLJJACsQqBeRf9X1IWv15iUEcDiDsKtAVgIxZ9CnqGZVl1eCmE6cI
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

one USB controller can have multiple ports specified in dts, all of them
should be setup to make use of all possible ports.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Yang Xiwen (3):
      phy: add generic_setup(shutdown)_phy_bulk()
      test: phy: test generic_setup(shutdown)_phy_bulk()
      usb: ehci: Make usage of generic_{setup,shutdown}_phy_bulk() helpers

 drivers/phy/phy-uclass.c        | 33 +++++++++++++++++++++++++++++++++
 drivers/usb/host/ehci-generic.c |  8 ++++----
 include/generic-phy.h           | 29 +++++++++++++++++++++++++++++
 test/dm/phy.c                   |  4 ++++
 4 files changed, 70 insertions(+), 4 deletions(-)
---
base-commit: b6d8969bcb94321dfed1399f2eaa8768ba42caaa
change-id: 20240201-ehci-6c3aa7d97932

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

