From: Tin Posavec <tin.posavec04@gmail.com>
Subject: [PATCH 0/3] media: ov9734, ipu-bridge: Enable the camera on the
 Intel NUC M15
Date: Sat, 17 Oct 2026 10:31:56 +0200
Message-Id: <20261017-ov9734-ipu6-v1-0-86eab22ae258@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQ6DIBBFr2JmXRKhRkqv0nQBw1inCzSMGhPj3
 Qt1+X7+ewcIZSaBZ3NApo2Fp1RA3xrA0acPKY6FwbSm1622atqcvXeK57VXXUQXtXUGzQOKMWc
 aeP/XXu+LZQ1fwqUm6iN4IRWyTzjWKdG+wHn+AOv816SGAAAA
X-Change-ID: 20261017-ov9734-ipu6-4dc9d1792c28
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Bingbu Cao <bingbu.cao@amd.com>, Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Dan Scally <dan.scally@ideasonboard.com>, Hans de Goede <hansg@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Tin Posavec <tin.posavec04@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792225933; l=1899;
 i=tin.posavec04@gmail.com; s=20261017; h=from:subject:message-id;
 bh=f8OnSobOSVw7SAIjgs7CnYG7FNsm7CZdkmTmhcthv0E=;
 b=z/UVEXikEsdvGLW3AMGsI8lMG9zw5kSZkE6e1YE8mjxcWYM2I5Ft/DzIIKlNpLBRVsizsMFAr
 8qYMB2tNQgyCKms9Prq+sXIrrNc/XdLkjMSmRBvJ6TClqU2Ta1AXOXz
X-Developer-Key: i=tin.posavec04@gmail.com; a=ed25519;
 pk=SHQVmXmK88mO08JT/P9vzu9gKd208IICWLSbsX3TmcI=
X-Endpoint-Received: by B4 Relay for tin.posavec04@gmail.com/20261017 with auth_id=1222
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

The camera on my Intel NUC M15 laptop (LAPRC710, Alder Lake-P, IPU6)
does not work with mainline. It is an OmniVision OV9734 (OVTI9734) whose
avdd supply and clock come from an INT3472 discrete device; its ACPI
device has neither _PS0 nor _PR0.

Patch 1 makes ov9734 defer its probe until ipu-bridge has created the
endpoint, patch 2 adds power on/off sequencing with runtime PM, and
patch 3 adds the sensor to ipu-bridge. The camera needs all three.

Tested on the NUC M15 with Ubuntu's 7.0.0-38 kernel (7.0.14) and the
series backported; the tested ov9734.c differs from this series only
by commit 7eef49c16461 ("media: v4l2-subdev: Add struct
v4l2_subdev_client_info pointer to pad ops"). The sensor streams
1296x734 SGRBG10 at 30 fps (libcamera, simple pipeline, software ISP);
it is powered off when idle, and s2idle works with the camera idle.
Not tested: S3, other boards, and kernels with lock debugging enabled.
v4l2-compliance: 45/46, the SUBSCRIBE_EVENT failure is pre-existing
(no V4L2_SUBDEV_FL_HAS_EVENTS).

I used an AI coding assistant (Claude Code) to track down the cause,
compare with how other sensor drivers handle this, and draft the
patches, hence the Assisted-by tags. I have gone through every change
myself, tested the series on this laptop, and I am responsible for the
result.

---
Tin Posavec (3):
      media: i2c: ov9734: Return -EPROBE_DEFER if no endpoint is found
      media: i2c: ov9734: Add power on/off sequencing support
      media: ipu-bridge: Add OV9734 sensor config

 drivers/media/i2c/ov9734.c           | 139 +++++++++++++++++++++++++++++++----
 drivers/media/pci/intel/ipu-bridge.c |   2 +
 2 files changed, 128 insertions(+), 13 deletions(-)
---
base-commit: d7e7bca7169873b46e857c025c10f3336c1258d8
change-id: 20261017-ov9734-ipu6-4dc9d1792c28

Best regards,
--  
Tin Posavec <tin.posavec04@gmail.com>

