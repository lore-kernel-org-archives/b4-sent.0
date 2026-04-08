From: David Heidelberg <david@ixit.cz>
Date: Thu, 09 Apr 2026 00:15:49 +0200
Subject: [PATCH v4 06/11] Input: stmfts - use client to make future code
 cleaner
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260409-stmfts5-v4-6-64fe62027db5@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=999; i=david@ixit.cz;
 h=from:subject:message-id; bh=b/jklM1zbCQq0LgFU9O2NrDUidLzNIiCSesKs846UrE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp1tOSX/8wXIcBMj7wQU9sHsMyexCIa9bif82F+
 jn4O1E6y7uJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCadbTkgAKCRBgAj/E00kg
 cqcjEACw7KJL1B4IeGb5Y5BLhFGgrkasV9+ayx/oBWguyFHfkrIFB+xMFBltOu2p09IDBo1J4+p
 4qTRCWcb6YWbnDCLB9ROTbkJHB6FqnyqD0qHhzhCj6oe6bBX8VtwihwshYUqCMOiqYTPTfyZdYA
 zSPIchO03UcluHlUbSNzns5DBC8wz7OuPjcumDzo4Ookxf5SkDVFbL1jOsWIQaf9EV8NDTp0kYv
 Qd8zrfrmVJyd7TGsfqwYgEreMlu829h7AQSzyXM01kObdBqce32QrmXVCZvDMjTIXxkjy1YbmAJ
 gkWpCMn40rVe07LKoU1qu/Eur0SmHWQhrUqYTQP0NeUH9PpeQTOn7QqiY6cA2gGkzLLnt2KjDr3
 xlghMrox8RCtiMLMLcRJnJ26jJoDdxG+Omr8AE22F4bzHTUGQhZbBR/etFEzUAKKxXAxIu4By1X
 iReyQ06qNMqe2ZarSxS8YemKaFQa+TJ4kfHhjx/3k0v213zjyLkoRRBZxBy09lgIqJDCf9HsOpe
 fMArxmvZS0rqEKK82VhfTkuPnAPzTPV7FVjxCijX6gsJnS/DFfaqcIXXGWdnGAYnjby7VipMIz/
 lPcTzlVlCUbfVXC6WuirJsGcmE5Q+6v5jMgd1eq3D/gIEjipqbxu6SHj47+2DJ5T7zDrBW6FHh0
 a4CNzCUEFCnoVyQ==
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
index 290511dd69437..b61a19e954296 100644
--- a/drivers/input/touchscreen/stmfts.c
+++ b/drivers/input/touchscreen/stmfts.c
@@ -769,9 +769,10 @@ static int stmfts_runtime_suspend(struct device *dev)
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
2.53.0

