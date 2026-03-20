From: David Heidelberg <david@ixit.cz>
Date: Fri, 20 Mar 2026 17:44:45 +0100
Subject: [PATCH v7 4/7] Input: synaptics-rmi4 - f55: handle zero electrode
 count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260320-synaptics-rmi4-v7-4-379360de18d0@ixit.cz>
References: <20260320-synaptics-rmi4-v7-0-379360de18d0@ixit.cz>
In-Reply-To: <20260320-synaptics-rmi4-v7-0-379360de18d0@ixit.cz>
To: Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>
Cc: David Heidelberg <david@ixit.cz>, linux-input@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Casey Connolly <casey.connolly@linaro.org>, phone-devel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1139; i=david@ixit.cz;
 h=from:subject:message-id; bh=AmUwE6dlCCX02pALY0B7wBasdQMVqYZC32vlnsSfL44=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpvXl7/pqB1jbTnOT25HQzbiHjSJxghiXVEFt6P
 c+AXX9sjEeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCab15ewAKCRBgAj/E00kg
 crFUD/9KPBitTbe3GmT0dwbYVEkdnHvBGVEUT0z8TTB3Ovk+dE4my9X33BijUL52X53vWXx1ek0
 1VUAFpg95Uo0piNjuG/jplIoTHISeQhOjVriFgmyWvsQdqnNYhle+JBDRy2DNKJMo5enxRJcMrL
 gSkG6v+H6NIE0mDPTrWnDlcgNs/Q/coU/4mDojlN64/OtnqnvQWDrAghJKwO044lbWFmN4YhNu1
 fcQf67s9d02FVp4Wb6BoVKVFu4NvrNUcrxV1l8PojD+XTkDkhUiJ//1DUKexFYc4ffQsh+vBxMn
 TvmYjAhDKSWa9fFV3CvRma7GGsYmc3+VJF0smo4GJiBGt5E2axaOvauGNSDqOb0nWEWD9C3mFT5
 d6NvdgKqphchrYP/FcneYLjeg6cLZJZ4Plb3M1Ze6+OHy95GlaGpAem53TZdhQeReK8/p6bhJDd
 EgA1T3nxcPiltag+Vg2hQt/KxFiCnAlelhHX6mU5YmKENS8hI3YpcM+HeuGA8hjX8E+rruwJwLQ
 AFQ+GlEJ9TR/2S/rp3++ONjZG6C7/x3dv7dVTKWPP5e/M0ysepBFZjGp1P3+B5vAQXEzdCQS8Jg
 Cvdmm4fyVmOcMwJQSp2sG3nDMtDYs2weEVb19mcgj0D+Ny7lhkSu7gsoZRNuCBy5errnB9G1iU/
 x+xt48fBeaZTJkA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Kaustabh Chakraborty <kauschluss@disroot.org>

Some third party ICs claim to support f55 but report an electrode count
of 0. Catch this and bail out early so that we don't confuse the i2c bus
with 0 sized reads.

Signed-off-by: Kaustabh Chakraborty <kauschluss@disroot.org>
[simplify code, adjust wording]
Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/rmi4/rmi_f55.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/input/rmi4/rmi_f55.c b/drivers/input/rmi4/rmi_f55.c
index 488adaca4dd00..776c915b82e72 100644
--- a/drivers/input/rmi4/rmi_f55.c
+++ b/drivers/input/rmi4/rmi_f55.c
@@ -52,6 +52,11 @@ static int rmi_f55_detect(struct rmi_function *fn)
 
 	f55->num_rx_electrodes = f55->qry[F55_NUM_RX_OFFSET];
 	f55->num_tx_electrodes = f55->qry[F55_NUM_TX_OFFSET];
+	if (!f55->num_rx_electrodes || !f55->num_tx_electrodes) {
+		dev_err(&fn->dev, "%s: F55 query returned no electrodes, giving up\n",
+			__func__);
+		return -EINVAL;
+	}
 
 	f55->cfg_num_rx_electrodes = f55->num_rx_electrodes;
 	f55->cfg_num_tx_electrodes = f55->num_rx_electrodes;

-- 
2.53.0

