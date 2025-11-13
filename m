From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v6 0/7] Input: synaptics-rmi4 - add quirks for third party
 touchscreen controllers
Date: Thu, 13 Nov 2025 17:30:56 +0100
Message-Id: <20251113-synaptics-rmi4-v6-0-d9836afab801@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMAHFmkC/3XMTQ6CMBCG4auYrq0p05YfV97DuKBlkFkIpCUNS
 Li7hQ0aYmb1TfK8M/PoCD27nmbmMJCnro0jPZ+Ybcr2iZyquBkI0EKKnPupLfuBrOfuRYrbXIK
 BOpMWDYuod1jTuAXvj7gb8kPnpq0f5Pr9mwqSCw6JriRmkBcl3Gik4WLfbA0FtWMl4IBVxIkxh
 Y6HOlW/WH/hRBywjtiolYs6y02x42VZPoQLJkkkAQAA
X-Change-ID: 20250308-synaptics-rmi4-c832b2f73ceb
To: Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Casey Connolly <casey.connolly@linaro.org>, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Krzysztof Kozlowski <krzk@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=4429; i=david@ixit.cz;
 h=from:subject:message-id; bh=zuMj9RMEudcE2kQnfLdF/50q8kfhTWUDSl/uQKepk8M=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpFgfIRc6yH3o3Jkil7PH1g1sm6uaUiWHGsbBvE
 rnJakh0t8qJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRYHyAAKCRBgAj/E00kg
 cnnPEACGwMZirsxaVrrEOKYt+D9/QuiLLFqGUGpr/FK8C6ASBiB0FxI1+eC2AggVsXP3UqhdlMK
 xfIXepYyY6mnVMb6ACQxahw6Wr/AglFBPobs4jBTBsvVNDbRRaoiBlKHY5aLZhN+oV+6jAo2zUl
 LH1F+30VXhdncBF1Q1Vr/BUOnz2wxbmIO+dmE/6b4SkQrC5j5tjvFY09lRybcPoZ4gEsYeVZyrC
 AJSFgJ9EAki8obPbyDhzp+3UMrgapaCHs8As5IEifPvs23YaGDHvTJ05HeMFPRsjmkz8ygMqvvB
 fmGfeGylgGHKUe3kWe2d2MOgvT+YJ1LldTaDbyiHgCoE+SE7YMNOGUiolNmPvPpVSwarlKgWxYc
 E4frVRbvJe5H35+rKyVB1xzLn3b2plu80LMei3+p6pieBNwiv6I2MpucZZ1TdzxFPNpYgz2Mg3o
 JCVtBITvQJE2A+PtPjFCfKBhUFc8VLHMfFgYnVKt+o1Lw3KS7mkR5Je2vJBN+W63f7ju5mSgPrt
 mLzI3lS5gzNxL6XF2TsbjXoZfEt3Yxn/6cPSpBi8h9vqk5b0Yl0J2T5JpPv7ED/d7/HEjvzCFmf
 T5bxYSvbZN548pfl4XB9mUUE0L64lrOJpWyiiSBM3uGptg1+dDfoGuHx4fLp3TpGnVxhcoTK/j1
 RFuWzqngZ4cVgvw==
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
  https://gitlab.com/sdm845/sdm845-next/-/commits/b4/synaptics-rmi4

---
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

David Heidelberg (1):
      dt-bindings: input: syna,rmi4: Document syna,rmi4-s3706b

Kaustabh Chakraborty (5):
      Input: synaptics-rmi4 - f12: use hardcoded values for aftermarket touch ICs
      Input: synaptics-rmi4 - f55: handle zero electrode count
      Input: synaptics-rmi4 - don't do unaligned reads in IRQ context
      Input: synaptics-rmi4 - read product ID on aftermarket touch ICs
      Input: synaptics-rmi4 - support fallback values for PDT descriptor bytes

 .../devicetree/bindings/input/syna,rmi4.yaml       |  11 +-
 drivers/input/rmi4/rmi_driver.c                    | 124 +++++++++++++++++----
 drivers/input/rmi4/rmi_driver.h                    |  10 ++
 drivers/input/rmi4/rmi_f01.c                       |  14 +++
 drivers/input/rmi4/rmi_f12.c                       | 117 ++++++++++++++-----
 drivers/input/rmi4/rmi_f55.c                       |   5 +
 include/linux/rmi.h                                |   3 +
 7 files changed, 234 insertions(+), 50 deletions(-)
---
base-commit: 6d7e7251d03f98f26f2ee0dfd21bb0a0480a2178
change-id: 20250308-synaptics-rmi4-c832b2f73ceb

Best regards,
-- 
David Heidelberg <david@ixit.cz>

