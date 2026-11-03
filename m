From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Tue, 03 Nov 2026 14:50:20 +0800
Subject: [PATCH 2/5] media: Documentation: it6625: document the audio
 controls
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-upstream-it6625-alsa-i2s-v1-2-bb91e2879b01@ite.com.tw>
References: <20261103-upstream-it6625-alsa-i2s-v1-0-bb91e2879b01@ite.com.tw>
In-Reply-To: <20261103-upstream-it6625-alsa-i2s-v1-0-bb91e2879b01@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Mark Brown <broonie@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, linux-sound@vger.kernel.org, 
 linux-api@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793688630; l=2749;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=ysI2023N4J3uX9hTybs3IcHa3N84jOblyDxxemwdqPk=;
 b=Wf/UUYj5V/9n6qXXtNTs44d/blo0+4IUpelP+53k//2gxOddpy6cz7WNwMeFlVbeyTTk/uaPf
 DtnLq6Y8VX6CwLx7D3L0akmMLNih8WZXkCt04zH/i5gBhBLAU2VZta4
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The IT6625 driver exposes two read-only driver-specific controls,
V4L2_CID_IT6625_AUDIO_SAMPLING_RATE and V4L2_CID_IT6625_AUDIO_PRESENT,
which so far are described only in the uAPI header.

Add a page for the driver to the V4L2 driver-specific documentation that
describes both controls, and list it in MAINTAINERS.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 Documentation/userspace-api/media/drivers/index.rst  |  1 +
 Documentation/userspace-api/media/drivers/it6625.rst | 18 ++++++++++++++++++
 MAINTAINERS                                          |  1 +
 3 files changed, 20 insertions(+)

diff --git a/Documentation/userspace-api/media/drivers/index.rst b/Documentation/userspace-api/media/drivers/index.rst
index 8d2c489b8453e11b8e15ef9d9c1c0312f3da06af..57be8dd5749d7f5aa6e0e21c7e3d89d377a209d0 100644
--- a/Documentation/userspace-api/media/drivers/index.rst
+++ b/Documentation/userspace-api/media/drivers/index.rst
@@ -33,6 +33,7 @@ For more details see the file COPYING in the source distribution of Linux.
 	dcmipp
 	dw100
 	imx-uapi
+	it6625
 	mali-c55
 	max2175
 	npcm-video
diff --git a/Documentation/userspace-api/media/drivers/it6625.rst b/Documentation/userspace-api/media/drivers/it6625.rst
new file mode 100644
index 0000000000000000000000000000000000000000..efd970e8124979abffb6f9ba3ea1e1bc193820b3
--- /dev/null
+++ b/Documentation/userspace-api/media/drivers/it6625.rst
@@ -0,0 +1,18 @@
+.. SPDX-License-Identifier: GPL-2.0
+
+ITE IT6625/IT6626 HDMI to MIPI bridge driver
+============================================
+
+The IT6625 driver implements the following driver-specific controls. All of
+them are read-only and describe the audio of the HDMI input.
+
+``V4L2_CID_IT6625_AUDIO_SAMPLING_RATE (integer)``
+-------------------------------------------------
+    The sampling rate of the HDMI audio stream, in Hz. 0 means that the rate
+    is not available: there is no stable input signal or no audio, the bridge
+    reported a rate code that the driver does not recognize, or reading the
+    audio status failed.
+
+``V4L2_CID_IT6625_AUDIO_PRESENT (boolean)``
+-------------------------------------------
+    Whether the bridge currently receives HDMI audio.
diff --git a/MAINTAINERS b/MAINTAINERS
index 760791e3635f3c306e7fed7240b948d29b45ae66..1d6de374d86d3046d993bf220195b1a75049fa8a 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -13972,6 +13972,7 @@ M:	Hermes Wu <Hermes.Wu@ite.com.tw>
 S:	Maintained
 T:	git git://linuxtv.org/media.git
 F:	Documentation/devicetree/bindings/media/i2c/ite,it6625.yaml
+F:	Documentation/userspace-api/media/drivers/it6625.rst
 F:	drivers/media/i2c/it6625.c
 F:	include/uapi/linux/it6625.h
 

-- 
2.34.1

