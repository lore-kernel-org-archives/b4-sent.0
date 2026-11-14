From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Subject: [PATCH v6 0/7] Add E notation support to kstrtodec64() and IIO
 sysfs writes
Date: Sat, 14 Nov 2026 14:09:52 +0000
Message-Id: <20261114-e-notation-v6-0-205ca9a1438a@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIALBr+GoC/23OS07EMBAE0KuMvMao2994VtwDsXD8mTGCGMUhA
 o1yd+xhQaywLKledd9ICXMKhZxPNzKHNZWUpxrUw4m4q50ugSZfM2HAFAIgDXTKi11qjUIEraU
 2CEGSCj7mENPXfez55TeXz/E1uKUttMY1lSXP3/drK7bev8MrUqBa4qDHCMohPNnJvuXLo8vvp
 C2vbGeRd5ZV64X1owxoeHQHy3eWQWd5tdHzQTqIY1TyYMXeqs6Kai1XyiqPwkt9sPLPVtxZ2X7
 mxgQphDUD6+y2bT/wv777pwEAAA==
X-Change-ID: 20261001-e-notation-0f07757910e5
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794665398; l=6300;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=qkglJAAoJMp6WutJnose8xK7lLSYHcC33wrXVsxjJLM=;
 b=gd825G2+uZY8TWcjDbGm+AdgntuWosrdx95Jk+oJiTFOxV6OUsgTX9FBrPehe+7n6/9k0zvQv
 S8u5vrKEl0cBttAnvddhM81mdey6CQgY2DH4XxqHxb3yB2JUm9qXQiW
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
Changes in v6:
- Rename skip_digits() to skip_and_count_digits().
- Add a negative value example to the rounding commit message.
- Link to v5: https://patch.msgid.link/20261102-e-notation-v5-0-d399e544a982@analog.com

Changes in v5:
- Allow for a negative scale in kstrto[u]dec64().
- Add more details to the documentation.
- Link to v4: https://patch.msgid.link/20261026-e-notation-v4-0-a366a6d14d57@analog.com

Changes in v4:
- Adjust iio-test-rescale.c to use kstrtodec64().
- Minor changes on making the patches more readable.
- Link to v3: https://patch.msgid.link/20261020-e-notation-v3-0-fd385c0fbf65@analog.com

Changes in v3:
- New patch: round to nearest, ties to even, instead of truncating.
- Amend kstrtox E notation tests and IIO channel write tests for rounding.
- Link to v2: https://patch.msgid.link/20261013-e-notation-v2-0-d4adb5e193fc@analog.com

Changes in v2:
- More test cases on test-kstrtox.c.
- Rework fallback logic when parsing integers.
- Add iio kunit test cases for iio_write_channel_info()
- Link to v1: https://patch.msgid.link/20261001-e-notation-v1-0-75187bf06c10@analog.com

To: linux-kernel@vger.kernel.org
To: linux-iio@vger.kernel.org
Cc: Andrew Morton <akpm@linux-foundation.org>
Cc: Jonathan Cameron <jic23@kernel.org>
Cc: David Lechner <dlechner@baylibre.com>
Cc: Nuno Sá <nuno.sa@analog.com>
Cc: Andy Shevchenko <andy@kernel.org>
Cc: Rodrigo Alencar <rodrigo.alencar@analog.com>

---
Rodrigo Alencar (7):
      lib: kstrtox: support E notation in kstrtoudec64() and kstrtodec64()
      lib: kstrtox: round to nearest, ties to even in kstrto[u]dec64()
      lib: kstrtox: allow a negative scale in kstrto[u]dec64()
      lib: test-kstrtox: add E notation tests for kstrto[u]dec64()
      iio: test: rescale: compare scales against the precision of the output
      iio: core: use kstrtodec64() to parse fixed-point values
      iio: test: add kunit tests for channel info writes

 MAINTAINERS                               |   1 +
 drivers/iio/iio_core.h                    |   3 +
 drivers/iio/industrialio-core.c           | 186 ++++++++-------
 drivers/iio/test/Kconfig                  |  14 ++
 drivers/iio/test/Makefile                 |   1 +
 drivers/iio/test/iio-test-channel-write.c | 360 ++++++++++++++++++++++++++++++
 drivers/iio/test/iio-test-rescale.c       |  60 ++---
 include/linux/kstrtox.h                   |   4 +-
 lib/kstrtox.c                             | 127 ++++++++---
 lib/test-kstrtox.c                        | 246 ++++++++++++++++++--
 10 files changed, 833 insertions(+), 169 deletions(-)
---
base-commit: 7c054db85b5a3ce4d5465cc5cc682cc44ae9eabd
change-id: 20261001-e-notation-0f07757910e5

Best regards,
--  
Rodrigo Alencar <rodrigo.alencar@analog.com>

