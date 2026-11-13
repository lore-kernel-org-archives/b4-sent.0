From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Subject: [PATCH RFC wireless-next 0/2] wifi: wl18xx: Stop querying the
 firmware statistics
Date: Fri, 13 Nov 2026 20:14:19 +0100
Message-Id: <20261113-upstream-wl18xx-fw-stats-v1-0-cbdf50739185@tsv-stahl-riesa.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWNTQ6CMBCFr0Jm7SSUBYhbEw/glrgo7VTHYCWdY
 psQ7m7Rt/te3s8KQoFJ4FStEOjDwm9fQB0qMA/t74RsC0NTN60qwmWWGEi/ME3qmDO6hBJ1FDR
 dbftWW+tMD6U+B3Kcf9MDXC/n3UscaCIR9JQj3P4pWcYnmbi/wLZ9AYIYETOSAAAA
X-Change-ID: 20261111-upstream-wl18xx-fw-stats-c70d96addfc9
To: linux-wireless@vger.kernel.org
Cc: Johannes Berg <johannes@sipsolutions.net>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, linux-kernel@vger.kernel.org, 
 Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794597277; l=3601;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=xIHoochWWNIF1OBob5awdmieWYZJ3MmNdz4ox+BKRs8=;
 b=BmDcxnz+qaJUpjLNVd8On1QPe2mIV1DXo7LzCwM1yRoUmMe5yxROT9sVe8G970/EbTZszzu5O
 C5mIKHRaG3LDMC4ogmvhz8WI2xSPKaspkryZ/IbnNI/1zGFDcA5nYV3
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On a WL1801 (Tegra Note 7, firmware 8.9.0.0.83) the answer to
ACX_STATISTICS overwrites both event mailboxes. struct
wl18xx_acx_statistics is 1100 bytes, the command mailbox 740 bytes,
and the two 180-byte event mailboxes sit right behind it
(0xb007f8, +740, +920 on this chip). An event that is waiting in a
mailbox while the statistics are read is then handled with statistics
counters as its vector and data. I ran into it as a NULL pointer
dereference in wlcore_event_rssi_trigger() with a P2P device; the fix
for that crash went out separately earlier today [1].

What I measured, with a test kernel that logs the mailbox addresses and
can change the requested length at run time:

- idle, chip memory read through debugfs "mem" before and after one
  query: the pipeline counters (bytes 952-1000 of the statistics) show
  up in event mailbox B after every query, also when only 740 bytes are
  requested. The firmware ignores the requested length.
- 600 s iperf3 upload with the statistics read once a second: 50 bogus
  RSSI trigger events with 1100 bytes, 24 with 740 bytes, all from
  mailbox B and all with statistics content. Without the statistics
  reads: none.

So the only fix I see on the host side is not to send ACX_STATISTICS
on wl18xx at all, which is what this series does. Patch 1 lets wlcore
run without firmware statistics, patch 2 drops them from wl18xx.

Why RFC:

- It removes the wl18xx fw_stats debugfs files. If someone knows a
  firmware setting or version where the command mailbox is big enough,
  or another way to get the statistics, I would rather do that.
- I kept the statistics structures in wl18xx/acx.h as documentation of
  the firmware interface. I can drop them as well.
- Should patch 2 go to stable? It fixes corrupted events, but only for
  people who read the debugfs statistics.

Tested on the same Tegra Note 7 with v7.3 plus these two patches (the
touched files are the same in v7.3 and wireless-next): wl18xx/fw_stats,
clear_fw_stats and fw_stats_raw are gone, the other debugfs files are
still there; unloading and reloading wl18xx works and the station
reassociates. The same 600 s iperf3 upload, with the monitoring script
still trying to read the statistics once a second, ran at 46.7 Mbit/s
with no RSSI trigger event, no oops, no recovery and 0 failed frames.
Build-tested with W=1 for arm (gcc, clang) and arm64 (clang).

[1] https://lore.kernel.org/r/20261113-upstream-wlcore-p2p-rssi-v1-1-754bd625daca@tsv-stahl-riesa.de

Tool use (see Documentation/process/generated-content.rst): these
patches, the changelogs and this letter were prepared with an LLM
coding assistant (Claude Code). It worked out the mailbox layout from
the driver source and my logs, wrote the test tooling, the changes and
the texts from my measurements and instructions. I reviewed the
changes and ran the tests on the device.

---
Patrick Fischer (2):
      wifi: wlcore: Allow lower drivers without firmware statistics
      wifi: wl18xx: Stop querying the firmware statistics

 drivers/net/wireless/ti/wl18xx/acx.c     |  24 ---
 drivers/net/wireless/ti/wl18xx/acx.h     |   5 -
 drivers/net/wireless/ti/wl18xx/debugfs.c | 333 +------------------------------
 drivers/net/wireless/ti/wl18xx/main.c    |   1 -
 drivers/net/wireless/ti/wlcore/debugfs.c |  18 +-
 5 files changed, 14 insertions(+), 367 deletions(-)
---
base-commit: 5dbf2415ca9821a611d09308e3b29d2c37e7cd77
change-id: 20261111-upstream-wl18xx-fw-stats-c70d96addfc9

Best regards,
--  
Patrick Fischer <admin@tsv-stahl-riesa.de>

