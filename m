From: David Heidelberg <david@ixit.cz>
Date: Tue, 15 Jul 2025 13:49:03 +0200
Subject: [PATCH RESEND v5 4/7] Input: synaptics-rmi4 - f55: handle zero
 electrode count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250715-synaptics-rmi4-v5-4-ca255962c122@ixit.cz>
References: <20250715-synaptics-rmi4-v5-0-ca255962c122@ixit.cz>
In-Reply-To: <20250715-synaptics-rmi4-v5-0-ca255962c122@ixit.cz>
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
 h=from:subject:message-id; bh=A7OEIYExnthRZy4ymNUZNgZK4sBdBKSSdlBwvDvnG2E=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBodkA0QZAibncQ1s/mo8VQvjALZfHDgWvMVr1nt
 tYHJcP7LY+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaHZANAAKCRBgAj/E00kg
 cuDcD/46CbHny1DxeQA6WAL0HoJPZz4HDmuIqAd6q6Bn3jt1oXvkQAHjr5ldRee7pyCJ+EN2Hq0
 HeHpOUlvszPWcBboJqjtJ5kzuTncCDx+JsgY6ZeG31fu5VvBnoR77IDkDfoXhStq1G89GFFHTYS
 ngZFqWQ/MV2PpVLbGV5XGgrrFD3vNcbslGYulHyNGOHkKwk6O1nUf3gVvO6r6pgwZIY7ULxzckl
 GcOQU4Mz3ntJUiyaY09ZW3hI8FF7WmtDK/YIS/uk7rQoGCDhRO5dqNqRRE9jP6p/HiFn8IUpsFw
 fQaWi0ZS5mHkIYfs7NSXBr78tlaT8KyKAxZX66h6vOhbjtPr2bFLpassZJBH9RJWN/jQ4On7Qhn
 uonHZCs4Yq7YZqeCELf69MZ3p2inpXCd1noFedz/FGdDXeT7xaWCcSaNsRk3HGBUvKQR12Dllyi
 rOU/5hRM747Nf8pKrvE8D57QAS/d0ljnVl39Gx5ccF7tuRqQrj0Bv6zl71YjcToOncYPNokSbC6
 BRNkW6sztjLfLxtgimLJp3WjJk43EL3OkVVKOZ2vDpHFjjhxZqY22F43/2IOvogMhl2EEvaKFn6
 4RLmFPlLW2BxaRQXn779d9wqp+j5k6r3Fbse2Y+rkkRadm3unj7ogrPnvPmeMxvlm+hgervyDOD
 EGRLstT/93Up2pQ==
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
2.50.0

