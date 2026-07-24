From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 24 Jul 2026 13:10:56 +0200
Subject: [PATCH RFC v2 02/14] nvme: Add NVMe Controller Data Queue command
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260724-jag-cdq-lkml-v2-2-659a7449e849@kernel.org>
References: <20260724-jag-cdq-lkml-v2-0-659a7449e849@kernel.org>
In-Reply-To: <20260724-jag-cdq-lkml-v2-0-659a7449e849@kernel.org>
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Chaitanya Kulkarni <chaitanyak@nvidia.com>, Jason Gunthorpe <jgg@ziepe.ca>
Cc: linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3542;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=AZy2WTqOKzVRegCf28nvQJjMyVdHQz6BP3DV6TkjK9g=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGpjSFrWCyLD22UG7qKq/OMjAgVA1sOtD01sl
 bmdPnT8hw5KD4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqY0haAAoJELqXzVK3
 lkFP4pkL/3PeJxuMTzMA9qAWTcWk0ycTHCE6SA2NFl5AYprn9XXu7TyOMAGzTsk6rEm3KWbj9L5
 i3ert5Jd+DMdp5DQPKZKTblhyUa7QbYh8RM+Qnej04y7+Ysd+QdVNdV+NXNSV7jNIpd+n+m4iMF
 7P62wmJP3qJi7f5+xNG3SS3n+FHiZUXW/jNa8ezZCKd3KW4/OMGxdz1pKlmsLOBoNKbsQU0v2gn
 H0AEDsUrInE1CNGrEp/LOVg3veYyzp/FhMiVdwR8tF5nVMXSFCEH23IKbJ+NJF8Bza7dzVbQRfs
 LWpmfNzsDvPTA0kMWVxVgmB9+iCS18c4hrvdR/2DO060kfLY3pDpCelylPlLUa2/GF+SIZmmirJ
 t2Ol2foyS65NYG/rQ187sm2ZwOBYIiqqkOK024VTgkNmoH2GOHDQqs8MhAZ8OBmn+KAiEo/s5zi
 8kfTniQoGcnBeYZygauOoTGZJXP8+AoMParKfKkyZXVD/33lU2trn17wnT2sDsKebGTS91vyX56
 zw=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the struct (nvme_cdq_cmd) and define the relative values to support
NVMe Controller Data Queue management.
* struct nvme_cdq_cmd: Is the CDQ mgmt command
* nvme_cdq_cmd_mgmt_op: Specifies create or delete
* NVME_CDQ_CMD_MGMT_CREATE_*: Specifies the create operation.

No functional changes are included as this is a preparation commit.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/nvme/host/core.c |  1 +
 include/linux/nvme.h     | 45 ++++++++++++++++++++++++++++++++++++++++++++-
 2 files changed, 45 insertions(+), 1 deletion(-)

diff --git a/drivers/nvme/host/core.c b/drivers/nvme/host/core.c
index 6e7533ccf24bfe3df7188f442986ec18a3200660..d11858300ad43f3e229eab7f2dd77563075b801e 100644
--- a/drivers/nvme/host/core.c
+++ b/drivers/nvme/host/core.c
@@ -5387,6 +5387,7 @@ static inline void _nvme_check_size(void)
 	BUILD_BUG_ON(sizeof(struct nvme_directive_cmd) != 64);
 	BUILD_BUG_ON(sizeof(struct nvme_lm_send_cmd) != 64);
 	BUILD_BUG_ON(sizeof(struct nvme_lm_recv_cmd) != 64);
+	BUILD_BUG_ON(sizeof(struct nvme_cdq_command) != 64);
 	BUILD_BUG_ON(sizeof(struct nvme_feat_host_behavior) != 512);
 }
 
diff --git a/include/linux/nvme.h b/include/linux/nvme.h
index 60fb5b6808615ff7388f30e12ffe6ed5da2ef4f6..1c20ddc06a46066b5ab9acf1dc44b03d941592a9 100644
--- a/include/linux/nvme.h
+++ b/include/linux/nvme.h
@@ -1639,6 +1639,7 @@ enum nvme_admin_opcode {
 	nvme_admin_nvme_mi_recv		= 0x1e,
 	nvme_admin_lm_send		= 0x41,
 	nvme_admin_lm_recv		= 0x42,
+	nvme_admin_cdq			= 0x45,
 	nvme_admin_dbbuf		= 0x7C,
 	nvme_admin_format_nvm		= 0x80,
 	nvme_admin_security_send	= 0x81,
@@ -1679,7 +1680,8 @@ enum nvme_admin_opcode {
 		nvme_admin_opcode_name(nvme_admin_security_send),	\
 		nvme_admin_opcode_name(nvme_admin_security_recv),	\
 		nvme_admin_opcode_name(nvme_admin_sanitize_nvm),	\
-		nvme_admin_opcode_name(nvme_admin_get_lba_status))
+		nvme_admin_opcode_name(nvme_admin_get_lba_status),	\
+		nvme_admin_opcode_name(nvme_admin_cdq))
 
 enum {
 	NVME_QUEUE_PHYS_CONTIG	= (1 << 0),
@@ -1710,6 +1712,7 @@ enum {
 	NVME_FEAT_PLM_WINDOW	= 0x14,
 	NVME_FEAT_HOST_BEHAVIOR	= 0x16,
 	NVME_FEAT_SANITIZE	= 0x17,
+	NVME_FEAT_CDQ		= 0x21,
 	NVME_FEAT_FDP		= 0x1d,
 	NVME_FEAT_SW_PROGRESS	= 0x80,
 	NVME_FEAT_HOST_ID	= 0x81,
@@ -1739,6 +1742,10 @@ enum {
 	NVME_FWACT_ACTV		= (2 << 3),
 };
 
+enum {
+	NVME_FEAT_CDQ_ID_MASK = GENMASK(15, 0),
+};
+
 struct nvme_supported_log {
 	__le32	lids[256];
 };
@@ -1917,6 +1924,41 @@ struct nvme_directive_cmd {
 	__u32			rsvd16[3];
 };
 
+//Select values for dword 10
+enum nvme_cdq_cmd_mgmt_op {
+	NVME_CDQ_CMD_MGMT_CREATE = 0x0,
+	NVME_CDQ_CMD_MGMT_DELETE = 0x1
+};
+#define NVME_CDQ_CMD_MGMT_CREATE_MOS_QT_UDMQ	0x0
+#define NVME_CDQ_CMD_MGMT_CREATE_PC_CONT	0x1
+#define NVME_CDQ_CMD_MGMT_CREATE_PC_DISCONT	0x0
+
+union nvme_cdq_cmd_dw11 {
+	struct {
+		__le16	flags;
+		__le16	cqs;
+	};
+	struct {
+		__le16	cdqid;
+		__le16	rsvd;
+	};
+};
+
+struct nvme_cdq_command {
+	__u8			opcode;
+	__u8			flags;
+	__u16			command_id;
+	__u32			rsvd1[5];
+	__le64			prp1;
+	__le32			rsvd8[2];
+	__u8			sel;
+	__u8			rsvd10;
+	__le16			mos;
+	union nvme_cdq_cmd_dw11	dw11;
+	__le32			cdqsize;
+	__u32			rsvd13[3];
+};
+
 /*
  * Fabrics subcommands.
  */
@@ -2335,6 +2377,7 @@ struct nvme_command {
 		struct nvme_directive_cmd directive;
 		struct nvme_lm_command lm;
 		struct nvme_io_mgmt_recv_cmd imr;
+		struct nvme_cdq_command cdq;
 	};
 };
 

-- 
2.50.1

