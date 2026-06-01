From: Gabriel Prostitis <prostitisgabriel@gmail.com>
Subject: [PATCH v2 0/2] USB: gadget: fix mm lifetime use-after-free in
 async read paths
Date: Mon, 01 Jun 2026 08:44:09 +0200
Message-Id: <20260601-mm-uaf-fix-v2-0-3c942a707bce@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADkqHWoC/22NwQ6CMBBEf4Xs2Rpapaae/A/DoS4LrLFAWiAa0
 n+3xavHN5l5s0EgzxTgWmzgaeXA45BAHQrA3g4dCW4SgyqVLquTFM6Jxbai5bcwsjGNRYvaKEi
 DyVOKd9m9/nFYHk/CORtyo+cwj/6zv60y9/6KVynKZK8uElGjPetb5yy/jjg6qGOMX+btw1y2A
 AAA
X-Change-ID: 20260531-mm-uaf-fix-91d9dacac692
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alan Stern <stern@rowland.harvard.edu>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780296264; l=2076;
 i=prostitisgabriel@gmail.com; s=20260530; h=from:subject:message-id;
 bh=xHxB2pOSyyZowRo09CbcvppCJJkUZGCEt2dPo1xU3bY=;
 b=mgTzuF/rBl+4M9iB+1XIy28i/YyzgWvgjl/QTqb3d0ERehpAlLOpmAu3Qa94CZmoawG29aMEF
 fORc8iZZ8ocB4zR65g2ozfbNbdHnVYC7mmQwYw75ad3RMw8tBfliU0a
X-Developer-Key: i=prostitisgabriel@gmail.com; a=ed25519;
 pk=FwuU+O6ZnvvnFVA45nfqkGlhSmC1P64HLtxRgBebOuY=
X-Endpoint-Received: by B4 Relay for prostitisgabriel@gmail.com/20260530 with auth_id=800
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There is a use-after-free in the USB gadget FunctionFS and legacy
GadgetFS asynchronous read paths. Both implementations store
current->mm in per-request state without taking a reference, and
later use it in a workqueue context via kthread_use_mm().

If the submitting task exits before the USB request completes,
the stored mm_struct may be freed while a pending request still
references it, leading to a use-after-free.

The issue affects:

- FunctionFS: drivers/usb/gadget/function/f_fs.c
- GadgetFS legacy: drivers/usb/gadget/legacy/inode.c

Fix this by taking a reference to mm_struct with mmgrab() when
queueing the request and releasing it with mmdrop() after
completion. Before using the saved mm_struct, acquire a temporary 
reference with mmget_not_zero() to ensure it is still alive.

The issue can be triggered by submitting asynchronous reads on
OUT endpoints (e.g. via io_uring for FunctionFS) and exiting the
submitting task before completion. This may result in memory
corruption in the address space of another process if the freed
mm_struct is reclaimed during the race window.

KASAN reports confirm use-after-free in the workqueue completion
path when accessing the stale mm_struct.

Signed-off-by: Gabriel Prostitis <prostitisgabriel@gmail.com>
---
Changes in v2:
- Fix swapped lines in drivers/usb/gadget/legacy/inode.c
- Link to v1: https://patch.msgid.link/20260531-mm-uaf-fix-v1-0-91571cc6ca46@gmail.com

To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Gabriel Prostitis (2):
      USB: gadget: ffs: fix mm lifetime handling
      USB: gadget: inode: fix mm lifetime handling

 drivers/usb/gadget/function/f_fs.c | 27 ++++++++++++++++++++-------
 drivers/usb/gadget/legacy/inode.c  | 17 +++++++++++++----
 2 files changed, 33 insertions(+), 11 deletions(-)
---
base-commit: 22d91cef94b5b86cff0d68ebfce7741740672704
change-id: 20260531-mm-uaf-fix-91d9dacac692

Best regards,
--  
Gabriel Prostitis <prostitisgabriel@gmail.com>

