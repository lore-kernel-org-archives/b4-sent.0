From: Daejun Park <daejun7.park@samsung.com>
Date: Wed, 14 Oct 2026 13:10:28 +0900
Subject: [PATCH pynfs 3/3] Add README-blocklayout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-pynfs-block-commit-v1-3-1723979f495f@samsung.com>
References: <20261014-pynfs-block-commit-v1-0-1723979f495f@samsung.com>
In-Reply-To: <20261014-pynfs-block-commit-v1-0-1723979f495f@samsung.com>
To: Calum Mackay <calum.mackay@oracle.com>
Cc: linux-nfs@vger.kernel.org, Chuck Lever <cel@kernel.org>, 
 Jeff Layton <jlayton@kernel.org>, Christoph Hellwig <hch@lst.de>, 
 Dai Ngo <dai.ngo@oracle.com>, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791951025; l=2601;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=YqS0ogQssgr7gKBiOnKJ3S7SC8ISwfMrFhVX+bxl4Ns=;
 b=rtX1zAYBOjwXcsa68uY5QfmDPhb+tV1dg3Bkeaz0pDeg/gMrTXC9upUf8a4El1qwXl4s5rn6Q
 hsCbRYBS+vFBf6qS1s23INA+HxyvBToxy8sQoTsxUALb1LrPzk3rGLO
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe how the block layout tests are run against Linux nfsd: the
kernel options and export option that nfsd needs to hand out block
layouts, a setup that the tests have been run with, the testserver.py
command line, and how to leave out the tests that commit ranges no
layout covered when testing a server that shuts down on them.

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 nfs4.1/README-blocklayout | 41 +++++++++++++++++++++++++++++++++++++++++
 1 file changed, 41 insertions(+)

diff --git a/nfs4.1/README-blocklayout b/nfs4.1/README-blocklayout
new file mode 100644
index 0000000..48d3c1b
--- /dev/null
+++ b/nfs4.1/README-blocklayout
@@ -0,0 +1,41 @@
+Testing a block layout server
+=============================
+
+The "block" tests (server41tests/st_block.py) run testserver.py as the
+pNFS client of a server that hands out block layouts (RFC 5663). They
+only send NFS operations: none of them reads or writes the shared
+volume, so the host that runs them does not need access to it.
+
+They ask for LAYOUT4_BLOCK_VOLUME layouts. Linux nfsd hands those out
+for an XFS export with the "pnfs" option when it is built with
+CONFIG_NFSD_BLOCKLAYOUT. With CONFIG_NFSD_SCSILAYOUT it also hands out
+SCSI layouts (RFC 8154) if the device supports persistent
+reservations; the tests do not use those.
+
+One setup that the tests have been run with:
+
+  - nfsd built with CONFIG_NFSD_BLOCKLAYOUT=y, and XFS (mkfs.xfs
+    defaults, internal log) on a whole NVMe namespace, exported with
+    this line in /etc/exports:
+
+        /export  10.10.0.0/24(rw,sync,no_root_squash,pnfs)
+
+  - The namespace came over NVMe/TCP from nvmet on another host. As
+    the pynfs host never touches the volume, any block device that
+    XFS can be made on works for these tests; a shared device only
+    matters for clients that do I/O through the layout.
+
+  - A directory /export/pynfs on the server that the test user can
+    write to, and on the pynfs host:
+
+        ./testserver.py SERVER:/export/pynfs --secure --maketree block
+
+    --secure sends from a privileged port, which nfsd requires unless
+    the export has "insecure". --maketree creates the files that the
+    tests expect; it is needed the first time.
+
+BLOCK7 to BLOCK10 commit ranges that no layout covered. A server that
+does not refuse those may allocate blocks for them or, as XFS did,
+shut the filesystem down, which makes the tests after them fail. To
+leave them out, add "noBLOCK7 noBLOCK8 noBLOCK9 noBLOCK10" after
+"block".

-- 
2.43.0

