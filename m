From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Thu, 02 Jul 2026 03:45:14 -0500
Subject: [PATCH] nvmet-auth: zero the AUTH_RECEIVE response buffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260702-b4-disp-127414cf-v1-1-e5395cc0f9ae@proton.me>
X-B4-Tracking: v=1; b=H4sIABklRmoC/x3MQQqAIBBA0avIrBvQwRK6SrQwHWs2JQoRSHdPW
 r7F/w0qF+EKs2pQ+JYq19lhBgXh8OfOKLEbSNOknSbcLEapGQ05a2xImAxHm7wbw0TQs1w4yfM
 vl/V9P1/+7O1iAAAA
To: Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Chaitanya Kulkarni <kch@nvidia.com>, Hannes Reinecke <hare@suse.de>
Cc: linux-kernel@vger.kernel.org, Keith Busch <kbusch@kernel.org>, 
 linux-nvme@lists.infradead.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782981913; l=2253;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=gU5/fAZL43wPsT3d3TYzN8Tsh+FEfVV3hZS/y7sZgpQ=;
 b=uw6EkKIKIlzqvaFwO5ewHmz5r35ITG6phVPelJvCLGHpSNPv84yy8qs20an4v+tPvTMVH39Va
 rft5ALE4Va/BTb4Ru8ZX+/UVwsGw/JucLaw6OBst4JPdSoz6TKIXIl1
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

nvmet_execute_auth_receive() allocates the response buffer with kmalloc()
sized by the host-supplied AUTH_RECEIVE allocation length, but the
DH-HMAC-CHAP builders write only a fixed-size message into it. The full
allocation length is then copied to the wire by nvmet_copy_to_sgl(), so a
remote initiator receives the bytes past the built message -- up to nearly
a page of uninitialized slab -- during the pre-authentication handshake.

Allocate the buffer with kzalloc() so the unwritten tail is zeroed before
it is sent; conforming responses are unaffected.

Fixes: db1312dd9548 ("nvmet: implement basic In-Band Authentication")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Found by inspection and reproduced with KMSAN. The handler runs during the
DH-HMAC-CHAP exchange before authentication completes; that reachability is
by inspection. The leak itself was reproduced with a litmus of the
alloc/fill/copy path -- kmalloc(al), an 8-byte builder write, then copy the
full al to a userspace sink (the copy_to_sgl-to-wire analog). KASAN is silent
because the read is in-bounds of the allocation, so KMSAN is the witness.

Before, al=4096:

  BUG: KMSAN: kernel-infoleak in _copy_to_user+0x44/0x90
   _copy_to_user
   full_proxy_read
   vfs_read
  Uninit was created at:
   __kmalloc_noprof
  Bytes 8-4095 of 4096 are uninitialized

After: no report.

Builds with CONFIG_INIT_ON_ALLOC_DEFAULT_ON=y already zero the tail; kzalloc
closes it for the rest.
---
 drivers/nvme/target/fabrics-cmd-auth.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/nvme/target/fabrics-cmd-auth.c b/drivers/nvme/target/fabrics-cmd-auth.c
index 45820a12750d..2b617d3b8bba 100644
--- a/drivers/nvme/target/fabrics-cmd-auth.c
+++ b/drivers/nvme/target/fabrics-cmd-auth.c
@@ -557,7 +557,7 @@ void nvmet_execute_auth_receive(struct nvmet_req *req)
 		return;
 	}
 
-	d = kmalloc(al, GFP_KERNEL);
+	d = kzalloc(al, GFP_KERNEL);
 	if (!d) {
 		status = NVME_SC_INTERNAL;
 		goto done;

---
base-commit: dc59e4fea9d83f03bad6bddf3fa2e52491777482
change-id: 20260702-b4-disp-127414cf-f1ed4fa75c62

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

