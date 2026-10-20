From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Subject: [PATCH RFC v3 0/5] Add E notation support to kstrtodec64() and IIO
 sysfs writes
Date: Tue, 20 Oct 2026 09:26:58 -0300
Message-Id: <20261020-e-notation-v3-0-fd385c0fbf65@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABJe12oC/22NQQ6CMBBFr0K6tmYGLBVXJiYewK1xUcoANUpNW
 4mGcHcLbiRx+SfvvRmYJ2fIs10yMEe98cZ2cWSrhOlWdQ1xU8XNUkhzBEBOvLNBhYhxqEFKIQs
 EEiwKD0e1ec2xMzsdD+zyPfpneSUdpsyEtcYH697zyx5n+F+9Rw5cCtzKsoZcI+xVp262WWt7n
 8t9+uNitnDT6FYbVZWCsMhqvXDHcfwAyTm+KPgAAAA=
X-Change-ID: 20261001-e-notation-0f07757910e5
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792499229; l=5078;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=rO6A838qBXP/TP6FSpqRUMdEQfQmKaVBJ5QyMvmAWck=;
 b=tsOWdwi6YeZX6vIAYMBwU6earWjWCZ/bZ2ivkq2rZZmtX9p17hRHVy89j+USMmE6SMvyaq+nz
 amj8XPg7VhDAuS8zBAuu/3DrKVilsI3kHvg0W8rtdrGzyISpAyCFowN
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series lets kstrtoudec64() and kstrtodec64() accept numbers in E
notation (scientific notation), such as "2.7e9", "1.5E-3" or "1e+16".
It then moves the IIO core fixed-point parser over to kstrtodec64(), so
every IIO channel attribute written through iio_write_channel_info()
accepts that format as well.

There are two main motivations:

1. Shell usage of sysfs attributes

   Some IIO devices take values that are long to type and easy to get
   wrong in plain decimal. A frequency synthesizer or DDS might be
   programmed in the GHz range, and a scale might be a tiny fraction.
   With this series one can write:

     echo 2.7e9 > out_altvoltage0_frequency
     echo 1.5e-6 > in_voltage0_scale

   instead of counting zeros in "2700000000" or "0.0000015". It also
   works with shell tools that print in E notation by default, such as
   printf's %g conversion ("printf '%g' 2700000000" prints "2.7e+09")
   and awk, whose default output format ("%.6g") prints
   non-integral values like 1234567.5 as "1.23457e+06".

2. Userspace software that formats numbers automatically

   Many languages and libraries switch to E notation when converting
   floating point numbers to strings, without the caller asking for it:

   - Python: str() and repr() of a float use E notation for exponents
     below -4 or from 16 up, e.g. str(0.00001) == '1e-05' and
     str(1e16) == '1e+16'. Writing such a value straight to an attribute
     with open(...).write(str(value)) currently fails with -EINVAL.
     The same applies to NumPy scalars and to f-strings with the 'g'
     format spec (f"{2.7e9:g}" == '2.7e+09').
   - JavaScript/Node.js: Number.prototype.toString() uses E notation
     for magnitudes from 1e21 up or below 1e-6, e.g. String(1e-7)
     gives '1e-7'.
   - C/C++ applications and bindings that use printf("%g") or
     std::to_chars() with general formatting, as well as MATLAB/Octave
     and other numeric environments that print in a "short" form.

   Today these values have to be reformatted by the application, or are
   rejected by the kernel without warning. Accepting E notation in the
   kernel makes the IIO sysfs ABI more robust to this common
   behaviour.

The exponent is folded into the requested decimal scale, so no floating
point arithmetic is involved. Overflow is reported as -ERANGE and a
malformed exponent ("1e", "1e+") as -EINVAL.

Digits beyond the resulting precision are now rounded to nearest, ties
to even, instead of truncated (new patch 2). This follows from the
second motivation: floating point values printed by userspace often end
just below the intended decimal value. "%.17g" of 0.3 gives
"0.29999999999999999", which truncation turns into 299999 at micro
precision instead of 300000. E notation makes this more visible, since
a negative exponent can drop integer digits: with truncation, "19e-1"
written to an integer attribute gives 1. Round-half-even is the IEEE 754
default, as used by strtod() and printf(), it is unbiased and symmetric
for negative values, and inputs that fit the precision (including values
read back from sysfs) are parsed exactly as before. The rounding is done
before the IIO core conversion, so IIO fixed-point writes change
behaviour only once.

This changes existing kstrtodec64() behaviour, so feedback is welcome on
whether it should stay in this series or be sent as a follow-up.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
Changes in v3:
- New patch: round to nearest, ties to even, instead of truncating.
- Amend kstrtox E notation tests and IIO channel write tests for rounding.
- Link to v2: https://patch.msgid.link/20261013-e-notation-v2-0-d4adb5e193fc@analog.com

Changes in v2:
- More test cases on test-kstrtox.c.
- Rework fallback logic when parsing integers.
- Add iio kunit test cases for iio_write_channel_info()
- Link to v1: https://patch.msgid.link/20261001-e-notation-v1-0-75187bf06c10@analog.com

---
Rodrigo Alencar (5):
      lib: kstrtox: support E notation in kstrtoudec64() and kstrtodec64()
      lib: kstrtox: round to nearest, ties to even in kstrto[u]dec64()
      lib: test-kstrtox: add E notation tests for kstrto[u]dec64()
      iio: core: use kstrtodec64() to parse fixed-point values
      iio: test: add kunit tests for channel info writes

 MAINTAINERS                               |   1 +
 drivers/iio/iio_core.h                    |   3 +
 drivers/iio/industrialio-core.c           | 164 +++++++-------
 drivers/iio/test/Kconfig                  |  14 ++
 drivers/iio/test/Makefile                 |   1 +
 drivers/iio/test/iio-test-channel-write.c | 360 ++++++++++++++++++++++++++++++
 lib/kstrtox.c                             | 107 ++++++---
 lib/test-kstrtox.c                        | 119 ++++++++--
 8 files changed, 650 insertions(+), 119 deletions(-)
---
base-commit: 43ffda3c7f8456bbe641ae8249a077a361b97880
change-id: 20261001-e-notation-0f07757910e5

Best regards,
--  
Rodrigo Alencar <rodrigo.alencar@analog.com>

