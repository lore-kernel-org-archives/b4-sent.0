From: David Heidelberg <david@ixit.cz>
Date: Sat, 08 Mar 2025 15:08:40 +0100
Subject: [PATCH v3 4/7] Input: synaptics-rmi4 - f55: handle zero electrode
 count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250308-synaptics-rmi4-v3-4-215d3e7289a2@ixit.cz>
References: <20250308-synaptics-rmi4-v3-0-215d3e7289a2@ixit.cz>
In-Reply-To: <20250308-synaptics-rmi4-v3-0-215d3e7289a2@ixit.cz>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 ~postmarketos/upstreaming@lists.sr.ht, methanal <baclofen@tuta.io>, 
 Caleb Connolly <caleb.connolly@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1120; i=david@ixit.cz;
 h=from:subject:message-id; bh=hiDNyT5E2yGpmjVDicyfKBuIVjPA9Ga1ra8J+txE4mY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBnzE9q/je0m4BVEyzjtbsSLpYZ/5ZJOh5xCum1o
 Uxcb0p2e+uJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ8xPagAKCRBgAj/E00kg
 cllnD/4tPKZRlakbfkLb68qJ2DccOXIB/VhozmmGfWeG1AhRiiA2as/S77FNWDRXS2ISV9ypUgL
 +n1qoOudQxEv+Q1yaPCZ3leWhrvraCqOtgDSXlNtk7iJjmhy6sIncaFWItFD83vyS6+zfEm8DMN
 oqR7R5yNYx/UrND2I6tS3H1EijqJEQr/K2XL9NB3WjrYq9fToGlTenLWQ5EKireO/J/bNB89oBR
 7cJyCIaT2jCZnMLWtjz2Pclshwl3tDtxg1gU6ZBGjz/SuT8WNu5EpMo4TrlPGEFjaYRpJOpDRBp
 hp6oxW1t2TO0IczN0xqwRrmZWApEV4GamxNXbZ5oHwhV86wGsMC1HEuQALdgKdJ2t6xDd8bB7Cm
 22ekesLXe1bn1DCLNGrxOP2rv/8KnC9URil6mY7QWMUszf7cQZ0sRro/5qdVH8NVAUqSZKOTdTt
 bEnCjYJKYbpBH7Zcxk3RvlCAt9ZWe3libiyiiZ32pjh5L1KUg9qxgfgBt1FCK7c/rkVl2ae6+0X
 uzxB+QZL+iKGg+TDprNB7Znab8XsaSLYxj3HKXS6uZoyvmC8S97KhqTinbmjaXYeHHWXQyBaV59
 XVh9GIBHzVCe/XioXCJ9Afqy/FwD9IKi7Q5PdZkI24E+KwtUFp4yraVs5abwT7eJCu3QotbF5h3
 RBplUBqCR/w9k5Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: methanal <baclofen@tuta.io>

Some third party ICs claim to support f55 but report an electrode count
of 0. Catch this and bail out early so that we don't confuse the i2c bus
with 0 sized reads.

Signed-off-by: methanal <baclofen@tuta.io>
[simplify code, adjust wording]
Signed-off-by: Caleb Connolly <caleb.connolly@linaro.org>
---
 drivers/input/rmi4/rmi_f55.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/input/rmi4/rmi_f55.c b/drivers/input/rmi4/rmi_f55.c
index 488adaca4dd00482cd1106d813b32871092c83a0..ad2ef14ae9f4e897473db43334792cc3de966d52 100644
--- a/drivers/input/rmi4/rmi_f55.c
+++ b/drivers/input/rmi4/rmi_f55.c
@@ -52,6 +52,11 @@ static int rmi_f55_detect(struct rmi_function *fn)
 
 	f55->num_rx_electrodes = f55->qry[F55_NUM_RX_OFFSET];
 	f55->num_tx_electrodes = f55->qry[F55_NUM_TX_OFFSET];
+	if (!f55->num_rx_electrodes || !f55->num_tx_electrodes) {
+		rmi_dbg(RMI_DEBUG_FN, &fn->dev,
+			"F55 query returned no electrodes, giving up\n");
+		return 0;
+	}
 
 	f55->cfg_num_rx_electrodes = f55->num_rx_electrodes;
 	f55->cfg_num_tx_electrodes = f55->num_rx_electrodes;

-- 
2.47.2

