From: Weidong Wang <weidongw@illinois.edu>
Date: Wed, 11 Nov 2026 22:18:29 -0600
Subject: [PATCH] media: pulse8-cec: Unregister the adapter if applying the
 config fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-c4-n014-v1-1-a66fd8e2125c@illinois.edu>
X-B4-Tracking: v=1; b=H4sIABU+9WoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDINBNNtHNMzA00TUwTDFLMUszNTI3t1ACqi4oSk3LrACbFB0L4ReXJmW
 lJpeAtCvV1gIAP9r2qGsAAAA=
X-Change-ID: 20261111-c4-n014-01d6d6f52778
To: Hans Verkuil <hverkuil@kernel.org>
Cc: Mauro Carvalho Chehab <mchehab@kernel.org>, linux-media@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Zijie Zhao <zijie4@illinois.edu>, Weidong Wang <weidongw@illinois.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794457126; l=4025;
 i=weidongw@illinois.edu; s=20261108; h=from:subject:message-id;
 bh=XIF8JyNv4pQCSsgeieTZ6qi2XZW+IcjZVp9dPdC0fP0=;
 b=gPs7q29+4FwmadOTE1BAx1Ci2OPqW62WrPl2x0RhJDM6I358tKzpso63OFSxT3dmkQcma4Fg0
 1FzA+jfnBJvDm77KH+d0PGloGTlS2fNA8Gc/s2UVs1CqIYgc68Y7V85
X-Developer-Key: i=weidongw@illinois.edu; a=ed25519;
 pk=DR2S1xPEa5sELrWPfOpvUphJQ2VHC+MDc/wJavE/ifg=
X-Endpoint-Received: by B4 Relay for weidongw@illinois.edu/20261108 with auth_id=1449
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When persistent_config is set and the adapter is in autonomous mode,
pulse8_connect() applies the configuration stored in the adapter's
EEPROM after cec_register_adapter(). If that fails, for example because
cec_s_log_addrs() rejects the stored CEC version, the error path jumps to
close_serio, which frees the registered adapter with
cec_delete_adapter(). The cec device node stays registered, and the next
open() of /dev/cecN uses the freed adapter.

Unregister the adapter on that path, as pulse8_disconnect() does.

Found by an AI code review agent (an LLM-based bug-finding tool
developed by Zijie Zhao and the submitter) and confirmed on an
unmodified kernel, without error injection, on x86_64 under QEMU with
KASAN. The adapter was emulated on a pty with the serport line
discipline, as set up by inputattach --pulse8-cec: firmware version 8,
autonomous mode, and a stored configuration for a playback device with
CEC version 1.3a. With persistent_config=1 the probe fails with -EINVAL
but /dev/cec0 remains, and opening it gives

  BUG: KASAN: slab-use-after-free in exact_lock+0x66/0x70
  Read of size 8 at addr ffff88800e03c360 by task poc/72
   kobj_lookup+0x1d4/0x410
   chrdev_open+0x2d7/0x5b0

with the object allocated by cec_allocate_adapter() and freed by
pulse8_connect(). The same emulated adapter with a stored CEC version of
1.4 probes normally.

With this patch the failed probe leaves no /dev/cec0 behind and KASAN
reports nothing, and the CEC 1.4 adapter still probes and answers
CEC_ADAP_G_CAPS. The reproducer is available on request.

The reproducer, fix and changelog were drafted with AI assistance
(Claude), then reviewed and tested by the submitter.

Fixes: e28a6c8b3fcc ("[media] pulse8-cec: sync configuration with adapter")
Cc: stable@vger.kernel.org
Cc: Zijie Zhao <zijie4@illinois.edu>
Signed-off-by: Weidong Wang <weidongw@illinois.edu>
---
Tested on v7.4-rc1 (05441d697f7f), x86_64, KASAN, QEMU/KVM, with the
adapter emulated on a pty (serport ldisc, as inputattach --pulse8-cec
sets up), firmware v8, autonomous mode, persistent_config=1:

               stored CEC version 1.3a         stored CEC version 1.4
                                               (control)
  unpatched    probe fails, /dev/cec0 stays;   probes, G_CAPS works
               open: KASAN slab-use-after-free
  patched      probe fails, no /dev/cec0,      probes, G_CAPS works
               no report

No KASAN/UBSAN reports on the patched kernel; checkpatch clean. The
code is unchanged in mainline and linux-next (next-20261111).

The reproducer is not attached (AI-found issue, see security-bugs.rst)
and can be shared on request.
---
 drivers/media/cec/usb/pulse8/pulse8-cec.c | 12 +++++++++++-
 1 file changed, 11 insertions(+), 1 deletion(-)

diff --git a/drivers/media/cec/usb/pulse8/pulse8-cec.c b/drivers/media/cec/usb/pulse8/pulse8-cec.c
index fa5df1062..374a8fd25 100644
--- a/drivers/media/cec/usb/pulse8/pulse8-cec.c
+++ b/drivers/media/cec/usb/pulse8/pulse8-cec.c
@@ -888,7 +888,7 @@ static int pulse8_connect(struct serio *serio, struct serio_driver *drv)
 	if (persistent_config && pulse8->autonomous) {
 		err = pulse8_apply_persistent_config(pulse8, &log_addrs, pa);
 		if (err)
-			goto close_serio;
+			goto unregister_adap;
 		pulse8->restoring_config = true;
 	}
 
@@ -896,6 +896,16 @@ static int pulse8_connect(struct serio *serio, struct serio_driver *drv)
 
 	return 0;
 
+unregister_adap:
+	/* the adapter is registered: tear down as pulse8_disconnect() does */
+	mutex_lock(&pulse8->lock);
+	pulse8->serio = NULL;
+	mutex_unlock(&pulse8->lock);
+	cec_unregister_adapter(pulse8->adap);
+	serio_set_drvdata(serio, NULL);
+	serio_close(serio);
+	return err;
+
 close_serio:
 	pulse8->serio = NULL;
 	serio_set_drvdata(serio, NULL);

---
base-commit: 05441d697f7f9a927264f4058cbbc6a03dfcac9d
change-id: 20261111-c4-n014-01d6d6f52778

Best regards,
--  
Weidong Wang <weidongw@illinois.edu>

