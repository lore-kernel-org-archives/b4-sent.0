From: Gabriel Prostitis <prostitisgabriel@gmail.com>
Subject: [PATCH 0/2] USB: gadget: fix mm lifetime use-after-free in async
 read paths
Date: Sun, 31 May 2026 23:04:39 +0200
Message-Id: <20260531-mm-uaf-fix-v1-0-91571cc6ca46@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGeiHGoC/yXM0QpAMBTG8VfRuXZqm6h5FbmY7eCooQ0peXfD5
 e+r739BpMAUoc4uCHRw5GVOkHkGdjTzQMguGZRQlSgLid7jbnrs+UQtnXbGGltpBemwBkrzF2v
 a33HvJrLbW4D7fgCpR8VlbgAAAA==
X-Change-ID: 20260531-mm-uaf-fix-91d9dacac692
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Gabriel Prostitis <prostitisgabriel@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780261550; l=1813;
 i=prostitisgabriel@gmail.com; s=20260530; h=from:subject:message-id;
 bh=9xHmw36KDmoY3u+JBaKiwE1xkfzVDG8gdznwLgAwKC4=;
 b=RzkI0hNCePrSRxMfjkqz0VDak9y0kh1TjLp01zBROSZG5GOmfu5kQ/UY3ABwLLlrRPqZwbJyo
 TM/g2fRVhpyDkNQwz6n2H2yNaqyZJUf9fTOqf5X+TT3bHew4gu8F1wY
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

Best regards,
Gabriel

Signed-off-by: Gabriel Prostitis <prostitisgabriel@gmail.com>
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

