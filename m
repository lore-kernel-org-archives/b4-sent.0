From: David Heidelberg <david@ixit.cz>
Date: Wed, 02 Apr 2025 20:44:57 +0200
Subject: [PATCH v4 6/7] Input: synaptics-rmi4 - read product ID on
 aftermarket touch ICs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250402-synaptics-rmi4-v4-6-1bb95959e564@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1257; i=david@ixit.cz;
 h=from:subject:message-id; bh=fMXBJWuwOFgydtCp3BkAhLq4KC36XWjDlNvLR8bR7vw=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn7YWnijG6OkcpTVIBmk0cKl9KKtjytMDZK+55T
 r2VjtipXtuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ+2FpwAKCRBgAj/E00kg
 ck9nD/4tAdYAHLj2PTxpZT0SmmwgTSLss693LlWw6pZ/DiJx6dMyfIbrMOGqOsV7upY/YQGCrIQ
 PCBRh9JESfzUeB9uiNAUO0adcoDtLTktyRocx2usFlfQBN7PbTaavx00E1T9CFhnjGMdn7lRr2B
 +akyv8lP+arIBOF3MddHwVLWUHRJ5h46iOruN+pctMWWq6Orhg327GOyeheIlaUDhukszd5cZZ9
 r18qYhBVzHStD2mrLzx75tiFB08pPxscYp9HqgGgXCHGT3kw7swVV8sBFypanbKu/s1HGih+F0C
 WAnWUlZAoVPgTc0bsRWUET6It/xxQjLfKp4eyBsW68EOZ5khnKnd8XyIzx+W9wOdXbMcC1vCOeh
 2W+ptlfcyoMXfe5P2vuftNG+AamXz4dgksgxDkQ7Rt7ny32wjg0L+LJUeSOSovveH2jJLqsW25w
 4JpmBeVoijv8tjhF2GSppJY+7Awzgi4inLtG6e4/zgi4ugICEwek0T9pN/BMxlfmI+uHRyH/uu3
 PnQT5u68+MUwQccZ61wluLNjprqfON+lQAkJ0sXnDeR7i02KGGF9afEs8JwYIe87NTg0AtavEbz
 yDbRubuG1fJnoz3LZQQPDgNq33MluebvGmmwV6pKcByBhdLK3xgEGgspoRce5bq3UIBbDu4+Uot
 /Atyu/eJSZ+wduQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Kaustabh Chakraborty <kauschluss@disroot.org>

Some replacement displays include third-party touch ICs which do not
report the product ID correctly unless we read directly from the
product ID register. Add a check and a fallback read to handle this.

Signed-off-by: Kaustabh Chakraborty <kauschluss@disroot.org>
Signed-off-by: Caleb Connolly <caleb.connolly@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
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
2.49.0

