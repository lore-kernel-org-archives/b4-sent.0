From: Suyuan Wang <shyckless@gmail.com>
Date: Fri, 20 Nov 2026 04:26:16 +0000
Subject: [PATCH v3] tpm: xen-tpmfront: fix use-after-free in
 backend_changed()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-xen-tpmfront-v3-1-3ea2e3fd8611@gmail.com>
X-B4-Tracking: v=1; b=H4sIAOfL/2oC/yXMQQ5AMBBA0avIrDWpqi5cRSwYU0aipC2RiLsrl
 m/x/wWBPFOAOrvA08GBV5dQ5hng1LmRBA/JoKQyRaGkOMmJuC3Wry4K1Eiy16hMZSElmyfL57d
 r2t9h72fC+D7gvh/w/tYMcAAAAA==
X-Change-ID: 20261120-xen-tpmfront-c4ce0b4c265f
To: jgg@ziepe.ca, jarkko@kernel.org
Cc: sstabellini@kernel.org, jgross@suse.com, xen-devel@lists.xenproject.org, 
 linux-kernel@vger.kernel.org, linux-integrity@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795148775; l=2391;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=y48N31ZkViOWzWpWm3teQZk54JRgePEMfCs5wUrfGDI=;
 b=0aGMxum0hOy9buIFYkF9KMKvvK+7gQ4d4pH6piRdWeijez31/TgCv47CxSTssPFrw8PGRVo+T
 kKvn2MY1G2CBNupEha6M6Hdr1X/7rI0n8vlpeQPUJ7NaoZ9BDx6Cw+K
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

When the backend moves to Closing or Closed, backend_changed()
unregisters the device and then keeps using it:

	device_unregister(&dev->dev);
	xenbus_frontend_closed(dev);

The xenbus watch callback that calls backend_changed() does not hold a
reference to the device. The tpm_chip registered by xen-tpmfront has dev
as its parent and holds a reference to it, but tpmfront_remove() drops
that reference when it unregisters the chip. So device_unregister() can
release the last reference and free the xenbus_device, and
xenbus_frontend_closed(dev) then accesses freed memory.

The stubdom based vTPM backend, the only one in use today, never
switches to Closing or Closed, so this path is not reached with it. It
is reached with any backend that follows the normal xenbus state
machine on shutdown.

Take a temporary reference before unregistering and drop it after
xenbus_frontend_closed(). This keeps dev alive for the last access and
keeps the existing order, in which TPM operations are stopped before
the frontend is marked Closed.

Found with a static analysis tool and checked by hand.

Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Changes in v3:
- Drop the Fixes tag (Jarkko). No code change.

Changes in v2:
- Say that the stubdom vTPM backend never reaches this path, and don't
  ask for a stable backport (Juergen, Jarkko). No code change.

Compile tested on x86_64 (W=1, no new warnings). Not run with a Xen vTPM
backend.

v2: https://lore.kernel.org/all/20261119-xen-tpmfront-v2-1-e0e51c36360d@gmail.com/
v1: https://lore.kernel.org/all/20261119-xen-tpmfront-v1-1-bfabbbed462a@gmail.com/
---
 drivers/char/tpm/xen-tpmfront.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/char/tpm/xen-tpmfront.c b/drivers/char/tpm/xen-tpmfront.c
index 3c0cce57c4ae..1be925cca535 100644
--- a/drivers/char/tpm/xen-tpmfront.c
+++ b/drivers/char/tpm/xen-tpmfront.c
@@ -397,8 +397,11 @@ static void backend_changed(struct xenbus_device *dev,
 
 	case XenbusStateClosing:
 	case XenbusStateClosed:
+		/* device_unregister() can drop the last reference to dev */
+		get_device(&dev->dev);
 		device_unregister(&dev->dev);
 		xenbus_frontend_closed(dev);
+		put_device(&dev->dev);
 		break;
 	default:
 		break;



