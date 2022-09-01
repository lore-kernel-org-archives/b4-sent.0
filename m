Subject: [PATCH RESEND v7 0/4] Completely fake series
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Thu, 01 Sep 2022 10:31:29 -0400
Message-Id: <20220825-test-endpoint-send-2-v7-0-821f03d2f76c@linuxfoundation.org>
To: mricon@kernel.org
X-Mailer: b4 0.10.0-dev-b62e0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1709;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=3Mhv2en+cacrLJ1SPDDXh5KWEJeZNbTWqZ9da0WcNaA=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJIFDjn1vbnM76XJbhLCInTUxni99L5ky0NFdTJBwekz5ood
 UjXvKGVhEONikBVTZCnbF7spqPChh1x6jynMHFYmkCEMXJwCMJHj1xgZvt+V3rpmm+W1hTfPr8tiMK
 gOs2ypaDh1tHG1dvy/dcdS9RgZfvtO/Onh5ZTq2lpqHDDz2cRJMh4MzDLTGq/80LOuDAxjAwA=
X-Developer-Key: i=konstantin@linuxfoundation.org; a=openpgp;
 fpr=DE0E66E32F1FDD0902666B96E63EDCA9329DD07E
X-Endpoint-Received: by B4 Submission Endpoint for konstantin@linuxfoundation.org/default with auth_id=3
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Another completely fake series to test b4 endpoint sending. Please
ignore it -- it's a random set of patches that exists elsewhere.

Signed-off-by: Konstantin Ryabitsev <konstantin@linuxfoundation.org>

---
Changes in v7:
- No changes, just junk
- Link to v6: https://lore.kernel.org/r/20220825-test-endpoint-send-2-v6-0-897ea7d26b87@linuxfoundation.org

Changes in v6:
- No changes, just junk.
- Link to v5: https://lore.kernel.org/r/20220825-test-endpoint-send-2-v5-0-9473e5c87f1a@linuxfoundation.org

Changes in v5:
- No changes, just junk.
- Link to v4: https://lore.kernel.org/r/20220825-test-endpoint-send-2-v4-0-30ef563fc249@linuxfoundation.org

Changes in v4:
- Rebased on v6.0-rc3
- Link to v3: https://lore.kernel.org/r/20220825-test-endpoint-send-2-v3-0-6e3357d699cd@linuxfoundation.org

Changes in v2:
- No changes
- Link to v1: https://lore.kernel.org/r/20220825-test-endpoint-send-2-v1-0-e732ebcaa48a@linuxfoundation.org

---
Clément Péron (4):
      arm64: defconfig: Enable devfreq cooling device
      arm64: dts: allwinner: h6: Add cooling map for GPU
      arm64: dts: allwinner: h6: Add GPU OPP table
      arm64: dts: allwinner: beelink-gs1: Enable GPU OPP

 .../boot/dts/allwinner/sun50i-h6-beelink-gs1.dts   |  2 +
 .../boot/dts/allwinner/sun50i-h6-gpu-opp.dtsi      | 88 ++++++++++++++++++++++
 arch/arm64/boot/dts/allwinner/sun50i-h6.dtsi       | 22 ++++++
 arch/arm64/configs/defconfig                       |  1 +
 4 files changed, 113 insertions(+)
---
base-commit: b90cb1053190353cc30f0fef0ef1f378ccc063c5
change-id: 20220825-test-endpoint-send-2-c923fec10d0b

Best regards,
-- 
Konstantin Ryabitsev <konstantin@linuxfoundation.org>