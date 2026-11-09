From: Jing Lin <kayano050408@gmail.com>
Subject: [PATCH v6 0/3] usb: gadget: gadgetfs: fix ep0 request lifetime and
 event counter
Date: Mon, 09 Nov 2026 14:50:50 +0800
Message-Id: <20261109-b4-gadgetfs-ep0-v6-0-b410e3dced89@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/2WNwQ6CMBAFf4Xs2ZqWlAKe/A/DoS1LWSOUtEg0h
 H+3YDx5nGTevBUiBsIIl2yFgAtF8mMCdcrA9np0yKhNDDnPlRBcMSOZ063DuYsMJ866SkgrZCl
 KXUNaTQE7eh3FW/Pl+DR3tPOe2Y2e4uzD+7hcit371eu/+lKwdCFUy42SlbH51Q2aHmfrB2i2b
 fsAPAVoAMAAAAA=
X-Change-ID: 20261106-b4-gadgetfs-ep0-f814c14717a9
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Neill Kapron <nkapron@google.com>
Cc: Jing Lin <kayano050408@gmail.com>, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, 
 syzbot+c73e1942197af9f54ca3@syzkaller.appspotmail.com, 
 stable@vger.kernel.org, Alan Stern <stern@rowland.harvard.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794207052; l=3526;
 i=kayano050408@gmail.com; s=default; h=from:subject:message-id;
 bh=GcCNUmekM6wbTbyIEB2gC9FjsQCMbBNAVPMPCFSA7gc=;
 b=xY6KpBmdfqXcFYoORjdxjDbtG3KNbxbwbb5sVpu/YA8FeWCJvLyo2SNs1TWgVIGz4kt3G0pAl
 kPWNG6ttuKTCCBiWcE8DRWeIuq+hLgnNTetaOdTPCMpDX+T7QeFLt+7
X-Developer-Key: i=kayano050408@gmail.com; a=ed25519;
 pk=pr6i8RN1WEON1jbXPdghSglxaBSzfuJjXNGFknX//+A=
X-Endpoint-Received: by B4 Relay for kayano050408@gmail.com/default with auth_id=1441
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes the ep0 request lifetime and the shared request buffer
races in gadgetfs, and the pre-existing event counter underflow.

The first patch covers the request lifetime and buffer ownership
problems, the second patch the event counter underflow, and the third
removes the const cast in gadgetfs_setup().

Changes in v6:
- Only free the buffer that setup_req() allocated.  Descriptor responses
  point req->buf into dev->buf, so clean_req() must not kfree() whatever
  req->buf happens to point at.
- Wait for the asynchronous usb_ep_dequeue() completion in
  gadgetfs_unbind() before freeing dev->req; also restore req->buf before
  the request is destroyed.
- Detect a control request that arrives while ep0_write() copies from
  userspace with a setup counter, and drop the stale response.  Keeping
  dev->state == STATE_DEV_SETUP for this would also make gadgetfs_setup()
  skip in-kernel responses such as GET_DESCRIPTOR.
- Wake an ep0_read() that waits for a delegated OUT data stage when it is
  aborted, and make the abort part of the wait condition.
- Consume setup_abort through one helper that restores
  STATE_DEV_CONNECTED only while the state is still STATE_DEV_SETUP, so
  it cannot overwrite STATE_DEV_UNBOUND.
- Link to v5: https://patch.msgid.link/20261109-b4-gadgetfs-ep0-v5-0-f16d0b648bc2@gmail.com

Changes in v5:
- Expand the first patch's changelog with the concrete interleavings of
  the ep0_read()/ep0_write() races and explain why a mutex cannot be
  used, as requested by Alan Stern.
- Add a patch that clamps a local copy of the control request instead of
  casting away the constness and writing into the caller's setup packet,
  also suggested by Alan Stern.
- Restore STATE_DEV_CONNECTED when a delegated data read is aborted by a
  new setup, so the following event read is not misdirected into the
  control data path.
- Link to v4: https://lore.kernel.org/all/20261107-b4-gadgetfs-ep0-v4-0-86bdfd684b54@gmail.com/

On the submit/unbind window: every ep0 submission increments udc_usage
under dev->lock before the lock is dropped, and gadgetfs_unbind() sets
STATE_DEV_UNBOUND and waits for udc_usage to reach zero before it samples
ep0_req_queued.  A thread that has set ep0_req_queued but has not yet
called usb_ep_queue() therefore keeps unbind waiting; when unbind
resumes, the queue call has completed and the flag and the endpoint queue
agree.  The request that is still queued at unbind is then dequeued
before it is freed.  With a test-only delay between setting the flag and
calling usb_ep_queue(), close() blocked for the remaining delay (610 ms,
versus 3 ms without the delay), confirming that teardown waits for the
submission to finish.

The series was tested with the syzbot reproducer and with targeted
lifecycle, request-reuse, wedge, stale-response, and event-counter tests
on arm64 QEMU with dummy_hcd, KASAN, and lockdep.

Signed-off-by: Jing Lin <kayano050408@gmail.com>
---
Jing Lin (3):
      usb: gadget: gadgetfs: fix ep0 request lifetime on disconnect
      usb: gadget: gadgetfs: prevent ep0 event counter underflow
      usb: gadget: gadgetfs: avoid writing through the const setup pointer

 drivers/usb/gadget/legacy/inode.c | 265 +++++++++++++++++++++++++++-----------
 1 file changed, 189 insertions(+), 76 deletions(-)
---
base-commit: f66469d9905b39d2c260a15d7d6db450f4db67c1
change-id: 20261106-b4-gadgetfs-ep0-f814c14717a9

Best regards,
--  
Jing Lin <kayano050408@gmail.com>

