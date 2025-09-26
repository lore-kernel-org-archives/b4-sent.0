From: Dominique Martinet <asmadeus@codewreck.org>
Date: Fri, 26 Sep 2025 18:27:29 +0900
Subject: [PATCH 1/3] 9p: clean up comment typos
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250926-v9fs_misc-v1-1-a8b3907fc04d@codewreck.org>
References: <20250926-v9fs_misc-v1-0-a8b3907fc04d@codewreck.org>
In-Reply-To: <20250926-v9fs_misc-v1-0-a8b3907fc04d@codewreck.org>
To: "Randall P. Embry" <rpembry@gmail.com>, 
 Eric Van Hensbergen <ericvh@kernel.org>, 
 Latchesar Ionkov <lucho@ionkov.net>, 
 Christian Schoenebeck <linux_oss@crudebyte.com>
Cc: v9fs@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Dominique Martinet <asmadeus@codewreck.org>
X-Mailer: b4 0.15-dev-7be4f
X-Developer-Signature: v=1; a=openpgp-sha256; l=1608;
 i=asmadeus@codewreck.org; h=from:subject:message-id;
 bh=iGmjLo6EVujPyWtH4nBhmJfViu8T3yF4qPnQ2nTMqIQ=;
 b=owEBbQKS/ZANAwAKAatOm+xqmOZwAcsmYgBo1lyJAj4Xfe7DptT70ZeU109wolge7hWv3ztiB
 RRMQoL9sFqJAjMEAAEKAB0WIQT8g9txgG5a3TOhiE6rTpvsapjmcAUCaNZciQAKCRCrTpvsapjm
 cFSkD/9Naw3YNi2op0W1lypB3TgDOma9d+PCgWVVAh/7sKyE6LFQN+d9MRCBnj6FdYeV6wdNR6T
 c3xZuv/KPuAKMjTwDmXRlZ9Zgc46oayf1Vb5Ar9bNBFZI7qHLPLusS936HzsHEJQO5E72Kc8g2v
 ianuKT/qQ1k0ihNXkyy+kQO7mlp61Qf+KI99bVGNb/zYRg3PG9RM0oRo9oqCzQfZ6iaYK8BGNgA
 xtMFhGP/MKwF+Dx84beu6zwmavUL7cm/Z2Aknz65CGRAWFKC2Ku0vhSuRup7DSH2nIgz4IOxhoj
 1Xol7sEh10HyPKazMwKEdh10mD9/vElDVhmEHHTY0zzLJCvtC78gD5iulq1n0tfRvYM2KX77uHG
 il7aZFlGiJfjRqIoXzs7TqraOMoMnN0K7ud4DFkW+B6E2Eulv4VPttRgarZDVQhbN5fp/DdsaYw
 WvETUpj6u+CafhtGY62NGDoklMyA7aa8gZkjNruQVOMlDK5mpwP2fAbHw0mmDCfD4sFS+8oSUjf
 QzbcRCXS7KFl5NHV0nKwz2U8trZPPx2B3JcZsKQlxkZCVC9LLU54uxb1QaC20Jn8BXilyrA6dIM
 0XewSpZ9Oh8gaeWB9XrisNnSvbKo7W9x6W7NQCck3zGLPDObkgaS+GWlKA1zQW+Rwsa/KJaYOKD
 e29ABbxJ8zfZfWQ==
X-Developer-Key: i=asmadeus@codewreck.org; a=openpgp;
 fpr=B894379F662089525B3FB1B9333F1F391BBBB00A
X-Endpoint-Received: by B4 Relay for asmadeus@codewreck.org/default with auth_id=435
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: "Randall P. Embry" <rpembry@gmail.com>

Fix a few minor typos in comments (e.g. "trasnport" → "transport").

Signed-off-by: Randall P. Embry <rpembry@gmail.com>
Signed-off-by: Dominique Martinet <asmadeus@codewreck.org>
---
 fs/9p/v9fs.c | 7 +++----
 1 file changed, 3 insertions(+), 4 deletions(-)

diff --git a/fs/9p/v9fs.c b/fs/9p/v9fs.c
index 77e9c4387c1dfd4de8a54e9b6f676bdf987dbdc9..01e70a464b6039231df272e43b4ebdd3b5afb967 100644
--- a/fs/9p/v9fs.c
+++ b/fs/9p/v9fs.c
@@ -438,8 +438,7 @@ struct p9_fid *v9fs_session_init(struct v9fs_session_info *v9ses,
 		v9ses->flags &= ~V9FS_ACCESS_MASK;
 		v9ses->flags |= V9FS_ACCESS_USER;
 	}
-	/*FIXME !! */
-	/* for legacy mode, fall back to V9FS_ACCESS_ANY */
+	/* FIXME: for legacy mode, fall back to V9FS_ACCESS_ANY */
 	if (!(v9fs_proto_dotu(v9ses) || v9fs_proto_dotl(v9ses)) &&
 		((v9ses->flags&V9FS_ACCESS_MASK) == V9FS_ACCESS_USER)) {
 
@@ -450,7 +449,7 @@ struct p9_fid *v9fs_session_init(struct v9fs_session_info *v9ses,
 	if (!v9fs_proto_dotl(v9ses) ||
 		!((v9ses->flags & V9FS_ACCESS_MASK) == V9FS_ACCESS_CLIENT)) {
 		/*
-		 * We support ACL checks on clinet only if the protocol is
+		 * We support ACL checks on client only if the protocol is
 		 * 9P2000.L and access is V9FS_ACCESS_CLIENT.
 		 */
 		v9ses->flags &= ~V9FS_ACL_MASK;
@@ -669,7 +668,7 @@ static int __init init_v9fs(void)
 	int err;
 
 	pr_info("Installing v9fs 9p2000 file system support\n");
-	/* TODO: Setup list of registered trasnport modules */
+	/* TODO: Setup list of registered transport modules */
 
 	err = v9fs_init_inode_cache();
 	if (err < 0) {

-- 
2.51.0

