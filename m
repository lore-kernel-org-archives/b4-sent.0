From: David Heidelberg <david@ixit.cz>
Date: Sun, 01 Mar 2026 18:51:17 +0100
Subject: [PATCH 03/10] Input: stmfts - abstract reading information from
 the firmware
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260301-stmfts5-v1-3-22c458b9ac68@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1770; i=david@ixit.cz;
 h=from:subject:message-id; bh=LcR268CsLFX9IfFbR3m8SNFdiJ3g92w+33Vjc2KTWvw=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBppHyUWy/xfoO2DMWkvnS8Fo3kqaxb091fLqkJs
 yr4BN24YZ+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaaR8lAAKCRBgAj/E00kg
 cg5jD/0b2uRo3rzxQmo5CcalkkF0xubiFdZrbRZAflq92qK4+zrRzzXq42iZ5nMk/BYbtzm100G
 WpYXVpvzJXkhvbkF+fm4L+ZhYeAQ7Lp/FSrDrY0kcwlCDSMMsu5ptrIUTIjE1sL/Jp6oV571J6U
 +Nxio3frQuqOy1QTnq0Cb56/pC8eLFw/kkfxxoCYJ7w5iXU3Azp42xT9FeryOBosVKSUuCzYFZ5
 Y0r+x5SWY5t5UHPnni8piwCaJUqGZNh2kdOrhzC+7UTVp2yCuRWu1LFpr3y6n1kn/wIbnfn66d6
 Fglo+sr6ah9ROWcp1taGKX6OJIyQXOfUU5+do75qwLBlVwsaCRuxwX6f3UEjSo0MhqPhL9NbrHr
 igvOnKr8yBkIbKIXLmJn9nlC/AVE52hWUT3OVEi4tXAOoh08vMgRQWJDTusd/rboo6xv9PmJat5
 zwhTo5GTVGsANu33wnJKGIrw88FDW+/UMtvCRSA2VTbN8RWVpPECA8WkCdAmIWjGfWaf8lhB3fp
 rD9nKKpNJCzSbM6knCg69dXSXwVy8Am/+wNeioc3SJ9+0ZZ3I6De4GceMNKCwdqTxlurcd9DH8q
 enUW0gmPcWmuksR181zBO0HsFFG4vT6l5bE/U9SKeRE7QjEcyNPNRduVz6wk9OO7MIUzQtePR9b
 oWPsh/uRQCEpo7A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Improves readability and makes splitting power on function in following
commit easier.
---
 drivers/input/touchscreen/stmfts.c | 36 ++++++++++++++++++++++++------------
 1 file changed, 24 insertions(+), 12 deletions(-)

diff --git a/drivers/input/touchscreen/stmfts.c b/drivers/input/touchscreen/stmfts.c
index 7c0f94ba49464..db2dd0bb59fcc 100644
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
2.51.0

