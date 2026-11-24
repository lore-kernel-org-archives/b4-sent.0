From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Tue, 24 Nov 2026 11:04:46 +0800
Subject: [PATCH v2 9/9] media: uapi: it6625: remove the driver-specific
 audio controls
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-upstream-it6625-alsa-i2s-v2-9-a154685f6989@ite.com.tw>
References: <20261124-upstream-it6625-alsa-i2s-v2-0-a154685f6989@ite.com.tw>
In-Reply-To: <20261124-upstream-it6625-alsa-i2s-v2-0-a154685f6989@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Mark Brown <broonie@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, linux-sound@vger.kernel.org, 
 linux-api@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795489507; l=3311;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=6SaU9xnFrmm0KhiPbAskmhGNEZNumQBEu9u4f3AH160=;
 b=BAF4d0WKa6m7EEPENgMldLYWOoxoUUZsbvuud3OlhwNDeSnAPzjoGBpI2m/N8+abxbK/7agEh
 ZsMZNFek1jeCXHiX9vqtH7Te2rsnLkPE3Z23g4WUhyuhc3PRbxfeAFd
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

V4L2_CID_IT6625_AUDIO_SAMPLING_RATE and V4L2_CID_IT6625_AUDIO_PRESENT
have been replaced by the standard V4L2_CID_DV_RX_AUDIO_SAMPLING_RATE
and V4L2_CID_DV_RX_AUDIO_PRESENT controls, and the driver no longer uses
them. They were added together with the driver and are not part of any
released kernel yet.

Remove the uAPI header and the V4L2_CID_USER_IT6625_BASE reservation.
---
 MAINTAINERS                        |  1 -
 drivers/media/i2c/it6625.c         |  1 -
 include/uapi/linux/it6625.h        | 25 -------------------------
 include/uapi/linux/v4l2-controls.h |  6 ------
 4 files changed, 33 deletions(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index f4456f4589a1b86b140ab578d149884d46a3320a..a7a315f0e80585be26fe2b52a62c19e469cb5703 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -14271,7 +14271,6 @@ S:	Maintained
 T:	git git://linuxtv.org/media.git
 F:	Documentation/devicetree/bindings/media/i2c/ite,it6625.yaml
 F:	drivers/media/i2c/it6625.c
-F:	include/uapi/linux/it6625.h
 
 IVTV VIDEO4LINUX DRIVER
 M:	Andy Walls <awalls@md.metrocast.net>
diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index e4487e8111b94b2fa9f599e37ecd2b8a11425862..64c1cec26edfcb0e0105e00e1b7ba5960252aae7 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -33,7 +33,6 @@
 #include <sound/pcm.h>
 #include <sound/pcm_params.h>
 #include <sound/soc.h>
-#include <uapi/linux/it6625.h>
 
 static int debug;
 module_param(debug, int, 0644);
diff --git a/include/uapi/linux/it6625.h b/include/uapi/linux/it6625.h
deleted file mode 100644
index a895658aaf6a80d3fb624cdece33c5135161c72d..0000000000000000000000000000000000000000
--- a/include/uapi/linux/it6625.h
+++ /dev/null
@@ -1,25 +0,0 @@
-/* SPDX-License-Identifier: GPL-2.0+ WITH Linux-syscall-note */
-/*
- * Controls header for IT6625/IT6626 driver
- */
-
-#ifndef _UAPI_LINUX_IT6625_H
-#define _UAPI_LINUX_IT6625_H
-
-#include <linux/v4l2-controls.h>
-
-/*
- * Currently detected HDMI audio sampling rate, in Hz. Read-only.
- * 0 means the rate is unavailable/unknown: no audio is currently
- * present on the input, the hardware reported a sample-rate id this
- * driver doesn't recognize, or the status read itself failed. Never a
- * literal 0 Hz sample rate.
- */
-#define V4L2_CID_IT6625_AUDIO_SAMPLING_RATE	(V4L2_CID_USER_IT6625_BASE + 0)
-
-/*
- * Whether HDMI audio is currently present on the input. Read-only.
- */
-#define V4L2_CID_IT6625_AUDIO_PRESENT		(V4L2_CID_USER_IT6625_BASE + 1)
-
-#endif /* _UAPI_LINUX_IT6625_H */
diff --git a/include/uapi/linux/v4l2-controls.h b/include/uapi/linux/v4l2-controls.h
index 942a1df3057e3e49c9111f6a27ec1883d964bf64..a2d4ea909e01f9b705d30b680ef382f5fcd39714 100644
--- a/include/uapi/linux/v4l2-controls.h
+++ b/include/uapi/linux/v4l2-controls.h
@@ -249,12 +249,6 @@ enum v4l2_colorfx {
  */
 #define V4L2_CID_USER_DCMIPP_BASE		(V4L2_CID_USER_BASE + 0x1240)
 
-/*
- * The base for IT6625/IT6626 driver controls.
- * We reserve 16 controls for this driver.
- */
-#define V4L2_CID_USER_IT6625_BASE		(V4L2_CID_USER_BASE + 0x1250)
-
 /* MPEG-class control IDs */
 /* The MPEG controls are applicable to all codec controls
  * and the 'MPEG' part of the define is historical */

-- 
2.34.1

