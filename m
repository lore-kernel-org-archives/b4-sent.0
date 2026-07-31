From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v9 0/5] Input: synaptics-rmi4 - add quirks for third party
 touchscreen controllers
Date: Fri, 31 Jul 2026 22:34:11 +0200
Message-Id: <20260731-synaptics-rmi4-v9-0-f088c47af6c5@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XSS07DMBAG4KtEXmNke/yYZMU9EAs/qSWatnGIW
 qreHTcVtCFCXo2l7/fIM2dS4pBjIV1zJkOccsm7vhbtU0P8xvbvkeZQayKYUAwY0nLq7X7MvtB
 hmyX1CMKJZMBHRyraDzHl4xz4+lbrTS7jbjjN+RNcb/+NmoAyKrgKEI3A1oqXfMzjs/8i16BJ3
 rFkYoVlxdy5VtUTlZZLrB4wZyusKnbyylky6Nol1r+Ycw4rrCsOLYK2yTpkfInND9YMxPplUzG
 YFjQLkWNgS4yPWK4wzh+mMYiQNCZ1x5fbKIZ4+KwjHW/zIM6WSP1uu81j10BQ2rCgjbCRoUOvQ
 DrjYgw6KePRSRmNk0AeV6Fr5ma0MH+bSX3Zf+SRgm7RasFcXYlu4rWVyzdWZcxmZQIAAA==
X-Change-ID: 20250308-synaptics-rmi4-c832b2f73ceb
To: Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>, 
 Marcus Ramberg <marcus@means.no>, 
 Casey Connolly <casey.connolly@linaro.org>
Cc: David Heidelberg <david@ixit.cz>, linux-input@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5141; i=david@ixit.cz;
 h=from:subject:message-id; bh=nSDGjEKA51UJwmXKxoGd6bpjcAiKNzRHWUha+lzooIs=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqbQbLB3/EQaja+X50wQJeF3vf++Am48BACzrSo
 x1eUSESRQqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCam0GywAKCRBgAj/E00kg
 ckVnD/oCNuyTO3OTW8PHuj7DRPjx08jndk0DnvnvQsYot7A10knaFEiwDqAL2KUEv6iF22LUzEB
 tPoRBYK9fdUyo8UGcRJRex/q9+bG4wa1p8FolvYNENarcy/SJbvwLaDmLEvOpIpp2DXY0kYXM8k
 Ppns2GX8HjeS+kmOfknwBuzfXkjbHhEuIuo+tF0Auz8cEvsRcm7OsEATA//TIof/cNk3q/sGjDg
 oNmEaUHpN5TV+3irm2JNuwtoHomDvs5K74NXSKsKW7QB9AEMn91wnKYIYzkWv+UmXrZiuGqCLGW
 xo7Si5aFVx23vZpGWG46n4JKLlyEU/WPzi8lTVqrjtKWxTl6DQ/rc7yhes9RZM67lSCiFfPXUn+
 eIUpNTvlXTB9ZS5i2al/Q4JttmXOV0t6DhujLC4f5Rp379aQecJa0houehq+72TFfnKukNC6pur
 We2nn1fqKpTaDWZn+8aVprnW/sqYgeEYvIvkcTuNMioNUKSQ/tVqmfXfVCyKmXGATeHOYTy5HMK
 GtjFokPsTYkCLoWtEvSUUq+zgWCRo/8/OlNgNRWcDyvNg6sEdwy61c8fgPRhRzU2s5lvVbzDs+6
 IBl+Vpce8O3zIFLWCLktFi8DNYwrZ+s2rHQvDlunTK4GxQli+MuvhAgmjwCCIZOhAOOktAv+dHA
 J3nHprOcXlDKK8Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With the growing popularity of running upstream Linux on mobile devices,
we're beginning to run into more and more edgecases. The OnePlus 6 is a
fairly well supported 2018 era smartphone, selling over a million units
in it's first 22 days. With this level of popularity, it's almost
inevitable that we get third party replacement displays, and as a
result, replacement touchscreen controllers.

The OnePlus 6 shipped with an extremely usecase specific touchscreen
driver, it implemented only the bare minimum parts of the highly generic
rmi4 protocol, instead hardcoding most of the register addresses.
  
As a result, the third party touchscreen controllers that are often
found in replacement screens, implement only the registers that the 
downstream driver reads from. They additionally have other restrictions
such as heavy penalties on unaligned reads.
 
This series attempts to implement the necessary workaround to support  
some of these chips with the rmi4 driver. Although it's worth noting
that at the time of writing there are other unofficial controllers in
the wild that don't work even with these patches.
 
We have been shipping these patches in postmarketOS for the last several
years, and they are known to not cause any regressions on the OnePlus
6/6T (with the official Synaptics controller), however I don't own any
other rmi4 hardware to further validate this.

The series is also available (until merged) at
  https://codeberg.org/sdm845/linux/commits/b4/synaptics-rmi4

---
Changes in v9:
- Corrected the rmi_s3706_fallback_pdt sequence (dec -> hex). Thanks to
  Marcus.
- Separate changes moving the code around to own commit, send separately
  as
  Input: synaptics-rmi4 - f12: Move sensor initialization into own function
- Dropped `Input: synaptics-rmi4 - f55: handle zero electrode count` as
  it seems to be redundant and we cannot reproduce (at least for now).
- Link to v8: https://lore.kernel.org/r/20260324-synaptics-rmi4-v8-0-2168d2df68f5@ixit.cz

Changes in v8:
- The pdt_scan_state->pdts array should actually be of size
  (RMI_PDT_MAX+1). (Casey)
- Move the pdt_count introduction to the relevant patch. (Casey)
- Link to v7: https://lore.kernel.org/r/20260320-synaptics-rmi4-v7-0-379360de18d0@ixit.cz

Changes in v7:
- Rebased on top of next-20260320, no other changes.
- Link to v6: https://lore.kernel.org/r/20251113-synaptics-rmi4-v6-0-d9836afab801@ixit.cz

Changes in v6:
- Rebased on top of next-20251113.
- No other change since the Rob Herring comment.
- Link to v5: https://lore.kernel.org/r/20250410-synaptics-rmi4-v5-0-b41bb90f78b9@ixit.cz

Changes in v5:
- Removed -i2c suffix from rmi4-s3706b-i2c (Krzysztof).
- Link to v4: https://lore.kernel.org/r/20250402-synaptics-rmi4-v4-0-1bb95959e564@ixit.cz

Changes in v4:
- Replaced patch "dt-bindings: input: syna,rmi4: document syna,pdt-fallback-desc"
  with patch documenting specific touchscreen model used in OnePlus 6 and 6T.
- Fixed zero electrode return code (Dmitry).
- Switched the duplicate detection algo to bitmap (Dmitry).
- Optimized rmi_device_platform_data struct to avoid unnecessary
  padding.
- Changed fallback_size from int to unsigned int.
- Changed SoB from nickname and old address (methanal <baclofen@tuta.io>) to
  Kaustabh Chakraborty <kauschluss@disroot.org>.
  Verified ownership through the sdm845 chatroom on Matrix.
- Link to v3: https://lore.kernel.org/r/20250308-synaptics-rmi4-v3-0-215d3e7289a2@ixit.cz

Changes in v3:
- reworded dt-bindings property description
- fixed the rmi_driver_of_probe definition for non device-tree builds.
- fixed some indentation issues reported by checkpatch
- change rmi_pdt_entry_is_valid() variable to unsigned 
- Link to v2: https://lore.kernel.org/all/20230929-caleb-rmi4-quirks-v2-0-b227ac498d88@linaro.org

Changes in v2:
- Improve dt-bindings patch (thanks Rob)
- Add missing cast in patch 5 to fix the pointer arithmetic
- Link to v1: https://lore.kernel.org/r/20230929-caleb-rmi4-quirks-v1-0-cc3c703f022d@linaro.org

---
Casey Connolly (1):
      Input: synaptics-rmi4 - handle duplicate/unknown PDT entries

Kaustabh Chakraborty (4):
      Input: synaptics-rmi4 - f12: use hardcoded values for aftermarket touch ICs
      Input: synaptics-rmi4 - don't do unaligned reads in IRQ context
      Input: synaptics-rmi4 - read product ID on aftermarket touch ICs
      Input: synaptics-rmi4 - support fallback values for PDT descriptor bytes

 drivers/input/rmi4/rmi_driver.c | 125 +++++++++++++++++++++++++++++++++-------
 drivers/input/rmi4/rmi_driver.h |  10 ++++
 drivers/input/rmi4/rmi_f01.c    |  14 +++++
 drivers/input/rmi4/rmi_f12.c    |  76 ++++++++++++++++++++----
 include/linux/rmi.h             |   3 +
 5 files changed, 195 insertions(+), 33 deletions(-)
---
base-commit: 3d5670d672ae08b8c534b7beed6f57c8b44e7b43
change-id: 20250308-synaptics-rmi4-c832b2f73ceb
prerequisite-change-id: 20260627-synaptics-rmi4-fnsplit-3698a620b73c:v1
prerequisite-patch-id: 450869dc191388eb997574e376ee9c85991de503

Best regards,
--  
David Heidelberg <david@ixit.cz>

