From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH 0/3] usb: dwv3: add glue driver for hi3798mv200
Date: Sat, 03 Feb 2024 07:01:53 +0800
Message-Id: <20240203-hisi-dwc3-v1-0-448050c7b690@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGF0vWUC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDIwNj3QygEt2U8mRjXeNkE/M0c2OT5BQjAyWg+oKi1LTMCrBZ0bG1tQC
 1bbUZWwAAAA==
To: Marek Vasut <marex@denx.de>, Tom Rini <trini@konsulko.com>, 
 Sean Anderson <sean.anderson@seco.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706914914; l=704;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=XfSE37beJzpzPrXF96yeMvNm267FWmYb60Dr6neV8/I=;
 b=oo7IHJM8FAyP0vjIEzi8+e+F+IzUCsnlaoSxQQskPBaHhWW+g9Mvnjj/j7BULcS7s2NAUw46+
 WzfVaXiCWEfDv502OZTDg7QriojAUOlEkNuq4gP5HHC1KXLA8BvaPxr
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Also edit the prototype of .glue_configure to fulfill our needs.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Yang Xiwen (3):
      usb: dwc3: handle return value of clk_get_rate() correctly
      usb: dwc3: replace argument mode with child ofnode
      usb: dwc3: add glue driver for Hi3798MV200

 drivers/usb/dwc3/core.c         |  2 +-
 drivers/usb/dwc3/dwc3-generic.c | 52 ++++++++++++++++++++++++++++++++++-------
 drivers/usb/dwc3/dwc3-generic.h |  3 +--
 3 files changed, 46 insertions(+), 11 deletions(-)
---
base-commit: 050a9b981d6a835133521b599be3ae189ce70f41
change-id: 20240203-hisi-dwc3-3c47f734cd20

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

