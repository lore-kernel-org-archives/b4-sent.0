From: Joel Granados <joel.granados@kernel.org>
Date: Tue, 24 Jun 2025 22:05:48 +0200
Subject: [PATCH RFC 1/7] nvme: Add nvme_cdq to the nmve_command union
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250624-jag-cdq-v1-1-6d88476c9165@kernel.org>
References: <20250624-jag-cdq-v1-0-6d88476c9165@kernel.org>
In-Reply-To: <20250624-jag-cdq-v1-0-6d88476c9165@kernel.org>
To: joshi.k@samsung.com
Cc: Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2623;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=d/8dK4a7KdwxbCg4t0hMR1pGLVUx/BbppFI+idgJpw4=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGhbBR22QfLtuBPskOld9mFjWjSFcnQG2eRZ1
 4mjiRH1M0bwXIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoWwUdAAoJELqXzVK3
 lkFPxigL/0//ASPhoT9Qcn3dqqvfih6/xRwGLwQ78GS0xuxu3G5uiPRyUKgQaaw7JQ9ocsSrWr9
 OXSsnVCE2NVO8hWCyQt384MlQinxnFb1DQZ1hPGBIbaCnIaQbHrVm1YRjrGc8baNP6jCy8o18m7
 DvggcYwbtUwfRDV96SiIJow2nl0vBz/yAoJJ/k0fG3F7tshGuRjin0mi1qsZ62zMC/fZpyzG6rq
 NhcxkpcwWV2vPXGLZ1qEyrrLbR7KCwmrNziw7vc06GrANTlOV8TQZhusvRhVrvo8thsmZieGqWo
 dxSus7OfUL959RmJbEtinUvevU/tAnjTr9Jhi1fUUZg+DOW4XrpW0Hlu7LiBSKKgfH+W46gcruy
 8WqevUUDy1hIUlOyKyKCwbYliFkXqsPFIeaO8Rfav4KOtvdtw1WPn53gRAPWUXGuCKHpenvUBrv
 fQDCWncMgO2EXTpowqH+JfWJj0/4d5qRJcCd+WXSOEBh5Bd0wKJwMwEdsxD65YHs2saJXZCWRY8
 aQ=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a new type of nvme_command (nvme_cdq) to the list. With it comes a
new CDQ feature identifier value (0x21) and an admin code (0x45). Only
consider the case where the memory is contiguous even though the
specification allows for non-contiguous PRPs.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/nvme/host/core.c |  1 +
 include/linux/nvme.h     | 30 ++++++++++++++++++++++++++++++
 2 files changed, 31 insertions(+)

diff --git a/drivers/nvme/host/core.c b/drivers/nvme/host/core.c
index 6b04473c0ab73c61e208bb8fc230c2f9b65c69bc..7be6b42a1adcc3fdb3cec2e2d0e73fcf74244590 100644
--- a/drivers/nvme/host/core.c
+++ b/drivers/nvme/host/core.c
@@ -5133,6 +5133,7 @@ static inline void _nvme_check_size(void)
 	BUILD_BUG_ON(sizeof(struct nvme_rotational_media_log) != 512);
 	BUILD_BUG_ON(sizeof(struct nvme_dbbuf) != 64);
 	BUILD_BUG_ON(sizeof(struct nvme_directive_cmd) != 64);
+	BUILD_BUG_ON(sizeof(struct nvme_cdq) != 64);
 	BUILD_BUG_ON(sizeof(struct nvme_feat_host_behavior) != 512);
 }
 
diff --git a/include/linux/nvme.h b/include/linux/nvme.h
index 2479ed10f53e37055973ea3c899060913923fa62..a2012ec00e60c2f0de1b06599ba39481eebe4263 100644
--- a/include/linux/nvme.h
+++ b/include/linux/nvme.h
@@ -1240,6 +1240,7 @@ enum nvme_admin_opcode {
 	nvme_admin_virtual_mgmt		= 0x1c,
 	nvme_admin_nvme_mi_send		= 0x1d,
 	nvme_admin_nvme_mi_recv		= 0x1e,
+	nvme_admin_cdq			= 0x45,
 	nvme_admin_dbbuf		= 0x7C,
 	nvme_admin_format_nvm		= 0x80,
 	nvme_admin_security_send	= 0x81,
@@ -1309,6 +1310,7 @@ enum {
 	NVME_FEAT_PLM_WINDOW	= 0x14,
 	NVME_FEAT_HOST_BEHAVIOR	= 0x16,
 	NVME_FEAT_SANITIZE	= 0x17,
+	NVME_FEAT_CDQ		= 0x21,
 	NVME_FEAT_SW_PROGRESS	= 0x80,
 	NVME_FEAT_HOST_ID	= 0x81,
 	NVME_FEAT_RESV_MASK	= 0x82,
@@ -1514,6 +1516,33 @@ struct nvme_directive_cmd {
 	__u32			rsvd16[3];
 };
 
+struct nvme_cdq {
+	__u8			opcode;
+	__u8			flags;
+	__u16			command_id;
+	__u32			rsvd1[5];
+	__le64			prp1;
+	__u32			rsvd8[2];
+#define NVME_CDQ_SEL_CREATE_CDQ	0x0
+#define NVME_CDQ_SEL_DELETE_CDQ	0x1
+	__u8			sel;
+	__u8			rsvd10;
+	__le16			mos;
+	union {
+		struct {
+#define NVME_CDQ_CFG_PC_CONT	(1 << 0)
+			__le16	cdq_flags;
+			__le16	cqs;
+		} create;
+		struct {
+			__le16	cdqid;
+			__le16	rsvd;
+		} delete;
+	};
+	__le32			cdqsize;
+	__u32			rsvd13[2];
+};
+
 /*
  * Fabrics subcommands.
  */
@@ -1923,6 +1952,7 @@ struct nvme_command {
 		struct nvmf_auth_receive_command auth_receive;
 		struct nvme_dbbuf dbbuf;
 		struct nvme_directive_cmd directive;
+		struct nvme_cdq cdq;
 	};
 };
 

-- 
2.47.2

