From: lurenjia534 <lurenjia534@outlook.com>
Date: Sun, 02 Aug 2026 04:19:34 +0800
Subject: [PATCH] usb: gadget: f_hid: reject zero report length
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260802-hid-report-length-usb-testing-v1-1-0499f99136d2@outlook.com>
X-B4-Tracking: v=1; b=H4sIANVUbmoC/03MwQrCMAzG8VcZORuo3Sjqq4iHtkvbiHSj6YYw9
 u6uevH4Tz5+GwgVJoFbt0GhlYWnfMT51IFPNkdCHo8GrbRRF6Ux8YiF5qlUfFGONeEiDitJ5Rw
 xXAcTemuGfrRwGHOhwO+vf3/8Whb3JF8b2hbOCqErNvvUTv9Ye8G+fwDAN3G3pAAAAA==
X-Change-ID: 20260802-hid-report-length-usb-testing-f946f3a643da
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 syzbot+7b70c4a6021fd49c4151@syzkaller.appspotmail.com, 
 Felipe Balbi <balbi@ti.com>, Andrzej Pietrasiewicz <andrzej.p@samsung.com>, 
 lurenjia534 <lurenjia534@outlook.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785615577; l=2219;
 i=lurenjia534@outlook.com; s=20260801; h=from:subject:message-id;
 bh=iNhr1oVERThburQ7HiMLwACK+h6L6PLXeAOagepD/hQ=;
 b=SFtiOQdsjcQ/amIdJ1XFYxqjyf2dEDHjAoYI81mToMrDN+4Rmg3ySrfh7qRsPX+VfkZi5j1bn
 4Ll2LgqxnEtCSJwckgkbaGA7zp9swFQaojUgLpI7wfM/ewHl+qG3k1J
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
Signed-off-by: lurenjia534 <lurenjia534@outlook.com>
---
Testing:
- syzbot reproducer: warning and panic in 2/2 runs before the fix;
  no warning in 2/2 30-second runs after the fix
- configfs/dummy_hcd regression: FAIL before the fix and PASS after it
- current usb-testing: reproducer and regression test PASS, taint 0
- GCC built-in and module builds, sparse, and x86-64/arm64 target
  builds with both supported toolchains: PASS
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
lurenjia534 <lurenjia534@outlook.com>

