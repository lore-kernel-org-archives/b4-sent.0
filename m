From: Maurizio Casciano <mauriziocasciano7@gmail.com>
Subject: [PATCH v10 00/15] media: Add Lenovo Yoga Book camera support
Date: Fri, 02 Oct 2026 10:57:38 +0200
Message-Id: <20261002-submission-media-yogabook-v10-b4-final-v10-0-817ec765b257@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2N0QrCMAxFf2Xk2UBaq4K/Ij6kNp1B10rDhjL27
 1Yf7+Fw7gomTcXgPKzQZFHTWvpwtBvgducyCmrqADz5oyPyaHOc1H4eTpKU8VNHjrU+cHGEMWD
 Wwk/c+5CTHMJJmKHHXk2yvv9Pl+u2fQFqRK6aeQAAAA==
X-Change-ID: 20261002-submission-media-yogabook-v10-b4-final-324fde547eaa
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Jacopo Mondi <jacopo.mondi@ideasonboard.com>, 
 Nicholas Roth <nicholas@rothemail.net>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Bingbu Cao <bingbu.cao@amd.com>, 
 Dan Scally <dan.scally@ideasonboard.com>, Hans de Goede <hansg@kernel.org>, 
 Andy Shevchenko <andy@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Andy Shevchenko <andriy.shevchenko@intel.com>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-staging@lists.linux.dev
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790931470; l=6164;
 i=mauriziocasciano7@gmail.com; s=yogabook-kernel-20261002;
 h=from:subject:message-id; bh=2eJ1mchBfXwSxiTCzU9Q2DA9MfTAG55bJ6IJZIdcGKc=;
 b=CbT/xFIrrWRcJIIKV8lO15FLCS2miTT+8CB4/Eo9C/0acTanWZcwXfaDVZniNfN210Qola6Sg
 /UrbM2PxhK8BeU3+fwaTMtctT3rqohd7nfzlDDTl02f9LLPZvjWYr70
X-Developer-Key: i=mauriziocasciano7@gmail.com; a=ed25519;
 pk=ODC2oSPBqt7ukC3AEDZNS7LIE21D8ke8TEHoNlxniNM=
X-Endpoint-Received: by B4 Relay for mauriziocasciano7@gmail.com/yogabook-kernel-20261002 with auth_id=1099
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add camera support for the Lenovo Yoga Book YB1-X91L. The tablet uses
an AtomISP ISP2401 with an OV2740 front sensor, an OV8858 rear sensor
and a WV517S rear-camera lens actuator.

The series adds the missing ACPI and bridge configuration, selects the
OV2740 link frequency through the existing IPU PCI-ID mechanism, derives
AtomISP CSI-2 timing from the sensor link frequency, enables raw Bayer
capture and adds the sensor controls and actuator driver needed by the
hardware.

Runtime validation used the same functional 15-patch content on the
2026-10-01 media_stage.git master. The final media-committers.git next
rebase and review edits only change source formatting and equivalent
frequency notation:

- W=1 builds and sparse builds of all eight affected objects passed after
  the rebase. The OV8858 object passed both again after the v10 review
  edits.
- A full x86_64 Debian binary package build passed and produced kernel
  7.3.0-rc1-yogabook-media-v8-20261002-001605.
- The kernel booted on a Lenovo Yoga Book YB1-X91L with AtomISP PCI ID
  8086:22b8. OV2740 negotiated 288 MHz and OV8858 negotiated 360 MHz;
  both sensors bound and AtomISP registered two cameras.
- OV8858 digital, red and blue gains were changed during streaming and
  read back correctly. Continuous raw capture produced changing frames
  from both sensors (6/8 unique rear samples and 8/8 unique front
  samples), including front-to-rear-to-front switching without OV8858,
  I2C or CSI errors.
- Both front and rear cameras were also exercised successfully with
  Cheese.
- v4l2-compliance 1.32.0 completed 47 tests on the AtomISP capture node:
  40 succeeded and 7 failed in invalid-ioctl, multiple-open, input,
  control enumeration, stream-parameter and buffer tests. These failures
  remain a validation limitation; this series does not claim to make the
  staging AtomISP driver fully compliant.

Only the Yoga Book 19.2 MHz OV8858 path was hardware-tested; the existing
24 MHz paths received build and static-analysis coverage but were not
tested on separate hardware.

Changes in v10:

- Express both OV8858 input-clock rates with HZ_PER_KHZ.
- Drop trailing commas from the terminators of all four new OV8858 clock
  register tables.
- Use the b4 kernel web-submission workflow after Gmail corrupted the v8
  series and the incomplete v9 retry. Media CI confirmed v8 patch 1 was
  corrupt at line 10. There are no functional changes from v8.

Changes in v8:

- Keep patch 2's commit message focused on the implementation, remove the
  invalid review Link and move runtime results to this cover letter.
- Express OV8858 frequencies with HZ_PER_MHZ/HZ_PER_KHZ, name clock
  tables by their input and link frequencies, and remove platform names
  from the sensor driver.
- Explain that V4L2 exposes standard red and blue balance controls but no
  standard green-balance control, so green remains the unity reference.
- Replace the per-sensor link-frequency override with the IPU bridge's
  existing PCI-ID matching mechanism. Add an 8086:22b8-specific OV2740
  288 MHz entry before the generic 360 MHz fallback. This removes the
  associated AtomISP hand-off patch and reduces the series to 15 patches.
- Add the introducing commit to the OV2740 group-hold fix and mark it for
  stable backporting.
- Use the documented Assisted-by tag syntax.
- Keep the padding helper as a normal static function and avoid a
  single-use raw-format descriptor structure.
- Retain Andy's Reviewed-by tags only where the corresponding patches did
  not change materially. In particular, drop the tag from the redesigned
  IPU bridge frequency patch.

v9 (incomplete and transport-corrupted):
https://lore.kernel.org/linux-media/CAO7O_xjhrLNFu6sKEFWp8z+UCkcHu9kr9KfxtEQ=T9yKHCQT-w@mail.gmail.com/

v8 (transport-corrupted):
https://lore.kernel.org/linux-media/CAO7O_xi61=0kUtYkYFKonaSEJRC_KiXKvgMLSwRbnDTVfmQsPg@mail.gmail.com/

v7:
https://lore.kernel.org/linux-media/cover.1788360629.git.mauriziocasciano7@gmail.com/

Signed-off-by: Maurizio Casciano <mauriziocasciano7@gmail.com>
---
Maurizio Casciano (15):
      media: ov8858: Extract digital gain programming
      media: ov8858: support 19.2 MHz clock and manual white balance
      media: ov2740: Use C99 initializers for ACPI IDs
      media: ov2740: Add OVTI2740 ACPI ID
      media: ov8858: Add INT3477 ACPI ID
      media: intel: ipu-bridge: Add Yoga Book camera sensors
      media: atomisp: Add Yoga Book camera configuration
      media: ov2740: support 288 MHz link frequency
      media: intel: ipu-bridge: select OV2740 frequency by IPU ID
      media: atomisp: derive CSI-2 timing from sensor link frequency
      media: ov2740: release group hold after gain write errors
      media: ov2740: add manual white balance controls
      media: atomisp: Use struct v4l2_area for padding
      media: atomisp: allow raw Bayer capture
      media: i2c: Add WV517S lens actuator driver

 MAINTAINERS                                        |   1 +
 drivers/media/i2c/Kconfig                          |  11 +
 drivers/media/i2c/Makefile                         |   1 +
 drivers/media/i2c/ov2740.c                         | 114 ++++++++---
 drivers/media/i2c/ov8858.c                         | 221 ++++++++++++++++-----
 drivers/media/i2c/wv517s.c                         | 208 +++++++++++++++++++
 drivers/media/pci/intel/ipu-bridge.c               |  13 ++
 drivers/staging/media/atomisp/pci/atomisp_cmd.c    |  81 +++++---
 drivers/staging/media/atomisp/pci/atomisp_cmd.h    |   6 +-
 drivers/staging/media/atomisp/pci/atomisp_csi2.c   |  20 +-
 .../media/atomisp/pci/atomisp_csi2_bridge.c        |  19 +-
 drivers/staging/media/atomisp/pci/atomisp_ioctl.c  |  32 ++-
 drivers/staging/media/atomisp/pci/atomisp_subdev.c |   4 +-
 drivers/staging/media/atomisp/pci/atomisp_subdev.h |   3 +-
 14 files changed, 605 insertions(+), 129 deletions(-)
---
base-commit: 4a069a763e8a86821edac4159f7c59a20015631b
change-id: 20261002-submission-media-yogabook-v10-b4-final-324fde547eaa

With Best Regards,
Maurizio Casciano

