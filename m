From: David Heidelberg <david@ixit.cz>
Date: Tue, 24 Nov 2026 23:02:47 +0100
Subject: [PATCH v4] media: qcom: camss: Don't reject sensor links faster
 than 4x the CSIPHY timer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-csiphy-sdm845-limits-v4-1-f39f9149b62e@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4XNywrCMBCF4VeRrI1kJr3pyvcQF00ysSNeSlNLa
 +m7myooLsTlgZnvH0WghimIzWIUDXUc+HqJI1kuhK3Ky4Eku7gFKsxUgSht4LoaZHDnIknlic/
 cBmmAtDOlT50uRHytG/LcP9nd/rXDzRzJtrM1X1Qc2mszPLsdzHd/Eh1IkE5nyvjcxozfcs/ty
 t7FHOjwQ6wh+UFgJDJEZ9IyI+PVN6HfBCjMfxA6EjYt1pATJKDyDzFN0wOlc7/vTgEAAA==
X-Change-ID: 20260822-csiphy-sdm845-limits-b1e3dbaf5d38
To: Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Todor Tomov <todor.too@gmail.com>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Bjorn Andersson <andersson@kernel.org>, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3233; i=david@ixit.cz;
 h=from:subject:message-id; bh=ochRMDocSCeX7Q8h0M1gcBIPdY3ayiUWJfkM116gdZ4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrBgmIfWQ8kSxonNKGJu66CneXdPYw15r2NNJLO
 OiPPPEZlN2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawYJiAAKCRBgAj/E00kg
 cuXuD/9woMc8aXmQRwX/klS4HBOrhKnWOdHCx+CqlQASJ6KXM2UP3OiVqfwUFjeg74wu+Fqr7li
 VW2g/jK/fmUrVZDchZKZ7wABQrkJlTC6sW/tZJBVjWTe5FuM0oRTeSRrNsxMNkOSCm3aJwnlwcF
 PicfOLHXVEMzBRBH2YZ/dqpsyIFC+ONY+y2LIgni+yCoIp5hH/vTx4mlQai5fUgDWXJ/OunT1Ts
 Fe4yLzcjVaxtA16bOWb1RMoNUx8xxMel3tQHDIiPhEcmnTyvw/UT8Tyef7Tm9ogQ0yHdPn1k9Kl
 sC8uPr6hbD8Mmsmo71bzbiszimmMt9Bv57bKVSm6sWR/86VkUCraoAcdR7ShAv613Wq4EIUG2dt
 3mCQQ2JjOo3WNeDr5uQ0wTEG4ANZ7hv1vUi5oiqQ/pCNAF8cbHEp3D9FmRP7LzcGaVD/Vd0r25o
 2kam/INm9jDLtRcZFXYrnC3CjaomGL93h+jym2324De2wk//KxLLeScNbWoNaZbSk4/ly+U/RQf
 lRknt/rIkBS9cHAtRzjaxrpAu+ccOdWxLlO2HxU3J7Lr2wD/z089mu2hcF0fSqmsm5dyfgVc66M
 ZVNONOg6VfPDrcNhBVPpymXRrQFfh5kKeaB4O+CY78d3pib8TVDF9RTEETRaWKKwOA1jvIye9Wm
 9UhKuqHJUHzMijw==
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
Reviewed-by: Loic Poulain <loic.poulain@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
Tested on SHIFT 6MQ with sdm845-next-20260820-9.
---
Changes in v4:
- Fix stranded ` and rebased a top of next-20261120.
- Link to v3: https://patch.msgid.link/20261027-csiphy-sdm845-limits-v3-1-c58917e14107@ixit.cz

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
index cdb803843792c..459175709670f 100644
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
+			 * faster than the table covers or unknown.
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
base-commit: 909ef7a9a30fa139e69e555e3606680f5cca7726
change-id: 20260822-csiphy-sdm845-limits-b1e3dbaf5d38

Best regards,
--  
David Heidelberg <david@ixit.cz>

