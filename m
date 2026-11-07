From: Jing Lin <kayano050408@gmail.com>
Subject: [PATCH v4 0/2] usb: gadget: gadgetfs: fix ep0 request lifetime and
 event counter
Date: Sat, 07 Nov 2026 21:46:12 +0900
Message-Id: <20261107-b4-gadgetfs-ep0-v4-0-86bdfd684b54@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJQd72oC/4WPy07EMAxFf2WUNS5xmknqWfEfiEWaetog+lASK
 tCo/05T2AwsWF7b5+j6JhLHwElcTjcReQ0pzNMe9MNJ+MFNPUPo9iyUVAZRGmg19K7rOV8T8CL
 h2qD2qC1aR2KnlsjX8HEYn1++c3pvX9nnoikXrUsMbXSTH8pojqEP0+PoUuZY9kNIeY6fR6UVi
 0egpZqsITSkK2WtwYrOutakSVpU1jSIJKu7YovLfoDMKT/1owtvlZ9HURqt6nD+fGT/fLQqQOi
 ahgyj685of/P1P3wNEoySDXVespd3/LZtXyvFB0N0AQAA
X-Change-ID: 20261106-b4-gadgetfs-ep0-f814c14717a9
To: Neill Kapron <nkapron@google.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 syzbot+c73e1942197af9f54ca3@syzkaller.appspotmail.com, 
 stable@vger.kernel.org, Jing Lin <kayano050408@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794055573; l=3518;
 i=kayano050408@gmail.com; s=20261106-gadgetfs-gmail;
 h=from:subject:message-id; bh=bTvVhVMcfu7sgkbgZWUCkfdoko52Ui4bE2y5k9oCIrY=;
 b=B21GKPrJNI7wrXIy8PZGYR0WU8eEgz9b72MBnJdaxqL0PTbYWb6FD7tTVMkhomnAc8MN35SL1
 soDvDVg6IJFD5Yn9iVZ2xDGp/FK8vHxAnWEPKdM1sK0gbgNwPyPcm1E
X-Developer-Key: i=kayano050408@gmail.com; a=ed25519;
 pk=DtAI52kU3F0sVbAiS4n+5b4UKMnVF398eKHlj3H9KBY=
X-Endpoint-Received: by B4 Relay for kayano050408@gmail.com/20261106-gadgetfs-gmail with auth_id=1433
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

gadgetfs_unbind() frees the preallocated ep0 request after disconnecting
the gadget, assuming that no I/O remains active. With dummy_hcd, a
delayed userspace response can leave the request queued when it is freed,
which triggers the warning in dummy_free_request() and a use-after-free
when dummy_udc_stop() drains the endpoint queue.

gadgetfs_setup() and ep0_write() also race on dev->req and req->buf
while a control transfer is in flight or while a completed delegated OUT
transfer is waiting for ep0_read() to copy the payload to userspace.
Overwriting req->buf with a descriptor pointer causes clean_req() to
free the descriptor buffer instead of the request buffer.

Copy completed OUT payloads into a separate setup_buf in ep0_complete(),
copy IN payloads from userspace into a stack buffer before preparing
dev->req in ep0_write(), reset req->buf when transfers finish, reject
dev->req reuse while it is queued, and dequeue it before freeing in
gadgetfs_unbind(). The second patch dequeues ep0 events into the local
buffer under dev->lock before copy_to_user() to prevent event races,
dropped GADGETFS_SETUP events, and counter underflow.

Changes in v4:
- Reject reusing dev->req in setup_req() and gadgetfs_setup() while
  dev->ep0_req_queued is set, so an -EINVAL queue failure cannot clear
  ep0_req_queued while dev->req remains on the endpoint queue.
- Copy control IN payloads into a stack buffer before preparing dev->req
  in ep0_write(), copy completed control OUT payloads into setup_buf in
  ep0_complete(), and reset req->buf when control transfers complete so
  clean_req() cannot free descriptor memory.
- Dequeue ep0 events into the local buffer and update dev->ev_next under
  dev->lock before copy_to_user() instead of using a generation counter,
  avoiding unlocked dev->event[] reads and lost GADGETFS_SETUP events.
- Link to v3: https://patch.msgid.link/20261107-b4-gadgetfs-ep0-v3-0-62089dc0ec07@gmail.com

Changes in v3:
- Replace the v2 -EBUSY rejection with a separate buffer for pending OUT
  data, so a new SETUP can reuse dev->req without overwriting unread data
  or leaving ep0 permanently busy after a zero-length status stage.
- Dequeue a pending ep0 request before freeing it in gadgetfs_unbind().
- Add a separate patch preventing the ep0 event counter underflow.
- Link to v2: https://patch.msgid.link/20261107-b4-gadgetfs-ep0-v2-1-d8896e1ad517@gmail.com

Changes in v2:
- Also check dev->setup_out_ready in gadgetfs_setup() so a new SETUP
  request cannot reuse dev->req or overwrite req->buf while ep0_read()
  still has unread or in-progress control OUT data.
- Reset req->buf to dev->rbuf in setup_req() when len <= sizeof(dev->rbuf)
  and clean up unread control OUT buffer in gadgetfs_unbind().
- Remove RFC syzbot test commands from the commit description and add the
  syzbot Tested-by tag.
- Link to v1: https://patch.msgid.link/179397691694.27761.9543494907127681190.gadgetfs-ep0-patch-test@gmail.com

Signed-off-by: Jing Lin <kayano050408@gmail.com>

---
Jing Lin (2):
      usb: gadget: gadgetfs: fix ep0 request lifetime on disconnect
      usb: gadget: gadgetfs: prevent ep0 event counter underflow

 drivers/usb/gadget/legacy/inode.c | 171 ++++++++++++++++++++++++++------------
 1 file changed, 117 insertions(+), 54 deletions(-)
---
base-commit: f66469d9905b39d2c260a15d7d6db450f4db67c1
change-id: 20261106-b4-gadgetfs-ep0-f814c14717a9

Best regards,
--  
Jing Lin <kayano050408@gmail.com>

