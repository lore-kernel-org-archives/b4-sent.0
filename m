From: Manas Gupta <manas18244@iiitd.ac.in>
Date: Thu, 03 Jul 2025 02:57:40 +0530
Subject: [PATCH] usbmon: Fix out-of-bounds read in mon_copy_to_buff
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250703-fix-oob-mon_copy_to_buff-v1-1-1aa7f5723d91@iiitd.ac.in>
X-B4-Tracking: v=1; b=H4sIAEukZWgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDcwNj3bTMCt38/CTd3Py8+OT8gsr4kvz4pNK0NF3z5LRUI7NUC0PLJEs
 loPaColSgWrDR0bG1tQBD3PoGagAAAA==
X-Change-ID: 20250703-fix-oob-mon_copy_to_buff-7cfe26e819b9
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Pete Zaitcev <zaitcev@redhat.com>, Paolo Abeni <paolo.abeni@email.it>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Greg Kroah-Hartman <gregkh@suse.de>, 
 syzbot+86b6d7c8bcc66747c505@syzkaller.appspotmail.com, 
 Manas Gupta <manas18244@iiitd.ac.in>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751491666; l=1520;
 i=manas18244@iiitd.ac.in; s=20240813; h=from:subject:message-id;
 bh=7E8Us5M4J+FLzJSTXxCkqDU9TPMaxmpKlw0J3ayG1Dg=;
 b=56jVWByL3/RS/eEhTGBn6CQcbqSSpx7ZGDu4GdK9FGAuFnJMvbdffc5XvB9Z6ZyV4IiTrvse2
 YhQFtRIpM1PB4fWsF6eSBpp30yw/pSVa0JpcXqGsiT44ynKEkUhr0Am
X-Developer-Key: i=manas18244@iiitd.ac.in; a=ed25519;
 pk=pXNEDKd3qTkQe9vsJtBGT9hrfOR7Dph1rfX5ig2AAoM=
X-Endpoint-Received: by B4 Relay for manas18244@iiitd.ac.in/20240813 with auth_id=196
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

memcpy tries to copy buffer 'from' when it is empty. This leads to
out-of-bounds crash.

This checks if the buffer is already empty and throws an appropriate
error message before bailing out.

Fixes: 6f23ee1fefdc1 ("USB: add binary API to usbmon")
Reported-by: syzbot+86b6d7c8bcc66747c505@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=86b6d7c8bcc66747c505
Signed-off-by: Manas Gupta <manas18244@iiitd.ac.in>
---
I have used printk(KERN_ERR ... to keep things consistent in usbmon.
dev_err and pr_err are not used anywhere else in usbmon.
---
 drivers/usb/mon/mon_bin.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/usb/mon/mon_bin.c b/drivers/usb/mon/mon_bin.c
index c93b43f5bc4614ad75568b601c47a1ae51f01fa5..bd945052f6fb821ba814fab96eba5a82e5d161e2 100644
--- a/drivers/usb/mon/mon_bin.c
+++ b/drivers/usb/mon/mon_bin.c
@@ -249,6 +249,11 @@ static unsigned int mon_copy_to_buff(const struct mon_reader_bin *this,
 		 * Copy data and advance pointers.
 		 */
 		buf = this->b_vec[off / CHUNK_SIZE].ptr + off % CHUNK_SIZE;
+		if (!strlen(from)) {
+			printk(KERN_ERR TAG
+			       ": src buffer is empty, cannot copy from it\n");
+			return -ENOMEM;
+		}
 		memcpy(buf, from, step_len);
 		if ((off += step_len) >= this->b_size) off = 0;
 		from += step_len;

---
base-commit: d0b3b7b22dfa1f4b515fd3a295b3fd958f9e81af
change-id: 20250703-fix-oob-mon_copy_to_buff-7cfe26e819b9

Best regards,
-- 
Manas Gupta <manas18244@iiitd.ac.in>

