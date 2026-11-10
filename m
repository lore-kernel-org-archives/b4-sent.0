From: Jing Lin <kayano050408@gmail.com>
Subject: [PATCH v7 0/4] usb: gadget: gadgetfs: fix ep0 request lifetime and
 event counter
Date: Tue, 10 Nov 2026 11:40:46 +0900
Message-Id: <20261110-gadgetfs-v7-v7-0-6d05409cc61a@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAC6E8moC/yXMQQ5AMBBA0avIrDVpJ6G4ilgUo8YC6SAScXfF8
 i3+v0AoMAlUyQWBDhZe5gibJtCNbvakuI8G1JgbY7Tyrve0DaIOqyjD0hUZOo0WYrEGGvj8bnX
 zW/Z2om57F3DfD5UYMlVvAAAA
X-Change-ID: 20261110-gadgetfs-v7-e529a852a027
To: Neill Kapron <nkapron@google.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Jing Lin <kayano050408@gmail.com>, stable@vger.kernel.org, 
 linux-usb@vger.kernel.org, 
 syzbot+c73e1942197af9f54ca3@syzkaller.appspotmail.com, 
 Alan Stern <stern@rowland.harvard.edu>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794278513; l=3007;
 i=kayano050408@gmail.com; s=p600; h=from:subject:message-id;
 bh=PKUcg2l0YyjidzyI3AUerGASJfY84sbnjO7rcZqOJPg=;
 b=NnWcF6I+zVGDvJeFUfJlAm8S7qzFCsny+XGnztNTG2DNjspzooMcfYPkK3WFuK/cAlAGGcvur
 ywUX4a/2pnnB/0YlDNactv9yx+LZckTiILL/B+NIaB18HztasrtTpOW
X-Developer-Key: i=kayano050408@gmail.com; a=ed25519;
 pk=DtAI52kU3F0sVbAiS4n+5b4UKMnVF398eKHlj3H9KBY=
X-Endpoint-Received: by B4 Relay for kayano050408@gmail.com/p600 with auth_id=1475
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes the ep0 request lifetime and shared request buffer
races in gadgetfs, and the pre-existing event counter underflow.

The first patch covers request lifetime and buffer ownership, the second
the ep0 setup abort and unbind state races, the third the event counter
underflow, and the fourth removes the const cast in gadgetfs_setup().

The setup() callback runs in interrupt context and may not sleep, so a
mutex cannot be used to serialize it against ep0_read() and ep0_write().
The shared request state remains protected by dev->lock and the control
payloads are handed off through private buffers.

Changes in v7:
- Split the former lifetime patch into separate request lifetime and
  buffer ownership and setup abort and unbind state race patches, as
  requested by Alan Stern.
- Submit ep0 requests through a shared queue_ep0_req() helper and wake
  dev->wait on every runtime clear of ep0_req_queued, including failed
  submissions.
- Wait for the asynchronous dequeue completion under dev->lock in
  gadgetfs_unbind().  If the controller rejects ep0 dequeue, keep the
  request and its dev reference and let completion free it after
  udc_stop() drains ep0.
- Destroy non-ep0 endpoint files before tearing down dev->req, matching
  the order in which the endpoints are created and destroyed.
- Record setup_abort before gadgetfs_setup() early returns, keep
  ep0_poll() from consuming it, include state changes and setup_generation
  in the ep0_read() wait, and return -ESRCH from event reads after
  unbind.
- Ignore zero-length ep0_read() calls while a non-zero control OUT data
  stage is pending so they cannot clobber its payload.
- Address the remaining Sashiko findings from v6 patch 1, including the
  ep0_write() state transition around copy_from_user() and the unbind
  event path.
- Write only event->u.setup.wLength in the const setup pointer patch, as
  suggested by Alan Stern.
- Link to v6: https://patch.msgid.link/20261109-b4-gadgetfs-ep0-v6-0-b410e3dced89@gmail.com

The series was tested with the syzbot reproducer and with targeted
lifecycle, request-reuse, abort, unbind, and event-counter tests on
arm64 QEMU with dummy_hcd, KASAN, and lockdep.  The syzbot reproducer
still exits 137 on the fixed kernel without a BUG, WARNING, KASAN
report, or lockdep splat.

Signed-off-by: Jing Lin <kayano050408@gmail.com>
---
Jing Lin (4):
      usb: gadget: gadgetfs: fix ep0 request lifetime and buffer races
      usb: gadget: gadgetfs: fix ep0 setup abort and unbind state races
      usb: gadget: gadgetfs: prevent ep0 event counter underflow
      usb: gadget: gadgetfs: avoid writing through the const setup pointer

 drivers/usb/gadget/legacy/inode.c | 395 ++++++++++++++++++++++++++------------
 1 file changed, 276 insertions(+), 119 deletions(-)
---
base-commit: f66469d9905b39d2c260a15d7d6db450f4db67c1
change-id: 20261110-gadgetfs-v7-e529a852a027

Best regards,
--  
Jing Lin <kayano050408@gmail.com>

