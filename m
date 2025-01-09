From: "Vasiliy Doylov (NekoCWD)" <nekodevelopper@gmail.com>
Subject: [PATCH v3 0/4] Input: cyttsp5 - improve error handling and remove
 regmap
Date: Fri, 10 Jan 2025 00:37:46 +0300
Message-Id: <20250110-nekocwd-upstreaming-cyttsp5-v3-0-b33659c8effc@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKpBgGcC/x3MSw6DIBAA0KuYWXcSQIyfqzRdWBh10hQJQ9XGe
 PeSLt/mnSCUmASG6oREGwuvoaC+VeCWMcyE7IvBKNMorRUGeq1u9/iJkhONbw4zum/OEht8dpZ
 8r03rrIUyxEQTH//9/riuHz/WO91tAAAA
X-Change-ID: 20250110-nekocwd-upstreaming-cyttsp5-b84ed9127c44
To: Linus Walleij <linus.walleij@linaro.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 James Hilliard <james.hilliard1@gmail.com>, 
 "Vasiliy Doylov (NekoCWD)" <nekodevelopper@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1482;
 i=nekodevelopper@gmail.com; h=from:subject:message-id;
 bh=iDynsn5T3AIRd0fuaDAF6TG+oOSwkul/fDifxm3P8PY=;
 b=owGbwMvMwCW2fZ/SFZeSpU2Mp9WSGNIbHM9Unat0yl1SotVazH38coXUp96chqyt7lukbZTMb
 wbUup7sKGVhEONikBVTZLHZ6DFbLD9cctK0pwowc1iZQIYwcHEKwER8mBkZHnfG/XJ80TjtUcu5
 UvkP90/5cf+Yf8FywtP1H3/cXFynV8/w318qWawzVfJ578UT/yMvcG17GiHr6moaXZwevuxAkrw
 vBwA=
X-Developer-Key: i=nekodevelopper@gmail.com; a=openpgp;
 fpr=3CB1489B166F57199296E520B7BE22D44474A582
X-Endpoint-Received: by B4 Relay for nekodevelopper@gmail.com/default with auth_id=314
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The vendor cyttsp5 driver does not use regmap for i2c support, it
would appear this is due to regmap not providing sufficient levels
of control to handle various error conditions that may be present
under some configuration/firmware variants.

To improve reliability lets refactor the cyttsp5 i2c interface to
function more like the vendor driver and implement some of the error
handling retry/recovery techniques present there.

As part of this rather than assuming the device is in bootloader mode
we should first check that the device is in bootloader and only
attempt to launch the app if it actually is in the bootloader.

Co-developed-by: James Hilliard <james.hilliard1@gmail.com>
Signed-off-by: James Hilliard <james.hilliard1@gmail.com>
Signed-off-by: Vasiliy Doylov (NekoCWD) <nekodevelopper@gmail.com>
---
Changes v1 -> v2:
  - remove unused reg variable
Changes v2 -> v3:
  - splitted commit
---

---
Vasiliy Doylov (NekoCWD) (4):
      input: cyttsp5: improve error handling
      input: cyttsp5: improve read size
      input: cyttsp5: use raw i2c instead of regmap
      input: cyttsp5: add startup retry

 drivers/input/touchscreen/cyttsp5.c | 257 +++++++++++++++++++++++-------------
 1 file changed, 168 insertions(+), 89 deletions(-)
---
base-commit: 6ecd20965bdc21b265a0671ccf36d9ad8043f5ab
change-id: 20250110-nekocwd-upstreaming-cyttsp5-b84ed9127c44

Best regards,
-- 
Vasiliy Doylov (NekoCWD) <nekodevelopper@gmail.com>

