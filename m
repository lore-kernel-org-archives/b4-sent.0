From: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
Subject: [PATCH v2 0/2] iio: test: iio-test-format: char format test and
 overrun checks
Date: Mon, 02 Nov 2026 08:33:54 +0000
Message-Id: <20261102-iio-test-format-char-v2-0-926100689e62@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNQQ6CMBBFr0Jm7Zh2EgVceQ/DotQpjBFK2ko0h
 Ltb8AAuX/L++wtEDsIRLsUCgWeJ4scMdCjA9mbsGOWeGUjRWSs6oYjHxDGh82EwCbMVsDK6dK2
 rDSkNeToFdvLes7fmx/HVPtimrbUZvcTkw2f/nfXm/bmYNWpksqQqVyuuyms3GHkerR+gWdf1C
 wRXamPKAAAA
X-Change-ID: 20261025-iio-test-format-char-8a17fbf9a201
To: Rodrigo Alencar <rodrigo.alencar@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>, 
 Andy Shevchenko <andriy.shevchenko@intel.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793608466; l=1508;
 i=raffaele.tranfaglia@gmail.com; s=20261011; h=from:subject:message-id;
 bh=zOtnsvVKuqmWXFDwxhbutV/jvXsZEvAJ8P6C/sc77Tw=;
 b=bADJ50upmNxu7XNqALoxeIB0ZhnI0hWiY4moXOuXg/CZVKTgTi5tUJ9llY9HaVTY5nnIbKfTX
 JzQbMk7+ajiB4o3nKTN9cpShlW00RXpJL2dEHYV/Jd+T4urw0CbPsif
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

 drivers/iio/test/iio-test-format.c | 117 +++++++++++++++++++++++++++++++------
 1 file changed, 100 insertions(+), 17 deletions(-)
---
base-commit: d1425b382b9cc5bd19223fad8ba4a8af3dbe1305
change-id: 20261025-iio-test-format-char-8a17fbf9a201

Best regards,
--  
Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>

