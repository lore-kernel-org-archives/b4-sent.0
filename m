From: David Heidelberg <david@ixit.cz>
Date: Thu, 09 Apr 2026 00:15:47 +0200
Subject: [PATCH v4 04/11] Input: stmfts - abstract reading information from
 the firmware
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260409-stmfts5-v4-4-64fe62027db5@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1821; i=david@ixit.cz;
 h=from:subject:message-id; bh=MRRMNTeMVS8qh5Y3wcBKjF6ySEKPpTml4To4kFWgqxE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp1tOSDBefFkQ6pmg/ESv1rmphll3moGBi4877/
 AdaIOG9cUOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCadbTkgAKCRBgAj/E00kg
 ci2eEADECFzczHHY3Pw3nIE/rotnNSqUwkRYNMEFGe9E4VNC5iFgbpJXPFfYNTTC4gXdevtmLO1
 7QJz6f+uU0/a3G2yD3nPkQS83GYu4J7uDTFtkuQsDQ18s53YPBE8qSYkQXoJPPpd2DHPbdq5YKe
 0jIKBqpffX5dmbgcc2eRxHV5gV97Sw7cgl9VKNxanE9NWpZr3NV5fc7MsrcKWSwaljGS43jDCIY
 KEf9IyFIfwtdSymkLbG3JTHR6JfQYoTpeXAbG6pjARjAclR/w1o8Vz79Ywj757eGg6Eg+MyQjPk
 sg5GdSWX2qjTaxMaiUjXoXjG/ZHqp8Y5RbH+wGxA6wYgq4Y7/4D/QqG2tWSqVzSCrY4feS7/6s0
 JGAdBH5Yz6UslhhAmjf5WM99L7LfvmCzoXdTu3XZupZ2G+VXs8C4NxsYMjEdcDjJaabDo7P0xfd
 Zzl/UgcHiMIgvEiYrYJOX9LdVyplaOE4sHSKD4nfallEMxdDX+XeMIYEAtFMDjCbVk5X+j+Vz41
 X7BSz4YcnVUuenHs66nZRHYyIl3RH8oyAnoIeeHg2jK9gjV3PuxDzCQ5ADe6rgC8KSW/SI340vc
 AWWcgF7gyLrOQVjwJadnY1XIvwgrAkfOZMPD3HQ5mtlmbLawInYnA+Aq1p4tBv3NGyfahtAAu6N
 WampsCjGPsTGc0A==
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
index ff884e04ad4c8..71d9b747ccfc5 100644
--- a/drivers/input/touchscreen/stmfts.c
+++ b/drivers/input/touchscreen/stmfts.c
@@ -518,22 +518,11 @@ static struct attribute *stmfts_sysfs_attrs[] = {
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
@@ -547,6 +536,29 @@ static int stmfts_power_on(struct stmfts_data *sdata)
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

