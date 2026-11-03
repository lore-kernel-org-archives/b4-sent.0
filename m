From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 03 Nov 2026 11:52:57 -0300
Subject: [PATCH v3 01/10] iio: frequency: ad9910: powerdown fix
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261103-ad9910-backend-support-v3-1-0e9224ddf7b7@analog.com>
References: <20261103-ad9910-backend-support-v3-0-0e9224ddf7b7@analog.com>
In-Reply-To: <20261103-ad9910-backend-support-v3-0-0e9224ddf7b7@analog.com>
To: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux@analog.com, devicetree@vger.kernel.org, linux-pwm@vger.kernel.org, 
 linux-doc@vger.kernel.org, 
 Jonathan Cameron <jonathan.cameron@oss.qualcomm.com>
Cc: Olivier Moysan <olivier.moysan@foss.st.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793717581; l=2077;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=aJtPIXmw5LGBhO6Ijl0bIJNuEuTO3aFnvbkzsDyxwGs=;
 b=9/5AkNRnOThvLHbwYyM9gDBHV02u2WuZvK9mpIklVUEsyQJg/TrQCKv2F1CcKhRuUsx+Oljvh
 fEnKcBLvZaHAT3ro2LTw+NQUefbshq9kjv1SMoPWb6Lj8YlIRRZiQxE
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the software powerdown on all the applicable CFR1 register bits at
once with an IO update.

It turns out that DIGITAL and REFCLK_INPUT powerdown do need an IO update
when enabling the powerdown, but that is not the case when powering it up
again. It is an asymmetric behavior, which was observed while profiling
power consumption in the lab.

Fixes: 22452fe6cd08 ("iio: frequency: ad9910: initial driver implementation")
Reviewed-by: Nuno Sá <nuno.sa@analog.com>
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/frequency/ad9910.c | 26 ++++++++------------------
 1 file changed, 8 insertions(+), 18 deletions(-)

diff --git a/drivers/iio/frequency/ad9910.c b/drivers/iio/frequency/ad9910.c
index 04a4e184b873..8bc24d0b7442 100644
--- a/drivers/iio/frequency/ad9910.c
+++ b/drivers/iio/frequency/ad9910.c
@@ -621,26 +621,16 @@ static int ad9910_sw_powerdown_set(struct ad9910_state *st, bool enable)
 	if (ad9910_sw_powerdown_get(st) == enable)
 		return 0;
 
-	/*
-	 * When powering down, the DAC and AUX_DAC (SW1) must be powered down
-	 * first, as they require an I/O update to take effect. The opposite is
-	 * true when powering up, the DAC and AUX_DAC must be powered up last,
-	 * i.e., after the DIGITAL and REFCLK_INPUT (SW0) power up.
-	 */
-	if (enable) {
-		ret = ad9910_reg32_update(st, AD9910_REG_CFR1,
-					  AD9910_CFR1_SW1_POWER_DOWN_MSK,
-					  AD9910_CFR1_SW1_POWER_DOWN_MSK,
-					  true);
-		if (ret)
-			return ret;
-
+	if (enable)
 		return ad9910_reg32_update(st, AD9910_REG_CFR1,
-					   AD9910_CFR1_SW0_POWER_DOWN_MSK,
-					   AD9910_CFR1_SW0_POWER_DOWN_MSK,
-					   false);
-	}
+					   AD9910_CFR1_SW_POWER_DOWN_MSK,
+					   AD9910_CFR1_SW_POWER_DOWN_MSK,
+					   true);
 
+	/*
+	 * When powering up, the DIGITAL and REFCLK_INPUT (SW0) must be powered
+	 * up first, as they do not require an I/O update to take effect.
+	 */
 	ret = ad9910_reg32_update(st, AD9910_REG_CFR1,
 				  AD9910_CFR1_SW0_POWER_DOWN_MSK, 0, false);
 	if (ret)

-- 
2.43.0

