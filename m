From: Joshua Crofts <joshua.crofts1@gmail.com>
Subject: [PATCH v5 0/8] iio: light: si1133: driver cleanup
Date: Tue, 05 May 2026 09:31:25 +0200
Message-Id: <20260505-si1133-checkup-v5-0-5df86a9024ed@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAM2c+WkC/3XOTQ6CMBCG4auQrq3pTAuKK+9hXLRlRhrlJ1SJh
 nB3qysicflN8ryZSUQaAkVxyCYx0Bhi6No08k0mfG3bC8lQpS1QYaEM7mQMAFpLX5O/Pnppnfc
 57pWtWIuE+oE4PL/B0zntOsR7N7y+/RE+17+pESRIVJwzADlb+OOlseG29V0jPqkRl3y/4iiV3
 KVHwDgmJvzlesnLFdeJm6JkhKosFLlfbhZcqxU3ibPTVFaeDDhe8nme38TlfmFpAQAA
X-Change-ID: 20260427-si1133-checkup-abcc5280adf3
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Jean-Francois Dagenais <jeff.dagenais@gmail.com>, 
 =?utf-8?q?Maxime_Roussin-B=C3=A9langer?= <maxime.roussinbelanger@gmail.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>, 
 Jonathan Cameron <jic23@kernel.org>, sashiko-bot <sashiko-bot@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777966306; l=2308;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=lsNO2+RzQtpW8/cPFiBt8mezwI0CiJdsZYNT3rjRokM=;
 b=1lMiAumW5TWDeh5R5kVKcog4ojYe/+5F4RmeF3UOMUYcd2r1t3/OwAuCmjQ+2B7znKXTHwwO9
 tE5dN24xiMMB4SUUW+n1h5AYzEn0GA9RXbGbRgfCG/8LOfyktchoQSL
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series deals with the cleanup and modernization of the Silicon
Labs SI1133 UV/Ambient light sensor.

What seemed like a simple checkpatch cleanup turned out to be more
complex, therefore I've ended up doing a patch series instead.

Changes include:
 - adding missing headers
 - removing unused macros
 - adding guard(mutex)() support
 - code style fixes
 - race condition fixes reported by Sashiko

Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
Changes in v5:
- PATCH 5: fix commit message
- Pick up Andy's Reviewed-by tag
- Link to v4: https://lore.kernel.org/r/20260430-si1133-checkup-v4-0-fb3e9dce41bf@gmail.com

Changes in v4:
- Changed logical ordering of patchset
- PATCH 1: fix typo in comment, edit commit message
- PATCH 2: edit commit message
- PATCH 3: edit commit message
- PATCH 5: remove irqreturn.h and add mod_devicetable.h
- Link to v3: https://lore.kernel.org/r/20260429-si1133-checkup-v3-0-469f21d960eb@gmail.com

Changes in v3:
- PATCH 6: add local variable for timeout
- PATCH 7 & 8: fix potential race conditions as pointed out by Sashiko
- Link to v2: https://lore.kernel.org/r/20260428-si1133-checkup-v2-0-70ad14bfefe2@gmail.com

Changes in v2:
- Change v2 to patch series
- PATCH 2: remove unused macros
- PATCH 3: add missing include headers
- PATCH 4: group generic <linux/*> headers
- PATCH 5: add guard(mutex)() support
- Link to v1: https://lore.kernel.org/r/20260427-si1133-checkup-v1-1-20f5f11eba6c@gmail.com

---
Joshua Crofts (8):
      iio: light: si1133: reset counter to prevent race condition
      iio: light: si1133: prevent race condition on timeout
      iio: light: si1133: remove unused macros
      iio: light: si1133: prefer complex macros enclosed in parenthesis
      iio: light: si1133: add missing include headers
      iio: light: si1133: group generic <linux/*> headers
      iio: light: si1133: add local variable for timeout
      iio: light: si1133: use guard(mutex)() macro

 drivers/iio/light/si1133.c | 69 +++++++++++++++++++++++++++-------------------
 1 file changed, 41 insertions(+), 28 deletions(-)
---
base-commit: d86db1905add39f905cf9f04252804b359914ed6
change-id: 20260427-si1133-checkup-abcc5280adf3

Best regards,
-- 
Joshua Crofts <joshua.crofts1@gmail.com>

