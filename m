From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Subject: [PATCH 00/13] media: i2c: imx214: Miscellaneous cleanups and
 improvements
Date: Mon, 02 Sep 2024 23:54:27 +0200
Message-Id: <20240902-imx214-v1-0-c96cba989315@apitzsch.eu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIABM01mYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDC0ML3czcCiNDE10LYyMTcwuTZPOk1FQloOKCotS0zAqwQdGxtbUAjcG
 iblgAAAA=
To: Ricardo Ribalda <ribalda@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725314079; l=1440;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=fkLGY4U5lk/Rad59LcWYJhIpX0ElWK9FM/qu8thACn4=;
 b=E/Uhb4OXlg2lmNafSJOLnsbDj7RCoODhTb3s5BxODnAqUXPumwIW+Y+dbgrwiwHRTIBnozf5C
 UnTyBygQ/96C+y/xVYJlBGSDhYUg+BK+fyPZhsLZaxVOnPWhKWWDzXr
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series is a collection of miscellaneous cleanups and
improvements to the imx214 driver.

The series converts the driver to the CCI helpers and adds controls
needed to make the driver work with libcamera.

The changes are inspired by the imx219 driver.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
André Apitzsch (13):
      media: i2c: imx214: Use subdev active state
      media: i2c: imx214: Remove unneeded goto
      media: i2c: imx214: Simplify with dev_err_probe()
      media: i2c: imx214: Convert to CCI register access helpers
      media: i2c: imx214: Replace register addresses with macros
      media: i2c: imx214: Drop IMX214_REG_EXPOSURE from mode reg arrays
      media: i2c: imx214: Use number of lanes from device tree
      media: i2c: imx214: Add vblank and hblank controls
      media: i2c: imx214: Extract format and crop settings
      media: i2c: imx214: Implement vflip/hflip controls
      media: i2c: imx214: Add analogue/digital gain control
      media: i2c: imx214: Verify chip ID
      media: i2c: imx214: Add test pattern control

 drivers/media/i2c/Kconfig  |    1 +
 drivers/media/i2c/imx214.c | 1313 +++++++++++++++++++++++++++-----------------
 2 files changed, 803 insertions(+), 511 deletions(-)
---
base-commit: b891f84dd1f93ef4a716f10a70da80db443db431
change-id: 20240818-imx214-8324784c7bee

Best regards,
-- 
André Apitzsch <git@apitzsch.eu>

