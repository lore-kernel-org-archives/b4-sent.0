From: David Heidelberg <david@ixit.cz>
Date: Thu, 09 Apr 2026 00:15:46 +0200
Subject: [PATCH v4 03/11] Input: stmfts - Switch to
 devm_regulator_bulk_get_const
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260409-stmfts5-v4-3-64fe62027db5@ixit.cz>
References: <20260409-stmfts5-v4-0-64fe62027db5@ixit.cz>
In-Reply-To: <20260409-stmfts5-v4-0-64fe62027db5@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2336; i=david@ixit.cz;
 h=from:subject:message-id; bh=FK/zsREY/XInSNUuszAKmQ33vgOOISGuAWF3OsBIumA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp1tOS/t9Q5M2mBMugd7+B1QN2+hFxl8CFpy5AT
 r9wo8bBUf6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCadbTkgAKCRBgAj/E00kg
 cskbEADD0uywNEE0C4Qby+S4+XcDg8r/GbAfO73ZJ/s7X57qvmjMTkGGfXcMP19sgrxkJcxhY2z
 zrrYel32XiQtz+OCps0jAH+zm/p3d4UUrKBOybWVORZnRSG399kFlnZcOItbNnHNPfEy+NFfqFS
 Jel//UoxSwOzXV3vdHyc/ts2NkKN+D83pJGXDhBMEeddrtlqySPhJfPNzYSotEGXac1ZLAccZln
 gxvoL5opp2EAq47kAQE7L12qzzqxGLxW8g8zxGmyGamabjlGjqDQe05fi7x4t9UsyDGEE5cPzko
 7zbjOk+YJ4JngzfvrKYbXU5iWxz0BDJxwnjXDDNIH2urZhM1C0e2BWMFxIYqFiW1JIsrGsAAgZg
 b8VdNdMtBxaO710QM5TjtJzUpHekWBtTQwl5ueJeQzXdmUurfzaNPW7M5ViP7BI7qUSV4k1VYA6
 plOTN0DmqnBmOivHy3lCfFqFWMODLtZ28gJcYPQB5EvO1BFcoa6YU396qSbRIa2ftw5aD4+KXfX
 FBw/qmyyZ2iBn2u+5VYO+7vf7aqDXjW1wVNNJwqGqeEB9ivdFJSU2KyhSt4qZ0S0FxwT9KeBoWX
 kXx06/kok7uLh7RiD62AwdGAmxepAhN5Q1NqsK+RXRMLoGyslXwQN1k33nqxlXYLcu67w0xXan7
 Ib7gBUWLHXj/tdA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Switch to devm_regulator_bulk_get_const() to stop setting the supplies
list in probe(), and move the regulator_bulk_data struct in static const.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/touchscreen/stmfts.c | 25 ++++++++++++-------------
 1 file changed, 12 insertions(+), 13 deletions(-)

diff --git a/drivers/input/touchscreen/stmfts.c b/drivers/input/touchscreen/stmfts.c
index 7b1e975a85668..ff884e04ad4c8 100644
--- a/drivers/input/touchscreen/stmfts.c
+++ b/drivers/input/touchscreen/stmfts.c
@@ -69,9 +69,9 @@
 #define STMFTS_MAX_FINGERS	10
 #define STMFTS_DEV_NAME		"stmfts"
 
-enum stmfts_regulators {
-	STMFTS_REGULATOR_VDD,
-	STMFTS_REGULATOR_AVDD,
+static const struct regulator_bulk_data stmfts_supplies[] = {
+	{ .supply = "vdd" },
+	{ .supply = "avdd" },
 };
 
 struct stmfts_data {
@@ -82,7 +82,7 @@ struct stmfts_data {
 
 	struct touchscreen_properties prop;
 
-	struct regulator_bulk_data regulators[2];
+	struct regulator_bulk_data *supplies;
 
 	/*
 	 * Presence of ledvdd will be used also to check
@@ -523,8 +523,8 @@ static int stmfts_power_on(struct stmfts_data *sdata)
 	int err;
 	u8 reg[8];
 
-	err = regulator_bulk_enable(ARRAY_SIZE(sdata->regulators),
-				    sdata->regulators);
+	err = regulator_bulk_enable(ARRAY_SIZE(stmfts_supplies),
+				    sdata->supplies);
 	if (err)
 		return err;
 
@@ -589,8 +589,8 @@ static void stmfts_power_off(void *data)
 	struct stmfts_data *sdata = data;
 
 	disable_irq(sdata->client->irq);
-	regulator_bulk_disable(ARRAY_SIZE(sdata->regulators),
-						sdata->regulators);
+	regulator_bulk_disable(ARRAY_SIZE(stmfts_supplies),
+			       sdata->supplies);
 }
 
 static int stmfts_enable_led(struct stmfts_data *sdata)
@@ -638,11 +638,10 @@ static int stmfts_probe(struct i2c_client *client)
 	mutex_init(&sdata->mutex);
 	init_completion(&sdata->cmd_done);
 
-	sdata->regulators[STMFTS_REGULATOR_VDD].supply = "vdd";
-	sdata->regulators[STMFTS_REGULATOR_AVDD].supply = "avdd";
-	err = devm_regulator_bulk_get(dev,
-				      ARRAY_SIZE(sdata->regulators),
-				      sdata->regulators);
+	err = devm_regulator_bulk_get_const(dev,
+					    ARRAY_SIZE(stmfts_supplies),
+					    stmfts_supplies,
+					    &sdata->supplies);
 	if (err)
 		return err;
 

-- 
2.53.0

