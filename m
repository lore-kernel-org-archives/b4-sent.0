From: Julian Stecklina <julian.stecklina@cyberus-technology.de>
Date: Sat, 22 Mar 2025 21:34:14 +0100
Subject: [PATCH v2 2/9] initrd: fix double fput for truncated ramdisks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250322-initrd-erofs-v2-2-d66ee4a2c756@cyberus-technology.de>
References: <20250322-initrd-erofs-v2-0-d66ee4a2c756@cyberus-technology.de>
In-Reply-To: <20250322-initrd-erofs-v2-0-d66ee4a2c756@cyberus-technology.de>
To: Christoph Hellwig <hch@lst.de>, Al Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>
Cc: Linus Torvalds <torvalds@linux-foundation.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Gao Xiang <xiang@kernel.org>, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-erofs@lists.ozlabs.org, 
 Julian Stecklina <julian.stecklina@cyberus-technology.de>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742675713; l=1599;
 i=julian.stecklina@cyberus-technology.de; s=20250320;
 h=from:subject:message-id; bh=k4g6SAXWuxXSYv2iKkbm/npvjC9+dlFx9G1/+9RZN20=;
 b=rNJ683tIeaNnaJuuNqFjmoLWib1cKLA5DiGdVBrmkGkeiuHZxssO5pP0xtDM/im05voR1Nb/7
 4LsMkMemF0TAw9Mnp7ACjJIxCYIyVq4DeGqjSHbewp8eywATzHjpEsz
X-Developer-Key: i=julian.stecklina@cyberus-technology.de; a=ed25519;
 pk=m051/8gQfs5AmkACfykwRcD6CUr2T7DQ9OA5eBgyy7c=
X-Endpoint-Received: by B4 Relay for julian.stecklina@cyberus-technology.de/20250320 with auth_id=363
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When you actually take the exit via devblocks == 0, the code will do
fput(in_file) twice. This was introduced when the APIs where switched
to the file-based APIs.

Remove more of the multi-floppy support from the olden days.

Fixes: bef173299613 ("initrd: switch initrd loading to struct file based APIs")

Signed-off-by: Julian Stecklina <julian.stecklina@cyberus-technology.de>
---
 init/do_mounts_rd.c | 14 +++++++-------
 1 file changed, 7 insertions(+), 7 deletions(-)

diff --git a/init/do_mounts_rd.c b/init/do_mounts_rd.c
index 473f4f9417e157118b9a6e582607435484d53d63..d026df401afa0b7458ab1f266b21830aab974b92 100644
--- a/init/do_mounts_rd.c
+++ b/init/do_mounts_rd.c
@@ -234,20 +234,20 @@ int __init rd_load_image(char *from)
 		goto done;
 	}
 
+	if (devblocks < nblocks) {
+		printk(KERN_ERR "RAMDISK: looks truncated: (%luKiB vs %dKiB) - continuing anyway\n",
+		       devblocks, nblocks);
+		nblocks = devblocks;
+	}
+
 	buf = kmalloc(BLOCK_SIZE, GFP_KERNEL);
 	if (!buf) {
 		printk(KERN_ERR "RAMDISK: could not allocate buffer\n");
 		goto done;
 	}
 
-	printk(KERN_NOTICE "RAMDISK: Loading %dKiB [%ld disk%s] into ram disk... ",
-		nblocks, ((nblocks-1)/devblocks)+1, nblocks>devblocks ? "s" : "");
+	printk(KERN_NOTICE "RAMDISK: Loading %dKiB into ram disk... ", nblocks);
 	for (i = 0; i < nblocks; i++) {
-		if (i && (i % devblocks == 0)) {
-			pr_cont("done disk #1.\n");
-			fput(in_file);
-			break;
-		}
 		kernel_read(in_file, buf, BLOCK_SIZE, &in_pos);
 		kernel_write(out_file, buf, BLOCK_SIZE, &out_pos);
 	}

-- 
2.47.0

