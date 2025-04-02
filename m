From: David Heidelberg <david@ixit.cz>
Date: Wed, 02 Apr 2025 20:44:55 +0200
Subject: [PATCH v4 4/7] Input: synaptics-rmi4 - f55: handle zero electrode
 count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250402-synaptics-rmi4-v4-4-1bb95959e564@ixit.cz>
References: <20250402-synaptics-rmi4-v4-0-1bb95959e564@ixit.cz>
In-Reply-To: <20250402-synaptics-rmi4-v4-0-1bb95959e564@ixit.cz>
To: Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Caleb Connolly <caleb.connolly@linaro.org>, 
 phone-devel@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1193; i=david@ixit.cz;
 h=from:subject:message-id; bh=H6bOmSExs0ZAgCP3cU3lwTLmd7Kss/M3Mr3SFnE+ZgM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn7YWn4JQyFb7VhDg5lLgW60stVOWrBynm+ok1A
 na4mWl3IM+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ+2FpwAKCRBgAj/E00kg
 clq1D/9DsKFFzs5oylrtmlIOR9XlaQqSEQDBrlgF8OFfTswnh95jneM0QWsJdXt4GCOZ7ydhaWc
 XnRFAFk45zSU9iZHgxYjwWFxFV6mKP/eKacB2f+nEmX01Qj/KcKgeYkPAQybnwUNnoWlnHR9PSn
 R+ZYkVH5YRbkRLSKsnTpWz/UX7/tkRiH5Z4aRD4iaqwpRPUSMZW56wcOFy53Em+cYsiDCQLj9Bd
 nkKlZPzkGBzT3euAHy1+Ut/sIIKl5vfQSNbCZb2rz4UywBtE3yORM2YWjPViFQMFio6gG8NovD7
 aDdZ+BEXMT3rNf/xopKg1hdDvoZAlCuIEAZq9O80LdlFagZnMAeGE+8fCco/AOalFmgeliqEphQ
 XLWL5cIsiXIhkF3Zj9C2srrV/Ez+xF+cHzhoFsPqnySHPI21TCHXCJkNhodmj6hhqWon8wJR2rL
 7Pgg0mCsHzb6R1cPPHyH2xawSH+nrj5dsFjXlDYMwtsVW3axa8fPVzd1bPDkC2P8q7UTy63ioaG
 Zv7IYR3pY0dDgQzbjgfMNe+64QNQKhNt8nMiTaMrJL1S4osbgS0f70EEa8cpg2hpER42XvIw7bS
 pqXa3EhOZlm9bS3wETzyMLeCTGpi0/zPWq36FGDa5V/WqP12TxBzfm57f4Rb9Zl8QKQZ6vKBlv6
 wsdP8Ld+wY56Esg==
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
Signed-off-by: Caleb Connolly <caleb.connolly@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/rmi4/rmi_f55.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/input/rmi4/rmi_f55.c b/drivers/input/rmi4/rmi_f55.c
index 488adaca4dd00482cd1106d813b32871092c83a0..776c915b82e72b8a6eb5ec701cce9059c87089c4 100644
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
2.49.0

