From: David Heidelberg <david@ixit.cz>
Date: Fri, 31 Jul 2026 22:34:15 +0200
Subject: [PATCH v9 4/5] Input: synaptics-rmi4 - read product ID on
 aftermarket touch ICs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-synaptics-rmi4-v9-4-f088c47af6c5@ixit.cz>
References: <20260731-synaptics-rmi4-v9-0-f088c47af6c5@ixit.cz>
In-Reply-To: <20260731-synaptics-rmi4-v9-0-f088c47af6c5@ixit.cz>
To: Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>, 
 Marcus Ramberg <marcus@means.no>, 
 Casey Connolly <casey.connolly@linaro.org>
Cc: David Heidelberg <david@ixit.cz>, linux-input@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1495; i=david@ixit.cz;
 h=from:subject:message-id; bh=0ZX7YD1h+ukbpiEVF+1UBqpg30+ZDcn5w6CgQP4D90Y=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqbQbL9kDNHl04tATOlcEIr/yxofbkl7EcbhWZC
 ioxIdPepYWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCam0GywAKCRBgAj/E00kg
 ckW4D/9gv+UAdqO3cjHjyI42Qnbxm+nHT3tXwG6zreed2KxC07y1b89ZYsyryI/uRf+EkaVr3x2
 Tja5uaqQ2ZrjHMzdr/iFX5jyqnCTMW5xWbMDMt9sDxVBgYmmdpM4+Iircb2MJKJO5vyLgjrtlxM
 h/VZxMHYErvlh3VeUpGtDaXPl2Jwy5L1zzCgR9UJPbmkx7RmgEeAc8dqXMoOlerN2ZnNrN/eORp
 Z95j87dSWo4Fz1PaKRsoe8l6Lr63w6ntXm2UITi9DMugebNQumd0pRDSuMZ8vunvuIhxIjyRF2B
 esYugAxPXsDuhjMa5P5OQsp26gMkxJ2JR/ghD1FhseBM1WrdcOIyERkSIfWAPl3f8Luzu6gMIey
 b40Jh4kL8pIPdpeyUAxI+8gBL+6oEDv9cnFH+1CsIy5PNPsXNuF2TUbEX1eTm5QxkFPnVIPSWbu
 dwo+7DCxeF+Y4WCULHy9C+eYfPH0nMjiqDl3zTKlPCpLaSfTKGk17xemlwgbwV8+uBA5WDjMD9l
 R1jzZY1qK6WQcKmdQv1CmlMhSXLVJ2BSDM5+k9ZLfRbTSgrF+xxaTLu3XKEWI/68hlT5IY7NfLg
 EUgx77r55rVKjCSW/eplwfhL9V0pGRr4BtJrNjSMDQwrtI4z6BE8ihzKCuASeFEh1HJH1VtW6rd
 YRK81VdOcQuoVyA==
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
@@ -245,16 +245,30 @@ static int rmi_f01_read_properties(struct rmi_device *rmi_dev,
 				return ret;
 			}
 
 			props->firmware_id = queries[1] << 8 | queries[0];
 			props->firmware_id += queries[2] * 65536;
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
 
 const char *rmi_f01_get_product_ID(struct rmi_function *fn)
 {
 	struct f01_data *f01 = dev_get_drvdata(&fn->dev);
 
 	return f01->properties.product_id;

-- 
2.53.0

