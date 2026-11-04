From: Babis Danias <b.danias@tutamail.com>
Subject: [PATCH 0/3] media: i2c: ov8856: Power management fixes
Date: Wed, 04 Nov 2026 11:42:46 +0200
Message-Id: <20261104-ov8856-pm-fixes-v1-0-1958b730ce66@tutamail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3LQQqAIBBA0avErBtQK5GuEi0kp5pFKgoSiHdPW
 j4+v0KmxJRhHSokKpw5+A45DnDc1l+E7LpBCaWlFBOGYsyiMT548ksZLc32nM1hlHLQr5joD33
 a9tY+AyQ1TWEAAAA=
X-Change-ID: 20261103-ov8856-pm-fixes-ae4af48c822d
To: Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Serin Yeh <serin.yeh@intel.com>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Robert Foss <rfoss@kernel.org>, Hans de Goede <hansg@kernel.org>, 
 Bryan O'Donoghue <bod@kernel.org>, 
 Kieran Bingham <kieran.bingham@ideasonboard.com>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Babis Danias <b.danias@tutamail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793785376; l=3510;
 i=b.danias@tutamail.com; s=20261103; h=from:subject:message-id;
 bh=zPCKpa1WxT4M3EkE/P1dF4rtOobF4YsW7HE3y7Bx0Rc=;
 b=hlq/5LDnJZbHu6nvEaS/l2qT8VJ6qGkqmFa8ejkbU3Q/DFNYw6vmgWbc0SI6n9DrkKJvTYL64
 xpWvyvq4bm0DcBrrIMr6Is2jF0IPKg1zt+UuoLV3lAnapV3WN8l4Ipv
X-Developer-Key: i=b.danias@tutamail.com; a=ed25519;
 pk=6DWeigdk0D3JwBjwvmxo9RW8cG8S1Eku42cb9PP+ghk=
X-Endpoint-Received: by B4 Relay for b.danias@tutamail.com/20261103 with auth_id=1406
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit 609a71568664 ("media: i2c: ov8856 : remove ACPI node
bypass mechanism") in v7.4-rc1, ov8856 also controls the sensor's power
on ACPI systems. Bringing up the rear camera of a Dell Latitude 7320
Detachable (OV8856 and a DW9714 VCM, behind a TPS68470 PMIC) on top of
that showed three power management bugs, fixed here:

1. remove() powers the sensor off even when runtime PM already has,
   giving unbalanced regulator and clock disables. This also affects
   devicetree systems, since 2020.

2. probe() registers the sub-device before enabling runtime PM, so
   ipu-bridge can't runtime-resume the sensor to instantiate its VCM
   (-EACCES).

3. With the VCM driver bound, the sensor stays powered through system
   suspend: the VCM's device link stops the sensor from using
   direct-complete, acpi_subsys_suspend() runtime-resumes it, and ov8856
   has no system sleep callbacks to power it off again.

Patches 1 and 2 fix older bugs, so they carry Cc: stable. Patch 3 does
too, because 609a71568664 is tagged for stable: the bug it brings in
will reach stable kernels with it.

Testing

Tested on a Dell Latitude 7320 Detachable (BIOS 1.39.0) running the
Fedora rawhide kernel 7.4.0-0.rc1.13.fc46, with these patches built out
of tree. The board also needs TPS68470 board data that isn't upstream
yet: the front camera entry from Sahan Nissanka's series adding board
data for the Dell 7320 Detachable, plus the rear sensor's supplies,
reset GPIO and VCM supply, which I plan to post once I've agreed it with
him. With that:

- unbinding and rebinding the sensor gives no warnings (before: the
  warnings quoted in patch 1, on every unbind);
- the VCM is instantiated, and the dw9714 driver binds and moves the
  lens (before: the -EACCES error quoted in patch 2, on every bind);
- in 20 s of s2idle with the camera idle, regulator and clock traces
  show the sensor powered for about 12 ms at suspend entry, then off
  (before: on for the whole suspend);
- streaming with libcamera's cam works at 1640x1232 and 3264x2448.

The "before" results, and the logs quoted in the patches, come from
Fedora's 7.2.15 kernel with 609a71568664 backported, where these
patches also passed the same tests. On v7.4-rc1 I tested with the
patches applied only. checkpatch.pl --strict is clean, and each patch
builds without warnings with W=1. I haven't run sparse or smatch.

AI assistance

I'm not a kernel developer. I did this work with the help of an AI
assistant, Claude Opus 5.5, in one long session. I asked it to help me
get the rear camera working, one step at a time. It read the kernel
code, proposed each test, analysed the logs and traces I sent back,
found the commits the Fixes: tags point to, ran the build and checkpatch
checks, and wrote all three patches, their commit messages and this
cover letter. I ran every test on the hardware and reviewed each change
line by line before signing off.

---
Babis Danias (3):
      media: i2c: ov8856: Don't power off a suspended sensor in remove()
      media: i2c: ov8856: Enable runtime PM before registering the sub-device
      media: i2c: ov8856: Power off the sensor during system suspend

 drivers/media/i2c/ov8856.c | 34 ++++++++++++++++++++++------------
 1 file changed, 22 insertions(+), 12 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261103-ov8856-pm-fixes-ae4af48c822d

Best regards,
-- 
Babis Danias <b.danias@tutamail.com>

