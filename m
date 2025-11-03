From: Dominique Martinet <asmadeus@codewreck.org>
Date: Mon, 03 Nov 2025 16:42:36 +0900
Subject: [PATCH] net/9p: cleanup: change p9_trans_module->def to bool
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251103-v9fs_trans_def_bool-v1-1-f33dc7ed9e81@codewreck.org>
X-B4-Tracking: v=1; b=H4sIAOtcCGkC/x2MQQqAIBAAvxJ7TsiiwL4SIZa7tRAabkgQ/T3pN
 nOYeUAwMQqM1QMJMwvHUETXFay7Cxsq9sWhbdpe66ZT2ZDYK7kg1iPZJcZDOb8aGgz1BaCUZ0L
 i+79O8/t+kBGn8GUAAAA=
X-Change-ID: 20251103-v9fs_trans_def_bool-adc9f69f5adc
To: Eric Van Hensbergen <ericvh@kernel.org>, 
 Latchesar Ionkov <lucho@ionkov.net>, 
 Christian Schoenebeck <linux_oss@crudebyte.com>
Cc: v9fs@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Dominique Martinet <asmadeus@codewreck.org>, 
 Christophe JAILLET <christophe.jaillet@wanadoo.fr>
X-Mailer: b4 0.15-dev-7be4f
X-Developer-Signature: v=1; a=openpgp-sha256; l=3628;
 i=asmadeus@codewreck.org; h=from:subject:message-id;
 bh=e6a1iYQuHQC7x5fsHwGCTvDypr2b1ZkzPJioRFGi6XY=;
 b=owEBbQKS/ZANAwAKAatOm+xqmOZwAcsmYgBpCFz3yuyEQXZJcrjOEuC62x15QrGZfQvJftDe4
 cHKuq1TJ56JAjMEAAEKAB0WIQT8g9txgG5a3TOhiE6rTpvsapjmcAUCaQhc9wAKCRCrTpvsapjm
 cBdkD/wLg99Ehw6pxqNvcpYX9IDW48H/OKBbTGrGtJ1kIB9KVLMeG/oSyXAUVeVifpBEZgtnxoC
 d2TO1zxlITNeHZMFWqxHIjItEMQf8UlIt1QdTcvRrYSw0wWRWJhM4AFN9vVRSpJNFvZogESXSHs
 4tbyUd8eNmlgVEavm6QczfUC1AJbUZ8/gOd6bGnGm9StZyCErp7+qPvEY2VKT0UGRiXUjlyp0+/
 1d9gWY/herCreyiSF0FrWbQWO8uiYiiCXsByJrvqmSdlvuQIIdC2gKclVaAGm6hcwZdyAntsJMP
 XHIHaUgMzEkabsn7jwf/sv2mRPp9EKXpSLVE8ObpMtnDZYaV9y4DKzJtruqbPKJqClEtCYGdw0J
 sN5H4DcuJR9uRgaRbwtmLZGTB87hDPgenOcYgRGQofCw2noNHvKP1CGEgLSnW30e3jF6QPdZzPj
 nbBzHPBamA55eUZTuURKMqKTuhUdCIjq48PYHNOxST2kBKnUy+3EcxKDloztvq4/jY0sKg5/wm6
 1/hY4kPowgv/kKevvY0O6P+YUdRxS2nOE9JMkX51NUQqZE5uo8zAPEgdkD2IVsLCl3jQVyG7jbq
 DwXaGKOo6NXPMHSi6hxqgFrM1fY+rF+GGke5/un80w93i1nVWKkfNKkvxbC3emQOlHWnNTiBnYQ
 NLN1U+qI0xvONTg==
X-Developer-Key: i=asmadeus@codewreck.org; a=openpgp;
 fpr=B894379F662089525B3FB1B9333F1F391BBBB00A
X-Endpoint-Received: by B4 Relay for asmadeus@codewreck.org/default with auth_id=435
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'->def' is only ever used as a true/false flag

Signed-off-by: Dominique Martinet <asmadeus@codewreck.org>
Reported-by: Christophe JAILLET <christophe.jaillet@wanadoo.fr>
---
 include/net/9p/transport.h | 2 +-
 net/9p/trans_fd.c          | 6 +++---
 net/9p/trans_rdma.c        | 2 +-
 net/9p/trans_virtio.c      | 2 +-
 net/9p/trans_xen.c         | 2 +-
 5 files changed, 7 insertions(+), 7 deletions(-)

diff --git a/include/net/9p/transport.h b/include/net/9p/transport.h
index f0981515148d69abdaf06a2874eaab39f7ee2e94..0aedabc9b7ebe19e2c7273679fc934eff203de03 100644
--- a/include/net/9p/transport.h
+++ b/include/net/9p/transport.h
@@ -46,7 +46,7 @@ struct p9_trans_module {
 	char *name;		/* name of transport */
 	int maxsize;		/* max message size of transport */
 	bool pooled_rbuffers;
-	int def;		/* this transport should be default */
+	bool def;		/* this transport should be default */
 	bool supports_vmalloc;	/* can work with vmalloc'd buffers */
 	struct module *owner;
 	int (*create)(struct p9_client *client,
diff --git a/net/9p/trans_fd.c b/net/9p/trans_fd.c
index e7334033eba5ae41f03fe8fe0fef7f8f35924886..bd4903d6482710cc3ae9e192fab2fd0d5318ad7a 100644
--- a/net/9p/trans_fd.c
+++ b/net/9p/trans_fd.c
@@ -1100,7 +1100,7 @@ static struct p9_trans_module p9_tcp_trans = {
 	.name = "tcp",
 	.maxsize = MAX_SOCK_BUF,
 	.pooled_rbuffers = false,
-	.def = 0,
+	.def = false,
 	.supports_vmalloc = true,
 	.create = p9_fd_create_tcp,
 	.close = p9_fd_close,
@@ -1115,7 +1115,7 @@ MODULE_ALIAS_9P("tcp");
 static struct p9_trans_module p9_unix_trans = {
 	.name = "unix",
 	.maxsize = MAX_SOCK_BUF,
-	.def = 0,
+	.def = false,
 	.supports_vmalloc = true,
 	.create = p9_fd_create_unix,
 	.close = p9_fd_close,
@@ -1130,7 +1130,7 @@ MODULE_ALIAS_9P("unix");
 static struct p9_trans_module p9_fd_trans = {
 	.name = "fd",
 	.maxsize = MAX_SOCK_BUF,
-	.def = 0,
+	.def = false,
 	.supports_vmalloc = true,
 	.create = p9_fd_create,
 	.close = p9_fd_close,
diff --git a/net/9p/trans_rdma.c b/net/9p/trans_rdma.c
index 6c5ad232c19463ff42c611f5e409555381911c39..a0bc766199dadf448b8e048e68b97c646e125435 100644
--- a/net/9p/trans_rdma.c
+++ b/net/9p/trans_rdma.c
@@ -748,7 +748,7 @@ static struct p9_trans_module p9_rdma_trans = {
 	.name = "rdma",
 	.maxsize = P9_RDMA_MAXSIZE,
 	.pooled_rbuffers = true,
-	.def = 0,
+	.def = false,
 	.supports_vmalloc = false,
 	.owner = THIS_MODULE,
 	.create = rdma_create_trans,
diff --git a/net/9p/trans_virtio.c b/net/9p/trans_virtio.c
index 12806207f4f03c5b291db938842d78f5146dc0b7..b58f50b00c7237d529556484ca497fe438b78d31 100644
--- a/net/9p/trans_virtio.c
+++ b/net/9p/trans_virtio.c
@@ -802,7 +802,7 @@ static struct p9_trans_module p9_virtio_trans = {
 	 */
 	.maxsize = PAGE_SIZE * (VIRTQUEUE_NUM - 3),
 	.pooled_rbuffers = false,
-	.def = 1,
+	.def = true,
 	.supports_vmalloc = false,
 	.owner = THIS_MODULE,
 };
diff --git a/net/9p/trans_xen.c b/net/9p/trans_xen.c
index 4b1cec0ab82977e366dfa6673a71b5a90cb2cd45..9389c1247001e2d8ed7e2151390295b09cdcf98c 100644
--- a/net/9p/trans_xen.c
+++ b/net/9p/trans_xen.c
@@ -257,7 +257,7 @@ static struct p9_trans_module p9_xen_trans = {
 	.name = "xen",
 	.maxsize = 1 << (XEN_9PFS_RING_ORDER + XEN_PAGE_SHIFT - 2),
 	.pooled_rbuffers = false,
-	.def = 1,
+	.def = true,
 	.supports_vmalloc = false,
 	.create = p9_xen_create,
 	.close = p9_xen_close,

---
base-commit: e21d451a82f39e91b7635c4fc3ff5ac082873ec3
change-id: 20251103-v9fs_trans_def_bool-adc9f69f5adc

Best regards,
-- 
Dominique Martinet <asmadeus@codewreck.org>

