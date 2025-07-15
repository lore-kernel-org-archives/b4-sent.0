From: David Heidelberg <david@ixit.cz>
Date: Tue, 15 Jul 2025 13:49:05 +0200
Subject: [PATCH RESEND v5 6/7] Input: synaptics-rmi4 - read product ID on
 aftermarket touch ICs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250715-synaptics-rmi4-v5-6-ca255962c122@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1257; i=david@ixit.cz;
 h=from:subject:message-id; bh=Sh+t0WcseDQHFJEFbXieonJc4P0xUM6YkeQyPxTCtsk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBodkA0Iia17vtPtthzTNCm/Tbp/HKpiHjAJdN11
 zzrs3FOWEiJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaHZANAAKCRBgAj/E00kg
 clQSEACEiURfdgKtkgQFtUJQPEC7zzLRG9WdiPIDhH4DtERRzH9DU9E9qlfzF5S+bLnx+F7qdaf
 9+wsjRKnTROT+czEhCZrW2f/OmPmOYavRIma5UlF3/NA1LCL636sgt6D2ZUUFDzUvazbofYBdEd
 z5WkAOZ6VkdOK/HregncRxOCI49gHKRxvfTIU8d3qHYuJjvo6IagSsiD8BC+jBtgSDybdwmLyEK
 4al4xI82LY/YLd9j6YFBHUxF7q/58uNw5n6HI628Q9Bj3ry8zGKAPf430Joeg6mTsuJxd3fhVr9
 cZLTb5VbjCFhM0WLjF+TAlpqIMIcKvsHZiONiX6fmZnL4To9BFCxECD+SW2CubEYtqrNbzVTcE3
 mONx2gvBxuaLc4Jb43c+y4sEWdyNjCE9h2ZfHo1Um4FnZ9sYcS9m3tf2n1/i52NMKQs3od2VPA/
 0lXU5bssRHbXZZGGg1bDZRac9qZW5B45sg4sLZWrLMJC4qrzOQbq2IG5kM5POI3M5asO4iLfQ93
 DPORPq/YOsnRN2ScaSWs81ra6Lv2urlMls3tXeODJLe8dwSFwnj/aUVbCP0ByBu1UOFJznaPI20
 3aDRib/m14dyXS7KWCMM8zokR4U67mCc3NXA3KDAgw9w22WDhClPKsO5RrabgmyUb7zMXudXeHc
 iVIeLRmxOEJS4uw==
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
2.50.0

