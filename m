From: Suyuan Wang <shyckless@gmail.com>
Date: Sat, 21 Nov 2026 15:26:27 +0000
Subject: [PATCH] ASoC: SOF: ipc4-mtrace: fix the wrapped read when the user
 buffer is short
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-sof-mtrace-wrap-v1-1-9798707c3439@gmail.com>
X-B4-Tracking: v=1; b=H4sIACK4AWsC/yXMwQrCMAyA4VcZORuwHR3UVxEPtUlnBLeRbG4w9
 u5WPX6H/9/BWIUNLs0Oym8xGYcKd2ogP9LQMwpVgz/7zjnv0MaCr1lTZlw1TRioLRSJcgwt1Gp
 SLrL9jtfb37bcn5zn7waO4wO9roLXcwAAAA==
X-Change-ID: 20261121-sof-mtrace-wrap-5d3fd9ddc953
To: yung-chuan.liao@linux.intel.com, broonie@kernel.org, 
 lgirdwood@gmail.com, peter.ujfalusi@linux.intel.com
Cc: linux-kernel@vger.kernel.org, sound-open-firmware@alsa-project.org, 
 kai.vehmanen@linux.intel.com, tiwai@suse.com, 
 pierre-louis.bossart@linux.dev, daniel.baluta@nxp.com, 
 linux-sound@vger.kernel.org, perex@perex.cz
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795274787; l=2836;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=eCZ+OHYWPM9lk6X07kSRGna3tHg4IdTpUM5N3XCFjbA=;
 b=gljffVztdZYIhKC+yfJh8dtwobmcl9RKf2zd3Vthk2kNVBmFUctSJ3Yrg54DcHdX/pg7VKPAQ
 y40IMyriAuGCFTG3uky0QbP9j1vYeAE5Yp/zliVCPp0hw3d5fQfAaAX
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

When the log data wraps around the end of the slot,
sof_ipc4_mtrace_dfs_read() copies it in two parts:

	sof_mailbox_read(..., log_buffer, avail - write_ptr);
	sof_mailbox_read(..., log_buffer + avail - write_ptr, write_ptr);

This assumes that avail is still the full distance from read_ptr to
write_ptr. But avail has just been cut down to count - sizeof(avail) if
the user asked for less. If it ends up smaller than write_ptr,
avail - write_ptr wraps around, and the first sof_mailbox_read() gets a
length of about 4 GiB for the 4 KiB log_buffer.
For example, with read_ptr = 4080 and write_ptr = 16, a read of 12 bytes
gives avail = 8 and a copy of 0xfffffff8 bytes. If avail is cut but
still larger than write_ptr, the two parts don't line up with read_ptr
and the user gets the wrong bytes.

Copy from read_ptr up to the end of the slot, but no more than avail,
and take the rest from the start of the slot.

Found with a static analysis tool and checked by hand.

Fixes: f4ea22f7aa75 ("ASoC: SOF: ipc4: Add support for mtrace log extraction")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested (x86_64, W=1). I don't have SOF hardware, so I checked
the pointer arithmetic in userspace instead: the code of this function
with the mailbox replaced by an array, under ASan. Without the patch a
12-byte read at read_ptr 4080, write_ptr 16 copies 0xfffffff8 bytes,
and a 104-byte read at read_ptr 4000 returns 16 wrong bytes; with it
both return the expected data.
---
 sound/soc/sof/ipc4-mtrace.c | 13 ++++++++-----
 1 file changed, 8 insertions(+), 5 deletions(-)

diff --git a/sound/soc/sof/ipc4-mtrace.c b/sound/soc/sof/ipc4-mtrace.c
index 064291e26974..0d5135d256c3 100644
--- a/sound/soc/sof/ipc4-mtrace.c
+++ b/sound/soc/sof/ipc4-mtrace.c
@@ -230,14 +230,17 @@ static ssize_t sof_ipc4_mtrace_dfs_read(struct file *file, char __user *buffer,
 		/* Read data between read pointer and write pointer */
 		sof_mailbox_read(sdev, log_buffer_offset + read_ptr, log_buffer, avail);
 	} else {
+		/* avail may have been cut to the user's count above */
+		u32 tail = min(avail, log_buffer_size - read_ptr);
+
 		/* read from read pointer to end of the slot */
 		sof_mailbox_read(sdev, log_buffer_offset + read_ptr, log_buffer,
-				 avail - write_ptr);
-		/* read from slot start to write pointer */
-		if (write_ptr)
+				 tail);
+		/* read the rest from slot start */
+		if (avail > tail)
 			sof_mailbox_read(sdev, log_buffer_offset,
-					 (u8 *)(log_buffer) + avail - write_ptr,
-					 write_ptr);
+					 (u8 *)(log_buffer) + tail,
+					 avail - tail);
 	}
 
 	/* first write the number of bytes we have gathered */



