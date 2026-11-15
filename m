From: Ihor Urazov <z0rc3r@gmail.com>
Date: Sun, 15 Nov 2026 23:50:31 +0200
Subject: [PATCH] intel/ish: Link HP Panther Lake ISH firmware for ZBook 8
 G2i 14
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-hp-ish-ptl-zbook-8-g2i-link-v1-1-a27cf02d6b1d@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQ6CMAwA0F8hPdvEzUzUXzEe7CysQrZlRUIk/
 LtTj+/yVlAuwgqXZoXCs6ikWGF2Dfhwjz2jPKrB7u3RGOMwZBQNmKcR35TSgCfsreAocUBPLXX
 UHszZOahDLtzJ8tuvt7/1RU/207eEbfsAYMvj3n8AAAA=
X-Change-ID: 20261115-hp-ish-ptl-zbook-8-g2i-link-cb7bfb731955
To: linux-firmware@kernel.org
Cc: Pin-Hao Huang <pin-hao.huang@hp.com>, 
 Letitia Tsai <letitia.tsai@hp.com>, Ihor Urazov <z0rc3r@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2706; i=z0rc3r@gmail.com;
 h=from:subject:message-id; bh=TZKsZTzkTy0g/leC9rgDyaAS5w5tCosA7u0DOxen1Ao=;
 b=owGbwMvMwCWmab25vPXFu0bG02pJDFm/NLXZXn4pMhZmTopcpdn/NviNXazGzTlx/i8dOWpOh
 M3lMpnaUcrCIMbFICumyNK/z4BXW8hUnOmLzRuYOaxMIEMYuDgFYCJ86owMx9R8S31tg+dNj/f8
 0mcnwFXOeLz2371Qx/129/okpEqKGBk2310k+4Fr9ZR7nJMEdzc7rrvUaddpzqai1la6OeDx+je
 cAA==
X-Developer-Key: i=z0rc3r@gmail.com; a=openpgp;
 fpr=F7D877ECBB274E704A31F3AC5D006BEB7252F7F2
X-Endpoint-Received: by B4 Relay for z0rc3r@gmail.com/default with auth_id=1320
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

HP/ish/ish_ptl_12128606_581.7779.0.bin has no Link entry, so it is not
installed under any name the ISH loader requests. On the HP ZBook 8 G2i
14 (board 8ED9) the loader falls back to the generic image, which the
ISH rejects, and no ISH sensors are available:

  intel_ish_ipc 0000:00:12.0: ISH loader: load firmware: intel/ish/ish_ptl.bin
  intel_ish_ipc 0000:00:12.0: ISH loader: cmd 2 failed 10

Link the HP image under the vendor and product name CRC32 pair of this
model. The link is limited to the model it was tested on, as is the HP
Lunar Lake image. A vendor-only link for the same image was proposed
and tested on the HP EliteBook X Flip G2i 14 in [1], which was closed
without an answer from HP; HP is welcome to widen this link instead.

Tested on an HP ZBook 8 G2i 14 with BIOS Y70 01.02.08 and Linux 7.3.4:

  intel_ish_ipc 0000:00:12.0: ISH loader: load firmware: intel/ish/ish_ptl_12128606_93ec38f0.bin
  intel_ish_ipc 0000:00:12.0: ISH loader: firmware loaded. size:883200
  intel_ish_ipc 0000:00:12.0: ISH loader: FW base version: 5.8.1.7779

The ISH then enumerates and hid-sensor-hub exposes its ambient light
sensors.

Link: https://gitlab.com/kernel-firmware/linux-firmware/-/merge_requests/1259 [1]
Cc: Pin-Hao Huang <pin-hao.huang@hp.com>
Cc: Letitia Tsai <letitia.tsai@hp.com>
Assisted-by: Claude:claude-fable-5-2
Signed-off-by: Ihor Urazov <z0rc3r@gmail.com>
---
This only adds a WHENCE link for a firmware image HP submitted itself
in commit 1b9b0fbf ("Add HP ISH firmware for Intel Panther Lake
systems"). No binary is added or changed. I own the laptop and am not
affiliated with HP.

Pin-Hao, Letitia: could one of you ack this? The same link was
proposed in merge request 1259 and closed for lack of an answer from
HP. If you prefer the vendor-only name ish_ptl_12128606.bin from that
request, so that all HP Panther Lake systems pick the image up, say so
and I will send a v2.
---
 WHENCE | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/WHENCE b/WHENCE
index 100fefb7..c010f0a1 100644
--- a/WHENCE
+++ b/WHENCE
@@ -11654,6 +11654,8 @@ Link: intel/ish/ish_lnlm_12128606_f9751b71.bin -> ../../HP/ish/ish_lnlm_12128606
 Version: 5.8.200.7720_1029
 
 File: HP/ish/ish_ptl_12128606_581.7779.0.bin
+Link: intel/ish/ish_ptl_12128606_93ec38f0.bin -> ../../HP/ish/ish_ptl_12128606_581.7779.0.bin
+Info: product_name - "HP ZBook 8 G2i 14 inch Mobile Workstation PC"
 Version: 5.8.1.7779
 
 License: Redistributable. See LICENCE.HP for details

---
base-commit: 2b2c1f39d7ae274bfe56d829e62d3993249e3a82
change-id: 20261115-hp-ish-ptl-zbook-8-g2i-link-cb7bfb731955

Best regards,
--  
Ihor Urazov <z0rc3r@gmail.com>

