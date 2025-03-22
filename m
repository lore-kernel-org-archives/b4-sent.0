From: Julian Stecklina <julian.stecklina@cyberus-technology.de>
Date: Sat, 22 Mar 2025 21:34:13 +0100
Subject: [PATCH v2 1/9] initrd: remove ASCII spinner
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250322-initrd-erofs-v2-1-d66ee4a2c756@cyberus-technology.de>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742675713; l=1419;
 i=julian.stecklina@cyberus-technology.de; s=20250320;
 h=from:subject:message-id; bh=xaOtsZSXLvGxcDVIZd0k1LuXf7yoO5wFbuBG8A93PMw=;
 b=Q/f0Rz5QFOyX0GFtzyWhjf7NZaw5DwLqmAK+UT+Lih/KQRXWu2ZWjHPR87PxJ073JhZ6qoeo1
 dSKgyuoEHDHC8bSj5x2zOKyRbhADY7Q0NrHhkpa8NkAZjxmafF66erV
X-Developer-Key: i=julian.stecklina@cyberus-technology.de; a=ed25519;
 pk=m051/8gQfs5AmkACfykwRcD6CUr2T7DQ9OA5eBgyy7c=
X-Endpoint-Received: by B4 Relay for julian.stecklina@cyberus-technology.de/20250320 with auth_id=363
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Writing the ASCII spinner probably costs more cycles than copying the
block of data on some output devices if you output to serial and in
all other cases it rotates at lightspeed in 2025.

Signed-off-by: Julian Stecklina <julian.stecklina@cyberus-technology.de>
---
 init/do_mounts_rd.c | 11 -----------
 1 file changed, 11 deletions(-)

diff --git a/init/do_mounts_rd.c b/init/do_mounts_rd.c
index ac021ae6e6fa78c7b7828a78ab2fa3af3611bef3..473f4f9417e157118b9a6e582607435484d53d63 100644
--- a/init/do_mounts_rd.c
+++ b/init/do_mounts_rd.c
@@ -189,11 +189,7 @@ int __init rd_load_image(char *from)
 	unsigned long rd_blocks, devblocks;
 	int nblocks, i;
 	char *buf = NULL;
-	unsigned short rotate = 0;
 	decompress_fn decompressor = NULL;
-#if !defined(CONFIG_S390)
-	char rotator[4] = { '|' , '/' , '-' , '\\' };
-#endif
 
 	out_file = filp_open("/dev/ram", O_RDWR, 0);
 	if (IS_ERR(out_file))
@@ -249,18 +245,11 @@ int __init rd_load_image(char *from)
 	for (i = 0; i < nblocks; i++) {
 		if (i && (i % devblocks == 0)) {
 			pr_cont("done disk #1.\n");
-			rotate = 0;
 			fput(in_file);
 			break;
 		}
 		kernel_read(in_file, buf, BLOCK_SIZE, &in_pos);
 		kernel_write(out_file, buf, BLOCK_SIZE, &out_pos);
-#if !defined(CONFIG_S390)
-		if (!(i % 16)) {
-			pr_cont("%c\b", rotator[rotate & 0x3]);
-			rotate++;
-		}
-#endif
 	}
 	pr_cont("done.\n");
 

-- 
2.47.0

