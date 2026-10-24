From: Moe Mahhouk <moe@flashbots.net>
Subject: [PATCH v3 0/2] virt: tdx-guest: Fix and speed up the wait for a
 Quote
Date: Sat, 24 Oct 2026 19:17:11 +0000
Message-Id: <20261024-tdx-guest-quote-poll-v3-0-6a83bb767314@flashbots.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADcE3WoC/4WNyw6CMBQFf4V07TVtkUdd+R/GBS23UEMotoVgC
 P8uxY0xMS4nOWdmIR6dQU/OyUIcTsYb22+QHhKi2qpvEEy9MeGU54xyBqGeoRnRB3iMNiAMtuu
 A6kJqlQlBqSTbdXCozbxrr7c3+1HeUYXoiovW+GDdc+9OLO7+JCYGDAQTVVmUjKOSF91VvpU2+
 GOPgcTMxD9F/IeIA4UiO6UqR8nrNP8Wrev6Am58KRIXAQAA
X-Change-ID: 20261021-tdx-guest-quote-poll-0f7bfc59900b
To: Kiryl Shutsemau <kas@kernel.org>, 
 Rick Edgecombe <rick.p.edgecombe@intel.com>, 
 Dave Hansen <dave.hansen@linux.intel.com>, 
 Erdem Aktas <erdemaktas@google.com>, Tom Lendacky <thomas.lendacky@amd.com>, 
 Dan Williams <djbw@kernel.org>, 
 Kuppuswamy Sathyanarayanan <sathyanarayanan.kuppuswamy@linux.intel.com>
Cc: Jun Miao <jun.miao@intel.com>, x86@kernel.org, 
 linux-coco@lists.linux.dev, kvm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Moe Mahhouk <moe@flashbots.net>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792869441; l=3495;
 i=moe@flashbots.net; s=20261021; h=from:subject:message-id;
 bh=IVZw3pNNxHAWxQnRDT0sxY97XzAFqgNzzTc6OB604NA=;
 b=svVqwMwL4TZHeYuxIYWsQfzBZK5iWYLkS6AsuKDTLZAbTWAoChWFT3RbN/TltKSXFlbSU27H5
 iOn6x5KEkWIDm4tISI8HdCkcFnCyvYI5MZtxsb8LRW6OV97rqxg5qxB
X-Developer-Key: i=moe@flashbots.net; a=ed25519;
 pk=hJTKfjLno/YESrpxMIKDJk34GM+/8Tol+24XK2b4xf0=
X-Endpoint-Received: by B4 Relay for moe@flashbots.net/20261021 with auth_id=1259
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Getting a TDX Quote takes at least one second, because
wait_for_quote_completion() sleeps a full second before each status
check, while a local Quote Generation Service answers in a few
milliseconds. Patch 2 polls with an exponential backoff instead.

In v1, Kiryl noticed that the same loop gets a real timeout wrong.
Patch 1 fixes that on its own, so that it can be backported; patch 2
then replaces the loop.

The GHCI SetupEventNotifyInterrupt mechanism would avoid polling
altogether, but it relies on the VMM implementing that service. This
series keeps the existing polling model, which works with any VMM.

Jun Miao posted a patch for the same latency in September [1]. It polls
every 2 ms with read_poll_timeout() and lowers the timeout to 1 s, and
has had no review so far. This series keeps the 30 s timeout and backs
off instead of polling at a fixed rate. Patch 1 is needed for released
kernels either way.

[1] https://lore.kernel.org/all/20260917102202.750895-1-jun.miao@intel.com/

Testing on mainline a804c5742 in a TDX guest (KVM host v7.0, QEMU
11.1.2, TDX module 1.5.34, Intel QGS, guest HZ=250), through
configfs-tsm:
- Latency, 40 back-to-back Quotes: 1021-1024 ms each before, 6-12 ms
  (median 8 ms) with the series. msleep_interruptible() rounds up to
  jiffies; v1's usleep_range() got 2-3 ms.
- Timeout, with a QGS socket that accepts and never answers. QEMU fails
  such a request itself after 30 s, so for this test getquote_timeout
  was lowered to 5 s: without patch 1 the request fails with -EIO and
  no message, with it -ETIMEDOUT and "GetQuote request timedout". With
  the default 30 s and the old loop, QEMU's error lands in the last
  sleep and is reported as -ETIMEDOUT, the second case in patch 1.
- SIGTERM to a reader waiting on such a request: it exits within one
  10 ms tick of /proc/uptime with the series, as before it; with v1 it
  took 110 ms.
- W=1 build of drivers/virt/coco/tdx-guest/ and checkpatch.pl --strict
  are clean.

The patches and this cover letter were written with an AI coding
assistant, Claude (Claude Code, model Claude Opus 5.5), which also ran
the tests.

---
Changes in v3:
- Patch 1: Cc stable (Sathyanarayanan)
- Patch 2: say in the comment and the changelog that
  msleep_interruptible() rounds up to whole jiffies, so at HZ=250 the
  first steps are one tick each (Sathyanarayanan). No code change.
- Collected Reviewed-by tags (Kiryl, Sathyanarayanan)
- Link to v2: https://patch.msgid.link/20261022-tdx-guest-quote-poll-v2-0-7543c6eb2d36@flashbots.net

Changes in v2:
- New patch 1: fix the timeout detection on its own, for backporting
  (Kiryl)
- Patch 2: msleep_interruptible() with a 1-100 ms backoff instead of
  usleep_range(), which sleeps uninterruptibly (Kiryl)
- Patch 2: secs_to_jiffies() for the deadline
- Test and tool notes moved from the changelog to this cover letter
  (Kiryl)
- Link to v1: https://patch.msgid.link/20261021-tdx-guest-quote-poll-v1-1-919a87812ecb@flashbots.net

---
Moe Mahhouk (2):
      virt: tdx-guest: Fix timeout detection in wait_for_quote_completion()
      virt: tdx-guest: Poll Quote status with exponential backoff

 drivers/virt/coco/tdx-guest/tdx-guest.c | 20 ++++++++++++++------
 1 file changed, 14 insertions(+), 6 deletions(-)
---
base-commit: 7be4bc52fd9e0e55dc9a2e0232b89427d2c4b614
change-id: 20261021-tdx-guest-quote-poll-0f7bfc59900b

Best regards,
--  
Moe Mahhouk <moe@flashbots.net>

