From: Bryam Vargas <hexlabsecurity@proton.me>
Subject: [PATCH v3 0/2] Input: apple_z2 - bound device-reported packet
 length and finger count
Date: Mon, 15 Jun 2026 13:20:50 -0500
Message-Id: <20260615-b4-disp-05943ee1-v3-0-bbfe1b651613@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIJCMGoC/x3MSwqAIBRG4a3EHXfBHhq1lWhQ+lt3YqEQgbT3p
 OE3OCdTQhQkmqpMEbckOUNBV1dkjzXsYHHF1KrWKNNo3np2ki5Weuw7oOHRWW0tzKA8qGRXhJf
 nX87L+36pHeheYgAAAA==
To: Sasha Finkelstein <k@chaosmail.tech>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Neal Gompa <neal@gompa.dev>, asahi@lists.linux.dev, 
 Sven Peter <sven@kernel.org>, linux-input@vger.kernel.org, 
 Janne Grunau <j@jannau.net>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781547650; l=4223;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=LHjIQuxX3I0P97by+TixGf9E2OyDn7KeunIpzWewOQg=;
 b=og68OIf/C2guQ7Z1a94j9uP8UzdZEudHLdixjd+QyMCALrSGfUH4QQwWkRReRpGHaTIkiackj
 USnaBxfF97QAfNdBBE7BD2DJ81uBm7tZFo3HJrvgDESOzeZDNbgE66G
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Apple Z2 touch controller is across an SPI bus and its reports are not
trusted: a malicious, malfunctioning or counterfeit controller (or an
interposer on the bus) can put arbitrary values in the report header.  Two
such device-supplied fields are used as sizes without being bounded against
the fixed 4000-byte receive buffer, giving the device a heap out-of-bounds
write and a heap out-of-bounds read.  This series bounds both.

Patch 1 bounds the 16-bit packet length before the second SPI transfer
(spi_read() into the 4000-byte rx_buf) -- the OOB write.

Patch 2 bounds the device-reported finger count in apple_z2_parse_touches()
-- the OOB read that is then forwarded to userspace as input events.

The two are paired because, as Dmitry noted on v2 of patch 2, the finger
count alone is not enough: msg_len is itself derived from the device length,
so patch 1 is what makes the patch 2 bound meaningful.  Patch 1 was posted
standalone first and carries Sasha Finkelstein's Reviewed-by; it is unchanged
here.

This v3 series supersedes the two separate postings:
  - packet length (standalone): https://lore.kernel.org/all/20260613-b4-disp-b1926f1a-v1-1-3a277b7c0cfa@proton.me/
  - finger count v1:            https://lore.kernel.org/all/20260613-b4-disp-f0148c89-v1-1-868a48b2a187@proton.me/
  - finger count v2:            https://lore.kernel.org/all/20260613-b4-disp-4ebcbd68-v2-1-0161acfbd688@proton.me/

Changes since the v2 finger-count patch (Dmitry Torokhov review,
https://lore.kernel.org/all/ai8U0QiwpBH8qNS3@google.com/):
- Patch 2: instead of clamping the finger count to what the packet holds
  (v2 used min_t and reported the fingers that fit), drop the whole packet
  when the device claims more fingers than it can hold, with a
  dev_warn_ratelimited(), per Dmitry's "I'd drop such packet" suggestion.
  A legitimate zero-finger ("all lifted") report (nfingers == 0) is still
  passed through to input_mt_sync_frame()/input_sync(), so lifting all
  fingers is not lost.  (Dropped Joshua Peisach's v2 Reviewed-by, as the
  fix shape changed materially from clamp to drop.)
- Patch 2 bound uses the multiplication form
  (msg_len < FINGERS_OFFSET + nfingers * sizeof(*fingers)) rather than a
  (msg_len - FINGERS_OFFSET) subtraction, so there is no unsigned underflow
  when msg_len < FINGERS_OFFSET (which would otherwise re-open the read).
- Patch 1 folded into the series unchanged (Reviewed-by Sasha Finkelstein).

Note on patch 1 (Sasha Finkelstein, on the standalone thread): rejecting an
over-long packet desyncs the SPI datastream and the device then needs a reset
before it operates again.  That is the intended outcome for a controller that
is already misbehaving or hostile -- a recoverable desync is preferable to a
~61 KiB heap overflow -- so the reject is kept.

Verification (in-kernel KASAN, CONFIG_KASAN=y kasan.fault=panic, plus userspace
ASan models of the exact parse arithmetic on x86_64 and i386):
  Patch 1 (packet length): reported length -> pkt_len 65540:
    Arm A (no patch): KASAN slab-out-of-bounds / ASan heap-buffer-overflow WRITE,
      both ABIs.
    Arm B (patch): rejected, clean.   Arm C (benign): clean.
  Patch 2 (finger count, drop shape): nfingers 255 in a short packet (msg_len 19):
    Arm A (no patch): BUG: KASAN: slab-out-of-bounds, Read of size 2, 1 byte to
      the right of the allocated 4000-byte region (cache kmalloc-4k) -> panic;
      ASan heap-buffer-overflow READ, both ABIs.
    Arm B (patch): packet dropped, zero reads, clean, not synced.
    Arm C (benign 3 fingers, msg_len 114): parsed in-bounds, clean, synced.
    Arm D (zero-finger all-lifted, nfingers 0, msg_len 19): clean, synced.
Reproducers and full logs available on request.

---
Bryam Vargas (2):
      Input: apple_z2 - bound the device-reported packet length
      Input: apple_z2 - bound the device-reported finger count

 drivers/input/touchscreen/apple_z2.c | 16 +++++++++++++++-
 1 file changed, 15 insertions(+), 1 deletion(-)
---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260615-b4-disp-05943ee1-9dc5cce670fe

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

