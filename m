From: Amber Gao <ambergao@apptronik.com>
Date: Wed, 30 Sep 2026 12:08:04 -0500
Subject: [PATCH] nvme-pci: avoid the deepest sleep state on Transcend
 MTE672A SSDs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-nvme-transcend-mte672a-v1-1-a025655acd9a@apptronik.com>
X-B4-Tracking: v=1; b=H4sIAPNBvWoC/yXMQQrCMBBG4auUWRsYI43Wq0gXafqrI3SUTCxC6
 d1Ndfkt3lvIkAVG52ahjFlMnlqx3zWU7lFvcDJWk2cfuDuw03mCKzmqJejopoJw9NF1fBqA4ME
 tqMavjKt8fuNL/7e9hwdS2W60rl+KotoKegAAAA==
X-Change-ID: 20260930-nvme-transcend-mte672a-908bee62e05e
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>
Cc: linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Amber Gao <ambergao@apptronik.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790788102; l=3749;
 i=ambergao@apptronik.com; s=20260930; h=from:subject:message-id;
 bh=LZs7S1NoTlL/SdsSCVJp0FZHzu9IOgUyTgnCjquUuPo=;
 b=ldUU+zp98Bnmxv6XGHeCZ+TN6wpx6X0RqytwKBmv+ogcdbFFyOcd4ULn8a8gNNhyoIvP17jFh
 Uu5JkfMGhBUBlKBmcn4Qu+9APdN8gUzI1HFJhtwj2L1pch8yeMDBkow
X-Developer-Key: i=ambergao@apptronik.com; a=ed25519;
 pk=0/6wixcQKuRsYBFf5+L/ltWe5KwC7hPcuyFl2nDaG+Q=
X-Endpoint-Received: by B4 Relay for ambergao@apptronik.com/20260930 with auth_id=1087
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Transcend MTE672A (PCI ID 1d79:2263, Silicon Motion SM2263XT
controller) stops responding after it has been idle long enough to
enter its deepest APST power state. This reproduces without any
workload: on every boot observed, a write issued about 16 s after the
kernel starts never completes, and about 45 s in the kernel reports

  nvme nvme0: I/O tag 191 (30bf) opcode 0x1 (I/O Cmd) QID 2 timeout,
              aborting req_op:WRITE(1) size:131072
  nvme nvme0: I/O tag 191 (30bf) opcode 0x1 (I/O Cmd) QID 2 timeout,
              reset controller
  nvme nvme0: Abort status: 0x371

The abort is not completed either; the drive only comes back once the
controller has been reset. If the hang occurs while many I/Os are
queued, that reset can time out as well; the driver then gives up and
removes the NVMe device from the system. On the affected system this
has happened twice, both times during a firmware update, leaving the
ext4 root filesystem unusable.

Booting with nvme_core.default_ps_max_latency_us=10000, which excludes
only PS4 (the deepest state), makes the boot-time timeout disappear. With
NVME_QUIRK_NO_DEEPEST_PS applied instead, on a stock command line, no
timeout has been seen on any boot since, including six multi-GB A/B
firmware updates.

The same controller is already quirked for this under other vendors'
IDs: Kingston A2000 (2646:2263), Kingston SKC2000 (2646:2262) and the
Silicon Motion generic IDs 126f:2262 and 126f:1001.

Tested on a 6.8-based vendor kernel; the patch is against mainline,
where the surrounding code is unchanged, but has not been retested
there.

  vid       : 0x1d79
  ssvid     : 0x1d79
  mn        : TS2TMTE672AI-VS1
  fr        : X0122B3
  [...]
  ps    0 : mp:6.00W operational enlat:0 exlat:0 rrt:0 rrl:0
            rwt:0 rwl:0 idle_power:- active_power:-
  ps    1 : mp:3.00W operational enlat:0 exlat:0 rrt:1 rrl:1
            rwt:1 rwl:1 idle_power:- active_power:-
  ps    2 : mp:1.50W operational enlat:0 exlat:0 rrt:2 rrl:2
            rwt:2 rwl:2 idle_power:- active_power:-
  ps    3 : mp:0.0450W non-operational enlat:3000 exlat:3000 rrt:3 rrl:3
            rwt:3 rwl:3 idle_power:- active_power:-
  ps    4 : mp:0.0040W non-operational enlat:25000 exlat:25000 rrt:4 rrl:4
            rwt:4 rwl:4 idle_power:- active_power:-

Assisted-by: LLM
Signed-off-by: Amber Gao <ambergao@apptronik.com>
---
Two-line device-ID addition. The affected drive hangs in PS4 shortly after boot;
NVME_QUIRK_NO_DEEPEST_PS is the same quirk already applied to the Kingston A2000 and
SKC2000 and the Silicon Motion generic IDs, which share this controller.
Tested on a 6.8-based vendor kernel; not retested on mainline, where the surrounding
table is unchanged.
---
 drivers/nvme/host/pci.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/nvme/host/pci.c b/drivers/nvme/host/pci.c
index 5440cf18b..1a3353782 100644
--- a/drivers/nvme/host/pci.c
+++ b/drivers/nvme/host/pci.c
@@ -4221,6 +4221,8 @@ static const struct pci_device_id nvme_id_table[] = {
 		.driver_data = NVME_QUIRK_NO_DEEPEST_PS, },
 	{ PCI_DEVICE(0x2646, 0x2263),   /* KINGSTON A2000 NVMe SSD  */
 		.driver_data = NVME_QUIRK_NO_DEEPEST_PS, },
+	{ PCI_DEVICE(0x1d79, 0x2263),   /* Transcend MTE672A */
+		.driver_data = NVME_QUIRK_NO_DEEPEST_PS, },
 	{ PCI_DEVICE(0x2646, 0x5013),   /* Kingston KC3000, Kingston FURY Renegade */
 		.driver_data = NVME_QUIRK_NO_SECONDARY_TEMP_THRESH, },
 	{ PCI_DEVICE(0x2646, 0x5018),   /* KINGSTON OM8SFP4xxxxP OS21012 NVMe SSD */

---
base-commit: 551c722f40809618230001baccf219193e22fc5a
change-id: 20260930-nvme-transcend-mte672a-908bee62e05e

Best regards,
--  
Amber Gao <ambergao@apptronik.com>

