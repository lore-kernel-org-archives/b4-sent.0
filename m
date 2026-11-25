From: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
Subject: [PATCH v2 0/3] regmap: handle values wider than val_bits
 consistently
Date: Wed, 25 Nov 2026 08:09:29 +0000
Message-Id: <20261125-regmap-kunit-val-bits-v2-0-81db3b79cd3f@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNTQ6CMBBGr0K6dkynVTCuvIdhUcoIo/ylLY2Gc
 HcLHsDlS973vkV4ckxeXLNFOIrseRwSqEMmbGuGhoDrxEJJlSNiAY6a3kzwmgcOEE0HFQcP+an
 QWp5JXnQl0nZy9OD33r2XP/Zz9SQbtthmtOzD6D77ccTN+/cRERAM2loqmWuFxS1Z3B3t2ItyX
 dcvrvesyMwAAAA=
X-Change-ID: 20261117-regmap-kunit-val-bits-6473305e083b
To: Mark Brown <broonie@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Johan Hovold <johan@kernel.org>, Liam Girdwood <lgirdwood@gmail.com>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: Andy Shevchenko <andriy.shevchenko@intel.com>, 
 Jonathan Cameron <jic23@kernel.org>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, driver-core@lists.linux.dev, 
 linux-sound@vger.kernel.org, Neo Chang <YLCHANG2@nuvoton.com>, 
 Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795594173; l=1960;
 i=raffaele.tranfaglia@gmail.com; s=20261011; h=from:subject:message-id;
 bh=niRjLc5BPtItCfeqEJ3V75a61ksSwRctBYQr3XvGWXM=;
 b=Du8pd/IZETKlBvTPHNlt422/qO1bNIozP3bj2PlLrjcfGyjp7C+mSS5hhzM4WEUHj6GsEmT5r
 5q4H77EIz3lADGuiNvX/6xzcLVrsTGE+wtSnKZ92F8zj7Hwc+DerlBi
X-Developer-Key: i=raffaele.tranfaglia@gmail.com; a=ed25519;
 pk=mweuSGNM6vguCTdqa+aiHwMXdgk70suj2wolzCp6XGM=
X-Endpoint-Received: by B4 Relay for raffaele.tranfaglia@gmail.com/20261011 with auth_id=1160
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

regmap_write() takes an unsigned int, and what happens to the bits above
val_bits currently depends on the bus and on the cache type. As agreed
on the RFC, mask them in the core, before the cache is updated.

Patch 1 prepares nau8360, which sets val_bits = 16 but writes 32-bit
values to its DSP registers, so it would break with the masking.
Patch 2 adds the masking.
Patch 3 adds the KUnit tests from the RFC, which now pass.

I searched for other drivers whose reg_write() handles more bits than
val_bits and found no other clear case, but the search cannot be
exhaustive. Implementations of reg_update_bits() do not go through
_regmap_write() and are not changed.

The regmap KUnit tests pass on arm64 QEMU. The nau8360 change is only
compile tested.

I prepared these patches with the help of an AI coding assistant, and
reviewed and tested them myself.

---
Changes in v2:
- No longer an RFC.
- New patch masking the values in the regmap core (Andy, Mark).
- New patch preparing nau8360.
- Use be16_to_cpup()/le16_to_cpup() instead of casts in the tests (Andy,
  Mark).
- Rebased on regmap for-7.5.
- Link to v1: https://patch.msgid.link/20261117-regmap-kunit-val-bits-v1-1-a1cd02063217@gmail.com

---
Raffaele Tranfaglia (3):
      ASoC: codecs: nau8360: set val_bits to the widest register size
      regmap: mask values to val_bits on write
      regmap: kunit: add tests for values wider than val_bits

 drivers/base/regmap/internal.h     |  1 +
 drivers/base/regmap/regmap-kunit.c | 60 ++++++++++++++++++++++++++++++++++++++
 drivers/base/regmap/regmap.c       | 14 ++++++++-
 sound/soc/codecs/nau8360.c         |  3 +-
 sound/soc/codecs/nau8360.h         |  3 +-
 5 files changed, 77 insertions(+), 4 deletions(-)
---
base-commit: 573c689219af87f6d5a4bbf809c174e7f28a23a1
change-id: 20261117-regmap-kunit-val-bits-6473305e083b

Best regards,
--  
Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>

