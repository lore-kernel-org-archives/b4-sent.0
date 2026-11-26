From: Jing Lin <kayano050408@gmail.com>
Subject: [PATCH v9 0/6] usb: gadget: gadgetfs: fix ep0 request lifetime and
 control races
Date: Thu, 26 Nov 2026 14:37:03 +0800
Message-Id: <20261126-gadgetfs-ep0-v9-0-81b464c6e641@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAI/TB2sC/1WNyw6CMBREf4XctTWlUF4r/8OwqOW2XCOUtEg0h
 H+XohuT2Zxk5swKAT1hgCZZweNCgdy4Q31KQPdqtMio2xkEF0WaioJZ1VmcTWA4cWa0EFJmXKp
 Swj6ZPBp6Hbpr++XwvN1Rz9ERGz2F2fn38bdUsfdTp/xfvVQxnFWm5nmWyzI3eLGDosdZuwHab
 ds+1xKosL0AAAA=
X-Change-ID: 20261126-gadgetfs-ep0-fc2255305a75
To: Neill Kapron <nkapron@google.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Alan Stern <stern@rowland.harvard.edu>, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 syzbot+c73e1942197af9f54ca3@syzkaller.appspotmail.com, 
 stable@vger.kernel.org, Jing Lin <kayano050408@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795675024; l=3893;
 i=kayano050408@gmail.com; s=20261126; h=from:subject:message-id;
 bh=fvfwlA9wimqwVKnxLxvsfDJkX3M7MoycSS4Qn4OBS1Q=;
 b=bOdNzpvTZmi8LCOaQlCH7+dUQtZxXvvh+W5jRQ9aPcskDohwk8u7hmklZFJyCd5b3DMxArj+F
 O67PO+YlGOwDubELwbd44C4W50HkfAi2dEKj/R1/gnWwvbeovTFJmzj
X-Developer-Key: i=kayano050408@gmail.com; a=ed25519;
 pk=40M3hugIx++9w3nkAoFXGcN/vLWsPMGDYdbduV+lUlI=
X-Endpoint-Received: by B4 Relay for kayano050408@gmail.com/20261126 with auth_id=1648
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes the ep0 request lifetime on unbind, control buffer and
setup_abort state races, lost completed control-OUT transfers, event
counter underflow, and the const cast in gadgetfs_setup().

1/6 tracks active ep0 requests and waits for completion after
    usb_ep_dequeue() in gadgetfs_unbind() before freeing dev->req, while
    keeping descriptor buffers out of kfree().
2/6 copies delegated control-IN payloads into a private memdup_user()
    buffer before touching dev->req and drops responses superseded
    during the unlocked copy.
3/6 fixes setup_abort tracking across ep0_poll(), gadgetfs_disconnect(),
    and early returns or in-kernel requests in gadgetfs_setup().
4/6 preserves completed control-OUT payloads until ep0_read() collects
    them, leaving ep0 unqueued so the controller NAKs newly arriving
    control transfers in the meantime and replaying the deferred setup
    afterwards.
5/6 dequeues ep0 events before dropping dev->lock for copy_to_user() to
    prevent dev->ev_next underflow.
6/6 removes the const cast on ctrl->wLength in gadgetfs_setup().

The setup() callback runs in atomic context and may not sleep, so a
mutex cannot serialize it against ep0_read() and ep0_write(); shared ep0
state remains protected by dev->lock.

---
Changes in v9:
- Split the first two patches into single-purpose patches (1/6 through
  4/6) so each problem is addressed separately.
- Drop the rejected usb_ep_dequeue() fallback (ep0_req_free) in 1/6.
- Allocate a private buffer with memdup_user() for control-IN writes in
  2/6 instead of copying through a stack buffer, and clarify that the
  generation check narrows rather than eliminates the unlocked window.
- Preserve properly completed control-OUT transfers in 4/6 by deferring
  any subsequent SETUP (leaving ep0 without a queued request so the UDC
  NAKs it) until userspace reads the completed OUT payload, then replay
  the deferred SETUP.
- Drop the STATE_DEV_UNBOUND event-read changes from this series.  For
  context on how unbind can happen before close(ep0): unloading the UDC
  driver (usb_del_gadget_udc()) or writing to
  /sys/bus/gadget/drivers/gadgetfs/unbind runs gadgetfs_unbind() while
  userspace still holds the open ep0 descriptor, where a queued
  GADGETFS_SETUP event could otherwise put dev->state back into
  STATE_DEV_SETUP on the next read().  If that case is worth guarding
  against, a small follow-up patch can clear dev->ev_next and wake
  dev->wait in gadgetfs_unbind() and check STATE_DEV_UNBOUND before
  delivering events in ep0_read().
- Use a local events[N_EVENT] array in 5/6 instead of sharing a buffer
  with control-OUT reads.
- Link to v8: https://patch.msgid.link/20261110-gadgetfs-ep0-v8-v8-0-8f90434574fe@gmail.com

To: Neill Kapron <nkapron@google.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Alan Stern <stern@rowland.harvard.edu>
Cc: linux-usb@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: syzbot+c73e1942197af9f54ca3@syzkaller.appspotmail.com
Cc: stable@vger.kernel.org
Signed-off-by: Jing Lin <kayano050408@gmail.com>

---
Jing Lin (6):
      usb: gadget: gadgetfs: fix ep0 request lifetime on unbind
      usb: gadget: gadgetfs: isolate ep0_write() buffer and reduce setup race
      usb: gadget: gadgetfs: fix ep0 setup_abort tracking and reporting
      usb: gadget: gadgetfs: NAK new setups until control-OUT data is read
      usb: gadget: gadgetfs: prevent ep0 event counter underflow
      usb: gadget: gadgetfs: avoid writing through the const setup pointer

 drivers/usb/gadget/legacy/inode.c | 514 +++++++++++++++++++++++++++-----------
 1 file changed, 366 insertions(+), 148 deletions(-)
---
base-commit: 90d6263e867be7089b3d3323bef8d2accd327c77
change-id: 20261126-gadgetfs-ep0-fc2255305a75

Best regards,
--  
Jing Lin <kayano050408@gmail.com>

