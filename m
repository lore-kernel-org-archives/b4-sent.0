Subject: [PATCH RESEND v3 0/4] Completely fake series
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Tue, 30 Aug 2022 09:31:25 -0400
Message-Id: <20220825-test-endpoint-send-2-v3-0-736c986dd55c@linuxfoundation.org>
X-b4-tracking: H4sIAC0RDmMC/43Oy6rCMBAG4FeRrM9IMrGn6sr3EBfTZGwDNZEkLYr03R10K+hqLvB/Mw9VOAcuar
 96qMxzKCFFGezfSrmBYs8QvMwKNaLeYgOVSwWO/ppCrFCkAwS3Q3tmZ7TXnZJoR4WhyxTdIOE4jaMs
 h1BqyvfXqdlIOX5RZwMauLXInSPabOkwhjjdzmmKnqo8uk65VyehZ/yFQ+Gs17pB09pNYw79hcK4du
 nyRuwviBWEvCP3b3yzw/bzT8uyPAFsmn7yWwEAAA==
To: mricon@kernel.org
X-Mailer: b4 0.10.0-dev-bfc54
X-Developer-Signature: v=1; a=openpgp-sha256; l=1101;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=7mHNgptN96qkzteBPQC69Oz8Eod6Pwb8cHeOjXMJSHQ=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJL5BHXfOVRdS+idNae/jSthfvSGL+Fms7nzfGeoyB6O3s9a
 t3FHRykLgxgXg6yYIkvZvthNQYUPPeTSe0xh5rAygQxh4OIUgIm4ujIydD2+opNmVd3Dls9uuu5P87
 w9M7o+m0zs8ffVfn/UxNG4h+GfmdgSxuP/jjxgPGujnKai/m1OfMDB004PKydtE1Q9rMLDDQA=
X-Developer-Key: i=konstantin@linuxfoundation.org; a=openpgp;
 fpr=DE0E66E32F1FDD0902666B96E63EDCA9329DD07E
X-Endpoint-Received: by B4 Submission Endpoint for konstantin@linuxfoundation.org/default with auth_id=3
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Another completely fake series to test b4 endpoint sending. Please
ignore it -- it's a random set of patches that exists elsewhere.

Signed-off-by: Konstantin Ryabitsev <konstantin@linuxfoundation.org>

---
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
base-commit: 4c2d0b039c5cc0112206a5b22431b577cb1c57ad
change-id: 20220825-test-endpoint-send-2-c923fec10d0b

Best regards,
-- 
Konstantin Ryabitsev <konstantin@linuxfoundation.org>
