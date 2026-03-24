From: David Heidelberg <david@ixit.cz>
Date: Tue, 24 Mar 2026 20:40:37 +0100
Subject: [PATCH v8 4/7] Input: synaptics-rmi4 - f55: handle zero electrode
 count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260324-synaptics-rmi4-v8-4-2168d2df68f5@ixit.cz>
References: <20260324-synaptics-rmi4-v8-0-2168d2df68f5@ixit.cz>
In-Reply-To: <20260324-synaptics-rmi4-v8-0-2168d2df68f5@ixit.cz>
To: Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>, 
 Casey Connolly <casey.connolly@linaro.org>
Cc: David Heidelberg <david@ixit.cz>, linux-input@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1139; i=david@ixit.cz;
 h=from:subject:message-id; bh=AmUwE6dlCCX02pALY0B7wBasdQMVqYZC32vlnsSfL44=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpwuizsK4wbsCpKaelusCTqcOTmYH5iCrIp7Aaj
 bx1cvZplzeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCacLoswAKCRBgAj/E00kg
 cpSfEAC1mYqRx9nANs4VvHg3Eodu4ms5VZyhlwzQYVSPPPnue7tDOLzk+GnBJiavMuS6tf5FeK6
 +JsCIKEXZ6in228e6fwxbvyxIbb3d8tQOfFMbS4yzW8tL1gXd+mf7MJ+JB2dWYoloGkRMZIuMY6
 Zyhs/WQgbas5SC2nfDrE7S9BTKQzcVp3mQDbuXcNu9N0TS8C/51+5GFxh/zsrxDh8h0N5i84LZQ
 FvKQ/1gbibyfeiAZC+AKPARe621vqtfkCxJir3rsuCDKt/XGXg5pm2iLdjmNTdi+Kn29EKi9BLm
 WYJnX3C2rw98aW4e3c4+BcUjF92sfzKJztkyYVhvJDuVZnMbz2uZegD3+BpF+m3+5xwAUMStKuh
 XLiIUDu0oz+p+qYD5OSZefbEZ6cxSxHjqw23sGInCkO8I4fIYB0niCwEgbwN2vRFUST3nZBpjNp
 Uke+iyjyuy2+tA9hTN36qCws079kjeJCWRjbZr0QgUodS1K0Ri6vgTm0HJizU0UCY45gUm3FBw2
 0dhtrs8RA6eykM4Zh/Nz+savsgycC9/r2Drp0cMt7Lx8eGqTJhpG3EbuKKLlrJynQZ+V/k/EQCK
 ezRy9uRvzDUy9TKEIFX2fRa+Eru4ogWIgPihx0We7ptGbIt99l3Ycu1Z30DaEXR20FRhg/aqjFQ
 Rz6Jhsw3CGpwn5A==
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

