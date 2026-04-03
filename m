From: David Heidelberg <david@ixit.cz>
Date: Fri, 03 Apr 2026 19:08:35 +0200
Subject: [PATCH WIP v3 06/11] Input: stmfts - use client to make future
 code cleaner
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260403-stmfts5-v3-6-5da768cfd201@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=999; i=david@ixit.cz;
 h=from:subject:message-id; bh=lbYMNOyikKvzSOq1O72SDp83zLBiEDw5AionEdJRDJQ=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpz/QQADNC8bWKbBtksX+13HyaXLaUKZUVfxXHk
 07gDDNOQnGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac/0EAAKCRBgAj/E00kg
 cmJ+D/9IK24uy72rHSw+JqStVL356K7AGLtPpHDc95QFrDKE2f2kUT+x6P7o9SqSBP3I1N76QCD
 6yV7c32f1U/8vgx4zNLD4Z/3ncV94IaEAwfxLB5SiG2Hxe7NC4JQZAzTQCIBIfl3u8wlZFxqf1H
 uqfRt5Cu0hJDH1+51p/pvBrcIiAjdCd0zAKDO9tAk4HLkjTF9VJvgZF55DdNjWpZSeyv+ePxStR
 E4J1l7kvFvA2mOdFGhSQVlc5RGZjgHHRRIcPx5mUNk/nqqeTUBgNMGcnp9r/KTS/T0O4FqKkizw
 eLFz0q7mwyUfBhGKdC699DKtT4EwoLROVYBnzx2DvWjKfizwj4B8BRuR2/ULcVP0wh68zGBVg3c
 QtwgVIbgSKH0g9FKBVNDUxNT/WmTXzoPvuON8IhKMGOFAtBcuRJ3YyXrTvr/hMhKK5e10Gy6JJu
 VGzMtIsdysc4tjxbl2xGjR7XcxH/cJ4R/YdVoogMS1hBceSFnXYJJA/HpF+lVmeNvOJQeP2EAgY
 eGgxMZQG8fbvXLYwtDTbdUTlAExnFHsd1Ap/m9RochKmbCPILoxPmm9qcDE2o9BvwuPNJ8lbAhG
 da801WhDMPR1dUkdi8ANdK4IQHZxs+WDmQnBUfQ7G8s5hKPVI9gLbN0grqKm+agBqRZw8ZK+G7t
 KxJYscsQBkZfYKw==
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
index a90528b76f52b..5f7de5e687da2 100644
--- a/drivers/input/touchscreen/stmfts.c
+++ b/drivers/input/touchscreen/stmfts.c
@@ -763,9 +763,10 @@ static int stmfts_runtime_suspend(struct device *dev)
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

