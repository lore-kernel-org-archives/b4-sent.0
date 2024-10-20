From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Subject: [PATCH v2 00/13] media: i2c: imx214: Miscellaneous cleanups and
 improvements
Date: Mon, 21 Oct 2024 00:13:20 +0200
Message-Id: <20241021-imx214-v2-0-fbd23e99541e@apitzsch.eu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAICAFWcC/zXMQQ6CMBCF4auQWVvTDlVaV97DsCh1tLMQSIsNS
 ri7FePyf3n5FkgUmRKcqgUiZU489CVwV4EPrr+T4GtpQIlaGmUEP2ZUWpgadWO0bzoiKOcx0o3
 nDbq0pQOnaYivzc3qu/4IK/FPZCWk8PboO2eNrdXh7Eae3smHPT2hXdf1A48vnBeeAAAA
X-Change-ID: 20240818-imx214-8324784c7bee
To: Ricardo Ribalda <ribalda@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>, 
 Ricardo Ribalda <ribalda@chromium.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729462449; l=2197;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=Gl8hfYn2T/YTDKU4HaLJgS6y5RrOxB6rv+1XIPta0Pk=;
 b=Lh4y4Jql8cRhJZudqunmzS9M2VT+jXR8X11Va+js09+iFftk5tan5RJTyKBOBCLzcH1/nDj5k
 kCBUOckAF/mBdKlR/anlLsjPdAqjcCFpUA2VTtdMs7W+UW4r8SfYKfx
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
Changes in v2:
- Add patch to fix link frequency
- Don't use and remove fmt and crop from struct imx214
- Squash patch 1/13 and 2/13
- Only check if #lanes == 4
- Add comment that enum_frame_interval() shouldn't be used by userspace
- Set V4L2_CID_VBLANK step size to 2 (according to datasheet Table 4-4)
- Increase IMX214_VBLANK_MIN to limit max frame rate of full resolution
  to the documented 30 fps
- As bpp is always 10, simplify setting IMX214_REG_CSI_DATA_FORMAT and
  IMX214_REG_OPPXCK_DIV
- Simplify imx214_get_format_code()
- Cluster hflip and vflip
- Remove kernel log note from 11/13, issue was fixed by a kernel update
- Add A-b tags
- Link to v1: https://lore.kernel.org/r/20240902-imx214-v1-0-c96cba989315@apitzsch.eu

---
André Apitzsch (13):
      media: i2c: imx214: Fix link frequency
      media: i2c: imx214: Use subdev active state
      media: i2c: imx214: Simplify with dev_err_probe()
      media: i2c: imx214: Convert to CCI register access helpers
      media: i2c: imx214: Replace register addresses with macros
      media: i2c: imx214: Drop IMX214_REG_EXPOSURE from mode reg arrays
      media: i2c: imx214: Check number of lanes from device tree
      media: i2c: imx214: Add vblank and hblank controls
      media: i2c: imx214: Extract format and crop settings
      media: i2c: imx214: Implement vflip/hflip controls
      media: i2c: imx214: Add analogue/digital gain control
      media: i2c: imx214: Verify chip ID
      media: i2c: imx214: Add test pattern control

 drivers/media/i2c/Kconfig  |    1 +
 drivers/media/i2c/imx214.c | 1320 +++++++++++++++++++++++++++-----------------
 2 files changed, 800 insertions(+), 521 deletions(-)
---
base-commit: dc492038a748d54f9be2a31a629c44710989034c
change-id: 20240818-imx214-8324784c7bee

Best regards,
-- 
André Apitzsch <git@apitzsch.eu>

