From: David Heidelberg <david@ixit.cz>
Date: Thu, 31 Jul 2025 23:06:56 +0200
Subject: [PATCH RESEND v5 6/7] Input: synaptics-rmi4 - read product ID on
 aftermarket touch ICs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250731-synaptics-rmi4-v5-6-cd0d87d34afa@ixit.cz>
References: <20250731-synaptics-rmi4-v5-0-cd0d87d34afa@ixit.cz>
In-Reply-To: <20250731-synaptics-rmi4-v5-0-cd0d87d34afa@ixit.cz>
To: Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 ~postmarketos/upstreaming@lists.sr.ht, 
 Casey Connolly <casey.connolly@linaro.org>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1257; i=david@ixit.cz;
 h=from:subject:message-id; bh=foQKt41rQkAeUSTCVE7iH9xBlmzERmbzM9YslceBQZg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBoi9sAu/mrgfMKeArK4vh6IGkuRovnV9p7Dg8Qd
 izMhSnge8uJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaIvbAAAKCRBgAj/E00kg
 cvO2D/4758jMTi2wt46u0dMYho4JQK93gvpMFXOmSZ4yEd/qAXieqjaq9KhTlCfR7nq2zT7lC88
 y4Du/w1Ia56A/x166kgDBHbpCMAV6hsMQC8s8V9LeEx1QHc7+H8nH1MhWY1rsRXLeiCj6qEP1r5
 aaXLNSg/Xs55Bb4aSePSsStVSoMUkcTTbT6FnYEz6GjkbsUm3iPRwska4ShU+Mgaf3d/eSpld4e
 7YGrUk5jniMsnqaUp4lkm/Kqb1gXwn9Mef0VzXAXySuZPBB3mwG4cbLP1psqQmZVAe3cjwiGQ4g
 rSTy0gPgjYOEveWdf5OBTv5V4bNrtDqaw3+vsJhaiJJfEO9V24vgBZEccBhOSMys4Wpm2HtfYUs
 OhX+rud5tIDle2BbHJzePCabhfsei7fhK+mJBaMbvbETwpOSblK3l7R6Q0aPwSVWXuAIqpGO/8b
 lYMetz6P5DzdtHRU7IXVCwkOI3Dll+0guyPy0R+MjLHUfcMGGP7ntzUewKKZLJ1uQd9FMwofYs6
 ss2ZDXeyXEXGAIQ7S8A8c6xOSovrGKV726iBOhcFyNlvY9iuQ9YhJoVP1aDvTvGXvpFg2o/9uHU
 8tD/wbpmoSi0YSxanOyOPwSlRu+YuIEt9qD3oFYNM+GYxIo1ET3qFhOWTk9gi2jISoY0t9iZkrN
 VXd8ZSXOo62nM4A==
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
2.50.1

