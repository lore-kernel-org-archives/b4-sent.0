From: Samuel Wheeler <swheel33@gmail.com>
Subject: [PATCH 0/2] platform/x86: hp-wmi: HP OmniBook Ultra 14-kd0xxx
 (8EB4) fixes
Date: Wed, 11 Nov 2026 21:54:25 -0500
Message-Id: <20261111-omnibook-8eb4-v1-0-3127f45cc338@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ5AMBCF4avIrDVREcpVxKJlMEQrLSJpenfF2
 32L93twaAkdNIkHixc5MjqCpwn0s9QTMhqiIc/ykscxs2lSxqxMoCpYJUTNMasKyUeIn93iSPf
 Xa7vf7lQL9scbgRAeA9uN6HEAAAA=
X-Change-ID: 20261111-omnibook-8eb4-78891e074a1f
To: Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Shang En Sim <sim@shangen.org>, Samuel Wheeler <swheel33@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794452066; l=1572;
 i=swheel33@gmail.com; s=20261112; h=from:subject:message-id;
 bh=Y4xTG+8RxmiuTXb8mMsG5seOcwWC4EfIZOX+4VckSBk=;
 b=HwgbCzhMGJBDO+FlTWk1qVHPMAeJTtMjNLT0MBjnDZpGXIPHT5YyytGhU+TdHhBb0PwdJHMrX
 ex1CXT+aqiWAJH/GNnnmm1cKE/uGnTDnhX51ZpSmkLjDV4f6sI3xOge
X-Developer-Key: i=swheel33@gmail.com; a=ed25519;
 pk=cokeT6B31W84o+Gc4wuP2okLF8wShbbGQ7pb5h5JPXg=
X-Endpoint-Received: by B4 Relay for swheel33@gmail.com/20261112 with auth_id=1494
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two small hp-wmi changes for the HP OmniBook Ultra Laptop 14-kd0xxx
(board 8EB4, BIOS F.06, Panther Lake):

1. The thermal profile query returns status flags in its upper bytes,
   so reading the platform profile always fails with -EINVAL. Use only
   the low byte.
2. The laptop has the same battery charge mode interface as the
   Spectre 8C15/8C17. Add it to the charge_behaviour quirk list.

Both were tested on the laptop with the same code changes applied to the
hp-wmi of a 7.2.15-based distribution kernel. The patches themselves are
against pdx86 for-next and build there with W=1 without warnings;
checkpatch --strict is clean.

Patch 2 touches the same quirk table as the pending "platform/x86:
hp-wmi: Add OmniBook 7 14-fr0xxx to charge_behaviour quirks"
(https://lore.kernel.org/r/20261102155409.3061761-1-taranarmo@gmail.com),
so whichever is applied second will need a trivial rebase.

The ACPI analysis, the changes and these descriptions were prepared with
an AI coding assistant (Claude, by Anthropic), as described in each
patch. I reviewed them and ran the tests myself.

---
Samuel Wheeler (2):
      platform/x86: hp-wmi: Only use the low byte of the thermal profile
      platform/x86: hp-wmi: Add charge_behaviour quirk for OmniBook Ultra 14

 drivers/platform/x86/hp/hp-wmi.c | 18 +++++++++++++++++-
 1 file changed, 17 insertions(+), 1 deletion(-)
---
base-commit: a514d723595bd8e5ce926a7fea148ceb3c26915c
change-id: 20261111-omnibook-8eb4-78891e074a1f

Best regards,
--  
Samuel Wheeler <swheel33@gmail.com>

