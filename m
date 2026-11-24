From: Armandas Kvietkus <armandas.kvietkus@proton.me>
Date: Tue, 24 Nov 2026 18:43:00 +0100
Subject: [PATCH 1/4] firmware: qcom: scm: Add QSEE app start, shutdown and
 services image load
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-fpc1540-tee-v1-1-6c6985f05b06@proton.me>
References: <20261124-fpc1540-tee-v1-0-6c6985f05b06@proton.me>
In-Reply-To: <20261124-fpc1540-tee-v1-0-6c6985f05b06@proton.me>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Arnd Bergmann <arnd@arndb.de>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org, 
 Armandas Kvietkus <armandas.kvietkus@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795542180; l=4679;
 i=armandas.kvietkus@proton.me; h=from:subject:message-id;
 bh=kiEq95ST1or3ds4W0ln0vId1q7/z6qUKlXQN7xs7Bnw=;
 b=mibjb2GFW5pUbiegvhXEERwzhRGEtTzhh30gjZSjZIUx33OnOAhq/S1LNjdcEGM5APLCKpsvZ
 3wo/0RLRLKwAlWq74G8V9CsmoPGYABt6T3ZEQgVfypJzz1yzUN4O9pY
X-Developer-Key: i=armandas.kvietkus@proton.me; a=ed25519;
 pk=wuqmImJ9sKlDVcwALOvfGhjj7G8EBjjM4TpCdmlrAf8=
X-Endpoint-Received: by B4 Relay for armandas.kvietkus@proton.me/default with auth_id=974
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

qseecom can only talk to apps that are already running in QSEE. Add
the app manager calls to start an app from an image, shut it down and
load a services image such as cmnlib64.

Signed-off-by: Armandas Kvietkus <armandas.kvietkus@proton.me>
---
 drivers/firmware/qcom/qcom_scm.c       | 83 ++++++++++++++++++++++++++++++++++
 include/linux/firmware/qcom/qcom_scm.h | 23 ++++++++++
 2 files changed, 106 insertions(+)

diff --git a/drivers/firmware/qcom/qcom_scm.c b/drivers/firmware/qcom/qcom_scm.c
index fcb04441dd52..979e101280b6 100644
--- a/drivers/firmware/qcom/qcom_scm.c
+++ b/drivers/firmware/qcom/qcom_scm.c
@@ -119,6 +119,12 @@ enum qcom_scm_qseecom_tz_cmd_app {
 	QSEECOM_TZ_CMD_APP_LOOKUP		= 3,
 };
 
+enum qcom_scm_qseecom_tz_cmd_app_mgr {
+	QSEECOM_TZ_CMD_APP_START		= 1,
+	QSEECOM_TZ_CMD_APP_SHUTDOWN		= 2,
+	QSEECOM_TZ_CMD_SERVICES_IMAGE_LOAD	= 7,
+};
+
 enum qcom_scm_qseecom_tz_cmd_info {
 	QSEECOM_TZ_CMD_INFO_VERSION		= 3,
 };
@@ -2220,6 +2226,83 @@ int qcom_scm_qseecom_app_send(u32 app_id, void *req, size_t req_size,
 }
 EXPORT_SYMBOL_GPL(qcom_scm_qseecom_app_send);
 
+static int qcom_scm_qseecom_image_call(u32 cmd, phys_addr_t image,
+				       size_t mdt_len, size_t img_len,
+				       struct qcom_scm_qseecom_resp *res)
+{
+	struct qcom_scm_desc desc = {};
+	int status;
+
+	desc.owner = QSEECOM_TZ_OWNER_QSEE_OS;
+	desc.svc = QSEECOM_TZ_SVC_APP_MGR;
+	desc.cmd = cmd;
+	desc.arginfo = QCOM_SCM_ARGS(3);
+	desc.args[0] = mdt_len;
+	desc.args[1] = img_len;
+	desc.args[2] = image;
+
+	status = qcom_scm_qseecom_call(&desc, res);
+	if (status)
+		return status;
+
+	if (res->result != QSEECOM_RESULT_SUCCESS)
+		return -EIO;
+
+	return 0;
+}
+
+int qcom_scm_qseecom_app_start(phys_addr_t image, size_t mdt_len,
+			       size_t img_len, u32 *app_id)
+{
+	struct qcom_scm_qseecom_resp res = {};
+	int status;
+
+	status = qcom_scm_qseecom_image_call(QSEECOM_TZ_CMD_APP_START, image,
+					     mdt_len, img_len, &res);
+	if (status)
+		return status;
+
+	if (res.resp_type != QSEECOM_SCM_RES_APP_ID)
+		return -EIO;
+
+	*app_id = res.data;
+	return 0;
+}
+EXPORT_SYMBOL_GPL(qcom_scm_qseecom_app_start);
+
+int qcom_scm_qseecom_app_shutdown(u32 app_id)
+{
+	struct qcom_scm_desc desc = {};
+	struct qcom_scm_qseecom_resp res = {};
+	int status;
+
+	desc.owner = QSEECOM_TZ_OWNER_QSEE_OS;
+	desc.svc = QSEECOM_TZ_SVC_APP_MGR;
+	desc.cmd = QSEECOM_TZ_CMD_APP_SHUTDOWN;
+	desc.arginfo = QCOM_SCM_ARGS(1);
+	desc.args[0] = app_id;
+
+	status = qcom_scm_qseecom_call(&desc, &res);
+	if (status)
+		return status;
+
+	if (res.result != QSEECOM_RESULT_SUCCESS)
+		return -EIO;
+
+	return 0;
+}
+EXPORT_SYMBOL_GPL(qcom_scm_qseecom_app_shutdown);
+
+int qcom_scm_qseecom_services_image_load(phys_addr_t image, size_t mdt_len,
+					 size_t img_len)
+{
+	struct qcom_scm_qseecom_resp res = {};
+
+	return qcom_scm_qseecom_image_call(QSEECOM_TZ_CMD_SERVICES_IMAGE_LOAD,
+					   image, mdt_len, img_len, &res);
+}
+EXPORT_SYMBOL_GPL(qcom_scm_qseecom_services_image_load);
+
 /*
  * We do not yet support re-entrant calls via the qseecom interface. To prevent
  + any potential issues with this, only allow validated machines for now.
diff --git a/include/linux/firmware/qcom/qcom_scm.h b/include/linux/firmware/qcom/qcom_scm.h
index a0a6bc0229c4..1027907e27b0 100644
--- a/include/linux/firmware/qcom/qcom_scm.h
+++ b/include/linux/firmware/qcom/qcom_scm.h
@@ -143,6 +143,11 @@ int qcom_scm_shm_bridge_delete(u64 handle);
 int qcom_scm_qseecom_app_get_id(const char *app_name, u32 *app_id);
 int qcom_scm_qseecom_app_send(u32 app_id, void *req, size_t req_size,
 			      void *rsp, size_t rsp_size);
+int qcom_scm_qseecom_app_start(phys_addr_t image, size_t mdt_len,
+			       size_t img_len, u32 *app_id);
+int qcom_scm_qseecom_app_shutdown(u32 app_id);
+int qcom_scm_qseecom_services_image_load(phys_addr_t image, size_t mdt_len,
+					 size_t img_len);
 
 #else /* CONFIG_QCOM_QSEECOM */
 
@@ -158,6 +163,24 @@ static inline int qcom_scm_qseecom_app_send(u32 app_id,
 	return -EINVAL;
 }
 
+static inline int qcom_scm_qseecom_app_start(phys_addr_t image, size_t mdt_len,
+					     size_t img_len, u32 *app_id)
+{
+	return -EINVAL;
+}
+
+static inline int qcom_scm_qseecom_app_shutdown(u32 app_id)
+{
+	return -EINVAL;
+}
+
+static inline int qcom_scm_qseecom_services_image_load(phys_addr_t image,
+						       size_t mdt_len,
+						       size_t img_len)
+{
+	return -EINVAL;
+}
+
 #endif /* CONFIG_QCOM_QSEECOM */
 
 int qcom_scm_qtee_invoke_smc(phys_addr_t inbuf, size_t inbuf_size,

-- 
2.56.0

