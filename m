From: David Heidelberg <david@ixit.cz>
Date: Thu, 13 Nov 2025 17:31:02 +0100
Subject: [PATCH v6 6/7] Input: synaptics-rmi4 - read product ID on
 aftermarket touch ICs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251113-synaptics-rmi4-v6-6-d9836afab801@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1203; i=david@ixit.cz;
 h=from:subject:message-id; bh=fdg+12tEzxS7iHUQg0vbJynpAJ6kRapCVogkHxp+sbM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpFgfJJSUY09P6h/jPNxdHSCu3ss2AzYgdLsAQf
 40kLo686jaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRYHyQAKCRBgAj/E00kg
 cqsOD/9THOF3+00OTbZkhaH5F7LZR7lng7MGQ59Ew3D+EuiaZ7sTjIWBF/om2rwFDqOS7ZsFzf7
 mKWEI68HbXO5R5M38cOzsyolTb6Q+xdfp7MCUNKHNaCGn7tfrlSWFOYjb66PwZxUD4wTlpDFXL6
 DAuhi73YTgp+Du2n9QiwRojTH0cZFicStU4l5aFS/efxUkAeKOYZEpa/FZMRUrLWPiUhGnuswee
 pdVizwYMloQKq+3+ziueGRPNSkySNFm9uuCY++zTIzyLbJWD0/bJzhUBF/ypvCMe3LlnHcGtq3J
 TU0IBXUi46h8y6GR9ocBlC30p1yreB2yXHTioYQSPOqSSDan6EIo0Gl1HBA5gEvVY0Nbl1y2udR
 bU0OWwuTdTQACXbL3XUZwmmOTGBXPMimsQkrflx3EtyctOPXdGIleMBr9EnNRW5MNXNIq8nPYIm
 qKdBqx78dHSqJAjEIxkHEK5jG/0DNsHBQkPWwIH37L5ANGUXA2NWyvEA7hsy8JVwwUjZPjHPiW4
 dX+vBsXgUEdTFuMih5JJK0nZiYwys7rM9W3sg3/JbtFH93jkM9BkPX2jBN6YnWyGEzO2V3AyY9k
 2Onxkmot4F3riXdRmIhIUdyWjTEMwyz4MvsqECpHEp3X2B1vGVMxuLyAck+5Bawiz+EX9mz3GtV
 nt3lTNcrD3oXYpQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Kaustabh Chakraborty <kauschluss@disroot.org>

Some replacement displays include third-party touch ICs which do not
report the product ID correctly unless we read directly from the
product ID register. Add a check and a fallback read to handle this.

Signed-off-by: Kaustabh Chakraborty <kauschluss@disroot.org>
Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/rmi4/rmi_f01.c | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/drivers/input/rmi4/rmi_f01.c b/drivers/input/rmi4/rmi_f01.c
index 47be64284b25e..2278e9b6a9207 100644
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
2.51.0

