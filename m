From: Suyuan Wang <shyckless@gmail.com>
Date: Sun, 22 Nov 2026 12:37:14 +0000
Subject: [PATCH] um: line: Free the read IRQ when the write IRQ request
 fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-uml-line-irq-v1-1-64b525cf8d2f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAPnhAmsC/yXMyw5AMBCF4VeRWWui4+5VxMJlMELRIhLx7orld
 5LzX2BIMxnInAs0HWx4VhbSdaDuS9WR4MYa0MNISkSxT6MYWdldr8JPieIYkyCUCPayaGr5/HJ
 58dvs1UD19jbgvh/S+U5ncAAAAA==
X-Change-ID: 20261122-uml-line-irq-39ee77284512
To: johannes@sipsolutions.net, anton.ivanov@cambridgegreys.com, 
 richard@nod.at
Cc: linux-um@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795351033; l=1580;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=EbX7KODF5wd8UgFNPa78Kwlbo1tt/cnAoI1sKqIv8xo=;
 b=aJAuyN16nWR2Vppc4QoXL1GhbRI+Pv7Eg/ats+Kvd4l/cImMnwPfjvpR06CzeWnvnPwoXf2QL
 Y3JSi2SS7ULCUub3MVqA8RxPuGPJQ+hWe5hFPWJyFhlzGLh8hJmiyf9
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

line_setup_irq() requests the read IRQ first and then the write IRQ.
If the write IRQ request fails, it returns the error without freeing
the read IRQ. Its caller, open_chan(), then calls close_chan(), but
close_one_chan() only frees the IRQs of a channel that is enabled, and
the channel was never marked enabled. So the read IRQ stays registered
for an fd that close_one_chan() then closes.

Free the read IRQ in line_setup_irq() before returning the error.

Found with a static analysis tool and checked by hand.

Fixes: d14ad81f800a ("uml: handle errors on opening host side of consoles")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested with ARCH=um (W=1, no new warnings); the failure path wasn't run.
---
 arch/um/drivers/line.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/arch/um/drivers/line.c b/arch/um/drivers/line.c
index c851a592809c..5589fa68871e 100644
--- a/arch/um/drivers/line.c
+++ b/arch/um/drivers/line.c
@@ -273,8 +273,12 @@ int line_setup_irq(int fd, int input, int output, struct line *line, void *data)
 		err = um_request_irq(UM_IRQ_ALLOC, fd, IRQ_WRITE,
 				     line_write_interrupt, 0,
 				     driver->write_irq_name, data);
-		if (err < 0)
+		if (err < 0) {
+			/* the caller won't free it, the channel isn't enabled */
+			if (input)
+				um_free_irq(line->read_irq, data);
 			return err;
+		}
 
 		line->write_irq = err;
 	}



