From: Joel Granados <joel.granados@kernel.org>
Date: Tue, 24 Jun 2025 22:05:53 +0200
Subject: [PATCH RFC 6/7] nvme: Add Controller Data Queue (CDQ) ioctl
 command
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250624-jag-cdq-v1-6-6d88476c9165@kernel.org>
References: <20250624-jag-cdq-v1-0-6d88476c9165@kernel.org>
In-Reply-To: <20250624-jag-cdq-v1-0-6d88476c9165@kernel.org>
To: joshi.k@samsung.com
Cc: Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2018;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=bfC2MogadITVuvh4V1MQ+7UqvOr9WOJ8eghd+VmSC7k=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGhbBSD77QOAiS77V9UHxjlXfdcaNtHMoLwHE
 x6B8Qnmn4DlXYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoWwUgAAoJELqXzVK3
 lkFPI1gL/3dlPZKcq8qzv8AhKqeKbpmFb7NSLsJrUtO8AGdNJCkXqpVfDccbEGkpdLhFl9ZLfC8
 wqfX9Afqwj6CTnNOE3ZLlxqZT6w7orX1wP2fyL4WEHaP26/qrZrKJwCiclB22An1l7QgN1vlyob
 YY1In1Ea6mxJv72kaN8x9ofoHEydlUkBesWBBwQLo61klNR4TTjSx1f+wJqcbeLwJaWrQq4pgJu
 q/IL6Cd8aBQTTJ5Bs81jv6KeUhqO+XiTqEUIdMPaws/ySAcn88tEhr0lphaBmgIi1gysPDnX6CS
 GtgeTbv5oyFbXK8E7f60RaXNdRDfjPIT+b8xaR+9h1kW2dyPMm2CyV4d2yN2b0fPmT4bOeMt6Lk
 wLJfbpWWxYxf27GOjmIk80GX+1djzbyhf4eci84G94bEAoGkz+vuhFcZQp5/+eiQFyyXSY8mEe3
 dDNr5imSrhhN7rtSBnkvwdzRCmOScD3daaIynLEDq7mmOMOi9Aoxp8IJS9WbvHufWLQwNGowPj6
 wg=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add new ioctl command to create and delete a CDQ. The action is
controlled and set by using NVME_CDQ_ADM_FLAGS_{CREATE,DELETE}.

Creating a CDQ:
  Set the following memebers:
    * flags must be set to NVME_CDQ_ADM_FLAGS_CREATE
    * entry_nr: Number of CDQ entries
    * entry_nbytes: size in bytes of each CDQ entry
    * cqs: Create Queue Specific. Value depends on CDQ type
    * mos: Management Operation Specific. Value depends on CDQ type
    * cdqp_{offset,mask}: Location of CDQ Phase tag bit within an entry
  Values returned
    * cdq_id: The identifying value set by the controller for the
      created CDQ
    * read_fd: The file descriptor that can be used to read the CDQ

Deleting a CDQ:
  Set the following members:
    * cdq_id: The CDQ that is to be deleted

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 include/uapi/linux/nvme_ioctl.h | 18 ++++++++++++++++++
 1 file changed, 18 insertions(+)

diff --git a/include/uapi/linux/nvme_ioctl.h b/include/uapi/linux/nvme_ioctl.h
index 2f76cba6716637baff53e167a6141b68420d75c3..de38f5f653bd92985db92de5800326a6c18dde3b 100644
--- a/include/uapi/linux/nvme_ioctl.h
+++ b/include/uapi/linux/nvme_ioctl.h
@@ -92,6 +92,21 @@ struct nvme_uring_cmd {
 	__u32   rsvd2;
 };
 
+struct nvme_cdq_cmd {
+	__u32	argsize;
+	__u32	flags;
+#define NVME_CDQ_ADM_FLAGS_CREATE	(1 << 0)
+#define NVME_CDQ_ADM_FLAGS_DELETE	(1 << 1)
+	__u32	entry_nr;
+	__u32	entry_nbyte;
+	__u16	cdq_id;
+	__u16	cqs;
+	__u16	mos;
+	__u32	cdqp_offset;
+	__u32	cdqp_mask;
+	int	read_fd;
+};
+
 #define nvme_admin_cmd nvme_passthru_cmd
 
 #define NVME_IOCTL_ID		_IO('N', 0x40)
@@ -111,4 +126,7 @@ struct nvme_uring_cmd {
 #define NVME_URING_CMD_ADMIN	_IOWR('N', 0x82, struct nvme_uring_cmd)
 #define NVME_URING_CMD_ADMIN_VEC _IOWR('N', 0x83, struct nvme_uring_cmd)
 
+/* Controller Data Queue: */
+#define NVME_IOCTL_ADMIN_CDQ	_IOR('N', 0x84, struct nvme_cdq_cmd)
+
 #endif /* _UAPI_LINUX_NVME_IOCTL_H */

-- 
2.47.2

