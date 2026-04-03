From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Fri, 03 Apr 2026 21:36:06 +0530
Subject: [PATCH v2 3/5] net: qrtr: ns: Free the node during ctrl_cmd_bye()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260403-qrtr-fix-v2-3-f88a14859c63@oss.qualcomm.com>
References: <20260403-qrtr-fix-v2-0-f88a14859c63@oss.qualcomm.com>
In-Reply-To: <20260403-qrtr-fix-v2-0-f88a14859c63@oss.qualcomm.com>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1899;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=/IYkRv6TPT121VtWWvMGCswFaIzLb9VKFEQbapivX0Q=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpz+V5/dD8PbvIUlqd0cZdQwy4HKVv9WbX7+cOM
 ACM0pPpT2iJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCac/leQAKCRBVnxHm/pHO
 9f3AB/474jeE5ogQivj26joZxxPOfK7BJtqUVJPmApO/uhzYcsqAwTA9TAJMgfDZNJ5yE7uHIuH
 bpMxWSe9wPrhLeAG1sD+xg114iQAvNPyeIO9q50MYf0Q5XK3Wv4NBm9PVKg5swtbUtwhniw0UZf
 1YrdxMc41+yof73Kp0hOrB7RNSqxrl5Y2fppGtDYudx3oTLcGHGPhm5Yt19fPHhPZajLDDRg5op
 VMDxwcPGsvMx1JiZufRvekQ+RyWOJf9LMSs+VbUbnEuSdcTm3EAROtejcSME000uOjTb3tx4Lia
 OGCOuGjfEI8QRHqnfdrMljj4IklEscCQLniZ1kqCfnKSIGCT
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A node sends the BYE packet when it is about to go down. So the nameserver
should advertise the removal of the node to all remote and local observers
and free the node finally. But currently, the nameserver doesn't free the
node memory even after processing the BYE packet. This causes the node
memory to leak.

Hence, remove the node from Xarray list and free the node memory during
both success and failure case of ctrl_cmd_bye().

Cc: stable@vger.kernel.org
Fixes: 0c2204a4ad71 ("net: qrtr: Migrate nameservice to kernel from userspace")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 net/qrtr/ns.c | 17 ++++++++++++-----
 1 file changed, 12 insertions(+), 5 deletions(-)

diff --git a/net/qrtr/ns.c b/net/qrtr/ns.c
index 5b08d4d4840a..c95014673135 100644
--- a/net/qrtr/ns.c
+++ b/net/qrtr/ns.c
@@ -359,7 +359,7 @@ static int ctrl_cmd_bye(struct sockaddr_qrtr *from)
 	struct qrtr_node *node;
 	unsigned long index;
 	struct kvec iv;
-	int ret;
+	int ret = 0;
 
 	iv.iov_base = &pkt;
 	iv.iov_len = sizeof(pkt);
@@ -374,8 +374,10 @@ static int ctrl_cmd_bye(struct sockaddr_qrtr *from)
 
 	/* Advertise the removal of this client to all local servers */
 	local_node = node_get(qrtr_ns.local_node);
-	if (!local_node)
-		return 0;
+	if (!local_node) {
+		ret = 0;
+		goto delete_node;
+	}
 
 	memset(&pkt, 0, sizeof(pkt));
 	pkt.cmd = cpu_to_le32(QRTR_TYPE_BYE);
@@ -392,10 +394,15 @@ static int ctrl_cmd_bye(struct sockaddr_qrtr *from)
 		ret = kernel_sendmsg(qrtr_ns.sock, &msg, &iv, 1, sizeof(pkt));
 		if (ret < 0 && ret != -ENODEV) {
 			pr_err("failed to send bye cmd\n");
-			return ret;
+			goto delete_node;
 		}
 	}
-	return 0;
+
+delete_node:
+	xa_erase(&nodes, from->sq_node);
+	kfree(node);
+
+	return ret;
 }
 
 static int ctrl_cmd_del_client(struct sockaddr_qrtr *from,

-- 
2.51.0

