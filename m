From: Xiubo Li <xiubo.li@clyso.com>
Date: Sat, 21 Nov 2026 08:18:15 +0200
Subject: [PATCH] ceph: ignore a cap IMPORT peer that names the importing
 MDS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-b4-ceph-cap-import-self-peer-v1-1-9cbc14a6c8b7@clyso.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQrCMAwA0F8ZORtoO1Hmr4iHNaYuoltINhHG/
 t2qx3d5KzibsMOpWcH4JS7TWBF3DdDQjzdGuVZDCukQYwqY90isA1KvKE+dbEbnR0FlNqTUhtg
 dc1u6BLVQ4yLvX3++/O1LvjPN3xO27QOEUZxBgAAAAA==
X-Change-ID: 20261120-b4-ceph-cap-import-self-peer-c230197b3f92
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, stable@vger.kernel.org, security@kernel.org, 
 Quinn Grant <leograntquinn@gmail.com>, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795241898; l=3029;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=/3Lg5v/cOBVmlJ+Hh/ywgxHY68XitXvI31NKdYtN2P0=;
 b=Xrn1wuHrIpn8W8Cq4p1Heqk4JkoHGwrmCkFXb7IcicSv78cp+r1y90vhRJHPFn6ERr+ThxF0U
 /w6nxw8hzwlDpMF6NwjkKf6oFcWKRrt/fF6te/4NTCxV8le9LWGUcQa
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

handle_cap_import() first adds or updates the importing MDS's cap,
then looks up the export peer's cap with __get_cap_for_mds() and
removes it.  The caps rbtree holds one cap per MDS, so when the peer
rank in the IMPORT is the sending MDS itself and the peer cap_id is
the imported cap_id, the "export" cap is the very cap that was just
added: ceph_remove_cap() puts it, and handle_cap_import() still hands
it back to ceph_handle_caps(), which passes it to handle_cap_grant().
That then writes the freed cap (KASAN: slab-use-after-free in
handle_cap_grant()).

A cap is always moved from one MDS to another, so a real MDS never
sends such a peer; only a broken or malicious one can.  Warn and treat
the IMPORT as having no export peer.

Fixes: 2cd698be9a3d ("ceph: handle cap import atomically")
Cc: stable@vger.kernel.org
Reported-by: Quinn Grant <leograntquinn@gmail.com>
Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
A buggy or malicious MDS can send a cap IMPORT whose export peer is the
sending MDS itself, with the peer cap_id equal to the imported cap_id.
handle_cap_import() then removes, and frees, the very cap it has just
added, and handle_cap_grant() goes on to use it.  This patch ignores
such a peer.

Tested on a KASAN kernel, with a test-only hook that turns an MDS cap
REVOKE into an IMPORT whose peer is the sending MDS (the cap pool was
filled to its retention limit first, so the put really frees):
 - without the patch: KASAN reports a slab-use-after-free in
   handle_cap_grant() on the ceph_cap freed by ceph_remove_cap(); the
   client loses the cap and the other client's write waits for the
   revoke forever
 - with the patch: the peer is ignored with a warning, the revoke
   completes, and two-client read/write ping-pong and umount work with
   no KASAN or lockdep reports
---
 fs/ceph/caps.c | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/fs/ceph/caps.c b/fs/ceph/caps.c
index 3f4ac4d94d5b..ac780fdfaeb7 100644
--- a/fs/ceph/caps.c
+++ b/fs/ceph/caps.c
@@ -4652,6 +4652,21 @@ static void handle_cap_import(struct ceph_mds_client *mdsc,
 		peer = -1;
 	}
 
+	/*
+	 * A cap moves from the exporting MDS to the importing one, so the
+	 * export peer can never be the MDS that sends the IMPORT.  Caps are
+	 * kept one per MDS, so a peer naming the sender itself would make
+	 * the export cap removed below the very cap this IMPORT adds or
+	 * updates, and handle_cap_grant() would then write the freed cap.
+	 */
+	if (peer == mds) {
+		pr_warn_ratelimited_client(cl,
+			"%llx.%llx mds%d names itself as cap export peer, ignoring it\n",
+			ceph_vinop(inode), mds);
+		p_cap_id = 0;
+		peer = -1;
+	}
+
 	boutc(cl, " cap %llx.%llx import from peer %d piseq %u pmseq %u\n",
 	      ceph_vinop(inode), peer, piseq, pmseq);
 retry:

---
base-commit: 6a9830a8f414d3830c584782568d0233be969d09
change-id: 20261120-b4-ceph-cap-import-self-peer-c230197b3f92

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

