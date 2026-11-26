From: Jing Lin <kayano050408@gmail.com>
Subject: [PATCH v10 0/6] usb: gadget: gadgetfs: fix ep0 request lifetime
 and control races
Date: Thu, 26 Nov 2026 21:44:50 +0900
Message-Id: <20261126-gadgetfs-ep0-v10-0-8add6d9cace2@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMIpCGsC/3WNQQ6CMBREr0L+2pq20iquvIdhUcqnfCOUtNhoC
 HeX4trlTN68WSBiIIxwLRYImCiSH7cg+KEA25vRIaN2K0ByqYWQmjnTOpy7yHDirLNSKnXiypw
 VbJMpYEfv3Xevfzm+mgfaOTsy0VOcffjsh6nK3B91qhhnF9GUurQadSlubjD0PFo/QL2u6xdFh
 /U6uwAAAA==
X-Change-ID: 20261126-gadgetfs-ep0-fc2255305a75
To: Neill Kapron <nkapron@google.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Alan Stern <stern@rowland.harvard.edu>, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 syzbot+c73e1942197af9f54ca3@syzkaller.appspotmail.com, 
 stable@vger.kernel.org, Jing Lin <kayano050408@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795697092; l=3154;
 i=kayano050408@gmail.com; s=20261106-gadgetfs-gmail;
 h=from:subject:message-id; bh=p1lLMpmlt9kkScFn61Zfzl16KKY6YuNALR7PHkXUvx8=;
 b=O2mkzLygLtk7Y+w9TR/AvEQBl0FICi95CRZek/N04F0038+LYWq54dOzcil2PtA9CW21UDMWg
 jkq+vZAmk/rBO/iBDl1L6DlTyvyOb49/gunXuwmramUEgmalvDJ0V67
X-Developer-Key: i=kayano050408@gmail.com; a=ed25519;
 pk=DtAI52kU3F0sVbAiS4n+5b4UKMnVF398eKHlj3H9KBY=
X-Endpoint-Received: by B4 Relay for kayano050408@gmail.com/20261106-gadgetfs-gmail with auth_id=1433
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
    ep0_read() event waits, and early returns or in-kernel requests in
    gadgetfs_setup().
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
Changes in v10:
- Re-check setup_abort and dev->state in ep0_read() after waking from
  the event wait before jumping to scan: (3/6).
- Track the active control-OUT request with dev->setup_out_generation so
  ep0_complete() ignores requests superseded before completion, and
  check setup_generation in the ep0_read() control-OUT wait path (4/6).
- Recheck dev->state and dev->setup_generation after queue_ep0_req()
  re-acquires dev->lock in gadgetfs_do_setup(), increment
  setup_generation on disconnect and unbind, and verify generation and
  state before calling usb_ep_set_halt() in ep0_process_pending_setup()
  (4/6).
- Link to v9: https://patch.msgid.link/20261126-gadgetfs-ep0-v9-0-81b464c6e641@gmail.com

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

 drivers/usb/gadget/legacy/inode.c | 551 +++++++++++++++++++++++++++-----------
 1 file changed, 399 insertions(+), 152 deletions(-)
---
base-commit: 90d6263e867be7089b3d3323bef8d2accd327c77
change-id: 20261126-gadgetfs-ep0-fc2255305a75

Best regards,
--  
Jing Lin <kayano050408@gmail.com>

