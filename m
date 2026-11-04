From: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
Date: Wed, 04 Nov 2026 10:28:22 +0000
Subject: [PATCH] iio: light: adux1020: harden sampling frequency table
 lookup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-adux1020-rate-bounds-v1-1-2db71ad2cc21@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQqDMAyA4VeRnBdI6ihsrzJ2qDbdskMdjRVBf
 HfrdvwO/7+BSVExuHcbFFnUdMoNfOlgfIf8EtTYDI6cZ6YrhlhXJkdYwiw4TDVHQ8/Sp3TzQqm
 Hln6LJF1/28fzb6vDR8b5fMG+H6oMYnl4AAAA
X-Change-ID: 20261104-adux1020-rate-bounds-61e3ff96e0f3
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux@analog.com, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793788105; l=1810;
 i=raffaele.tranfaglia@gmail.com; s=20261011; h=from:subject:message-id;
 bh=cqE5CwXxkaaFLmmwvn2ph1c33wcfTad0JYMx5iByIGE=;
 b=HsWSTDAh+Bqk5NAHtkm9e0sJLQeq4gRYJlTkT2QJ2TcqrrvK28afb3e5qZY1ydY360J4nNLGR
 q8mKXJR+bnDDJdhmnRE2xFLGHP0mEn/Srx/n4zGYFyM0sPumlE5GhYM
X-Developer-Key: i=raffaele.tranfaglia@gmail.com; a=ed25519;
 pk=mweuSGNM6vguCTdqa+aiHwMXdgk70suj2wolzCp6XGM=
X-Endpoint-Received: by B4 Relay for raffaele.tranfaglia@gmail.com/20261011 with auth_id=1160
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The proximity frequency field read from the FREQUENCY register is four
bits wide, so it can hold values from 0 to 15, but adux1020_rates[] only
has 14 entries. The driver never programs values 14 or 15, but if a
misbehaving device reports one of them, reading the sampling frequency
indexes past the end of the table and returns garbage.

Reject such values with -EINVAL instead of indexing past the end of
the table.

Signed-off-by: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
---
Found with LLM-assisted static analysis of drivers/iio, looking for
table lookups indexed by unchecked register fields; the fix was drafted
with the same assistant and reviewed and tested by me.

Tested on arm64 QEMU with i2c-stub and CONFIG_UBSAN_BOUNDS=y. After
setting the frequency field in FREQUENCY (0x40) to 14, reading
in_proximity_sampling_frequency:
- before: two array-index-out-of-bounds reports, and the attribute
  reads 0.025000
- after: the read fails with -EINVAL and no report is printed
---
 drivers/iio/light/adux1020.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/iio/light/adux1020.c b/drivers/iio/light/adux1020.c
index 0ea282ecc99a..d4281b9754c3 100644
--- a/drivers/iio/light/adux1020.c
+++ b/drivers/iio/light/adux1020.c
@@ -414,6 +414,10 @@ static int adux1020_read_raw(struct iio_dev *indio_dev,
 				goto fail;
 
 			regval = FIELD_GET(ADUX1020_PROX_FREQ_MASK, regval);
+			if (regval >= ARRAY_SIZE(adux1020_rates)) {
+				ret = -EINVAL;
+				goto fail;
+			}
 
 			*val = adux1020_rates[regval][0];
 			*val2 = adux1020_rates[regval][1];

---
base-commit: 20ce8ef9c9e04cd6c5ae0422e251a9b5936c6b7c
change-id: 20261104-adux1020-rate-bounds-61e3ff96e0f3

Best regards,
--  
Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>

