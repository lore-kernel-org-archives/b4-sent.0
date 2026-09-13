From: David Heidelberg <david@ixit.cz>
Date: Mon, 14 Sep 2026 00:04:01 +0200
Subject: [PATCH v2] media: qcom: camss: Don't reject sensor links faster
 than 4x the CSIPHY timer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260914-csiphy-sdm845-limits-v2-1-622db5a6ebf0@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNTQ6CMBBGr0JmbQ0tgsQV9zAsaDuVMfKTTiUg4
 e4WPIDLl3zfeyswekKGW7KCx4mYhj6COiVg2qZ/oCAbGVSqirRUShimsV0E26685OJFHQUWWmJ
 mdeNym5UQr6NHR/Ohvdc/5rd+ogm7a1+0xGHwy9Gd5L77k5ikkMJmRard1cSMq2imcDYfqLdt+
 wK+q0GsyAAAAA==
X-Change-ID: 20260822-csiphy-sdm845-limits-b1e3dbaf5d38
To: Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Bjorn Andersson <andersson@kernel.org>, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2724; i=david@ixit.cz;
 h=from:subject:message-id; bh=4Cq9bOXeGKICKWJHpNyYvsyQ9j7GJVD/aYCdslBWgjk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqpx3SFUalm5mC9E2nv/wBYp16G9lduNx5j352M
 stJXr6XkPWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaqcd0gAKCRBgAj/E00kg
 clLbD/4+CjTgR2qBsW2lv29+7ydJstXFbe0MqkBjKJBxK33hfox9lLhnbqy40UzSWx+UyBb8+rO
 aZttSoYguDNXTTZ5aooSzzhwCS1X1DXK1bIta7WQ1ubiSPRytWD7FbMQTBqmqIqqjf3UuaPr0PS
 SiYvqj8B11J8z/xYaCCz7JDIddW0nd9fJeLw2HxMPUDIPjfPYfcBoIbXoitX5ShrbUvATIBfX0N
 CvvfBu6lDHu9/p/Kz7/A7NhyHCTng2FdtqYhyDh/TTF64GPeHv/+7JzEmYLTG6HOG9nXoJSfMww
 0weqpHGm7sUn/aqPCQir4Fn3SGBlVSHHeV/hP420TSSWWn4dMygoLDR9XbnGFhd6Ehq7IywRBZH
 0OtVyBNyC9Kf7Y388ECqFePMaexPcaxqbqK0gaAWzuhbsTNPFidr+NITA5H7ZnyWesLVkS79dq/
 PK2D+tzihFgnrx52q4iQ4qythhVarC3VnT7WYS3wfii601fTfoxG90QgXZN3awXN0iubcqdilxH
 +YZpRPH6tlN7uB4WSNzdUCh0u+ml4ROD8E8A5+N8YL1db5etY9dierXJUUeT794ekW2SIm8L1fk
 Fh5HiSx7cl3dC9QOGJZ9JvXH4z8vHPWEyMJL4gUHN0Q+TGo8FcdEfGe1nltlvB9h7i+l2PldQSs
 SjvDXAZPrTv0Krg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The timer clock has no such relationship to the link rate. Both the 2ph
and 3ph code use it only as the reference for csiphy_settle_cnt_calc(),
where a faster link makes the settle count smaller, not larger: at
269.33 MHz the count converges to 16 as the link rate grows. The vendor
driver pins the timer to 269.33 MHz for every sensor (it is the highest
rate in the SDM845 clock plan) and streams this exact link with it.

Clamp to the highest listed rate instead of failing, the same way the
unknown-link-rate case is already handled.

Solves issue on sdm845 that caps the link at ~1.02 GHz,
so the Samsung S5K2X7SP, ~2.3 Gbps/lane, link 1.15 GHz) fails with
Pixel clock is too high for CSIPHY

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Tested on SHIFT 6MQ with sdm845-next-20260820-9.
---
Changes in v2:
- Drop the camcc change entirely; the 269.33 MHz ceiling stands. (Konrad)
- Fix the check in camss instead: clamp the timer clock to the highest
  listed rate rather than failing, matching the vendor driver.
- Link to v1: https://patch.msgid.link/20260822-csiphy-sdm845-limits-v1-1-d360bf7cd38f@ixit.cz
---
 drivers/media/platform/qcom/camss/camss-csiphy.c | 16 +++++++---------
 1 file changed, 7 insertions(+), 9 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy.c b/drivers/media/platform/qcom/camss/camss-csiphy.c
index 539ac4888b608..f3d17ea0ab515 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy.c
@@ -157,25 +157,23 @@ static int csiphy_set_clock_rates(struct csiphy_device *csiphy)
 			long round_rate;
 
 			camss_add_clock_margin(&min_rate);
 
 			for (j = 0; j < clock->nfreqs; j++)
 				if (min_rate < clock->freq[j])
 					break;
 
-			if (j == clock->nfreqs) {
-				dev_err(dev,
-					"Pixel clock is too high for CSIPHY\n");
-				return -EINVAL;
-			}
-
-			/* if sensor pixel clock is not available */
-			/* set highest possible CSIPHY clock rate */
-			if (min_rate == 0)
+			/*
+			 * The timer clock is only the reference for the
+			 * settle count and does not need to track the link
+			 * rate. Use the highest listed rate when the link is
+			 * faster than the table covers or unknown.`
+			 */
+			if (j == clock->nfreqs || min_rate == 0)
 				j = clock->nfreqs - 1;
 
 			round_rate = clk_round_rate(clock->clk, clock->freq[j]);
 			if (round_rate < 0) {
 				dev_err(dev, "clk round rate failed: %ld\n",
 					round_rate);
 				return -EINVAL;
 			}

---
base-commit: 7079a12d7506b07fb53b54a664bfad5fa9b16d70
change-id: 20260822-csiphy-sdm845-limits-b1e3dbaf5d38

Best regards,
--  
David Heidelberg <david@ixit.cz>

