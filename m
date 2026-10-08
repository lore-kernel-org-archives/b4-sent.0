From: Praveen Puglia <praveenpuglia@gmail.com>
Date: Thu, 08 Oct 2026 20:39:37 +0530
Subject: [PATCH] media: i2c: cvs: Leave the privacy LED to firmware on
 Synaptics SVP7xxx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-cvs-privacy-led-v1-1-b78d5c512cba@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqAIBBA0avErBtQg4yuEi1CxxoIkxGkkO6et
 HyL/ytkEqYMc1dBqHDmKzbovgN3bHEnZN8MRplRKzWhKxmTcNncgyd5tF4FMxjrBh2gVUko8P0
 fl/V9P+1l4LBhAAAA
X-Change-ID: 20261008-cvs-privacy-led-7d0f2327c31f
To: Miguel Vadillo <miguel.vadillo@intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mehdi Djait <mehdi.djait@linux.intel.com>
Cc: Marco Nenciarini <mnencia@kcore.it>, linux-media@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Praveen Puglia <praveenpuglia@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2309;
 i=praveenpuglia@gmail.com; h=from:subject:message-id;
 bh=HkOKW4kz9V77Mdvv3KELVLj5WUPOFOQXjEg6NNQFd4c=;
 b=owEBbQKS/ZANAwAKAY+nnsgxDLtBAcsmYgBqx7I0EjPpdtqo3fOlsDpQ/25VU/sHYrU9C62GA
 d9yuk5KIjyJAjMEAAEKAB0WIQQFOQz1fOStysPMknmPp57IMQy7QQUCaseyNAAKCRCPp57IMQy7
 QeZ7D/9A0UIBEfVNj5qNGFmEqbgQ3jjVB+0DkgqHFJ/mGb2ytLTE2vhZRdOcaKquBL8U3KzV3Sd
 pmst/g/+KIAWtPBJbQz40P7TsZtToOsZ9pwMJQtgI++BSBdhQ9dg6rCcEAevDxiqgHcmuB5JDst
 jsr6LMZCtcx9Vmzn4Wmj5bZIIRbXirGuK6yBx/bl6xoYSlBr8t5BAB9g9NTTqRmbTlAEBUZdmRZ
 tXZkUOIrBzfqQbjVVtXzsz3XGopcIXCeZ3efwsNH/KDboHONlhtgPCcvOuNnKXbfjXxdwo+cmcU
 DPWpP1KcuIOcrM/6bR+nZQQ/VwcF9g8KiC92Ae+YpI83jKSL8xRxWZGWHKC6zKcLJNVTLcNfUmq
 /2SO3Ip7bTDGaG8cYGvw5x+nWOSu2V8F/yIkwln002qwaUdBl8Q0FnCFmvEHmpcboG8nw8DcJw2
 XCBqHvc1AhxhgrHuqLhgPqiaNmoSww3F+HmSlPzsbNeuvs+pwKdS8TyZEVPsUYYhP4gjTK+mx1a
 iEOJM3UxAfFM9CzmsEl8/GxuiwrPZTUkU902VDWulWmQNxurlbA1UbTIFEURLQ6IiEApASVDZAv
 ZQgoDyWdsY8LT+aAez3PB86TZc3hXLRmt45ODdg005q0IfYZVokqzC4+C7RoEr6QlCbP8oRRXVb
 be9diTGXhgKLQKg==
X-Developer-Key: i=praveenpuglia@gmail.com; a=openpgp;
 fpr=05390CF57CE4ADCAC3CC92798FA79EC8310CBB41
X-Endpoint-Received: by B4 Relay for praveenpuglia@gmail.com/default with auth_id=1134
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Synaptics SVP7xxx (06cb:0701) quirk sets ICVS_HOST_PRIV_CTRL, so
SET_DEV_HOST_ID tells the CVS firmware that the host owns the privacy
LED. Nothing in the driver drives it, though: V4L2_CID_PRIVACY is a
read-only placeholder. The firmware then never turns the LED on and the
camera streams with the LED off.

The host has no way to drive it on these machines either. On the Dell
Pro Max 16 Premium (MA16250) the only camera LED that INT3472 exposes
is the IR flood LED. The out-of-tree Intel vision driver sends
privacy_led_host = 0 for this bridge, and the LED works there.

Drop ICVS_HOST_PRIV_CTRL from the quirk (quirks 0x7a -> 0x3a). The LED
now turns on while streaming and the stream is unaffected.

Tested on a Dell Pro Max 16 Premium (MA16250) with v7.2.8.

Fixes: 8e2b43d2c10b ("media: i2c: cvs: Add driver of Intel Computer Vision Sensing Controller(CVS)")
Cc: stable@vger.kernel.org
Link: https://github.com/intel/ipu6-drivers/issues/417
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Praveen Puglia <praveenpuglia@gmail.com>
---
This is my first kernel patch. I found and debugged this with an AI
assistant (Claude), then verified it myself on the laptop: quirks read
0x3a, the LED turns on and off with streaming, and the stream is
unchanged. Tested as a rebuilt module on Fedora's v7.2.8, not on
v7.3-rc.

Marco Nenciarini reproduced this on the same laptop with Debian and
v7.2.6, and found no host-controlled privacy LED pin in the DSDT/SSDTs:
https://github.com/intel/ipu6-drivers/issues/417#issuecomment-5996738346
---
 drivers/media/i2c/cvs/core.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/media/i2c/cvs/core.c b/drivers/media/i2c/cvs/core.c
index d4a3b9c3ba..3520325717 100644
--- a/drivers/media/i2c/cvs/core.c
+++ b/drivers/media/i2c/cvs/core.c
@@ -72,7 +72,6 @@ static const struct icvs_device_quirk cvs_quirk_table[] = {
 	},	/* Lattice NX33 */
 	{ 0x06CB, 0x0701, ICVS_SKIP_FW_RESET |
 			  ICVS_HOST_SENSOR_PWR_CTRL |
-			  ICVS_HOST_PRIV_CTRL |
 			  ICVS_FW_BUF_SIZE_256 |
 			  ICVS_FW_HEADER_SIZE_256
 	},	/* Synaptics SVP7xxx */

---
base-commit: 47324d3a5b3abd781295044d01d92d09f184e872
change-id: 20261008-cvs-privacy-led-7d0f2327c31f

Best regards,
-- 
Praveen Puglia <praveenpuglia@gmail.com>

