From: Jiaheng Zhang <lurenjia534@outlook.com>
Date: Mon, 03 Aug 2026 02:12:59 +0800
Subject: [PATCH v2] usb: gadget: f_hid: reject zero report length
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-hid-report-length-usb-testing-v2-1-49144e0d11ae@outlook.com>
X-B4-Tracking: v=1; b=H4sIAKqIb2oC/42OQQ7CIBREr2JY+w2lDRFX3sN0QeFT0AoN0EbT9
 O6WunHp8s1MXmYhCaPDRC6HhUScXXLBb8COB6Ks9D2C0xsTRhmnZ8rAOg0RxxAzDOj7bGFKHWR
 M2fkejGi4qSVvai3J5hgjGvfa/bf2y2nq7qhykZZFJxNCF6VXtkS/slKViXUph/jeP85VUf17Z
 66gAtoIYYSoaq7ZNUx5COFxUuFJ2nVdP3bL18QBAQAA
X-Change-ID: 20260802-hid-report-length-usb-testing-f946f3a643da
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 syzbot+7b70c4a6021fd49c4151@syzkaller.appspotmail.com, 
 Felipe Balbi <balbi@ti.com>, Andrzej Pietrasiewicz <andrzej.p@samsung.com>, 
 Jiaheng Zhang <lurenjia534@outlook.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785694383; l=2465;
 i=lurenjia534@outlook.com; s=20260801; h=from:subject:message-id;
 bh=O2BdkvFQJmn8WM8m861gjCJrv/A+Rv0+aSvZQnkLtyY=;
 b=LRa3ZEUBkieSiDH0kyo5QbqaOeXnx2Ntre5qJt6NoErr07dCJt3c6qvApcOc4hxSwge2Ox1uj
 WK/oV23xv6wAaBFX/7s5JyFSjQ18Wf+yjrOkB8T8Y5JTDL8eXPmYDbE
X-Developer-Key: i=lurenjia534@outlook.com; a=ed25519;
 pk=nMa0OcUJYxnaGbhs5f95IwVQ7sPrWI7It3LMsh0BJX4=
X-Endpoint-Received: by B4 Relay for lurenjia534@outlook.com/20260801 with auth_id=906
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

New configfs HID function instances leave report_length at zero until
userspace sets the attribute.  hidg_alloc() currently accepts that value
and copies it into the function state.  hidg_bind() then uses it as the
maximum packet size of the interrupt endpoint descriptors.

If userspace links the unconfigured function and enables the gadget,
hidg_set_alt() reaches usb_ep_enable() with a zero maximum packet size,
which triggers a warning.

Reject the function from hidg_alloc() when report_length is zero.  This
makes the configfs link fail before invalid endpoint descriptors can be
added while leaving configured HID functions unchanged.

Fixes: 21a9476a7ba8 ("usb: gadget: hid: add configfs support")
Reported-by: syzbot+7b70c4a6021fd49c4151@syzkaller.appspotmail.com
Closes: https://lore.kernel.org/all/6a6cd7bd.1aa927e4.17d4bf.0004.GAE@google.com/
Assisted-by: Codex:GPT-5.6 MAX
Signed-off-by: Jiaheng Zhang <lurenjia534@outlook.com>
---
Testing:
- syzbot reproducer: warning and panic in 2/2 runs before the fix;
  no warning in 2/2 30-second runs after the fix
- configfs/dummy_hcd regression: FAIL before the fix and PASS after it
- current usb-testing: reproducer and regression test PASS, taint 0
- GCC built-in and module builds, sparse, and x86-64/arm64 target
  builds with both supported toolchains: PASS
---
Changes in v2:
- Use the real name Jiaheng Zhang in the author and Signed-off-by fields,
  as requested.
- No code changes.
- Link to v1: https://patch.msgid.link/20260802-hid-report-length-usb-testing-v1-1-0499f99136d2@outlook.com
---
 drivers/usb/gadget/function/f_hid.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/usb/gadget/function/f_hid.c b/drivers/usb/gadget/function/f_hid.c
index 3c6b43d06a..74a78cfd37 100644
--- a/drivers/usb/gadget/function/f_hid.c
+++ b/drivers/usb/gadget/function/f_hid.c
@@ -1605,6 +1605,11 @@ static struct usb_function *hidg_alloc(struct usb_function_instance *fi)
 	opts = container_of(fi, struct f_hid_opts, func_inst);
 
 	mutex_lock(&opts->lock);
+	if (!opts->report_length) {
+		mutex_unlock(&opts->lock);
+		kfree(hidg);
+		return ERR_PTR(-EINVAL);
+	}
 
 	spin_lock_init(&hidg->write_spinlock);
 	spin_lock_init(&hidg->read_spinlock);

---
base-commit: 5d5fd841c34649f1b09220fe58e59dffd61c447d
change-id: 20260802-hid-report-length-usb-testing-f946f3a643da

Best regards,
--  
Jiaheng Zhang <lurenjia534@outlook.com>

