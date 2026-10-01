From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Subject: [PATCH RFC 0/3] Add E notation support to kstrtodec64() and IIO
 sysfs writes
Date: Thu, 01 Oct 2026 12:34:55 -0300
Message-Id: <20261001-e-notation-v1-0-75187bf06c10@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJ99vmoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAwND3VTdvPySxBKgMl2DNANzc1NzS0ODVFMloIaCotS0zAqwYdFKQW7
 OSrEQweLSpKzU5BKQMUq1tQDcTrO9cwAAAA==
X-Change-ID: 20261001-e-notation-0f07757910e5
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790868966; l=3248;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=hl5SNynqRKSEbsuJCrx+Ql4cWB3bAeMxxmKi0ACdAiY=;
 b=ljHTM2iJc3dLa2XmllaihB4mzrVICVACtuuzkNTnaRsID5vnLNR4oeTGQW49tGe55O7h0US9W
 ZXOGyjuMjsZDPwbNPnSMbkotcnhX0WXklBMXmPG0PLFvF4KBTl1HOar
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
point arithmetic is involved. Digits beyond the resulting precision are
truncated, matching the existing kstrtodec64() behaviour. Overflow is
reported as -ERANGE and a malformed exponent ("1e", "1e+") as -EINVAL.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
Rodrigo Alencar (3):
      lib: kstrtox: support E notation in kstrtoudec64() and kstrtodec64()
      lib: test-kstrtox: add E notation tests for kstrto[u]dec64()
      iio: core: use kstrtodec64() to parse fixed-point values

 drivers/iio/industrialio-core.c | 155 ++++++++++++++++++++--------------------
 lib/kstrtox.c                   |  64 +++++++++++------
 lib/test-kstrtox.c              |  52 ++++++++++++++
 3 files changed, 170 insertions(+), 101 deletions(-)
---
base-commit: a3b3580713f3ac5a32dc2874ee546828977a1d68
change-id: 20261001-e-notation-0f07757910e5

Best regards,
--  
Rodrigo Alencar <rodrigo.alencar@analog.com>

