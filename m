From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Subject: [PATCH v4 0/2] iio: light: Add Capella CM3217 ambient light sensor
Date: Sat, 28 Nov 2026 00:38:55 +0100
Message-Id: <20261128-upstream-iio-cm3217-v4-0-fdab04f40bbc@tsv-stahl-riesa.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33OQQ7CIBAF0KsY1o7pAC3qynsYFxSmFqOtASQa0
 7sLunFRXf7kz/vzZIG8o8C2iyfzlFxw45CDXC6Y6fVwJHA2Z8Yr3iBWCLdriJ70BZwbwVwERwU
 kOpRGqqaimuXLq6fO3d/q/vDJ4daeyMRClUbvQhz94z2bsPT+LySECmpCxaXRpFq1iyFBiLo/Q
 /lfryyxMpX4N9bMYzxjdqO0tbRBheYnJr4wFPOYyJiRtm65XNe262axaZpegl8QDmsBAAA=
X-Change-ID: 20261101-upstream-iio-cm3217-e3f14c4760e5
To: Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Kevin Tsai <ktsai@capellamicro.com>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795822755; l=7256;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=Ny6vyllDTSVrESnJILjBNKDu5yers3ghxEQhKJ3JD+I=;
 b=k/qag+BOSFpvM61YZl7TFc+M+2n7lZsiZiMbSxm7RAPTKcgcxLvSfWQzEUenjzJlwUyTvj5pg
 qO0JuJIya9/BfN1HrXiEykgpcUJw5TreCnlNZCIIwRYn10Psix9Dx6y
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Capella CM3217 is a small ambient light sensor without registers.
NVIDIA used it in the Tegra Note 7 and the Shield Tablet. Mainline has
no driver for it: cm32181 and cm3232 expect registers and an ID, the
CM3217 has neither.

Patch 1 adds the binding, patch 2 the driver with raw value, scale and
integration time. The datasheet is not public, so the bit fields come
from NVIDIA's downstream drivers and the scale from Capella's published
detection range. Patch 2 explains both.

Tested on a Tegra Note 7 (P1640) with v7.3 and the driver built as a
module, the device created through new_device. In room light all 32
combinations of integration time and scale gave the same illuminance
within the count resolution (6.0 to 7.3 lux), and the first read after
each change matched the second one. The raw counts scale linearly with
both fields. Svyatoslav Ryhel also tried it on the P1988 variant of the
Tegra Note 7.

Probing through the device tree works with the real supply (vdd_dev,
Palmas LDO6), and unloading and reloading the module twice brought the
device back each time. Next to a phone light sensor the readings were
about 7 to 20 times lower. NVIDIA's Android HAL for this tablet
multiplies the count by 2.1505 at the same 2 T/100 ms setting, which is
7.2 times the scale here, so most of that is the dark cover window. With
that factor the tablet was within 15 % of the phone in bright light but
a factor of three lower in dim room light; I could not tell whether that
was my setup.

v3 was run again on the P1640, through the device tree with both
addresses in reg and through new_device without a device tree node: in
both cases the driver binds to 0x10 and claims 0x11, and all 32
settings give the same scale and integration time values as v2. With
the device tree, unloading and reloading the module twice freed and
claimed the second address again. Suspend/resume was not tested.

There is no MAINTAINERS entry: drivers/iio/light/cm* is covered by the
Capella entry and the binding by IIO. I am happy to add one if you
prefer.

The device tree node for the Tegra Note 7 will follow with Svyatoslav's
tegratab series.

Tool use (see Documentation/process/generated-content.rst): this series
was prepared with an LLM coding assistant (Claude Code). It read the
NVIDIA downstream drivers and Capella's product data, wrote the driver,
the binding and the texts from my instructions, and ran the build and
binding checks. I reviewed the code and ran the tests on the device.

---
Changes in v4:
- Binding: drop "without registers or interrupt line" from the
  description (Jonathan). Kept Krzysztof's Reviewed-by on patch 1, as
  this is the only change to the binding since his review.
- Driver: don't read the second address from firmware at all, it is
  always the device address plus one (Jonathan). This also removes the
  fallback for new_device and with it the question of how to detect a
  missing firmware node (Jonathan, Andy).
- Driver: one lookup helper each for the scale and the integration time
  instead of cm3217_find_avail() with a length parameter (Andy).
- Driver: reversed xmas tree order in cm3217_read_count() and probe()
  (Andy).
- Driver: devm_i2c_new_dummy_device() call on one line (Andy).
- Driver: include mod_devicetable.h for the device ID tables.
- Commit messages: patch 2 describes the new address handling; both
  patches now say what the coding assistant did, in addition to the
  "Tool use" paragraph above.
- Rebase onto the current iio togreg branch.
- No functional change on the Tegra Note 7: the scale and integration
  time tables in the object file are identical to v3, and the second
  address is still 0x11.
- Link to v3: https://patch.msgid.link/20261113-upstream-iio-cm3217-v3-0-c4d5b2485dff@tsv-stahl-riesa.de

Changes in v3:
- Binding: list both I2C addresses in reg, one description each
  (Conor).
- Driver: take the second address from the second reg entry, with 0x11
  as fallback when there is no firmware node (new_device). Svyatoslav,
  I kept your Tested-by as a device tree with only the first address
  still works through the fallback, but a quick retest would be
  welcome.
- Driver: write the resolution constant as 0.01875 lux times 800 ms in
  nanolux * ms, so that NANO is no longer part of it (Andy).
- Driver: split the scale into its integer and nano parts with a named
  helper macro (Andy).
- Driver: static_assert() on one line, the conversion margin added to
  conv_ms with a comment, FIELD_MODIFY() for IT_T, and the error return
  in probe inside scoped_guard() (Andy).
- No functional change: the scale and integration time tables in the
  object file are identical to v2. struct cm3217_data was checked with
  pahole: one 2-byte hole on 32-bit ARM, and no field order makes it
  smaller as ktime_t needs 8-byte alignment, so the order stays (Andy).
- Tested again on the device, see above.
- Link to v2: https://patch.msgid.link/20261106-upstream-iio-cm3217-v2-0-d97adde9171c@tsv-stahl-riesa.de

Changes in v2:
- Binding: describe the two I2C addresses under reg, including what each
  one is used for (Jonathan).
- Driver: replace the scale list that was recomputed on every change of
  the integration time by a const table built at compile time;
  read_avail() returns the row for the current integration time, so no
  table is rewritten while a caller may hold a pointer to it (Jonathan,
  Sashiko).
- Driver: write the resolution constant with NANO and explain its unit
  (Jonathan).
- Driver: add cm3217_power_down() for the shutdown write used in three
  places (Jonathan), and a helper for the table lookups in write_raw()
  so the loop counter can live in the for statement (Jonathan).
- Driver: take the conversion time from the integration time table and
  drop the separate table in milliseconds.
- Pick up Svyatoslav's Tested-by on patch 2 (given on v1).
- Commit messages: name the downstream trees, note that the 4 T field
  value differs from the vendor header, drop "driver" from the binding
  text.
- Rebase onto the current iio togreg branch (based on v7.4-rc1).
- No functional change intended. The 32 scale values match the v1
  computation. Run again on the Tegra Note 7 (P1640) as a module: each
  integration time lists the same scales as with v1, all 32 settings are
  accepted and read back, invalid values are rejected, and the sensor is
  shut down when the device is removed.
- Link to v1: https://patch.msgid.link/20261101-upstream-iio-cm3217-v1-0-5e1724cae7b7@tsv-stahl-riesa.de

---
Patrick Fischer (2):
      dt-bindings: iio: light: Add Capella CM3217
      iio: light: Add Capella CM3217 ambient light sensor driver

 .../bindings/iio/light/capella,cm3217.yaml         |  49 +++
 drivers/iio/light/Kconfig                          |  10 +
 drivers/iio/light/Makefile                         |   1 +
 drivers/iio/light/cm3217.c                         | 420 +++++++++++++++++++++
 4 files changed, 480 insertions(+)
---
base-commit: 92c9d64c0cf749c8369403a32630562f0e855a6c
change-id: 20261101-upstream-iio-cm3217-e3f14c4760e5

Best regards,
--  
Patrick Fischer <admin@tsv-stahl-riesa.de>

