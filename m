From: David Heidelberg <david@ixit.cz>
Date: Tue, 27 Oct 2026 17:15:37 +0100
Subject: [PATCH v3] media: qcom: camss: Don't reject sensor links faster
 than 4x the CSIPHY timer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-csiphy-sdm845-limits-v3-1-c58917e14107@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNOQ7CMBQFr4JcY+QlMYGKeyCKeCMfkUW2sRKi3
 B07FKkQ5UjvzczIGwfGo/NuRs5E8NB3Cfh+h1RTd3eDQSdGjDBBKsaw8jA0E/a6rYoSP6GF4LG
 khmtZ21LzCqXr4IyFcdVeb1/2L/kwKmRXXjTgQ++mtRtp3v1JRIop1lwQaY8qZewFRggH9UY5E
 NmmONHih4IlhWBMy7IWRlqyKZZl+QBo78HLCwEAAA==
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3007; i=david@ixit.cz;
 h=from:subject:message-id; bh=YngNkwq0tcL9PzNnoy5oOuxivPBzZW+yX4YIxcz9VjA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq4M4sHysknjH4WTsZyWkGpInzz0sse10LN+oGu
 LzBgYQacXGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCauDOLAAKCRBgAj/E00kg
 ct0GEACJ8rn600wBR0k5Z1JbaLYFD61PRSQA05cvG01mbkv3yrDyjRxDJSDoLU1Hud9eZh0PlmN
 g3V0sUmz/i6gzp/bgieRRnXGLj7gTElwpYQORX04ggzT/Q+HB302jsvkuxuBUf2/Ly+9Zc9Uu3x
 2ThAX7a0ufkI7KlDtKJHtOTJPPNZkjxrErGYonI9bHNCIh6oifO4J9DUOew7lRnF0/UtvhUvZZj
 jonRCzQQOP63yxrS80V+uZXHrCfcnXaC6tVRBxpN+d9GrFCkjGNbAa+nkK+pP1m+wapQ5lyxODB
 Cen/fMp+IPA7zlXN6iE73Vf49+gHNnCvGZGOOE5hDIEdpaNsEg1BQQw3LtYzcPTJWYemukMq08s
 uqacGib7nDzC0lFq5Yj6VdipZhgf6R9df2pWOGYzZmwGF2FE7nwI8WHNiPc0YmWNNHZkR3C9X2b
 RIq1Dfl2CebMQlcpsNnRvbfhSI0+SI36LThMxKjlIa3eH9tanNcg8lyjJioC6B2YCxmnejl1+eQ
 U/70CCqLTn7UFWiHBmEUa8/Qoh6kZWiWREIjN4RWB3bJjYhZozCWwHr35DNC2ckI6hB4Tvy36oK
 n9glKnmFI77jx3URR4NZmCeqEwfqsYBAHf0x/zrkirs/4xSEtHQsQRpS0guLfxwdyDkHVoTwjkd
 Ln2CQ+ROZ/2mvxQ==
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

Fixes: bbde31047434 ("media: camss: Use optimal clock frequency rates")
Reviewed-by: Bryan O'Donoghue <bryan.odonoghue@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
Tested on SHIFT 6MQ with sdm845-next-20260820-9.
---
Changes in v3:
- Added R-b and Fixes: tag.
- Link to v2: https://patch.msgid.link/20260914-csiphy-sdm845-limits-v2-1-622db5a6ebf0@ixit.cz

Changes in v2:
- Drop the camcc change entirely; the 269.33 MHz ceiling stands. (Konrad)
- Fix the check in camss instead: clamp the timer clock to the highest
  listed rate rather than failing, matching the vendor driver.
- Link to v1: https://patch.msgid.link/20260822-csiphy-sdm845-limits-v1-1-d360bf7cd38f@ixit.cz
---
 drivers/media/platform/qcom/camss/camss-csiphy.c | 16 +++++++---------
 1 file changed, 7 insertions(+), 9 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy.c b/drivers/media/platform/qcom/camss/camss-csiphy.c
index f99eea2ef2289..985171276ce47 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy.c
@@ -159,25 +159,23 @@ static int csiphy_set_clock_rates_legacy(struct csiphy_device *csiphy)
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
base-commit: 151a134a4e6ec66f69db8750c66006f5207f7a9d
change-id: 20260822-csiphy-sdm845-limits-b1e3dbaf5d38

Best regards,
--  
David Heidelberg <david@ixit.cz>

