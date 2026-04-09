From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Thu, 09 Apr 2026 23:04:13 +0530
Subject: [PATCH v3 2/5] net: qrtr: ns: Limit the maximum number of lookups
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260409-qrtr-fix-v3-2-00a8a5ff2b51@oss.qualcomm.com>
References: <20260409-qrtr-fix-v3-0-00a8a5ff2b51@oss.qualcomm.com>
In-Reply-To: <20260409-qrtr-fix-v3-0-00a8a5ff2b51@oss.qualcomm.com>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2866;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=IhZvm8cwMMv2YMLHez1GlQYA3ZymEM0NuV9RTHrTenE=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBp1+MV6OOS+sE0Q6zOPdpJZF2nE6VonDdOb+TxP
 hrY1Ji3OLWJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCadfjFQAKCRBVnxHm/pHO
 9WXLB/9S7FKGRYTtolf8iR5ePF1KEB2WQk1Qpp5SGBNW/iXpRv9hyvuz3I62myAwFIa3S0sLKB/
 OYTpOcNZUA45tWNTYDmK53WCvPzdzW9K9AAMdGY4uO3ie/n/BI+5jV1DSB92aio+96tyCwPrhqk
 LGc5CP1E/4PQP3XyDDMky2+B046uh2RG8PWddHTJZPrxnZj2O3xV+njwNhHBeIKGKWENWSGTZbf
 LvAYfaRTqrWeHlhsCUybfJhjDRpxzsTMbrryTAqL6mbZU1acXjnViczU/1l3Y7rs1S4PdDhOFAm
 4QdcXmZ6Ug6MSqfAzjv8EcT0SxWnAKIYDGV60JHvKTYxlkEm
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Current code does no bound checking on the number of lookups a client can
perform. Though the code restricts the lookups to local clients, there is
still a possibility of a malicious local client sending a flood of
NEW_LOOKUP messages over the same socket.

Fix this issue by limiting the maximum number of lookups to 64 globally.
Since the nameserver allows only atmost one local observer, this global
lookup count will ensure that the lookups stay within the limit.

Note that, limit of 64 is chosen based on the current platform
requirements. If requirement changes in the future, this limit can be
increased.

Cc: stable@vger.kernel.org
Fixes: 0c2204a4ad71 ("net: qrtr: Migrate nameservice to kernel from userspace")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 net/qrtr/ns.c | 14 ++++++++++++--
 1 file changed, 12 insertions(+), 2 deletions(-)

diff --git a/net/qrtr/ns.c b/net/qrtr/ns.c
index 63cb5861d87a..5b08d4d4840a 100644
--- a/net/qrtr/ns.c
+++ b/net/qrtr/ns.c
@@ -22,6 +22,7 @@ static struct {
 	struct socket *sock;
 	struct sockaddr_qrtr bcast_sq;
 	struct list_head lookups;
+	u32 lookup_count;
 	struct workqueue_struct *workqueue;
 	struct work_struct work;
 	int local_node;
@@ -70,10 +71,11 @@ struct qrtr_node {
 	u32 server_count;
 };
 
-/* Max server limit is chosen based on the current platform requirements. If the
- * requirement changes in the future, this value can be increased.
+/* Max server, lookup limits are chosen based on the current platform requirements.
+ * If the requirement changes in the future, these values can be increased.
  */
 #define QRTR_NS_MAX_SERVERS 256
+#define QRTR_NS_MAX_LOOKUPS 64
 
 static struct qrtr_node *node_get(unsigned int node_id)
 {
@@ -433,6 +435,7 @@ static int ctrl_cmd_del_client(struct sockaddr_qrtr *from,
 
 		list_del(&lookup->li);
 		kfree(lookup);
+		qrtr_ns.lookup_count--;
 	}
 
 	/* Remove the server belonging to this port but don't broadcast
@@ -550,6 +553,11 @@ static int ctrl_cmd_new_lookup(struct sockaddr_qrtr *from,
 	if (from->sq_node != qrtr_ns.local_node)
 		return -EINVAL;
 
+	if (qrtr_ns.lookup_count >= QRTR_NS_MAX_LOOKUPS) {
+		pr_err_ratelimited("QRTR client node exceeds max lookup limit!\n");
+		return -ENOSPC;
+	}
+
 	lookup = kzalloc_obj(*lookup);
 	if (!lookup)
 		return -ENOMEM;
@@ -558,6 +566,7 @@ static int ctrl_cmd_new_lookup(struct sockaddr_qrtr *from,
 	lookup->service = service;
 	lookup->instance = instance;
 	list_add_tail(&lookup->li, &qrtr_ns.lookups);
+	qrtr_ns.lookup_count++;
 
 	memset(&filter, 0, sizeof(filter));
 	filter.service = service;
@@ -598,6 +607,7 @@ static void ctrl_cmd_del_lookup(struct sockaddr_qrtr *from,
 
 		list_del(&lookup->li);
 		kfree(lookup);
+		qrtr_ns.lookup_count--;
 	}
 }
 

-- 
2.51.0

