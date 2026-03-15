From: David Heidelberg <david@ixit.cz>
Date: Sun, 15 Mar 2026 19:52:41 +0100
Subject: [PATCH WIP v2 05/11] Input: stmfts - disable regulators when power
 on fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260315-stmfts5-v2-5-70bc83ee9591@ixit.cz>
References: <20260315-stmfts5-v2-0-70bc83ee9591@ixit.cz>
In-Reply-To: <20260315-stmfts5-v2-0-70bc83ee9591@ixit.cz>
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
 h=from:subject:message-id; bh=2qW8ngTjzm302YCB/fjirEd8lBZHppTYTL/irHDu0sU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBptv/53lQgPZkVE/1ff0MlL4oM6tmmzYpj7LZkM
 I5gtNehdp6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCabb/+QAKCRBgAj/E00kg
 ckTBD/9d4Fas9MuxGRDBXkRc2fYIYSoRcXx3TcyfKoIpKrnKUiK8rzfIU0SlAg599HVJq/cpPA8
 t507y5DmYEyhyMwSGAFKUnp366aMbjBfX68OV3Zd1ofuv/IpqFwITPliK0N7EuNo/RSQZCBo6m4
 n7TqvPnXGYBJdg51oS9ZYyFhfvmRYm/JMuHTv9EE/hlgOEMS0h40CbticIBAnLqUGaRIxCJNU2L
 Ita88L14n5Qj7eKV9XF08aiVVC9jfT5WPnNmMZFkkYRrQA2ux729GVwUJc7dywNMBl5c8cMjfJR
 hqAOcTfglNYc4X3LYx8p+HrWv9yEsU8X+qyztoXxay7qriMRC7uwBXLjUnpGTg3XE5f3JF0j34u
 /uKRr5zUPrL8805QQF2HKlEXb+Tl2ldFi7ZrsIKivSpuVxSkOOkK4B4g9jlIcRsmT6MwqcWGRMa
 gVS53sC9SIrVRjrAXzw7DSIfjijn4seWDo1QMA5u1zsP8ST2iK2o7MqUphqIgldofokB4bON/v8
 lbgb3wImj5mUgeykHlkU1IkqmlKtBMF4Vl6ATvDNjAw3u3AgXDwAVhtwU3YGZi4fGym3hnG0XNE
 ugj0bO65jbRvjTbAa+LtkKMdq0uOylPQrE0W7tAYp1GJgUfhAtZk52ortLkepchu4YQMZofd4wu
 dPGniMVnb5dUODg==
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
index c1c9570ddea2d..bf176907177d0 100644
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
2.53.0

