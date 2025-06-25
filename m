From: Stuart Burtner <sburtner@d3embedded.com>
Subject: [PATCH 0/2] media: i2c: Add driver for Sony IMX728
Date: Wed, 25 Jun 2025 14:20:02 -0400
Message-Id: <20250625-imx728-on-6-12-v4-v1-0-cfc6e18c3e23@d3embedded.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANM9XGgC/x3MPQqAMAxA4atIZgMaU/+uIg7SRs1glRakIN7d4
 vgN7z0QJahEGIsHgtwa9fQZdVmA3Re/CarLBqrIVC0x6pE66vH02GJNeDMyN9YY4cF1K+TuCrJ
 q+p/T/L4f4BTSnWMAAAA=
X-Change-ID: 20250624-imx728-on-6-12-v4-443c55e49d7f
To: Stuart Burtner <sburtner@d3embedded.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Spencer Hill <shill@d3engineering.com>, 
 Sebastian LaVine <slavine@d3engineering.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3965;
 i=sburtner@d3embedded.com; h=from:subject:message-id;
 bh=6zTjp7jRB2Jx+9WHHH175m07BThSG/TYu6uPE8FB4jo=;
 b=owEB7QES/pANAwAKAUhClGWrMl62AcsmYgBoXD4UCgoBBbMxRsAo6haiO2mY7nAmNjcvb0+aI
 cVGZrqZxAuJAbMEAAEKAB0WIQRYcXSPQoXxpLLN1/FIQpRlqzJetgUCaFw+FAAKCRBIQpRlqzJe
 tg/ODACzTuZLcmQupvz2GECUgNtyaPVLf5/NKaD8BBA2G6eft66Ee0t6kuMcgIgA+KeXf6h1UZi
 NmWZPTHo7DB9HhDImLl8gu19mTJt89ocTH/va19/im54B6zQvjGxGXysKsBZRy/RiqgVgV02uFg
 cdAXF/qbe1ygQGot5rXJy/nIrxM4ALW2H/chZQRn5qaYXotq05mOfqq/9Zun9On4ZemLkgVP+ns
 z0Fbv3e9xe7smoaMYF929MNTLdj2dhEQSRUSOEHqf2tndrfEQh/C3PV1BT2NC1qISTIlDBHZ6W1
 W05ccVYdwSpfjOJGRTe64ust/HkaiHG7kjFNnUHwcmAk2U2m+LNJgm3E0Ozk+svBCXYgwuO6anT
 AoibwPaMPZVRdk3XTP+yBtx9EpxaZtjswUoCYmjBN8fvWS42eKNqzMtBYDJCSTZ6aLt6cYrwJUi
 nnJue1rw9kaZXO5FG01mWNpe/6hzL8DuTx6gkvGHBzG7o+2Vv56o939PH77PpKLFAi19M=
X-Developer-Key: i=sburtner@d3embedded.com; a=openpgp;
 fpr=5871748F4285F1A4B2CDD7F148429465AB325EB6
X-Endpoint-Received: by B4 Relay for sburtner@d3embedded.com/default with auth_id=441
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello! My name is Stuart Burtner.  I will be continuing the work done by Sebastian & Spencer
on this driver. I will finish this patch series and maintain this driver moving forward.

This series adds a V4L2 sensor driver for the Sony IMX728, and related
devicetree overlays.

v3 [0] -> v4:
- Drop set_fps() function because it doesn't actually change FPS
- Use "guard" instead of mutex_lock()
- Fix error checking on imx728->reset_gpio
- Fix attribution of Spencer Hill as Co-Author
- Fix maintainer entry for Stuart
- Clean up documentation for gpios, per notes from Krzysztof Kozlowski
- Removed defconfig modifications

[0]: https://lore.kernel.org/all/20250212195656.69528-1-slavine@d3embedded.com/

v4l2-compliance 1.26.1-5142, 64 bits, 64-bit time_t
v4l2-compliance SHA: 4aee01a02792 2023-12-12 21:40:38

Compliance test for device /dev/v4l-subdev4:

Driver Info:
	Driver version   : 6.12.33
	Capabilities     : 0x00000000

Required ioctls:
	test VIDIOC_SUDBEV_QUERYCAP: OK
	test invalid ioctls: OK

Allow for multiple opens:
	test second /dev/v4l-subdev4 open: OK
	test VIDIOC_SUBDEV_QUERYCAP: OK
	test for unlimited opens: OK

Debug ioctls:
	test VIDIOC_LOG_STATUS: OK (Not Supported)

Input ioctls:
	test VIDIOC_G/S_TUNER/ENUM_FREQ_BANDS: OK (Not Supported)
	test VIDIOC_G/S_FREQUENCY: OK (Not Supported)
	test VIDIOC_S_HW_FREQ_SEEK: OK (Not Supported)
	test VIDIOC_ENUMAUDIO: OK (Not Supported)
	test VIDIOC_G/S/ENUMINPUT: OK (Not Supported)
	test VIDIOC_G/S_AUDIO: OK (Not Supported)
	Inputs: 0 Audio Inputs: 0 Tuners: 0

Output ioctls:
	test VIDIOC_G/S_MODULATOR: OK (Not Supported)
	test VIDIOC_G/S_FREQUENCY: OK (Not Supported)
	test VIDIOC_ENUMAUDOUT: OK (Not Supported)
	test VIDIOC_G/S/ENUMOUTPUT: OK (Not Supported)
	test VIDIOC_G/S_AUDOUT: OK (Not Supported)
	Outputs: 0 Audio Outputs: 0 Modulators: 0

Input/Output configuration ioctls:
	test VIDIOC_ENUM/G/S/QUERY_STD: OK (Not Supported)
	test VIDIOC_ENUM/G/S/QUERY_DV_TIMINGS: OK (Not Supported)
	test VIDIOC_DV_TIMINGS_CAP: OK (Not Supported)
	test VIDIOC_G/S_EDID: OK (Not Supported)

Control ioctls:
	test VIDIOC_QUERY_EXT_CTRL/QUERYMENU: OK
	test VIDIOC_QUERYCTRL: OK
	test VIDIOC_G/S_CTRL: OK
	test VIDIOC_G/S/TRY_EXT_CTRLS: OK
	test VIDIOC_(UN)SUBSCRIBE_EVENT/DQEVENT: OK
	test VIDIOC_G/S_JPEGCOMP: OK (Not Supported)
	Standard Controls: 9 Private Controls: 0

Format ioctls:
	test VIDIOC_ENUM_FMT/FRAMESIZES/FRAMEINTERVALS: OK (Not Supported)
	test VIDIOC_G/S_PARM: OK (Not Supported)
	test VIDIOC_G_FBUF: OK (Not Supported)
	test VIDIOC_G_FMT: OK (Not Supported)
	test VIDIOC_TRY_FMT: OK (Not Supported)
	test VIDIOC_S_FMT: OK (Not Supported)
	test VIDIOC_G_SLICED_VBI_CAP: OK (Not Supported)
	test Cropping: OK (Not Supported)
	test Composing: OK (Not Supported)
	test Scaling: OK (Not Supported)

Codec ioctls:
	test VIDIOC_(TRY_)ENCODER_CMD: OK (Not Supported)
	test VIDIOC_G_ENC_INDEX: OK (Not Supported)
	test VIDIOC_(TRY_)DECODER_CMD: OK (Not Supported)

Buffer ioctls:
	test VIDIOC_REQBUFS/CREATE_BUFS/QUERYBUF: OK (Not Supported)
	test CREATE_BUFS maximum buffers: OK
	test VIDIOC_EXPBUF: OK (Not Supported)
	test Requests: OK (Not Supported)

Total for device /dev/v4l-subdev4: 44, Succeeded: 44, Failed: 0, Warnings: 0

---
Stuart Burtner (2):
      media: dt-bindings: Add Sony IMX728
      media: i2c: Add driver for Sony IMX728

 .../devicetree/bindings/media/i2c/sony,imx728.yaml |   95 +
 MAINTAINERS                                        |    7 +
 drivers/media/i2c/Kconfig                          |   12 +
 drivers/media/i2c/Makefile                         |    1 +
 drivers/media/i2c/imx728.c                         | 9628 ++++++++++++++++++++
 5 files changed, 9743 insertions(+)
---
base-commit: 23fdf46589db718d538fa3e65ab0d57362d50b4a
change-id: 20250624-imx728-on-6-12-v4-443c55e49d7f

Best regards,
-- 
Stuart Burtner <sburtner@d3embedded.com>

