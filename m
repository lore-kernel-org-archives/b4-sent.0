From: Anuj Bolewar <bolewara@gmail.com>
Subject: [PATCH 0/2] usb: gadget: f_uac1/f_uac2: fix invalid-free in srate
 configfs store
Date: Tue, 04 Aug 2026 23:13:22 +0530
Message-Id: <20260804-f-uac-srate-invalid-free-v1-0-2c980378cdf5@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBCF4avIrDsQo9TQq0gXMU7aKSXKjIog3
 t2oy4/H+zdQEiaFV7GB0MLKQ8ooHwWEr08fQu6zwRr7NM7UGHH2AVX8lKe0+D/3GIUInW1CdK4
 2ZdVAvo9Ckdcr3b5v69z9KExnD/b9AA0zg6B8AAAA
X-Change-ID: 20260804-f-uac-srate-invalid-free-827cf8840137
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Anuj Bolewar <bolewara@gmail.com>, 
 syzbot+38bab69d2760cc99cfbe@syzkaller.appspotmail.com, 
 syzbot+a4f65284f1451010b0a8@syzkaller.appspotmail.com, 
 syzbot+2532c7901f590afd0c3a@syzkaller.appspotmail.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785865402; l=1062;
 i=bolewara@gmail.com; s=20260802; h=from:subject:message-id;
 bh=yQbPabwNlDcu0lA8Xh/FOL5pkzjzn/Be+O3KXo+0Hlc=;
 b=/ZNmtEoK+b7WB0vx2PZ4AmfHEiUmj9vFlY1Y5u+KuFKUTbGD0bZWS1+vEOcaFG7AZFUUrWVzm
 N7R4aQayQ8NBL14WhTLJZ5Bcmk5RZty22zDJzDvGknAVllHTNcu00M1
X-Developer-Key: i=bolewara@gmail.com; a=ed25519;
 pk=XxcXxqFWk9xQziyNEfhS6NRJQR1shqHRRYzkbaYamm0=
X-Endpoint-Received: by B4 Relay for bolewara@gmail.com/20260802 with auth_id=907
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The p_srate/c_srate configfs store helpers in f_uac1 and f_uac2 free
the strsep()-advanced split_page pointer instead of the buffer returned
by kstrdup(). When a non-numeric token appears in the first position,
kstrtou32() fails and kfree() releases a pointer into the middle of the
slab object, which KASAN reports as invalid-free.

Keep the original kstrdup() pointer and free that instead. This fixes
the syzbot reports for f_uac2_opts_p_srate_store,
f_uac2_opts_c_srate_store and f_uac1_opts_c_srate_store.

Signed-off-by: Anuj Bolewar <bolewara@gmail.com>
---
Anuj Bolewar (2):
      usb: gadget: f_uac2: fix invalid-free in srate configfs store
      usb: gadget: f_uac1: fix invalid-free in srate configfs store

 drivers/usb/gadget/function/f_uac1.c | 5 +++--
 drivers/usb/gadget/function/f_uac2.c | 5 +++--
 2 files changed, 6 insertions(+), 4 deletions(-)
---
base-commit: 2d2338c93da79b3bfe4b6099a931d9468d539952
change-id: 20260804-f-uac-srate-invalid-free-827cf8840137

Best regards,
--  
Anuj Bolewar <bolewara@gmail.com>

