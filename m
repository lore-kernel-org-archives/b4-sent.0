From: Tin Posavec <tin.posavec04@gmail.com>
Subject: [PATCH v2 0/3] media: ov9734, ipu-bridge: Enable the camera on the
 Intel NUC M15
Date: Mon, 09 Nov 2026 19:17:49 +0100
Message-Id: <20261109-ov9734-ipu6-v2-0-0481b512c4c0@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22Oyw6CMBBFf4V0bQ0dkYcr/8OwaMsIY6QlbWkwh
 H+X4tblubmvlXl0hJ7dspU5jOTJmh3glDE9SNMjp25nBjmUIhcVt7GpLgWnaS550emmE1UDGmq
 2JyaHT1qOtkf7Yz+rF+qQKpJDSY9cOWn0kCSDS0jyQD5Y9zleRJHi/wej4DmvS5QKQCJc63s/S
 nqftR1Zu23bF+z3bkLPAAAA
X-Change-ID: 20261017-ov9734-ipu6-4dc9d1792c28
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Bingbu Cao <bingbu.cao@amd.com>, Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Dan Scally <dan.scally@ideasonboard.com>, Hans de Goede <hansg@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Afonso Figuinha <afonso.figuinha@gmail.com>, 
 Tin Posavec <tin.posavec04@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794248315; l=3284;
 i=tin.posavec04@gmail.com; s=20261109; h=from:subject:message-id;
 bh=1PlHlu8TNlYrqMNUeipl48+lGoBqTAH//j4ns2X12X4=;
 b=I1IftJgBIRkvh3kpNAlcE5dM4y+M+jtu8LbAFoA06eNVaWInyx+OcTQ+AlDXxA1xFhdhaiQ7N
 efXkQNTrmYoA3NusRHYQlhAqq/S4sG7ZG4+1t5R+uc20BlqGnGQYKoK
X-Developer-Key: i=tin.posavec04@gmail.com; a=ed25519;
 pk=h4O+VaAXzwd3B9L6H8RltugTkzF65lam1c1ls5knAVg=
X-Endpoint-Received: by B4 Relay for tin.posavec04@gmail.com/20261109 with auth_id=1463
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

The camera on the Intel NUC M15 laptop (LAPRC710, Alder Lake-P, IPU6)
does not work with mainline. It is an OmniVision OV9734 (OVTI9734) whose
avdd supply and clock come from an INT3472 discrete device; its ACPI
device has neither _PS0 nor _PR0.

Patch 1 makes ov9734 defer its probe until ipu-bridge has created the
endpoint, patch 2 adds power on/off sequencing with runtime PM, and
patch 3 adds the sensor to ipu-bridge. The camera needs all three.
Patch 1 relies on commit 8015a49d8b33 ("media: v4l2-fwnode: Return
-EPROBE_DEFER on parsing NULL endpoints"), which is in v7.1, so a
backport to an older kernel needs that commit as well (v1 did not
depend on it).

v1 was tested on the NUC M15 with Ubuntu's 7.0.0-38 kernel (7.0.14) and
the series backported. The sensor streamed 1296x734 SGRBG10 at 30 fps
(libcamera, simple pipeline, software ISP); it was powered off when
idle, and s2idle worked with the camera idle. Not tested: S3 and kernels
with lock debugging enabled. v4l2-compliance: 45/46, the SUBSCRIBE_EVENT
failure is pre-existing (no V4L2_SUBDEV_FL_HAS_EVENTS).

Afonso Figuinha also tested v1 on a Surface Laptop 1 (IPU3) with
6.19.8-surface-3, with the ipu-bridge entry of patch 3 added by hand:
probe, streaming 1280x704 NV12 at 30 fps (libcamera, IPU3 pipeline),
runtime suspend, module reload and v4l2-compliance (45/46). He did not
test probe deferral at boot or system suspend.

I no longer have the NUC M15, so v2 is only build-tested, not tested
on hardware. The main functional change is in patch 2, which now waits
for 8192 external clock cycles (about 427 us) instead of 20 ms after
power-on, so testing on hardware would be very welcome.

I used an AI coding assistant (Claude Code) to track down the cause,
compare with how other sensor drivers handle this, and draft the
patches. I have gone through every change myself and I am responsible
for the result.

---
Changes in v2:
- Patch 1: Drop the endpoint check and return the error code of
  v4l2_fwnode_endpoint_alloc_parse() instead (Sakari).
- Patch 2: Drop two comments, wait for 8192 external clock cycles after
  power-on instead of 20 ms, and request only the reset GPIO (Sakari).
- Patch 3: Drop the NUC M15 test result from the commit message, as it
  was for the whole v1 series; testing is described above.
- Patches 1 and 3: Add Afonso's Tested-by from v1. It is not added to
  patch 2, as its power-on sequence and GPIO handling changed.
- Drop the Assisted-by tags, see commit 1e035297ffda ("docs: remove
  Assisted-by references").
- Rebase on media-committers next (v7.4-rc1).
- Link to v1: https://patch.msgid.link/20261017-ov9734-ipu6-v1-0-86eab22ae258@gmail.com

---
Tin Posavec (3):
      media: i2c: ov9734: Return -EPROBE_DEFER if no endpoint is found
      media: i2c: ov9734: Add power on/off sequencing support
      media: ipu-bridge: Add OV9734 sensor config

 drivers/media/i2c/ov9734.c           | 124 ++++++++++++++++++++++++++++++-----
 drivers/media/pci/intel/ipu-bridge.c |   2 +
 2 files changed, 111 insertions(+), 15 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261017-ov9734-ipu6-4dc9d1792c28

Best regards,
--  
Tin Posavec <tin.posavec04@gmail.com>

