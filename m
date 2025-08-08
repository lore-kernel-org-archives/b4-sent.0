From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Fri, 08 Aug 2025 17:09:42 +0100
Subject: [PATCH] iio: frequency: adf4350: Fix prescaler usage.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250808-adf4350-fix-v1-1-58eed5c07359@analog.com>
X-B4-Tracking: v=1; b=H4sIAEUhlmgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDCwML3cSUNBNjUwPdtMwKXeNUgyTLJPNkYxMjAyWgjoKiVKAw2LTo2Np
 aAAL/BKhdAAAA
X-Change-ID: 20250808-adf4350-fix-3e0b9b7c3420
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754669382; l=1975;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=cHVai96PjFNOGjoTgFHrKbrwRfCUNqOlh5ER9e9oWHQ=;
 b=ISIHb5W8ZRu5AH1W+JKS7aYmlDzKC4EFN2LtgPZ3ZRcxZaUJVW47FRWVrPfLnCocrhzwo8L9z
 vZf6B3SAg/HA9RyITswzWb0dukl0Y9IQp3pk97zl9P+IALzVuE63FAF
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Michael Hennerich <michael.hennerich@analog.com>

The ADF4350/1 features a programmable dual-modulus prescaler of 4/5 or 8/9.
When set to 4/5, the maximum RF frequency allowed is 3 GHz.
Therefore, when operating the ADF4351 above 3 GHz, this must be set to 8/9.
In this context not the RF output frequency is meant
- it's the VCO frequency.

Therefore move the prescaler selection after we derived the VCO frequency
from the desired RF output frequency.

This BUG may have caused PLL lock instabilities when operating the VCO at
the very high range close to 4.4 GHz.

Signed-off-by: Michael Hennerich <michael.hennerich@analog.com>
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
The Signed-off is because I'm just carrying Michael's patch without any
change from me.
---
 drivers/iio/frequency/adf4350.c | 14 +++++++-------
 1 file changed, 7 insertions(+), 7 deletions(-)

diff --git a/drivers/iio/frequency/adf4350.c b/drivers/iio/frequency/adf4350.c
index 47f1c7e9efa9f425a4c7cf82be930234e2c18434..2b8b935965ed4536bda835844ed6c7d0a7b88330 100644
--- a/drivers/iio/frequency/adf4350.c
+++ b/drivers/iio/frequency/adf4350.c
@@ -149,6 +149,13 @@ static int adf4350_set_freq(struct adf4350_state *st, unsigned long long freq)
 	if (freq > ADF4350_MAX_OUT_FREQ || freq < st->min_out_freq)
 		return -EINVAL;
 
+	st->r4_rf_div_sel = 0;
+
+	while (freq < ADF4350_MIN_VCO_FREQ) {
+		freq <<= 1;
+		st->r4_rf_div_sel++;
+	}
+
 	if (freq > ADF4350_MAX_FREQ_45_PRESC) {
 		prescaler = ADF4350_REG1_PRESCALER;
 		mdiv = 75;
@@ -157,13 +164,6 @@ static int adf4350_set_freq(struct adf4350_state *st, unsigned long long freq)
 		mdiv = 23;
 	}
 
-	st->r4_rf_div_sel = 0;
-
-	while (freq < ADF4350_MIN_VCO_FREQ) {
-		freq <<= 1;
-		st->r4_rf_div_sel++;
-	}
-
 	/*
 	 * Allow a predefined reference division factor
 	 * if not set, compute our own

---
base-commit: 6408dba154079656d069a6a25fb3a8954959474c
change-id: 20250808-adf4350-fix-3e0b9b7c3420
--

Thanks!
- Nuno Sá

