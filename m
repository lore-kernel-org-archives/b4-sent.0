From: David Heidelberg <david@ixit.cz>
Date: Sun, 01 Mar 2026 18:51:18 +0100
Subject: [PATCH 04/10] Input: stmfts - disable regulators when power on
 fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260301-stmfts5-v1-4-22c458b9ac68@ixit.cz>
References: <20260301-stmfts5-v1-0-22c458b9ac68@ixit.cz>
In-Reply-To: <20260301-stmfts5-v1-0-22c458b9ac68@ixit.cz>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Henrik Rydberg <rydberg@bitmath.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Petr Hodina <petr.hodina@protonmail.com>, linux-input@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1598; i=david@ixit.cz;
 h=from:subject:message-id; bh=Z29IokqtA9ULVf4cQSlm3q9NJhfdPu/mSq+nU9M0a4M=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBppHyU9u/DZ1GreqI2xQDH8VFabq8lVGipnGV6u
 YblMQC0S3WJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaaR8lAAKCRBgAj/E00kg
 cuLzD/45dchsfZkaDN8R4+2qYOi2IqahkhRBhZymvtMYZ+qXaWMz652M3IZpAy59eOOwkGO5B6j
 qfvIu57Qipc1I+UeTxkmepghYsA+E46SSYff8toz8tUAsOJBEY01FgLX4VSKV4hXPGR438LipBg
 2TjRUk5+jlm9sHdaOYdBQuGqejUnD/oL14qi4yYtOoGqLbqWs8wzDXFRTMS6YvT2GjnFOlDRqcB
 5DC+Idb7rWxyNtJdbOdH/ht3R5CCrpsq6YhK4KVub9rrCuRKAT/qQYMeXiSQVBr0eu4elXnm2Cy
 qZV/1QwsbgVwL5IiysQdp8T5Wu1ESmCMKB59jeR2QAmflZ0R3AkEsI69TK9akDlFEzsfFUm7mrz
 om83TzDnVnLrOZPYYMOzWNVLEPjSgpYWsBYK7U674/cEfRDFOkqdew6tw70v2GJm3Oio5VEzGVL
 O1SuQ+WaaVzCxEy9aqtNNxpy/FTnSsgcLc2xfFY4zgsS/Uxvgm83J7unPbfnaKxxizEy5w3NJ+A
 nHsF5XzVxS3APrLPRfLwnO5G4g4UVLw2lcJvsTp45CHzjthuOZiqZxvd177P52lkivJE//X4bnK
 02GDVbH9OLze8pxZBwDyrQLrbleT1JV1CuEywAlZwe9uk6weDvJTYTiPatc0US27Zw5CMDd9/tc
 9S68x3aBfA3/spQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We must power off regulators after failing at power on phase.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/touchscreen/stmfts.c | 13 +++++++++----
 1 file changed, 9 insertions(+), 4 deletions(-)

diff --git a/drivers/input/touchscreen/stmfts.c b/drivers/input/touchscreen/stmfts.c
index db2dd0bb59fcc..f4e5f1b3ce796 100644
--- a/drivers/input/touchscreen/stmfts.c
+++ b/drivers/input/touchscreen/stmfts.c
@@ -558,7 +558,7 @@ static int stmfts_power_on(struct stmfts_data *sdata)
 
 	err = stmfts_read_system_info(sdata);
 	if (err)
-		return err;
+		goto power_off;
 
 	enable_irq(sdata->client->irq);
 
@@ -566,11 +566,11 @@ static int stmfts_power_on(struct stmfts_data *sdata)
 
 	err = stmfts_command(sdata, STMFTS_SYSTEM_RESET);
 	if (err)
-		return err;
+		goto power_off;
 
 	err = stmfts_command(sdata, STMFTS_SLEEP_OUT);
 	if (err)
-		return err;
+		goto power_off;
 
 	/* optional tuning */
 	err = stmfts_command(sdata, STMFTS_MS_CX_TUNING);
@@ -586,7 +586,7 @@ static int stmfts_power_on(struct stmfts_data *sdata)
 
 	err = stmfts_command(sdata, STMFTS_FULL_FORCE_CALIBRATION);
 	if (err)
-		return err;
+		goto power_off;
 
 	/*
 	 * At this point no one is using the touchscreen
@@ -595,6 +595,11 @@ static int stmfts_power_on(struct stmfts_data *sdata)
 	(void) i2c_smbus_write_byte(sdata->client, STMFTS_SLEEP_IN);
 
 	return 0;
+
+power_off:
+	regulator_bulk_disable(ARRAY_SIZE(stmfts_supplies),
+			       sdata->supplies);
+	return err;
 }
 
 static void stmfts_power_off(void *data)

-- 
2.51.0

