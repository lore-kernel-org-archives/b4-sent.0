From: Marco Ziliani <rylos78@gmail.com>
Subject: [PATCH 0/3] media: i2c: ov5693: Fix mode changes, flips and
 autosuspend
Date: Tue, 27 Oct 2026 21:29:44 +0100
Message-Id: <20261027-ov5693-fixes-v1-0-3c8ab1ae104d@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ5AMBCF4avIrDVhpKWuIhbUYCyQDiIRd1csv
 7z87wIhzyRQRhd4Olh4mQPSOAI3NvNAirtgwARNmmCulkMbm6meTxJVkEObayxs1kBIVk/fEIq
 q/i17O5Hb3g+47wc/tte7cAAAAA==
X-Change-ID: 20261027-ov5693-fixes-8ec29752893a
To: Daniel Scally <dan.scally@ideasonboard.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, Chris Simpson <chris@nilk.net>, 
 Simon Kruse <simon0x+git@proton.me>, "D. Manresa" <dmanresa@gmail.com>, 
 linux-kernel@vger.kernel.org, Marco Ziliani <rylos78@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793132984; l=2340;
 i=rylos78@gmail.com; s=20261027; h=from:subject:message-id;
 bh=b+xs0p06/qWDzb+PB6KudqXqlOojT5He/NY8G0f4Yus=;
 b=bYnjA7bQi0B7AN/cS16FsNuFrp6oV/gD/3QR9pnQNOLPapiYWOIPuY+4LmsWbtgXL/pv4DSPH
 uGv30dHlRncCXFdCozIgweW1w7f/f/XW6eMuOEalPLB7fbGmteQCh/J
X-Developer-Key: i=rylos78@gmail.com; a=ed25519;
 pk=nXCfiK5yExPZCMp+lfKif3gdXkfjkUK2qk7bDW+ixMo=
X-Endpoint-Received: by B4 Relay for rylos78@gmail.com/20261027 with auth_id=1333
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Three fixes for the ov5693, found while getting the front camera of the
Microsoft Surface Pro 5 (IPU3) to work, and since tested on IPU6 and
IPU4P Surfaces as well.

Patch 1 programs the mode registers on every stream start. They are
only written on runtime PM resume, so a format change on a sensor that
stays powered never reaches the chip. This is the ov5693 counterpart of
commit 4e1446ac169a ("media: i2c: ov8865: Program the sensor on stream
start").

Patch 2 keeps the reported SBGGR10 order when a single flip is enabled
at full resolution: each flip moves the Bayer phase by one column, so
the output window is shifted by one column when hflip XOR vflip.

Patch 3 drops the usage count at stream stop with
pm_runtime_put_autosuspend(), so that the autosuspend delay counts from
stream stop rather than from the last resume.

Patch 1 has been public and in testing in the linux-surface tree since
2026-10-23 [2]. Simon Kruse's active state conversion [1], posted this
morning, makes the same change as part of a larger rework. Patch 1 is
kept here as a small standalone fix with a Fixes: tag, so that it can
be applied and backported on its own; should the rework land first, I
will rebase patches 2 and 3 on top of it.

Patches 1 and 2 were developed in the linux-surface tree and tested
there on a Surface Pro 5 (IPU3), a Surface Pro 7 (IPU4P) and a Surface
Pro 7+ and Pro 9 (IPU6); patch 3 follows a report by Dario Manresa in
the same thread [2]. The three patches as posted here have also been
run on a Surface Pro 7 (IPU4P) and a Surface Pro 9 (IPU6) there.

[1] https://lore.kernel.org/linux-media/20261027074933.21921-1-simon0x+git@proton.me/
[2] https://github.com/linux-surface/kernel/pull/181

Signed-off-by: Marco Ziliani <rylos78@gmail.com>
---
Marco Ziliani (3):
      media: i2c: ov5693: Program the mode registers on stream start
      media: i2c: ov5693: Keep the Bayer order when flipping at full resolution
      media: i2c: ov5693: Use autosuspend when stopping the stream

 drivers/media/i2c/ov5693.c | 71 ++++++++++++++++++++++++++++++++++++++++------
 1 file changed, 62 insertions(+), 9 deletions(-)
---
base-commit: d7e7bca7169873b46e857c025c10f3336c1258d8
change-id: 20261027-ov5693-fixes-8ec29752893a

Best regards,
--  
Marco Ziliani <rylos78@gmail.com>

