From: Jing Lin <kayano050408@gmail.com>
Subject: [PATCH v8 0/4] usb: gadget: gadgetfs: fix ep0 request lifetime and
 event counter
Date: Tue, 10 Nov 2026 12:13:21 +0800
Message-Id: <20261110-gadgetfs-ep0-v8-v8-0-8f90434574fe@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/22NOw7CMBBErxJtjZE35F9xD5TCOBtnEfnINhYoy
 t2JQ4s0zZNm3qzgyDI5aJIVLAV2PE87VKcE9KAmQ4K7nSGVaYGIUhjVGfK9E7RIESpx0WWmqMY
 8RQX7arHU8/sw3tofu9f9QdpHTWwM7PxsP8dlwNj7Yw9ljBRFJ/NM1loXqK5mVPw863mEdtu2L
 zAAcB28AAAA
X-Change-ID: 20261110-gadgetfs-ep0-v8-3c74ae91521a
To: Neill Kapron <nkapron@google.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Jing Lin <kayano050408@gmail.com>, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 syzbot+c73e1942197af9f54ca3@syzkaller.appspotmail.com, 
 stable@vger.kernel.org, Alan Stern <stern@rowland.harvard.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794284002; l=2061;
 i=kayano050408@gmail.com; s=default; h=from:subject:message-id;
 bh=BlzA0Qa2znzj8wOnyhlzEGmT96YORddPRspoCgok8lU=;
 b=5nKStOoz1gCplPEVEFe9tOPU3HcgunCLaLVMgYZnJLvw+/cZnU7WnwhxUSSPhDHyIgu4gb3sS
 wuwfRcze6m0BRRhpNWs0SPgBjleZKUcf7zIZKrautxqq6U1qI61BBi8
X-Developer-Key: i=kayano050408@gmail.com; a=ed25519;
 pk=pr6i8RN1WEON1jbXPdghSglxaBSzfuJjXNGFknX//+A=
X-Endpoint-Received: by B4 Relay for kayano050408@gmail.com/default with auth_id=1441
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

The series was tested with the syzbot reproducer and with targeted
lifecycle, request-reuse, abort, unbind, stale-setup, and event-counter
tests on arm64 QEMU with dummy_hcd, KASAN, and lockdep.  The syzbot
reproducer still exits 137 on the fixed kernel without a BUG, WARNING,
KASAN report, or lockdep splat.

Signed-off-by: Jing Lin <kayano050408@gmail.com>
---
Changes in v8:
- Discard a queued but uncollected GADGETFS_SETUP event when a new SETUP
  arrives, so userspace cannot queue a response for a control transfer
  the host has already superseded.
- Link to v7: https://patch.msgid.link/20261110-gadgetfs-v7-v7-0-6d05409cc61a@gmail.com

To: Neill Kapron <nkapron@google.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Jing Lin (4):
      usb: gadget: gadgetfs: fix ep0 request lifetime and buffer races
      usb: gadget: gadgetfs: fix ep0 setup abort and unbind state races
      usb: gadget: gadgetfs: prevent ep0 event counter underflow
      usb: gadget: gadgetfs: avoid writing through the const setup pointer

 drivers/usb/gadget/legacy/inode.c | 437 ++++++++++++++++++++++++++------------
 1 file changed, 305 insertions(+), 132 deletions(-)
---
base-commit: f66469d9905b39d2c260a15d7d6db450f4db67c1
change-id: 20261110-gadgetfs-ep0-v8-3c74ae91521a

Best regards,
--  
Jing Lin <kayano050408@gmail.com>

