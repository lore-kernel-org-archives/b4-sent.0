From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Fri, 29 Aug 2025 12:25:43 +0100
Subject: [PATCH v2 2/2] iio: frequency: adf4350: Fix
 ADF4350_REG3_12BIT_CLKDIV_MODE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250829-adf4350-fix-v2-2-0bf543ba797d@analog.com>
References: <20250829-adf4350-fix-v2-0-0bf543ba797d@analog.com>
In-Reply-To: <20250829-adf4350-fix-v2-0-0bf543ba797d@analog.com>
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756466743; l=1107;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=SEribMCTyRhjHbFbiMgxBRvJs0kZrg1X8F3ZYiKK3jg=;
 b=T8rECER14OX50SHkKm5lPSB91hgx7zC3e2ygMX1Wq7S3b1/M9GSVSGIXY/CIWDNelslg9KQSl
 3jNkIqMH83wBbRVOZdaUcH7LZfJV7KykpNBET05KcJqCECPrkDJn8D+
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Michael Hennerich <michael.hennerich@analog.com>

The clk div bits (2 bits wide) do not start in bit 16 but in bit 15. Fix it
accordingly.

Fixes: e31166f0fd48 ("iio: frequency: New driver for Analog Devices ADF4350/ADF4351 Wideband Synthesizers")
Signed-off-by: Michael Hennerich <michael.hennerich@analog.com>
Signed-off-by: Nuno Sá <nuno.sa@analog.com>

---
v2:
 * New patch.
---
 include/linux/iio/frequency/adf4350.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/include/linux/iio/frequency/adf4350.h b/include/linux/iio/frequency/adf4350.h
index de45cf2ee1e4f8278a02cb2efb1540662023d9fb..ce2086f97e3fcf609d77de0bc2c15d5d47f7baae 100644
--- a/include/linux/iio/frequency/adf4350.h
+++ b/include/linux/iio/frequency/adf4350.h
@@ -51,7 +51,7 @@
 
 /* REG3 Bit Definitions */
 #define ADF4350_REG3_12BIT_CLKDIV(x)		((x) << 3)
-#define ADF4350_REG3_12BIT_CLKDIV_MODE(x)	((x) << 16)
+#define ADF4350_REG3_12BIT_CLKDIV_MODE(x)	((x) << 15)
 #define ADF4350_REG3_12BIT_CSR_EN		(1 << 18)
 #define ADF4351_REG3_CHARGE_CANCELLATION_EN	(1 << 21)
 #define ADF4351_REG3_ANTI_BACKLASH_3ns_EN	(1 << 22)

-- 
2.51.0

