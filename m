From: Suyuan Wang <shyckless@gmail.com>
Date: Thu, 19 Nov 2026 11:20:33 +0000
Subject: [PATCH] tpm: xen-tpmfront: fix use-after-free in backend_changed()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-xen-tpmfront-v1-1-bfabbbed462a@gmail.com>
X-B4-Tracking: v=1; b=H4sIAIDb/moC/yXMQQqAIBBA0avErBMaF1JdJVqYTjVBFmohRHfPa
 vkW/18QyDMFaIsLPJ0ceHMZWBZgZu0mEmyzQVZSIWIjEjkR93X0m4sCq1prqWxtlIWc7J5GTt+
 u63+HY1jIxPcB9/0AQukJC3AAAAA=
X-Change-ID: 20261119-xen-tpmfront-108aa26d8c6d
To: jgg@ziepe.ca, jarkko@kernel.org
Cc: linux-kernel@vger.kernel.org, jgross@suse.com, sstabellini@kernel.org, 
 linux-integrity@vger.kernel.org, xen-devel@lists.xenproject.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795087232; l=1866;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=SeHCF57qvTjGFWZBGFq4/OdwCYQKor1OKDV0zKf38bM=;
 b=9LGNWNkQtNeORKMHA4bnA+tIT8SFxlO/+PusmyfK51AQl6KJ4CyCP1WJPlQ3nrvwC7h8yimPN
 OtFGagUC1FiBQkOBQJOxyhML/GeMEo1PWXi1jzh3R0xSmvnNzdoztCF
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

Take a temporary reference before unregistering and drop it after
xenbus_frontend_closed(). This keeps dev alive for the last access and
keeps the existing order, in which TPM operations are stopped before
the frontend is marked Closed.

Found with a static analysis tool and checked by hand.

Fixes: e2683957fb26 ("drivers/tpm: add xen tpmfront interface")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested on x86_64 (W=1, no new warnings). Not run with a Xen vTPM
backend.
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



