From: David Heidelberg <david@ixit.cz>
Date: Thu, 09 Apr 2026 00:15:48 +0200
Subject: [PATCH v4 05/11] Input: stmfts - disable regulators when power on
 fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260409-stmfts5-v4-5-64fe62027db5@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1834; i=david@ixit.cz;
 h=from:subject:message-id; bh=otDxlvvUy+vHqWnlpecsigv9uo2JKsE9RKwSL0jKxqM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp1tOSqxbb22SJazyTsOITYMHjjDrzpzJN7VpNu
 4ltZ1OQGniJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCadbTkgAKCRBgAj/E00kg
 cmzrD/4tZ0pmiTNrRcm3Y2eAc1o7V/ba3zu0DiVu8JqUrJ1yR3ITurB98GgXril/pT5MbPi9Z/C
 29ddmYiNjNewyip5qQD7oGYtlKx9peclhWk37mV1OsbrGScrmFPMbayNpwtXJY827ep2dfVZIlK
 8I4GyUUgZyTP8IDJ2g7oeudDLZVXV8vSMX5s4+6qMHecpp3/U3Kj49/LL88Xc9CvNc1aPzY87lZ
 Xm3hwBHlvRj7sEhxUv4sTgQWT/8YohJkA+srZfOJlAxhK1SBVlKATd1X100W3cNHaoakVtxDivh
 l/uTAX1FW5BxVxdzXhgWvbrqvwpGeGZUmlti/gbjpmL+ysz3ANWaW8gUNEFVYHbMS6jOzzj3d9S
 KQQbLDAREvM/D7c6XoA29y7dCjNjoYyyMPubUi9RgBhSX3DRKGtMif5WyUhl2h+3kSC6hSEIkn5
 Uqgk45GsgTtEdB2syjwbLPkaYGY/LXw9wsc5ONduLLTd2q3m52FThLf0LyxdK+7tNsz9qYKsLEc
 pZtK9QG+DfIJaFnY2GtewcKK+6TyZ+/ySIVMmxQo3O0vpafq1OYLi75OkEEJQ4lTlqOJ7jUqG2X
 bleIhh88KpQVs2DBplB5bMLJWyitMYGasnl7c0NY/mvy/mDIdiMQC/En//3ubLhHTxW2ppuEtm0
 ePllMuTArMZK1xw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We must power off regulators after failing at power on phase.
Create stmfts_configure function, so we don't have to use goto.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/touchscreen/stmfts.c | 37 ++++++++++++++++++++++++-------------
 1 file changed, 24 insertions(+), 13 deletions(-)

diff --git a/drivers/input/touchscreen/stmfts.c b/drivers/input/touchscreen/stmfts.c
index 71d9b747ccfc5..290511dd69437 100644
--- a/drivers/input/touchscreen/stmfts.c
+++ b/drivers/input/touchscreen/stmfts.c
@@ -539,22 +539,10 @@ static int stmfts_read_system_info(struct stmfts_data *sdata)
 	return 0;
 }
 
-static int stmfts_power_on(struct stmfts_data *sdata)
+static int stmfts_configure(struct stmfts_data *sdata)
 {
 	int err;
 
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
-
 	err = stmfts_read_system_info(sdata);
 	if (err)
 		return err;
@@ -596,6 +584,29 @@ static int stmfts_power_on(struct stmfts_data *sdata)
 	return 0;
 }
 
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
+	err = stmfts_configure(sdata);
+	if (err)
+		regulator_bulk_disable(ARRAY_SIZE(stmfts_supplies),
+				       sdata->supplies);
+
+	return err;
+}
+
 static void stmfts_power_off(void *data)
 {
 	struct stmfts_data *sdata = data;

-- 
2.53.0

