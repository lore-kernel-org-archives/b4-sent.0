From: Max Bretschneider <max.bretschneider@leica-geosystems.com>
Subject: [PATCH v2 0/4] media: i2c: ov08d10: use the subdev active state
 and add get_selection
Date: Sat, 24 Oct 2026 00:28:50 +0200
Message-Id: <20261024-ov08d10-get-selection-v2-0-f8c49972ca18@leica-geosystems.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKLf22oC/3WNyw6CMBREf4V0bU1vlQKu/A/Doo8LNAFqeptGQ
 vh3K3uXZzJzZmeE0SOxR7WziNmTD2sBeamYnfQ6IveuMJNCKtHJjocsWgeCj5g44Yw2lQW3Wjd
 GWdO6AVnZviMO/nN6X33hyVMKcTtvMvzS0wgC4I8xAwdeOzSo7jfVqPo5o7e6tAJtlHChqw0L6
 4/j+AKed3y/xQAAAA==
To: Jimmy Su <jimmy.su@intel.com>, Matthias Fend <matthias.fend@emfend.at>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, 
 Max Bretschneider <max.bretschneider@leica-geosystems.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792794706; l=3275;
 i=max.bretschneider@leica-geosystems.com; s=20260501;
 h=from:subject:message-id; bh=oNEbJ88MKt/pgzyIkNizvj1+LJU8OCz+hHF/MohQvGk=;
 b=0MAkuKBXNsy0Ea2kZjoRsfeij9FPgEPcXr5McPCGJBUnVNFE67b/kNZigLsDt3YIHB81Ge8sE
 8mRrr8iu4C0Ce8PfQFkTJo3PJfK+uBKu/X0AzGxPIaKflPYS/e5W0p1
X-Developer-Key: i=max.bretschneider@leica-geosystems.com; a=ed25519;
 pk=jf4ba33jrWlsOdGemi2InMtJAngoJVZU8Moetp0ixik=
X-Endpoint-Received: by B4 Relay for max.bretschneider@leica-geosystems.com/20260501 with auth_id=1161
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

v1 of this was a single patch adding get_selection. After review this grew
into four, three of which address points raised in the review.

Patch 1 fixes a NULL pointer dereference in ov08d10_get_hwcfg() and is
marked for stable.

Patches 2 and 3 port the driver to the subdev active state and drop the
cached current mode, both requested in review of v1. Dropping cur_mode
means the mode is now derived from the active state instead, for which a
small ov08d10_get_mode() helper was added.

Patch 4 then adds get_selection, the original change from v1. Without this
the driver never reports the analogue crop, so userspace cannot tell which
region of the pixel array each mode reads out.

Tested on a Hexagon/Leica CS50 (i.MX8MP, rkisp1) running 6.16.12 with the
equivalent of this series applied. Further tests on a more recent kernel
will be done in the coming weeks.

- Compile-tested against media/next, built with W=1, and checked with
  sparse and checkpatch --strict.
- The NULL dereference was first reproduced before the fix. With the fix
  applied, and dynamic debug enabled for that statement so that its
  arguments are actually evaluated, rebinding the driver prints
  "Using N data lanes" instead of oopsing.
- libcamera no longer reports "Unable to get rectangle" errors and no
  longer defaults PixelArraySize, PixelArrayActiveAreas or the analogue
  crop rectangle, all of which it did before.
- The crop rectangle is correct for all tested modes.
- Toggling HFLIP changes the media bus code reported on the source pad
  between SBGGR10 and SGBRG10, as expected.
- Streaming works in both the 3280x2460 and the 2x2 binned 1632x1224
  modes.
- v4l2-compliance 1.26.1 (SHA 4aee01a02792, 2023-12-12), run against the
  media device: 52 of 52 pass on the sensor subdev, no failures.
- With CONFIG_PROVE_LOCKING=y there were no lockdep reports across format
  and selection changes, both flips, exposure, gain and vblank writes,
  streaming in both modes, control writes while streaming, and a driver
  unbind/rebind cycle.

Mainly modelled on imx335, imx214, imx355.

---
Changes in v2:
- Fix the NULL pointer dereference in ov08d10_get_hwcfg(), Cc stable
- Port the driver to the subdev active state, drop the driver's
  own mutex in favor of the state lock shared with the control handler
- Drop the cached current mode and derive it from the active state
- Moved ov08d10_get_selection() out of the control handling section and
  appended it to the pad ops, keeping the driver's ordering
- Link to v1: https://lore.kernel.org/r/20261011-ov08d10-get-selection-v1-1-5debe6436765@leica-geosystems.com

---
Max Bretschneider (4):
      media: i2c: ov08d10: fix NULL pointer dereference in ov08d10_get_hwcfg()
      media: i2c: ov08d10: use the subdev active state
      media: i2c: ov08d10: drop the cached current mode
      media: i2c: ov08d10: add get_selection support

 drivers/media/i2c/ov08d10.c | 172 +++++++++++++++++++++++++++-----------------
 1 file changed, 106 insertions(+), 66 deletions(-)
---
base-commit: 2dcdfb625c3b8fe87454e19dfbc54b3e3f0ad70e
change-id: 20260929-ov08d10-get-selection-caa7b6cb8dfe

Best regards,
-- 
Max Bretschneider <max.bretschneider@leica-geosystems.com>

