From: David Heidelberg <david@ixit.cz>
Date: Thu, 10 Apr 2025 16:28:22 +0200
Subject: [PATCH v5 4/7] Input: synaptics-rmi4 - f55: handle zero electrode
 count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250410-synaptics-rmi4-v5-4-b41bb90f78b9@ixit.cz>
References: <20250410-synaptics-rmi4-v5-0-b41bb90f78b9@ixit.cz>
In-Reply-To: <20250410-synaptics-rmi4-v5-0-b41bb90f78b9@ixit.cz>
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
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn99WFwKp6ff+vZ6GDhp91Ltzu1lYjveQ2qOzR/
 eeY8Bl74OCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ/fVhQAKCRBgAj/E00kg
 cvXPD/4hbZ/koHOjQ27g0Ou3R7xnOaHpxzzWNvKT3Wa7du3vbvEhcVl9GjDqe50anwUV/LTvdxY
 oNd62daVeCNwhZj8xZnDY//w/EVqtdjfzkY9Qi3W/deu2I1TaRPzY6tqFxCAeMG4l47EZg2kQGZ
 VhkSQUYzI3d3h0GqbiwqyhOBzOmWRT3D4XMjg7TdaiSf57TPSz0WrkCNrl4C7xwH/rdh7BJrQkv
 XUd3RXj+GG53G8ydBdBDUcLCnzp8MUzd2zHvsOHVTcW5/E9OaVy5K9NAiG0Z8USpjf6EjA6KJky
 8NoYsb8axPLAo8SmbbJESM3Qq+3RA0vqUo7sT/+q6RYhmtmBN6Ay3P668aJ4zMz+hdOemN1kx6Y
 6C0PIgERil/MMWscwugJMIsA7Ot5Whz7WQShmp9wS8+aA2PoL2GoLJGXx+vr0aeGdzBF5Trk4x7
 rzm+eezJAUUza/X4ubQQEVqhVZETwojbQ4To191GS6APXcADth8hsivDHe28e2kn1ZW1fsliWxe
 biK4h/AH4Tx0tcZPv8uSVYNCJXxw99XXiu/bTPZF/BUb3CyiRG7VgME5Uz89wJbzLUHpsnbi1n/
 eK7ltffCwhAlU9S7bFA34sgSQno2hqUDSFxLENdDNdBn//dfKqGZC/rfux3sfvbfYM7F5W2kOB9
 96rsvC00T8U9eJg==
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

