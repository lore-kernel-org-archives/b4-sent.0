From: Bernd Schubert <bernd@bsbernd.com>
Date: Mon, 15 Jun 2026 14:07:18 +0200
Subject: [PATCH 1/2] fuse: {io-uring} use READ_ONCE() for ring->queues[] in
 fuse_uring_register()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260615-fix-7-2-next-v1-1-0a4c3908f13c@bsbernd.com>
References: <20260615-fix-7-2-next-v1-0-0a4c3908f13c@bsbernd.com>
In-Reply-To: <20260615-fix-7-2-next-v1-0-0a4c3908f13c@bsbernd.com>
To: Joanne Koong <joannelkoong@gmail.com>, 
 Miklos Szeredi <miklos@szeredi.hu>
Cc: fuse-devel@lists.linux.dev, Bernd Schubert <bernd@bsbernd.com>, 
 stable@kernel.org
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=851; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=nwGHU74m/mRySqbF1+v7DgK2QJZRMBx4cdOA2Xrs2w0=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLL0X3231F3FkvKmiL1w3o0LDE9/m21/5/GZXXnaBAa7F
 m1p88QzHaUsDGIcDLJiiixdEntsp/zjk1X7uv46zBxWJpAhDFycAjCR3RMYGRZ4M4iEpXRnGB8N
 9n53xe2SmsqqZNP4xa/3f67albRBIo3hf1p3QUOLCJ/bFAFBJ2sG7rbdNg0a0zI6m2QS2HtS+np
 YAQ==
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ring->queues[qid] is written with WRITE_ONCE() in fuse_uring_create_queue()
but read with a plain load in fuse_uring_register().
KCSAN might flag this as a data race.

Use READ_ONCE() to match the WRITE_ONCE() on the writer side.

Fixes: 24fe962c86f5 ("fuse: {io-uring} Handle SQEs - register commands")
Cc: stable@kernel.org # 6.14
---
 fs/fuse/dev_uring.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index ba5edf5d01b3..230177cc06c6 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -1193,7 +1193,7 @@ static int fuse_uring_register(struct io_uring_cmd *cmd,
 		return -EINVAL;
 	}
 
-	queue = ring->queues[qid];
+	queue = READ_ONCE(ring->queues[qid]);
 	if (!queue) {
 		queue = fuse_uring_create_queue(ring, qid);
 		if (!queue)

-- 
2.53.0

