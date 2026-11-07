From: Jing Lin <kayano050408@gmail.com>
Subject: [PATCH v3 0/2] usb: gadget: gadgetfs: fix ep0 request lifetime and
 event counter
Date: Sat, 07 Nov 2026 17:56:08 +0800
Message-Id: <20261107-b4-gadgetfs-ep0-v3-0-62089dc0ec07@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/2XMyw6CMBCF4Vchs3ZMB7EFVr6HcVHaaamRS1okJ
 oR3F3Rj4vJPzvkWSBwDJ6izBSLPIYWh3+J0yMC0uveMwW4NucglkZDYFOi19Ty5hDwKdCUVhgp
 FSlewvcbILrw+4vX27fRs7mymndkXLg4dTm1k/SurP3nOkdCWZSWZtD2TuvhOh8fRDB2s6xuxe
 VP0ugAAAA==
X-Change-ID: 20261106-b4-gadgetfs-ep0-f814c14717a9
To: Neill Kapron <nkapron@google.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jing Lin <kayano050408@gmail.com>, 
 syzbot+c73e1942197af9f54ca3@syzkaller.appspotmail.com, 
 stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794045369; l=2005;
 i=kayano050408@gmail.com; s=default; h=from:subject:message-id;
 bh=uuCOM4XxxKSay1DeLkiMJMLE9TgnzXP9EieCXzNPA98=;
 b=q3gwY2s2RvIl6xOyiZM0y9SxSfJKYitmPLTvrFGMJv3Fj/YS4mJ7qmhRRZQLU8eGl9YpWB2CA
 0wSWaZbBV0eCvqFOrY3vSoiMi/vBK/lV3vXvxg0wjNQ8gsl5xqdL/iA
X-Developer-Key: i=kayano050408@gmail.com; a=ed25519;
 pk=pr6i8RN1WEON1jbXPdghSglxaBSzfuJjXNGFknX//+A=
X-Endpoint-Received: by B4 Relay for kayano050408@gmail.com/default with auth_id=1441
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

gadgetfs_unbind() frees the preallocated ep0 request after disconnecting
the gadget, assuming that no I/O remains active. With dummy_hcd, a
delayed userspace response can leave the request queued when it is freed,
which triggers the warning in dummy_free_request() and a use-after-free
when dummy_udc_stop() drains the endpoint queue.

gadgetfs_setup() also reuses dev->req for a new control request while a
completed delegated OUT transfer still has setup_out_ready set waiting
for ep0_read() to copy the payload to userspace. This overwrites req->buf
with a descriptor pointer, so the later clean_req() frees the descriptor
buffer instead of the request buffer.

Keep the pending OUT payload in a separate buffer, track whether the
request is queued, dequeue it before freeing, and do not leave ep0 busy
after a zero-length status stage. The second patch prevents the ep0 event
counter from underflowing when a concurrent disconnect or connect purges
the queue while ep0_read() copies events to userspace.

Changes in v3:
- Replace the v2 -EBUSY rejection with a separate buffer for pending OUT
  data, so a new SETUP can reuse dev->req without overwriting unread data
  or leaving ep0 permanently busy after a zero-length status stage.
- Dequeue a pending ep0 request before freeing it in gadgetfs_unbind().
- Add a separate patch preventing the ep0 event counter underflow.
- Link to v2: https://patch.msgid.link/20261107-b4-gadgetfs-ep0-v2-1-d8896e1ad517@gmail.com

Signed-off-by: Jing Lin <kayano050408@gmail.com>
---
Jing Lin (2):
      usb: gadget: gadgetfs: fix ep0 request lifetime on disconnect
      usb: gadget: gadgetfs: prevent ep0 event counter underflow

 drivers/usb/gadget/legacy/inode.c | 102 ++++++++++++++++++++++++++++----------
 1 file changed, 77 insertions(+), 25 deletions(-)
---
base-commit: f66469d9905b39d2c260a15d7d6db450f4db67c1
change-id: 20261106-b4-gadgetfs-ep0-f814c14717a9

Best regards,
--  
Jing Lin <kayano050408@gmail.com>

