From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/2] sunxi: dram: H616 DDR3 init delays, retry transient
 training failures
Date: Tue, 10 Nov 2026 06:20:09 +0000
Message-Id: <20261110-h616-dram-retry-v1-0-ccaa6d7a6ef1@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrDuQEYzaq5QuopnoCNoy0VIR7
 27U5Vv8v0FkFY7wzDZQ/kmUz5RAjwza3k0do/hkyE1uichgb8miVzei8qwrVsFVvqhDaYyHVH2
 Vg/yv4+t9Oy7NwO18bmDfDx8fKAlzAAAA
X-Change-ID: 20261110-h616-dram-retry-8fa8d59f700d
To: u-boot@lists.u-boot-project.org
Cc: Andre Przywara <andre.przywara@arm.com>, Tom Rini <trini@konsulko.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Arun Iyengar <aiyengar1990@gmail.com>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794291609; l=2503;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=QbVBUcLtTolOgmS2ZIiW8adEurzeeDNLLJm66LF81es=;
 b=fEO6n6g9+e3XT9y7P9BiN4kHKrOWJenKom4Kc+jawwTQ8CgOBHZBp8c4mSwkyPTKuSaJFxkYO
 twHItDBp+rkBknpi9rOm7o9N9PE8yIb9a+bnExCvlySYgR1XcDEe6+F
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On an OrangePi Zero2 (H616, 1 GiB DDR3, 720 MHz) a hardware watchdog
reset taken while the DRAM was busy (a system thrashing under OOM, or
stress-ng loading the memory at about 75 C) sometimes leaves the DRAM
untrainable for up to about three seconds. The SPL then either panics
with "This DRAM setup is currently not supported." or, after the reset
that the panic causes, settles for a 16-bit bus and boots with 512 MiB
until the next reboot. Idle reboots, cold boots and idle watchdog
resets never showed it.

Patch 1 makes the H616 DDR3 init use the JEDEC RESET#/CKE delays. It is
a compliance fix; on its own it did not measurably change the failure
rate.

Patch 2 makes the rank/width detection keep the best combination that
trained in any pass, retries with an exponential backoff (12 passes,
about 2.5 s) while nothing trains, and retries the size probe and the
final init the same way. A board that trains first time pays for a
couple of quickly failing attempts; a retry is reported in the DRAM line
of the SPL. The final init helper is shared, so H6 and A523 get the
retry for that step too.

Testing on the OrangePi Zero2 is in the commit messages: with both
patches, 60 hot watchdog resets came up with 1 GiB (21 of them needed a
retry, the longest 1.7 s), and the board has since done 316 logged boots
with 1 GiB and no retry. Build-tested for orangepi_zero2, orangepi_3
(H6) and orangepi_4a (A523) with no new warnings; H6 and A523 are not
run-tested.

These patches were developed with Claude (Anthropic) as a
coding assistant: it investigated the problems, wrote the code and the
commit messages. I reviewed them, and they were tested on an Orange Pi
Zero2 (H616) as described above.

---
Arun Iyengar (2):
      sunxi: H616: dram: DDR3: use the JEDEC reset and CKE init delays
      sunxi: dram: retry transient DRAM training failures

 arch/arm/include/asm/arch-sunxi/dram_dw_helpers.h |   2 +
 arch/arm/mach-sunxi/dram_dw_helpers.c             | 167 +++++++++++++++++-----
 arch/arm/mach-sunxi/dram_sun50i_h6.c              |   2 +-
 arch/arm/mach-sunxi/dram_sun50i_h616.c            |   2 +-
 arch/arm/mach-sunxi/dram_sun55i_a523.c            |   2 +-
 arch/arm/mach-sunxi/dram_timings/h616_ddr3_1333.c |  11 +-
 6 files changed, 147 insertions(+), 39 deletions(-)
---
base-commit: ecdcf9e365df6249a57cd8cc946e7026804ff4ae
change-id: 20261110-h616-dram-retry-8fa8d59f700d

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

