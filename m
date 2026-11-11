From: Alban Munari <alban.kernel@gmail.com>
Date: Wed, 11 Nov 2026 20:24:48 +0000
Subject: [PATCH] ALSA: hda: cs35l41: Fix hibernation deadlock with the
 firmware reload
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-cs35l41-freezable-fw-load-v1-1-ebcaf549b2f7@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMyw6CMBCF4Vchs3YSW8DbqxgW7XSqYxowHUED4
 d2penbf4vwLKGdhhUu1QOZJVIa+wOwqoLvrb4wSisHu7cGUIWndpsZgzMyz84kxvjENLiCd28Z
 SPPngjlD+z8xRPr/2tftbR/9gen2DsK4bNq2gkn0AAAA=
X-Change-ID: 20261111-cs35l41-freezable-fw-load-c9542cf8bda7
To: David Rhodes <david.rhodes@cirrus.com>, 
 Richard Fitzgerald <rf@opensource.cirrus.com>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Stefan Binding <sbinding@opensource.cirrus.com>
Cc: linux-sound@vger.kernel.org, patches@opensource.cirrus.com, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Alban Munari <alban.kernel@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794428707; l=3724;
 i=alban.kernel@gmail.com; s=hephaestus; h=from:subject:message-id;
 bh=IXzrGoSena48kpecVx+KFjQckzRH8kQoM0LZy+B5cYI=;
 b=E5phtmV4Gn6aVvUFA1LPzfdPdrfTyxdtNb1tewiRSAM7gAMZoN6x9nLViSuPmIycTBlW6fX24
 CbOSxRcbkjoDPIc+y3A/0AyHUAkvqEX9YXllN36Fv3zd/1vHTr0wrow
X-Developer-Key: i=alban.kernel@gmail.com; a=ed25519;
 pk=E4gTLxHRk8yuKicoDcjhUfRHnlctgbnlV9dmOwM5338=
X-Endpoint-Received: by B4 Relay for alban.kernel@gmail.com/hephaestus with auth_id=1455
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cs35l41_system_resume() is also the .thaw and .restore callback, and it
schedules fw_load_work on system_wq. During hibernation, .thaw runs
right after the snapshot is created, while tasks and freezable
workqueues stay frozen until the system powers off. The work calls
request_firmware() with fw_mutex held. When the firmware files are not
cached, the lookup waits for filesystem I/O whose completion runs on a
freezable workqueue (btrfs completes reads on its endio workqueues,
which are WQ_FREEZABLE), so it never returns. The next step of
hibernation then waits for fw_mutex in cs35l41_system_suspend_prep(),
and the machine stays on after the image has been written.

Blocked tasks on an ASUS ROG Strix G17 (G713PI) after the image was
saved, from SysRq-W:

  task:systemd-sleep state:D
   __mutex_lock.constprop.0
   cs35l41_system_suspend_prep [snd_hda_scodec_cs35l41]
   dpm_prepare
   dpm_suspend_start
   hibernation_platform_enter
   hibernate.cold

  task:kworker/15:2 state:D
  Workqueue: events cs35l41_fw_load_work [snd_hda_scodec_cs35l41]
   bit_wait_io
   read_extent_buffer_pages [btrfs]
   btrfs_lookup [btrfs]
   path_openat
   kernel_read_file_from_path_initns
   fw_get_filesystem_firmware
   _request_firmware
   cs35l41_request_firmware_file [snd_hda_scodec_cs35l41]
   cs35l41_smart_amp [snd_hda_scodec_cs35l41]
   cs35l41_fw_load_work [snd_hda_scodec_cs35l41]

Queue the work on system_freezable_wq. After .thaw it then stays
pending until the system powers off, and on resume it runs once tasks
are thawed and the firmware files can be read.

Fixes: 88672826e2a4 ("ALSA: hda: cs35l41: Support System Suspend")
Cc: stable@vger.kernel.org
Signed-off-by: Alban Munari <alban.kernel@gmail.com>
---
Testing: ASUS ROG Strix G17 (G713PI), two CS35L41 amplifiers (CSC3551),
7.2.14-zen1 with this change applied. Before it, every hibernation since
2026-11-02 left the machine on after writing the image; with it, three
hibernations powered off, on mains and on battery, and both amplifiers
reloaded their firmware about one second after tasks restarted. Without
the change, setting "L0 DSP1 Firmware Load" and "R0 DSP1 Firmware Load"
to off before hibernating also avoided the hang. On sound/for-next the
change was build-tested only.

AI assistance: the fix was developed in an interactive session with
Claude Code (Claude Opus 5.5, Anthropic). The model read the journals
and the kernel source, proposed hypotheses and experiments, decoded the
pm_trace value and the pstore records, and wrote the change, the
changelog and these notes. I directed the investigation with a
troubleshooting procedure I wrote for the assistant (research before
experiments, one variable per test), supplied the observations, ran
every experiment on the machine, reviewed the change and tested it as
described above.
---
 sound/hda/codecs/side-codecs/cs35l41_hda.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/sound/hda/codecs/side-codecs/cs35l41_hda.c b/sound/hda/codecs/side-codecs/cs35l41_hda.c
index 6fbc194d3347..efe937d18330 100644
--- a/sound/hda/codecs/side-codecs/cs35l41_hda.c
+++ b/sound/hda/codecs/side-codecs/cs35l41_hda.c
@@ -1012,7 +1012,7 @@ static int cs35l41_system_resume(struct device *dev)
 
 	if (cs35l41->request_fw_load && !cs35l41->fw_request_ongoing) {
 		cs35l41->fw_request_ongoing = true;
-		schedule_work(&cs35l41->fw_load_work);
+		queue_work(system_freezable_wq, &cs35l41->fw_load_work);
 	}
 
 	return ret;

---
base-commit: 291d8707fa439ed4ec72552e7770177f6b6514e4
change-id: 20261111-cs35l41-freezable-fw-load-c9542cf8bda7

Best regards,
--  
Alban Munari <alban.kernel@gmail.com>

