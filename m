From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Subject: [PATCH v2 0/2] iio: light: Add Capella CM3217 ambient light sensor
Date: Fri, 06 Nov 2026 21:56:28 +0100
Message-Id: <20261106-upstream-iio-cm3217-v2-0-d97adde9171c@tsv-stahl-riesa.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32OzQ6CMBCEX4X07Bq2/DTx5HsYDqUsskaEdEujI
 by7FO8ev2Tmm1mVkGcSdclW5Smy8PTaQZ8y5Qb7uhNwt7PSua4Rc4RlluDJjsA8gRsLjQao6LF
 0palzqtTenD31/D6st+bHsrQPciGpUmJgCZP/HLMRU+7/QkTIoSI0unSWTGuuQSJIsMMT0n977
 kg127Z9AVqhuwvRAAAA
X-Change-ID: 20261101-upstream-iio-cm3217-e3f14c4760e5
To: Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Kevin Tsai <ktsai@capellamicro.com>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793998608; l=4415;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=kLKFgYm2QwqADdGOjoKVwsmNobJ9M++Xyl5SxExLuB0=;
 b=wr33SH4t4XPFdMDBe0HXzG4jVN0HMIE/A45qNcALpuiwmKap/kWziTKYeUsvpEq3BZCi1fbBi
 dW0pOFpZxfTDqJZrjVO03yAxoHR1L7rLGcmXCq5G/IcjPCzh69e7qFW
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

Probing through the device tree was run with v1 and not repeated for
v2. Suspend/resume was not tested.

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

 .../bindings/iio/light/capella,cm3217.yaml         |  51 +++
 drivers/iio/light/Kconfig                          |  10 +
 drivers/iio/light/Makefile                         |   1 +
 drivers/iio/light/cm3217.c                         | 407 +++++++++++++++++++++
 4 files changed, 469 insertions(+)
---
base-commit: 1390ca4953a7400ca932cb49635f02c727f885a6
change-id: 20261101-upstream-iio-cm3217-e3f14c4760e5

Best regards,
--  
Patrick Fischer <admin@tsv-stahl-riesa.de>

