From: Joshua Crofts <joshua.crofts1@gmail.com>
Subject: [PATCH v2 0/5] iio: light: si1133: driver cleanup
Date: Tue, 28 Apr 2026 15:18:32 +0200
Message-Id: <20260428-si1133-checkup-v2-0-70ad14bfefe2@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKmz8GkC/3XMyw6CMBCF4Vchs7am0woaV7yHYVGGKUyUS1olG
 tJ3t7J3+Z/kfBtEDsIRrsUGgVeJMk85zKEAGtzUs5IuNxhtKn0yZxUF0VpFA9P9tSjXEpXmol3
 nLeTTEtjLewdvTe5B4nMOn91f8bf+pVZUqIz2pUfk1lVU96OTx5HmEZqU0hcfalHvrAAAAA==
X-Change-ID: 20260427-si1133-checkup-abcc5280adf3
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777382314; l=1350;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=hlX2tTmUoxSKiSECEojELI2SP5G0fAlh4xQ9I68Ym9A=;
 b=KaHDT9/e92q7cjwRuLbSo9aWybWWLiq2Y4yMDZGTZ7rX1pUiNHCYXhLFOOJGjEWbF/flWvgBY
 dnncEjLbaGcA85hAQbmzsoAbkKirVhl+X2n6xJHBoqd5uvp7dPTganf
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

Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
Changes in v2:
- Change v2 to patch series
- PATCH 2: remove unused macros
- PATCH 3: add missing include headers
- PATCH 4: group generic <linux/*> headers
- PATCH 5: add guard(mutex)() support
- Link to v1: https://lore.kernel.org/r/20260427-si1133-checkup-v1-1-20f5f11eba6c@gmail.com

---
Joshua Crofts (5):
      iio: light: si1133: prefer complex macros enclosed in parenthesis
      iio: light: si1133: remove unused macros
      iio: light: si1133: add missing include headers
      iio: light: si1133: group generic <linux/*> headers
      iio: light: si1133: use guard(mutex)() macro

 drivers/iio/light/si1133.c | 57 ++++++++++++++++++++++------------------------
 1 file changed, 27 insertions(+), 30 deletions(-)
---
base-commit: d86db1905add39f905cf9f04252804b359914ed6
change-id: 20260427-si1133-checkup-abcc5280adf3

Best regards,
-- 
Joshua Crofts <joshua.crofts1@gmail.com>

