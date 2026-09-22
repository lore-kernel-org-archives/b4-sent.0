From: Jaidev Shastri <jaidevshastri@vt.edu>
Subject: [PATCH 0/3] vt: make the console_lock ordering explicit for three
 variables
Date: Mon, 21 Sep 2026 21:27:13 -0400
Message-Id: <20260921-mb-vt-v1-0-71b7990c26c1@vt.edu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHHZsWoC/yXMzQrCMBAE4Fcpe3Zlkxb/XqV4SOLGRjDKbg1C6
 bub1OM3zMwCypJY4dItIFySpleuMLsOwuTynTHdqsGSPdDZGnx6LDMGRxSHE/UmEtTuWzim7/Y
 zXv/Wj39wmNu4NbxTRi8uh6lFG8tx36OEAdb1B1pDSXeJAAAA
X-Change-ID: 20260921-mb-vt-ca00f48031f0
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790040439; l=1173;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=UG7lewV4+pwaB/tgYoBoUkEr0r3d/oFPFXqtv5DLQAA=;
 b=2U6L/bpo7bgH3CClVIi1J5FFquCjjlkI8E2ECOcBJ+J4KRGCDgBz5WBbTg4EpzNp9dvW4fcon
 5py/Y42tw/tBQfLRI8W3SXovgjVMpK/5UQ0gFjQRlpXOWyHsL4fELuJ
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Three variables in vt.c are written on one path and read on another with
plain accesses on both sides: fg_console between redraw_screen() and
vt_console_print(), console_blanked between do_blank_screen() and
do_unblank_screen(), and the vc_cons[] slot between vc_deallocate() and
console_callback().

Every one of these pairs is serialised by console_lock today, so no behaviour
changes. The patches state the publication order in the accessors rather than
leaving it implicit in the lock, so the dependency is visible where the
variables are used.

Found with MBCheck, a static herd7-based memory consistency checker.
Compile-tested on arm64 with W=1, no new warnings.

---
Jaidev Shastri (3):
      vt: order the fg_console switch against vt_console_print()
      vt: order console_blanked between blanking and unblanking
      vt: order the vc_cons[] clear against console_callback()

 drivers/tty/vt/vt.c | 24 ++++++++++++++++--------
 1 file changed, 16 insertions(+), 8 deletions(-)
---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-mb-vt-ca00f48031f0

Best regards,
--  
Jaidev Shastri <jaidevshastri@vt.edu>

