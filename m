From: David Heidelberg <david@ixit.cz>
Date: Sun, 01 Mar 2026 18:51:19 +0100
Subject: [PATCH 05/10] Input: stmfts - use client to make future code
 cleaner
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260301-stmfts5-v1-5-22c458b9ac68@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=999; i=david@ixit.cz;
 h=from:subject:message-id; bh=J6AT4NhPh73qOCpvlr3elkk31hc657GgBpzGKxirckY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBppHyUhUCNk886i9UHnFeU9WfswQgQdF4RB0CFY
 hE1WxDMyVSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaaR8lAAKCRBgAj/E00kg
 cv3hEADLtufWl141f1f1h14sRKMAUQ/PoEqhqbwRFbpVBK0+19MxXs+qgfz3O2zFaj2jijCLVtW
 ZuPmjvRGgQ/fZr3VS5JKnRSuWVxqrIWc7uYf0WO3UDw6VVzaTGkrJ5fdNPbHZAIH0jzaaDQAnfy
 z1stmZk9RWS0BVPkaz9C55qxwBVdATfJTb7+87BmRFJixu1WJeK/JWDgc+XrwOxtpFI3hQKSrH3
 oPNlm7ns/UbaS1gryeiXLSaXHl93B6IGwgDOouIJ7MHTIguincDwKfwoPOfekXpt0OUhyu5o9Tp
 JhD9BzftvNYOsZp4wfG0yngoJO2FWuROEF+aEqllVpgOar3RnbOkNOWImVHMWPLKRxLaj8uqYrK
 wfpier9Akmd0orG5s1TeqBhU7t1tqmChv2kOsXXgoYAKoMJU6/mUAZLISuDOa5p92//0j7MKDXs
 ADXPvTgxdunq9J/WL/tijtxwDfpDSvyoTxXsHMOvYuifChd+ZfnriG+xTQP+8iTpiNLSrHccI6y
 6pYEzSqcEWmGNjlEOad/2yS9DWnT/YRHAvMnlacgIjv6CJJou2PHt70CjY7xc2rPuA+ts/VBUNT
 lxrA/GIhYjS3Ufckok889Myqg6VupZ57VWysTrDxEKyfjgESgD/Hs/sKzQmNEUb4I3XIK2gEVRx
 FvYqik3DCVMk6OA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Petr Hodina <petr.hodina@protonmail.com>

Make code cleaner, compiler will optimize it away anyway.

Preparation for FTM5 support, where more steps are needed.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/touchscreen/stmfts.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/input/touchscreen/stmfts.c b/drivers/input/touchscreen/stmfts.c
index f4e5f1b3ce796..9dedccbb183ed 100644
--- a/drivers/input/touchscreen/stmfts.c
+++ b/drivers/input/touchscreen/stmfts.c
@@ -764,9 +764,10 @@ static int stmfts_runtime_suspend(struct device *dev)
 static int stmfts_runtime_resume(struct device *dev)
 {
 	struct stmfts_data *sdata = dev_get_drvdata(dev);
+	struct i2c_client *client = sdata->client;
 	int ret;
 
-	ret = i2c_smbus_write_byte(sdata->client, STMFTS_SLEEP_OUT);
+	ret = i2c_smbus_write_byte(client, STMFTS_SLEEP_OUT);
 	if (ret)
 		dev_err(dev, "failed to resume device: %d\n", ret);
 

-- 
2.51.0

