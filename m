From: Suyuan Wang <shyckless@gmail.com>
Subject: [PATCH 0/2] ALSA: firewire: Don't loop forever after a bus reset
Date: Fri, 20 Nov 2026 05:38:04 +0000
Message-Id: <20261120-firewire-busreset-v1-0-8bb9079a2984@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAL3c/2oC/yXMwQ6CMBCE4Vche6YJrSCBVyEe2jLoegCzW9SE8
 O5WOMzhO8y/kUIYSn2xkeDNysucYcuC4sPPdxges8lV7mqtq8zEgk+eCasKFMn4gC62Pl7qpqX
 8ewkm/h7N4XZa1/BETP8Q7fsP5EADmXUAAAA=
X-Change-ID: 20261120-firewire-busreset-abe9c7ac3457
To: clemens@ladisch.de, o-takashi@sakamocchi.jp, tiwai@suse.com
Cc: stefanr@s5r6.in-berlin.de, linux-sound@vger.kernel.org, perex@perex.cz, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795153085; l=868;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=kqdcAldR5ptexRkJpjKE62fPaO7t4IL0FVM36AEWNY8=;
 b=0XCSaYs+uCfOdVTIuNBd/1AOewM+siiNqG9KH3o/azct6PqpT7GNP5qfzbRKpk3fp155A+ZHW
 AMA0fZzRGoLBIZszI6zTgvwrXfkxZa8PsAXJSBhl8CWvh3VOVbog60k
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

fcp_avc_transaction() and snd_efw_transaction_run() resend their
command after a bus reset but never move the transaction back to
STATE_PENDING. The response to the resent command is then ignored and
the wait returns immediately, so both loops keep resending the command
after each ERROR_DELAY_MS pause, without a retry limit, until sending
fails.

Each patch sets the state back to STATE_PENDING before resending.

Found with a static analysis tool and checked by hand. Compile tested
only (x86_64, W=1); I don't have FireWire audio hardware.

---
Suyuan Wang (2):
      ALSA: firewire-lib: Rearm the FCP transaction after a bus reset
      ALSA: fireworks: Rearm the transaction after a bus reset

 sound/firewire/fcp.c                             | 2 ++
 sound/firewire/fireworks/fireworks_transaction.c | 2 ++
 2 files changed, 4 insertions(+)

