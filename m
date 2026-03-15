From: David Heidelberg <david@ixit.cz>
Date: Sun, 15 Mar 2026 19:52:42 +0100
Subject: [PATCH WIP v2 06/11] Input: stmfts - use client to make future
 code cleaner
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260315-stmfts5-v2-6-70bc83ee9591@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=999; i=david@ixit.cz;
 h=from:subject:message-id; bh=NjXdWrTyZ4AOoAMN8FANgtl5sLWDEzgbOr47MG8j63A=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBptv/5qkGhTYBwGm6+n5LMbiGmaXgdSYsz1eYSE
 Ggl5zzA+sqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCabb/+QAKCRBgAj/E00kg
 ci4wD/9H+6EPZMql8Si2W9hkziJlAifuPuI48m3hQ6EaoLCn1JV/ScaxW4RY95HrYgT28xyfwKl
 JUqdOBiTgQJQdSV2Dsc0FyMTr06BnXnMYTQaXZ+Q4ZGsfuerdylxbJ19YOLA/3JMjw1CfJdsHy7
 /mK8gdJDc3oPr+6kyde3hk5afi90oYN8LTNdDcf2ldPgGAKhnOfHOtbXfQzuU+reSNEe0M8qClf
 dXe4eRsyFdpZeoiZsBSRrYaSR7QkCc+lFWoUJNNjHbJIrxkDH5EU30XWIN8j4PYz576GAbE3aWc
 wJNq3ZheYbryH7Eq+riMQqPtyefk1ns/ERBv09JZOSYz0crh/9URS4rwy8dVoIQDLn4nHivzWFb
 +cKwYH3O48NlBfCY9M/KxUmAGMPPN5yAnQr5ze3MdcywvDhkwClk6tmm9NoeihwxlcnxK4MmwdB
 h61mx+2tFkpQy1rimaDTLFFTCWfiSGxAaxBHUeKAyNRIGaD/B+4Mjw9kDh76eRPcgdOrdpJShUI
 9DJPtL5wbAg4Ecux3t1yqYBsAtU0BshwV0lgKNBOCtpZ0OoQYnDATMj5tb3dt3h0+KH30rTChxG
 YbaAN/GXoD1VtHqI+wpMurzeVO9v2OGEeYVsjjArog1FM7WYvpZISJ44Ok1fng1PV2pT3hJ3aCb
 duIgAnQjAEzvirA==
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
index bf176907177d0..4dfaf3a6077d9 100644
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
2.53.0

