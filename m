From: David Heidelberg <david@ixit.cz>
Date: Mon, 15 Dec 2025 15:30:03 +0100
Subject: [PATCH 3/4] Input: stmfts - use sysfs_emit() instead of sprintf()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251215-fts-fixes-v1-3-8c1e3a63ebf1@ixit.cz>
References: <20251215-fts-fixes-v1-0-8c1e3a63ebf1@ixit.cz>
In-Reply-To: <20251215-fts-fixes-v1-0-8c1e3a63ebf1@ixit.cz>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, 
 Javier Martinez Canillas <javier@osg.samsung.com>, 
 Rob Herring <robh@kernel.org>, Andi Shyti <andi@etezian.org>
Cc: linux-input@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2787; i=david@ixit.cz;
 h=from:subject:message-id; bh=3xHAswUTtGvoQ6NmHBshFsBrqnYL61pqa0b3OMWeB7I=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpQBtrnuNSlCDEp3U0AMCL9StDPaBZkQm8UpZo5
 tdO7QEjWDuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaUAbawAKCRBgAj/E00kg
 ctYxEACflPTTG5VIeyFgwBgtxU3aAkYDozrwSyYm7rqhN45yyb+3Lj+UkzWI1NLtbuG1vk1o8Ql
 wcRbmjLeFtLKzOWvGprKN57MWOeQRduWiYWua/ZES83aVbK9SekWaxB3r7CAdMrPwjegBrDu7Lc
 cJDIz3yMv1AIEpwlN/eNxj85cpJP7F8+URLSuwE4NEGZcQ+AS/+nOmG0ri9WXvMz1WCs7GwZSL6
 AbOfbbHS0NVVJnSI0BqY1IlSzqBeQl9JSvGVqxgPiWXatmDFaWw+R/MDOiD/Eebfg6/S6onh4+Y
 K7ALIXs8jyrwovmA1FU0vVeHi/hRTvfQONG4G4r1vM4XceEVZyd8u4VHoN7O3M0RGIpxRa+X48/
 JYrrw0Bfe7tNzsl/m6tin9niNbdOQ6IULtAfRbA/E2PVaZDvm5VYRA5bIbb9fmWTnARq0vjshS9
 Cdk5P8sbVjT9Z5AACXDF/0cMszhIU1lnq6NA0rfIO2wfqgPqTPOI8sRdld2lnG0rz7F5NM/Pc6X
 nioeug9YnEXFUKhdPAfEGq/xFPNyE6nukMO9zV10WU/Duc0uE1n5gapGiXvuiwVUlbn+wYGhqpx
 D8vVJvrBlXjrtEtD15BONuFCNhJLSfMOrccvCSbTWRQyChqsrIOVVGkMHzQgZknDgF7OMM5pXMq
 kci2Br62lLhawTw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Petr Hodina <petr.hodina@protonmail.com>

Follow the advice in Documentation/filesystems/sysfs.rst:
show() should only use sysfs_emit() or sysfs_emit_at() when formatting
the value to be returned to user space.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/touchscreen/stmfts.c | 14 +++++++-------
 1 file changed, 7 insertions(+), 7 deletions(-)

diff --git a/drivers/input/touchscreen/stmfts.c b/drivers/input/touchscreen/stmfts.c
index ad363b3c344cd..4b166b0a9a5a6 100644
--- a/drivers/input/touchscreen/stmfts.c
+++ b/drivers/input/touchscreen/stmfts.c
@@ -410,7 +410,7 @@ static ssize_t stmfts_sysfs_chip_id(struct device *dev,
 {
 	struct stmfts_data *sdata = dev_get_drvdata(dev);
 
-	return sprintf(buf, "%#x\n", sdata->chip_id);
+	return sysfs_emit(buf, "%#x\n", sdata->chip_id);
 }
 
 static ssize_t stmfts_sysfs_chip_version(struct device *dev,
@@ -418,7 +418,7 @@ static ssize_t stmfts_sysfs_chip_version(struct device *dev,
 {
 	struct stmfts_data *sdata = dev_get_drvdata(dev);
 
-	return sprintf(buf, "%u\n", sdata->chip_ver);
+	return sysfs_emit(buf, "%u\n", sdata->chip_ver);
 }
 
 static ssize_t stmfts_sysfs_fw_ver(struct device *dev,
@@ -426,7 +426,7 @@ static ssize_t stmfts_sysfs_fw_ver(struct device *dev,
 {
 	struct stmfts_data *sdata = dev_get_drvdata(dev);
 
-	return sprintf(buf, "%u\n", sdata->fw_ver);
+	return sysfs_emit(buf, "%u\n", sdata->fw_ver);
 }
 
 static ssize_t stmfts_sysfs_config_id(struct device *dev,
@@ -434,7 +434,7 @@ static ssize_t stmfts_sysfs_config_id(struct device *dev,
 {
 	struct stmfts_data *sdata = dev_get_drvdata(dev);
 
-	return sprintf(buf, "%#x\n", sdata->config_id);
+	return sysfs_emit(buf, "%#x\n", sdata->config_id);
 }
 
 static ssize_t stmfts_sysfs_config_version(struct device *dev,
@@ -442,7 +442,7 @@ static ssize_t stmfts_sysfs_config_version(struct device *dev,
 {
 	struct stmfts_data *sdata = dev_get_drvdata(dev);
 
-	return sprintf(buf, "%u\n", sdata->config_ver);
+	return sysfs_emit(buf, "%u\n", sdata->config_ver);
 }
 
 static ssize_t stmfts_sysfs_read_status(struct device *dev,
@@ -457,7 +457,7 @@ static ssize_t stmfts_sysfs_read_status(struct device *dev,
 	if (err)
 		return err;
 
-	return sprintf(buf, "%#02x\n", status[0]);
+	return sysfs_emit(buf, "%#02x\n", status[0]);
 }
 
 static ssize_t stmfts_sysfs_hover_enable_read(struct device *dev,
@@ -465,7 +465,7 @@ static ssize_t stmfts_sysfs_hover_enable_read(struct device *dev,
 {
 	struct stmfts_data *sdata = dev_get_drvdata(dev);
 
-	return sprintf(buf, "%u\n", sdata->hover_enabled);
+	return sysfs_emit(buf, "%u\n", sdata->hover_enabled);
 }
 
 static ssize_t stmfts_sysfs_hover_enable_write(struct device *dev,

-- 
2.51.0

