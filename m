From: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
Subject: [PATCH v3 0/2] iio: test: iio-test-format: char format test and
 overrun checks
Date: Tue, 03 Nov 2026 21:17:06 +0000
Message-Id: <20261103-iio-test-format-char-v3-0-d44074ecca70@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNOw7CMBAFrxK5ZpG9iHyouAeicMw6WUQwsk0Ei
 nJ37FBAgyifNG9mEoE8UxC7YhKeRg7srmlsVoUwvb52BHxKW6DEUkncArODSCGCdX7QERLloda
 qsq1tNEol0vXmyfJj0R6O7x3u7ZlMzK5M9Byi88+lO6rM/UmMChQQGpS1bSTV1b4bNF/Wxg0iJ
 0b8SJLlhwRBQpMzsqwbKvFbMs/zCxxz9gQPAQAA
X-Change-ID: 20261025-iio-test-format-char-8a17fbf9a201
To: Rodrigo Alencar <rodrigo.alencar@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>, 
 Andy Shevchenko <andriy.shevchenko@intel.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793740628; l=1712;
 i=raffaele.tranfaglia@gmail.com; s=20261011; h=from:subject:message-id;
 bh=f06r8ldKJe+o50Na4aMFV/E3TQKjgDB9UYQu67IpN1I=;
 b=ALSTTMgDXcstqo24/MnKoJXUIlIleFQZ+HYJdtXcyAgwWanMhO160KaAVd1ApPfEnlAZtMIHZ
 up+WVal5iPNDFf0+Nv5pj5aZVnz7/mSCWXc1WROg/338HI8e3+6ajcN
X-Developer-Key: i=raffaele.tranfaglia@gmail.com; a=ed25519;
 pk=mweuSGNM6vguCTdqa+aiHwMXdgk70suj2wolzCp6XGM=
X-Endpoint-Received: by B4 Relay for raffaele.tranfaglia@gmail.com/20261011 with auth_id=1160
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a KUnit test for IIO_VAL_CHAR formatting and, as suggested by
Andy, make IIO_TEST_FORMAT_EXPECT_EQ() check that iio_format_value()
does not write past the formatted string.

A NUL character is currently emitted as is, so the attribute reads
back as "\0\n". The test documents this behaviour; please let me
know if it should rather be rejected or handled differently.

These patches were written with the help of an LLM-based coding
assistant, which I used to draft the code and commit messages. I
reviewed and tested all changes myself.

Tested with KUnit on arm64 QEMU.

Signed-off-by: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
---
Changes in v3:
- Reformat IIO_TEST_FORMAT_EXPECT_EQ() and use a local variable for
  the size (Andy)
- Link to v2: https://patch.msgid.link/20261102-iio-test-format-char-v2-0-926100689e62@gmail.com

Changes in v2:
- Drop the Assisted-by tag and describe the tool use here (Andy)
- New patch 1: poison the buffer and check that nothing is written
  past the string (Andy)
- Add special, non-printable, NUL and out-of-range cases (Andy)
- Link to v1: https://patch.msgid.link/20261025-iio-test-format-char-v1-1-e2c208f90e87@gmail.com

---
Raffaele Tranfaglia (2):
      iio: test: iio-test-format: check that nothing is written past the string
      iio: test: iio-test-format: add test case for char format

 drivers/iio/test/iio-test-format.c | 121 +++++++++++++++++++++++++++++++------
 1 file changed, 103 insertions(+), 18 deletions(-)
---
base-commit: d1425b382b9cc5bd19223fad8ba4a8af3dbe1305
change-id: 20261025-iio-test-format-char-8a17fbf9a201

Best regards,
--  
Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>

