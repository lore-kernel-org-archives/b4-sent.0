From: Moe Mahhouk <moe@flashbots.net>
Subject: [PATCH v4 0/2] virt: tdx-guest: Fix and speed up the wait for a
 Quote
Date: Wed, 25 Nov 2026 14:11:49 +0000
Message-Id: <20261125-tdx-guest-quote-poll-v4-0-d89f26854b88@flashbots.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKXsBmsC/4XNTQ6CMBQE4KuQrn2mP9CCK+9hXNDygBpCkRaCI
 dxdwI0xGpeTzHwzE4+9RU9O0Ux6HK23rl1DfIiIqfO2QrDFmgmnXDLKGYRigmpAH+A+uIDQuaY
 BWipdmiTLKNVknXY9lnba2cv1lf2gb2jCZm2N2vrg+sf+O7Kt9+diZMAgY1meqpRxNPpcNrmvt
 Qv+2GIg283I3yH+A+JAQSWxMBI1L4T8Bol3KP4BiRWSeSq0VlIJFn9Cy7I8AbEYblFgAQAA
X-Change-ID: 20261021-tdx-guest-quote-poll-0f7bfc59900b
To: Kiryl Shutsemau <kas@kernel.org>, 
 Rick Edgecombe <rick.p.edgecombe@intel.com>, 
 Dave Hansen <dave.hansen@linux.intel.com>, 
 Erdem Aktas <erdemaktas@google.com>, Tom Lendacky <thomas.lendacky@amd.com>, 
 Dan Williams <djbw@kernel.org>, 
 Kuppuswamy Sathyanarayanan <sathyanarayanan.kuppuswamy@linux.intel.com>, 
 Xiaoyao Li <xiaoyao.li@intel.com>
Cc: Jun Miao <jun.miao@intel.com>, x86@kernel.org, 
 linux-coco@lists.linux.dev, kvm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Moe Mahhouk <moe@flashbots.net>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795615914; l=2878;
 i=moe@flashbots.net; s=20261021; h=from:subject:message-id;
 bh=rqc80yhWsP3LWWLdVctDJ2+6rWedrVjJDW+t69zJnTU=;
 b=acqVLl+jCT3l8+VqkGMFlKvtMTzFpveSM0x23jDxqCPbhq7o2cbM01ORQjkjpNa3AjmR2aJJF
 SpkgTAREz+FB6mZAwAgXhcB7YWQP4XqTb0Y9D9iCUD1OmOrhXf1lWfy
X-Developer-Key: i=moe@flashbots.net; a=ed25519;
 pk=hJTKfjLno/YESrpxMIKDJk34GM+/8Tol+24XK2b4xf0=
X-Endpoint-Received: by B4 Relay for moe@flashbots.net/20261021 with auth_id=1259
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Getting a TDX Quote takes at least one second, because
wait_for_quote_completion() sleeps a full second before each status
check, while a local Quote Generation Service answers in a few
milliseconds. Patch 2 rechecks the status every 10 ms instead.

In v1, Kiryl noticed that the same loop gets a real timeout wrong.
Patch 1 fixes that on its own, so that it can be backported; patch 2
then replaces the loop.

The GHCI SetupEventNotifyInterrupt mechanism would avoid polling
altogether, but it relies on the VMM implementing that service. This
series keeps the existing polling model, which works with any VMM.

Jun Miao posted a patch for the same latency in September [1]. It polls
every 2 ms with read_poll_timeout() and lowers the timeout to 1 s. This
series keeps the 30 s timeout. Patch 1 is needed for released kernels
either way.

[1] https://lore.kernel.org/all/20260917102202.750895-1-jun.miao@intel.com/

Testing on mainline 7be4bc52fd9e in a TDX guest (KVM host v7.0, QEMU
11.1.2, TDX module 1.5.34, Intel QGS, guest HZ=250), through
configfs-tsm:
- Latency, 120 back-to-back Quotes: 1021-1024 ms each before (v3
  numbers, same setup), 14-20 ms (median 16 ms) with the series. At
  HZ=250, msleep_interruptible(10) sleeps 4 jiffies, 16 ms, and the
  first check right after the request almost never succeeds.
- Stress, 1000 back-to-back Quotes: none empty, 14-21 ms (median
  16 ms).
- Timeout, with a QGS socket that accepts and never answers: the read
  fails with -ETIMEDOUT after 30 s. Patch 1 is unchanged from v3, where
  the lowered-timeout test showed the fix.
- SIGTERM to a reader waiting on such a request: it exits within the
  same 10 ms tick of /proc/uptime.
- W=1 build of drivers/virt/coco/tdx-guest/ and checkpatch.pl --strict
  are clean.

The patches and this cover letter were written with an AI coding
assistant, Claude (Claude Code, model Claude Opus 5.5), which also ran
the tests.

---
Changes in v4:
- Patch 2: recheck every 10 ms instead of backing off from 1 to 100 ms
  (Rick). Title changed to "Poll Quote status every 10 ms"
- Patch 2: changelog says the first check comes before the first sleep
  (Xiaoyao)
- Patch 2: dropped Kiryl's and Sathyanarayanan's Reviewed-by, since the
  code changed
- Patch 1: collected Reviewed-by (Xiaoyao)
- Link to v3: https://patch.msgid.link/20261024-tdx-guest-quote-poll-v3-0-6a83bb767314@flashbots.net

---
Moe Mahhouk (2):
      virt: tdx-guest: Fix timeout detection in wait_for_quote_completion()
      virt: tdx-guest: Poll Quote status every 10 ms

 drivers/virt/coco/tdx-guest/tdx-guest.c | 16 ++++++++++------
 1 file changed, 10 insertions(+), 6 deletions(-)
---
base-commit: 7be4bc52fd9e0e55dc9a2e0232b89427d2c4b614
change-id: 20261021-tdx-guest-quote-poll-0f7bfc59900b

Best regards,
--  
Moe Mahhouk <moe@flashbots.net>

