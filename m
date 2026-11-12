From: Weidong Wang <weidongw@illinois.edu>
Date: Thu, 12 Nov 2026 01:07:06 -0600
Subject: [PATCH] serial: 8250_pci: don't re-enable an enabled device on
 resume
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-c3-n108-v1-1-d48f8da5894e@illinois.edu>
X-B4-Tracking: v=1; b=H4sIAJll9WoC/yXMQQqAIBCF4avErBOcESK6SrQoHWtaWGhFEN09q
 +UH/3sXJI7CCZrigsiHJFlCBpYF2KkPIytx2UCaKkQkZY0KqGvl9KANeSZ0HnK9RvZyfk9t9zv
 tw8x2e+dw3w/SS9AMawAAAA==
X-Change-ID: 20261112-c3-n108-d0b032fe21df
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: linux-serial@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Zijie Zhao <zijie4@illinois.edu>, Weidong Wang <weidongw@illinois.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794467308; l=2915;
 i=weidongw@illinois.edu; s=20261108; h=from:subject:message-id;
 bh=0/xY/OhzLDNgjLSJD2wXj/hY/A/IDIPAMgsYLiXYrAs=;
 b=nx1qBuKW7AP8OO6fTYRGSCF1fL0L0NWzb0cDILi7zFqEvGZCjKuNWjkvGhHZ2yt55OuQM4LOB
 ySXnlKw6j0CAP4XIWCdIgYTyd1EV+gysYCfdX2ZPVqk6QWapm/lTs3O
X-Developer-Key: i=weidongw@illinois.edu; a=ed25519;
 pk=DR2S1xPEa5sELrWPfOpvUphJQ2VHC+MDc/wJavE/ifg=
X-Endpoint-Received: by B4 Relay for weidongw@illinois.edu/20261108 with auth_id=1449
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pciserial_resume_one() calls pci_enable_device() on every resume. Probe
already enabled the device with pcim_enable_device() and suspend does
not disable it, so each suspend/resume cycle adds one to enable_cnt
that nothing drops. After N cycles, unbinding the driver leaves
enable_cnt at N and the device enabled.

Only re-enable the device when it is actually disabled.

Found by an AI code review agent (an LLM-based bug-finding tool
developed by Zijie Zhao and the submitter) and confirmed on an
unmodified kernel, without error injection, on x86_64 under QEMU with
the "pci-serial" device (1b36:0002), which 8250_pci drives: after five
s2idle cycles with pm_test=devices, /sys/bus/pci/devices/.../enable
read 6, and 5 after unbinding the driver; without the suspend
cycles it read 1, and 0 after unbinding.

With this patch it stays at 1 across the cycles and drops to 0 on
unbind.

The reproducer, fix and changelog were drafted with AI assistance
(Claude), then reviewed and tested by the submitter.

Cc: Zijie Zhao <zijie4@illinois.edu>
Signed-off-by: Weidong Wang <weidongw@illinois.edu>
---
Tested on v7.4-rc1 (05441d697f7f), x86_64, QEMU/KVM with -device
pci-serial (1b36:0002), pm_test=devices, five suspend-to-idle cycles
and then an unbind of the serial driver:

               5 x s2idle, then unbind         unbind only (control)
  unpatched    enable_cnt 1 -> 6, 5 after      1 -> 0
               unbind
  patched      stays 1, 0 after unbind         1 -> 0

No KASAN/UBSAN reports on the patched kernel. The code is unchanged in
mainline, linux-next (next-20261111) and tty-next.

The reproducer is available on request.
---
 drivers/tty/serial/8250/8250_pci.c | 14 +++++++++-----
 1 file changed, 9 insertions(+), 5 deletions(-)

diff --git a/drivers/tty/serial/8250/8250_pci.c b/drivers/tty/serial/8250/8250_pci.c
index 1dda63be6..e9b9bcc3d 100644
--- a/drivers/tty/serial/8250/8250_pci.c
+++ b/drivers/tty/serial/8250/8250_pci.c
@@ -4250,12 +4250,16 @@ static int pciserial_resume_one(struct device *dev)
 
 	if (priv) {
 		/*
-		 * The device may have been disabled.  Re-enable it.
+		 * The device may have been disabled.  Re-enable it, but only
+		 * then: probe enabled it once, and every extra enable here is
+		 * never undone.
 		 */
-		err = pci_enable_device(pdev);
-		/* FIXME: We cannot simply error out here */
-		if (err)
-			pci_err(pdev, "Unable to re-enable ports, trying to continue.\n");
+		if (!pci_is_enabled(pdev)) {
+			err = pci_enable_device(pdev);
+			/* FIXME: We cannot simply error out here */
+			if (err)
+				pci_err(pdev, "Unable to re-enable ports, trying to continue.\n");
+		}
 		pciserial_resume_ports(priv);
 	}
 	return 0;

---
base-commit: 05441d697f7f9a927264f4058cbbc6a03dfcac9d
change-id: 20261112-c3-n108-d0b032fe21df

Best regards,
--  
Weidong Wang <weidongw@illinois.edu>

