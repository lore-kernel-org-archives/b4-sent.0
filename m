From: David Heidelberg <david@ixit.cz>
Date: Fri, 03 Apr 2026 19:08:33 +0200
Subject: [PATCH WIP v3 04/11] Input: stmfts - abstract reading information
 from the firmware
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260403-stmfts5-v3-4-5da768cfd201@ixit.cz>
References: <20260403-stmfts5-v3-0-5da768cfd201@ixit.cz>
In-Reply-To: <20260403-stmfts5-v3-0-5da768cfd201@ixit.cz>
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
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpz/QP8lvBsnSoeLNS3kLwHE+ukHByluvgg4CGH
 EA7ol5HaTKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac/0DwAKCRBgAj/E00kg
 cjEPEACEeES+cw8KrgQ/FkfT1rtg5xVKw3K0g/1FQOBWO8wkru/JjO+YXcrkgneK1vfWuwF87zc
 Jx5q093Hyvr+oAqzHxo9tajfJt1ttI7IZ9NQPh9tPq/eWS9sumDxgE0riV//WpGhTjKvlrqKRej
 nlk41+OHeaR52WwJYXmlOYg2j/SJbr06YNs/U1K7HPmq1nZ/BJH9cpWCGQIUfPB4bDdr/R4oeI+
 frr1ZOhxVGQTkovkACicfhJ4zPVlSs7Yd3k8GzP8X1iC8/ZfnMudVWylSHoWjvBLmKZKgs8XIFT
 wAXxXDGxclf8alyObmGkAP/zSSumROCFcYd+STcIiybrI5IVuzTixaxpjBlHVJwQEilg9hGoF4r
 p0YrvNvu4QWpgQfGbDJvyBRBi10WIV8APkI/UhGLBg46NIHoC5WVxFNBrkUlqHhMvIj4YkYt5nc
 R6ZBL98/LraxqN3FhJc7KEFRj9P2xyLT0E7sxu5a/NKPdWLfOQ4jN1GHevzje8uBFC9uiku4Xbg
 r3MEWm03+AuzWJNim0h4suzJpMy+2M+P6bFH107s1yitNrI8YTgp2r1Vgi9IL5rB1NLHoj3VspC
 8PVo5OIrYihhKZflTWtCXCTHWCVO9zWCH/LWamEGjFxcIpKAYES2ztxzeBID1Ye7W2DQfGkBGTP
 X31kyDI8n5jo+4A==
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

