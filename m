From: David Heidelberg <david@ixit.cz>
Date: Thu, 13 Nov 2025 17:31:00 +0100
Subject: [PATCH v6 4/7] Input: synaptics-rmi4 - f55: handle zero electrode
 count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251113-synaptics-rmi4-v6-4-d9836afab801@ixit.cz>
References: <20251113-synaptics-rmi4-v6-0-d9836afab801@ixit.cz>
In-Reply-To: <20251113-synaptics-rmi4-v6-0-d9836afab801@ixit.cz>
To: Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Casey Connolly <casey.connolly@linaro.org>, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1139; i=david@ixit.cz;
 h=from:subject:message-id; bh=3c7m3oCwzt57bdfzOwx4uaTuzzkZpYNYe5psNsQXnvw=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpFgfJcR4qe0+5DRKXSWW3W6rklEUP8UkSMOjdN
 Bapf6/wdZ6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRYHyQAKCRBgAj/E00kg
 cj79D/44yfCfEMxwOetB0IicsaWLthhNakP/wZaYrQtcOolPO+r+i6lLr+AgBowBgGim8HFT8da
 qPwLkNQvfvZLiTTenYTNGJ7p7aGhvEUtByPBO+L26Vym/GLYSIm/+6YXeRsyTCVXybn6kD278x/
 Otr6n+ri0Ft652mo/6HNVhwA1z0Oi0yaDOCdwoC1QSHlnY2xHeUMDbqf6TS42AblRGFiMVI854D
 5L0BjDvNlj4nPd7/a0YBOj1rOKeqS3VrCFfCYWH6KlWS51G9Y3drU19J8QdTGcVb1F4ZDgQsR0V
 RnYBEkjj2sGxGYnkv4aXJxv+hSxL/pZ0CiyAa4LS9Ymodmi4RAk1Ua9pCWLJNbzmXyioCZ/0gk7
 l/SJnB6ZrUgz2X1GSMsVUSDFdhFnDMuNRLMAEZMzEGi4gbeah9pFqkWZR4eWTcblR1TUR+tOqd4
 s7RTeUeaphrWbHbBK2itEQMuB5JkfsHblkiy9Sy3mO35zIWDtYPF9ZJNM7dL2BmDF79YDy5ddPn
 JAJTGbyU0o6sAyVvWY6MkX9G2jct925vKyU7RpVaBuCE3XBcPKiP6QU41h7VPygmPk3gg/P1XnF
 EO2jsew9yXrWKrxzucs9IvKLMLyrw3AXbJQwJteEZgz2p0wNTeH+WeJBwaOChrRPy4YH56CQxH+
 xgeugKgDnjLseAg==
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
2.51.0

