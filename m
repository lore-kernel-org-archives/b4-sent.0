From: David Heidelberg <david@ixit.cz>
Date: Sun, 15 Mar 2026 19:52:40 +0100
Subject: [PATCH WIP v2 04/11] Input: stmfts - abstract reading information
 from the firmware
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260315-stmfts5-v2-4-70bc83ee9591@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1821; i=david@ixit.cz;
 h=from:subject:message-id; bh=XFaZaPRkaLRohySBuoaYMFPtZGjmqJauWlqz/Xv2L/c=;
 b=owEBbAKT/ZANAwAIAWACP8TTSSByAcsmYgBptv/5kO5OknDi5IJov8Qfi+fjgPxHlqfISspUX
 9v9Jtcd20eJAjIEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCabb/+QAKCRBgAj/E00kg
 cklID/iclHlpBybWVTbVwtV9yu6KKK2NHsWvquiTMXw5Q2Bq3saKr8FtQtKP9L/2czJtn0NRkqN
 o+ewo546H4IC6GRCwDi/h7E78jmmSCEOZQ/TqJwtfHkiy7NlEQkh7PzGicEf0aWiFUWtZU7R5Qb
 heSr3eDWJ5lEmYkVWnKhPPW5qkgMFYAGflkF/AgAt2NW/teJZDBRPVCyejI61nm+9GNElmDU7kD
 npbdeNTOrE8bSa0ARIe5hNA8wWB8HQXOeHj7M1rrqxkpzQektIEnzAUzsChiRWeOt+8okL1nynJ
 t/q9051yzuuRApWOig8y1Vx1GGqXrbTCWYQdxcAvxT9C6nAJVuUjRtKSFNCni8utJDzdbGtDgmb
 NwmKCZ3gcInJWgypcE6Eq82HgJfyadW7zyDcRcoQtsGYJ7iySa64gAMPr7HnMHiqmspE7WsYMme
 OduxikMWh8kZkndd/2/XSEJnImGBacrGKNEj5UKBRziPeZ9jgQy0hgncm+iu9mCSQ92GydHM8JG
 MY90UJTp9MgyZSyIbqe5x9qmKtGm4Oi36bDD35ukl11KKbVcMzOh2ZXwIuk6nWBGwrtPBP2sti4
 5vl1kOqbOdbCsu3xG4zrh4CEDMqh0+L2+bwzg7rWQNBwpfaR6LQjKwR0HqhF1V0RLWhiF2T4pZi
 KKyZBG7ctPyMH
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Improves readability and makes splitting power on function in following
commit easier.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/touchscreen/stmfts.c | 36 ++++++++++++++++++++++++------------
 1 file changed, 24 insertions(+), 12 deletions(-)

diff --git a/drivers/input/touchscreen/stmfts.c b/drivers/input/touchscreen/stmfts.c
index a9f240bac201e..c1c9570ddea2d 100644
--- a/drivers/input/touchscreen/stmfts.c
+++ b/drivers/input/touchscreen/stmfts.c
@@ -519,22 +519,11 @@ static struct attribute *stmfts_sysfs_attrs[] = {
 };
 ATTRIBUTE_GROUPS(stmfts_sysfs);
 
-static int stmfts_power_on(struct stmfts_data *sdata)
+static int stmfts_read_system_info(struct stmfts_data *sdata)
 {
 	int err;
 	u8 reg[8];
 
-	err = regulator_bulk_enable(ARRAY_SIZE(stmfts_supplies),
-				    sdata->supplies);
-	if (err)
-		return err;
-
-	/*
-	 * The datasheet does not specify the power on time, but considering
-	 * that the reset time is < 10ms, I sleep 20ms to be sure
-	 */
-	msleep(20);
-
 	err = i2c_smbus_read_i2c_block_data(sdata->client, STMFTS_READ_INFO,
 					    sizeof(reg), reg);
 	if (err < 0)
@@ -548,6 +537,29 @@ static int stmfts_power_on(struct stmfts_data *sdata)
 	sdata->config_id = reg[4];
 	sdata->config_ver = reg[5];
 
+	return 0;
+}
+
+static int stmfts_power_on(struct stmfts_data *sdata)
+{
+	int err;
+
+	err = regulator_bulk_enable(ARRAY_SIZE(stmfts_supplies),
+				    sdata->supplies);
+	if (err)
+		return err;
+
+	/*
+	 * The datasheet does not specify the power on time, but considering
+	 * that the reset time is < 10ms, I sleep 20ms to be sure
+	 */
+	msleep(20);
+
+
+	err = stmfts_read_system_info(sdata);
+	if (err)
+		return err;
+
 	enable_irq(sdata->client->irq);
 
 	msleep(50);

-- 
2.53.0

