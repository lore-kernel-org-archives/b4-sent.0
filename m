From: David Heidelberg <david@ixit.cz>
Date: Sat, 08 Mar 2025 15:08:42 +0100
Subject: [PATCH v3 6/7] Input: synaptics-rmi4 - read product ID on
 aftermarket touch ICs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250308-synaptics-rmi4-v3-6-215d3e7289a2@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1190; i=david@ixit.cz;
 h=from:subject:message-id; bh=fxuJtva2e8FaBzb+bW/oVy+YglxJV7q23OaA59oxqwY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBnzE9qpBbGcPsA3x2ZHJwwDVetMUitjwHkwxdpL
 GRZC7qAiN+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ8xPagAKCRBgAj/E00kg
 cqHJD/4yp/pHJI9xAQ7N2X0bGa8rE4STA/jHtd8IwnR8jCZHsN8u+2GmrD0D5wLeerPvvwQKKOc
 0l4qeOBKGKQ0TOpzf2LVNqxf+ml4J70rugkcTySRgjrY/XWAOpnr314xirqucDzWgdme16hDY44
 8c7cm/17fEUk0xw+qbFrFJJ70dGCr3U1vZEFJA3C45hMzPfwvQMQtf7mCdG5uEdqpUBcLcBQ6cS
 HhXcj9Is5e6Df/bc8sSY6fCyRiqdtYQYeHm3h/FzJk8Zr1zx2H7l9bdsYuunWuHIePY64A0nsCv
 E8YAZVn7uWQH/Ci3BlH1jgCA8jmifzk+eB4XIyLxzxItjcFmW32s4TO/bl5bMV6tciBxINW+FcP
 g38oR1dByV2Yjaqd8pPhUxsi242e9RgN8SVweq9IAtMIUzv2BAH4H9++kyLfMZoXf6FE1bXPrsc
 I/Q8JzJuknCwc3pY3dctxoJlGzbMQTUp+TQUMZD9vSXQmWpffTFrEc2jRXe+V6Vaw0aHQ4dqlW0
 8VnWCO4NmAtNfBmyBxJKp5+qNmiT17TQOUcBm9kJxx5CDCE/ZvJjxspOsnKFOsSCjE9lMWsq/hj
 Qn3JNN4N0Uj8g4nH4RrOXslwDPzx2Ftl07N9bwgxvd8Jqag+hAQD89OBYuibWuI6C/TEDrPNohL
 leiyOtthaX97seQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: methanal <baclofen@tuta.io>

Some replacement displays include third-party touch ICs which do not
report the product ID correctly unless we read directly from the
product ID register. Add a check and a fallback read to handle this.

Signed-off-by: methanal <baclofen@tuta.io>
Signed-off-by: Caleb Connolly <caleb.connolly@linaro.org>
---
 drivers/input/rmi4/rmi_f01.c | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/drivers/input/rmi4/rmi_f01.c b/drivers/input/rmi4/rmi_f01.c
index 47be64284b25ede8103ada86d6b58fd3a26976bb..2278e9b6a920774b07ec9dd3e452cedc69469be8 100644
--- a/drivers/input/rmi4/rmi_f01.c
+++ b/drivers/input/rmi4/rmi_f01.c
@@ -250,6 +250,20 @@ static int rmi_f01_read_properties(struct rmi_device *rmi_dev,
 		}
 	}
 
+	/*
+	 * Some aftermarket ICs put garbage into the product id field unless
+	 * we read directly from the product id register.
+	 */
+	if (props->product_id[0] < 0x20) {
+		ret = rmi_read_block(rmi_dev, query_base_addr + 11,
+				       props->product_id, RMI_PRODUCT_ID_LENGTH);
+		if (ret) {
+			dev_err(&rmi_dev->dev,
+				"Failed to read product id: %d\n", ret);
+			return ret;
+		}
+	}
+
 	return 0;
 }
 

-- 
2.47.2

