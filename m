From: David Heidelberg <david@ixit.cz>
Date: Thu, 10 Apr 2025 16:28:24 +0200
Subject: [PATCH v5 6/7] Input: synaptics-rmi4 - read product ID on
 aftermarket touch ICs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250410-synaptics-rmi4-v5-6-b41bb90f78b9@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1257; i=david@ixit.cz;
 h=from:subject:message-id; bh=fMXBJWuwOFgydtCp3BkAhLq4KC36XWjDlNvLR8bR7vw=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn99WFUqNTBVM/GY6vug1erJlsA3VIrAOgx4LSe
 gpvRBBp0l6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ/fVhQAKCRBgAj/E00kg
 cmYFD/sHqXVSPzp5jgWDXUwWxLaJdqhRo0zKA3Sz6LdcdCxfR/4HcpVHNhlRhqXUjjTaHFGkbAp
 AeVlpjCcq3kCrmJ2KOgME18orqIHtWHnSo1EcBy3bF3egVyhSiAEwyGP3xCtjsX88bXO/zcMD7J
 IsZDqcvL5UwgkOD2Gih0cU5UPXPgBNpmp3njS2j8WNEzjnozt06FfyT7bLFWD7hcCOB6f+L5tBS
 0wq+ANzjcvdumIC0Qw0ZNhqkYftRoNYy5M3JJ7GbRS3GvltUwFBFsksTp9W+hxx2hcBg+2+jbnt
 L1KyQd9WHNtvj6df+863IzkoUAO3aGajAWlkkDQu3IELOwPNesJLykQFt9aMoPTDEyOxqCveyk9
 OfbzOTE/dIjEeDxHKwS6OIUsODYpfcUtVMVjxlcjPWE0qXajDOQqxX66eIdQGlvjueqfEgk/yyu
 /lluzNpQt8QvfxtrvXXG00KX9nzbmyJr/k5DWMK/4dybkayWIXVLX+oRykudBLgHFQkj3PGmU16
 rs7JXjRevKZ/i0YWvUdjCy/+RDf2wgdwZ9rc7U53MtVHtENPuQHXzSTd46ffMN1GY9JB25mLH8K
 u4lXpVNWlXjU6HNi3VF7JbxVDxVyIfO/aV1DJLxCsG6j0BlCJ7G6pXnbRcGjQs84qSIypw2CSgF
 FJMtcbYGOgfOSBg==
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

