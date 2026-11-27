From: Dickson Wu <dickson.wu@certik.com>
Subject: [PATCH bluetooth-next 0/2] Bluetooth: SMP: keep pairing keys
 private until pairing completes
Date: Fri, 27 Nov 2026 21:19:16 +0000
Message-Id: <20261127-bt-smp-n-v1-0-e123c04c15be@certik.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANTzCWsC/yWMwQrDIBBEfyXsuQtRaJT+SulBzbZa0k1wTQiE/
 Hu1Pb6ZeXOAUE4kcOsOyLQlSTNXUJcOQnT8IkxjZdC9HpTSBn1B+SzIaG0fBqvd1RgLdb5keqb
 9d3UHP61U5rlEZNoLPP69rP5NobS/ZngnhD47DrFFQjxWZ8KWw3l+ASo8Q0qcAAAA
X-Change-ID: 20261127-bt-smp-n-880c682a5778
To: linux-bluetooth@vger.kernel.org
Cc: Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Johan Hedberg <johan.hedberg@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795814356; l=2169;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=02FxCK96bQDMry6ZNVOOlcvZDo/u/NT5xXIMJ9SA1Nw=;
 b=W8VmTdtMOSzDAPbmn8hZ/MfaxJlHMqc1+jMG9uVnn8vfQfw2YjN2bCpHkIjY8xCFa0h2dUQLm
 SWujmAOICs3CJHH8mCYck3kjEWgC2AwNM1mgOCsw+3/M3o5Yf2VnL88
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

An incomplete pairing can share an IRK registry entry with another pairing,
then free it during teardown. CTKD can replace an LTK retained by an
incomplete LE pairing and free it from the BR/EDR pairing context. A second
LE link can retype a retained LTK as an STK that the LTK Request handler
frees. The series keeps received or generated keys private to each pairing
context and publishes registry updates only after pairing completes.

Tested under UML with KASAN and a VHCI controller, no radio, on
bluetooth-next f57f78086ab5 and mainline 9437ee8b6cf6 (patch 2 needed
context adjustment for mainline). Stock and explicitly reverted kernels
hit slab-use-after-free in list_del_rcu() from smp_chan_destroy() for all
three cases (shared IRK, CTKD LTK, second-link STK). With the series all
three pass, and so do normal LE LTK storage, CTKD derivation and storage,
LTK and IRK replacement on re-pairing, and RPA resolution. Patch 1 builds
on its own and net/bluetooth/ is W=1 clean. A reproducer is available if
it helps.

These need a peer whose Just Works pairing requests get accepted, so a
default bluetoothd with an agent does not accept them silently.

Patch 1 is near "Bluetooth: SMP: Use pairing data for IRK notifications"
on the list, which fixes a different Load IRKs race in the same IRK
notification code, so the two may need rebasing against each other.

This was found and the fix prepared with AI coding tools (OpenAI Codex
agents, with review by Claude). I went over the analysis and the patch
before signing off.

---
Dickson Wu (2):
      Bluetooth: SMP: Defer IRK updates until pairing completes
      Bluetooth: SMP: Keep pending LTKs private

 include/net/bluetooth/hci_core.h |  5 +++
 net/bluetooth/hci_core.c         | 76 +++++++++++++++++++++++++++++++---------
 net/bluetooth/hci_event.c        | 16 ++++++---
 net/bluetooth/smp.c              | 73 +++++++++++++++++++++++++-------------
 4 files changed, 125 insertions(+), 45 deletions(-)
---
base-commit: f57f78086ab54f3b3122fbaeba2c842ba7bb6d00
change-id: 20261127-bt-smp-n-880c682a5778

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

