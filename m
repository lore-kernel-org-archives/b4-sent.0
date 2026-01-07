From: Sam Day <me@samcday.com>
Date: Thu, 08 Jan 2026 08:30:20 +1000
Subject: [PATCH 1/2] usb: gadget: f_fs: Fix ioctl error handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260108-ffs-dmabuf-ioctl-fix-v1-1-e51633891a81@samcday.com>
References: <20260108-ffs-dmabuf-ioctl-fix-v1-0-e51633891a81@samcday.com>
In-Reply-To: <20260108-ffs-dmabuf-ioctl-fix-v1-0-e51633891a81@samcday.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sam Day <me@samcday.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767825022; l=2103;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=+sgu2dykusg1HSD/3fjxdCUcleWQtBrEsLL9Ec/cHXA=;
 b=oxwqyO9NTmbV96vpdsjWeB2S8TLav+HWSi6CkMSB8muMROJLX7+wolOhFlwfATRY0GQnQ+GwX
 2Mu5iFkTnyxDgJk6rVTDN+Bsye/msuDhmY3wVaR2KxW30ORHnnl+JH9
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When ffs_epfile_ioctl handles FUNCTIONFS_DMABUF_* ioctls, it's currently
falling through when copy_from_user fails.

However, this fallthrough isn't being checked properly, so the handler
continues executing further than it should. It then tries the secondary
dispatch where it ultimately gives up and returns -ENOTTY.

The end result is invalid ioctl invocations will yield a -ENOTTY rather
than an -EFAULT.

It's a common pattern elsewhere in the kernel code to directly return
-EFAULT when copy_from_user fails. So we update ffs_epfile_ioctl to do
the same and fix this issue.

Signed-off-by: Sam Day <me@samcday.com>
---
 drivers/usb/gadget/function/f_fs.c | 18 ++++++------------
 1 file changed, 6 insertions(+), 12 deletions(-)

diff --git a/drivers/usb/gadget/function/f_fs.c b/drivers/usb/gadget/function/f_fs.c
index 05c6750702b609565d7a4adc1ebae16ba3ffeeb7..9ea1445bec97531f9c2bed678268bd6f76199bfb 100644
--- a/drivers/usb/gadget/function/f_fs.c
+++ b/drivers/usb/gadget/function/f_fs.c
@@ -1748,10 +1748,8 @@ static long ffs_epfile_ioctl(struct file *file, unsigned code,
 	{
 		int fd;
 
-		if (copy_from_user(&fd, (void __user *)value, sizeof(fd))) {
-			ret = -EFAULT;
-			break;
-		}
+		if (copy_from_user(&fd, (void __user *)value, sizeof(fd)))
+			return -EFAULT;
 
 		return ffs_dmabuf_attach(file, fd);
 	}
@@ -1759,10 +1757,8 @@ static long ffs_epfile_ioctl(struct file *file, unsigned code,
 	{
 		int fd;
 
-		if (copy_from_user(&fd, (void __user *)value, sizeof(fd))) {
-			ret = -EFAULT;
-			break;
-		}
+		if (copy_from_user(&fd, (void __user *)value, sizeof(fd)))
+			return -EFAULT;
 
 		return ffs_dmabuf_detach(file, fd);
 	}
@@ -1770,10 +1766,8 @@ static long ffs_epfile_ioctl(struct file *file, unsigned code,
 	{
 		struct usb_ffs_dmabuf_transfer_req req;
 
-		if (copy_from_user(&req, (void __user *)value, sizeof(req))) {
-			ret = -EFAULT;
-			break;
-		}
+		if (copy_from_user(&req, (void __user *)value, sizeof(req)))
+			return -EFAULT;
 
 		return ffs_dmabuf_transfer(file, &req);
 	}

-- 
2.52.0

