From: Suyuan Wang <shyckless@gmail.com>
Subject: [PATCH v2 0/2] ALSA: firewire: Abort transactions on a bus reset
Date: Sun, 22 Nov 2026 13:46:28 +0000
Message-Id: <20261122-firewire-busreset-v2-0-e104d785c8a1@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADTyAmsC/yXMOw6DQAyE4asg16wUTB6IqyAKFmYTU5DIZhMkx
 N2zQDHFV8y/kkEFRnW2kuIrJu8pgfOM+lc3PeFkSCa+8L0omF0QxS/N+WgKw+weZRmq23ANnpn
 S76MIshzNpj1t0Y/o5z1E2/YHbag963UAAAA=
X-Change-ID: 20261122-firewire-busreset-733f85d4fb22
To: o-takashi@sakamocchi.jp, clemens@ladisch.de, tiwai@suse.com
Cc: stefanr@s5r6.in-berlin.de, linux-sound@vger.kernel.org, perex@perex.cz, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795355188; l=1200;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=gufGP1tFKoniF5n8WhFO5Du7+ThxLlL18YVM0EKtypY=;
 b=7SmKUf8vP0uv2Lau8K38m2KZhlQQBdMO64jgUAhyfIEz0oDg9RPZZ/f3qUvjQWBGac8BO6dXu
 ELQgDZr6fz/A9VSrPJOjTIL3SWNrBBB3NCat5dDiEx/FMnk9BnzkUtp
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

fcp_avc_transaction() and snd_efw_transaction_run() resend their
command after a bus reset but never move the transaction back to
STATE_PENDING, so both loops keep resending without a retry limit
until sending fails.

As Takashi suggested, v2 no longer resends: on a bus reset the
transaction is ended and -EAGAIN is returned, following the AV/C
general specification, which says that a target discards any
transaction in progress on a bus reset.

Found with a static analysis tool and checked by hand. Compile tested
only (x86_64, W=1); I don't have FireWire audio hardware.

Changes in v2:
- Abort the transaction and return -EAGAIN on a bus reset instead of
  rearming it and resending (Takashi).
- Drop ERROR_DELAY_MS (and <linux/delay.h> in fcp.c), now unused.

v1: https://lore.kernel.org/all/20261120-firewire-busreset-v1-0-8bb9079a2984@gmail.com/
---
Suyuan Wang (2):
      ALSA: firewire-lib: Abort the FCP transaction on a bus reset
      ALSA: fireworks: Abort the transaction on a bus reset

 sound/firewire/fcp.c                             | 5 ++---
 sound/firewire/fireworks/fireworks_transaction.c | 4 ++--
 2 files changed, 4 insertions(+), 5 deletions(-)

