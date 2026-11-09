From: Jing Lin <kayano050408@gmail.com>
Subject: [PATCH v5 0/3] usb: gadget: gadgetfs: fix ep0 request lifetime and
 event counter
Date: Mon, 09 Nov 2026 13:55:38 +0800
Message-Id: <20261109-b4-gadgetfs-ep0-v5-0-f16d0b648bc2@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/yXMMQ6DMAxA0asgz1iKUYC2V0EMITipO1AUA6qEu
 HsDjG/4fwflJKzwKnZIvInKd8qoywL8202RUcZsqEzVEJkGB4vRjZGXoMizwfAg68m21Lon5Gp
 OHOR3Hbv+tq7Dh/1ybuA4/nZnaIBzAAAA
X-Change-ID: 20261106-b4-gadgetfs-ep0-f814c14717a9
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Neill Kapron <nkapron@google.com>
Cc: Jing Lin <kayano050408@gmail.com>, 
 syzbot+c73e1942197af9f54ca3@syzkaller.appspotmail.com, 
 Alan Stern <stern@rowland.harvard.edu>, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, linux-usb@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794203739; l=2478;
 i=kayano050408@gmail.com; s=default; h=from:subject:message-id;
 bh=DF1axyv67iSuG+wzHaBzMijjoGW1EVzMAH6xitD2aQA=;
 b=F1GfACeEdJiCFHx9fxiPDGc5KPHyAloblPu5sPW7JYotxvczXHMMb7fbfnYBRBAflAHB9PSis
 4OIknUGXDE5Cckhan+yHB/qZ2XOvyx113NweETMvJWFk7/gKjzM1vly
X-Developer-Key: i=kayano050408@gmail.com; a=ed25519;
 pk=pr6i8RN1WEON1jbXPdghSglxaBSzfuJjXNGFknX//+A=
X-Endpoint-Received: by B4 Relay for kayano050408@gmail.com/default with auth_id=1441
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes the ep0 request lifetime and the shared request buffer
races in gadgetfs, and the pre-existing event counter underflow.

The first patch covers the request lifetime and buffer ownership
problems, the second patch the event counter underflow, and the third
removes the const cast in gadgetfs_setup().

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
lifecycle, request-reuse, wedge, and event-counter tests on arm64 QEMU
with dummy_hcd, KASAN, and lockdep.

Signed-off-by: Jing Lin <kayano050408@gmail.com>
---
Jing Lin (3):
      usb: gadget: gadgetfs: fix ep0 request lifetime on disconnect
      usb: gadget: gadgetfs: prevent ep0 event counter underflow
      usb: gadget: gadgetfs: avoid writing through the const setup pointer

 drivers/usb/gadget/legacy/inode.c | 181 ++++++++++++++++++++++++++------------
 1 file changed, 123 insertions(+), 58 deletions(-)
---
base-commit: f66469d9905b39d2c260a15d7d6db450f4db67c1
change-id: 20261106-b4-gadgetfs-ep0-f814c14717a9

Best regards,
--  
Jing Lin <kayano050408@gmail.com>

