From: David Heidelberg <david@ixit.cz>
Date: Sun, 09 Nov 2025 10:39:51 +0100
Subject: [PATCH RFC 8/8] media: qcom: camss: Remove D-PHY-only endpoint
 restriction
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251109-qcom-cphy-v1-8-165f7e79b0e1@ixit.cz>
References: <20251109-qcom-cphy-v1-0-165f7e79b0e1@ixit.cz>
In-Reply-To: <20251109-qcom-cphy-v1-0-165f7e79b0e1@ixit.cz>
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, Petr Hodina <phodina@protonmail.com>, 
 Casey Connolly <casey.connolly@linaro.org>, "Dr. Git" <drgitx@gmail.com>
Cc: Joel Selvaraj <foss@joelselvaraj.com>, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=959; i=david@ixit.cz;
 h=from:subject:message-id; bh=zDsFzpKtJmk7KEk5h22OnNp/nXx6STTnT1WeAcZBwYA=;
 b=owEBbAKT/ZANAwAIAWACP8TTSSByAcsmYgBpEGFzR5ywwp3YOPFsLYzk5y09hMnyI69rHKk2T
 p7r1//BEMmJAjIEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRBhcwAKCRBgAj/E00kg
 cu0MD/dBQ5LH7bVr49IyfhX1vXrMkQzuBHMIUfDpVDGWKWzVVznV9CcopTkNZbdz6lfcbfl/D3p
 dF2G68aYGuo79pBTTsX5LycIJZqqrYLl3CmMM/CA2YqpDydDlw0/O2zwCx67lb6Ir6JZ/knCX08
 IGInYTQD9FsrfdRhxjYJ+rkoJLefYTgA1MBY42O2KzyFVymbdf5bR5VnfY78E3vHCb4PGvny6+q
 tD+luO9u8EWKmKjY9lHE5Ybs5eINa+q+I7gGue99qaWb7MFtoK0NevIZ9ZObMMiKLSxxvp2T138
 c4n13yoIPaQ2tDX26Gb16hp+Vv2pP1pbXZnlv65xgRb0v99atQdoeOQX4UT/h+sYP52ldYfy2va
 CBQnxizONrKdhpNS1j0d34qhOLXu0fzipXASRvJdutGPITHfUG6NQTK1BVHAr+H5KuDxXGRmOyu
 TdIknVTiCm0MKYvM7Z/4InX0aV1g2uSmlmyJMG9BjCfFlEjurO7SQBI+69BOEzVMhujZa8LEIVj
 9NDVrOjJjagF1UEdFUhBW1Y2C9Eb7s7n3oSLFmv+tE6z7I7vlF04HH6U4Z/I1M9VDedMe2fzYh1
 uc3FIkug3CIzlP/CpYGDuPr241go4qkqSs5Sg0vT2aaNtSX80LqDUAbmAvz6KauHOsFHK/jy3ry
 7Qjq8E6v5qi1B
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

C-PHY mode is now supported, so the endpoint bus-type restriction to
D-PHY can be removed.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/media/platform/qcom/camss/camss.c | 9 ---------
 1 file changed, 9 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss.c b/drivers/media/platform/qcom/camss/camss.c
index 248aa6b21b5ad..1408e8a03f0bd 100644
--- a/drivers/media/platform/qcom/camss/camss.c
+++ b/drivers/media/platform/qcom/camss/camss.c
@@ -4044,15 +4044,6 @@ static int camss_of_parse_endpoint_node(struct device *dev,
 	if (ret)
 		return ret;
 
-	/*
-	 * Most SoCs support both D-PHY and C-PHY standards, but currently only
-	 * D-PHY is supported in the driver.
-	 */
-	if (vep.bus_type != V4L2_MBUS_CSI2_DPHY) {
-		dev_err(dev, "Unsupported bus type %d\n", vep.bus_type);
-		return -EINVAL;
-	}
-
 	csd->interface.csiphy_id = vep.base.port;
 
 	mipi_csi2 = &vep.bus.mipi_csi2;

-- 
2.51.0

