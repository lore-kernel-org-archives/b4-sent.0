From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Subject: [PATCH v4 00/13] media: i2c: imx214: Miscellaneous cleanups and
 improvements
Date: Mon, 16 Dec 2024 22:00:46 +0100
Message-Id: <20241216-imx214-v4-0-8cbda160fbce@apitzsch.eu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAP6UYGcC/2XN0Q6CIBTG8VdpXEeDAwp01Xu0LgCPyUXqxJzlf
 PfQlm11+Z3x+zORiF3ASI67iXQ4hBiaOg253xFf2fqKNBRpE2AgmeaahtsIXFItQCotvXKIJD1
 uOyzDuIbOl7SrEPume6zdgS/Xd8Iw+CQGThn1JvfOGm0Ez062Df0z+uqAd7JEBtggZ8A3CAmWr
 gCBxmSS4z8UXwhMbVAkaF3ObKkQze+P8zy/ABnu8h0QAQAA
X-Change-ID: 20240818-imx214-8324784c7bee
To: Ricardo Ribalda <ribalda@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Vincent Knecht <vincent.knecht@mailoo.org>, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>, 
 Ricardo Ribalda <ribalda@chromium.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734382889; l=3433;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=6cmEGBmf36veit8RAD1wqzyDYYwOBtBNXEx1H15Ah0M=;
 b=EHfC7AL8dJQADMDbAL4P/CKLIviut5r5NixmWIuMRzSFr0QF5xle8MOcbtWRbgGRlNhqxrhd6
 jaevR7sxKU1BAURvSXgndxBaI1vxq45lb2HDpA7I3QTj+28r3K+h+On
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
Changes in v4:
- Drop function name from dev error message
- Initialize *format to fix compile error
- Improve comment "Update {FPS -> blank} limit"
- Improve code formatting
- Warn once on usage of frame_interval functions
- Fix commit message
- Add patch to fix clock handling on probe error or remove
- Warn if number of DT provided link frequencies != 1
- Add A-b tags
- Link to v3: https://lore.kernel.org/r/20241207-imx214-v3-0-ab60af7ee915@apitzsch.eu

Changes in v3:
- Also keep previous link freq for backward compatibility
- Move link freq patch to the end of the series
- Remove return-early check from imx214_set_format()
- Remove unneeded struct imx214 function parameter
- Use correct ret value on number of data lanes error
- Revert changing order (imx214_parse_fwnode, devm_kzalloc)
- Fix typo
- Remove unused definition IMX214_EXPOSURE_MAX
- Don't set FPS to default
- Simplify exposure_def definition
- Set state and format only if control id is V4L2_CID_VBLANK
- Restore Ricardo's message to Sony
- Drop "media: i2c: imx214: Extract format and crop settings" patch
- Add A-b tag
- Link to v2: https://lore.kernel.org/r/20241021-imx214-v2-0-fbd23e99541e@apitzsch.eu

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
      media: i2c: imx214: Use subdev active state
      media: i2c: imx214: Simplify with dev_err_probe()
      media: i2c: imx214: Convert to CCI register access helpers
      media: i2c: imx214: Replace register addresses with macros
      media: i2c: imx214: Drop IMX214_REG_EXPOSURE from mode reg arrays
      media: i2c: imx214: Check number of lanes from device tree
      media: i2c: imx214: Add vblank and hblank controls
      media: i2c: imx214: Implement vflip/hflip controls
      media: i2c: imx214: Add analogue/digital gain control
      media: i2c: imx214: Verify chip ID
      media: i2c: imx214: Add test pattern control
      media: i2c: imx214: Fix clock handling on probe error or remove
      media: i2c: imx214: Fix link frequency validation

 drivers/media/i2c/Kconfig  |    1 +
 drivers/media/i2c/imx214.c | 1267 ++++++++++++++++++++++++++------------------
 2 files changed, 753 insertions(+), 515 deletions(-)
---
base-commit: 62f608176a46b6a794725022101d0d7f42faedb9
change-id: 20240818-imx214-8324784c7bee

Best regards,
-- 
André Apitzsch <git@apitzsch.eu>

